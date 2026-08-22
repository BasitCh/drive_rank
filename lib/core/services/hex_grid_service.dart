import 'dart:math' as math;

import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:latlong2/latlong.dart';

/// Pure lat/lng ↔ hex-cell math for the "Territory Conquered" feature.
///
/// No hex-grid library (H3, etc.) is a dependency of this project. True
/// H3 is geodesically exact at planet scale via icosahedral projection
/// math — overkill for a single-country "explored area" reveal map, and
/// a real reimplementation-correctness risk to hand-roll from scratch.
/// This is a flat, local **axial** hex grid instead: lat/lng is treated
/// as locally planar (the standard simplification at country/city
/// scale — accurate within a single user's realistic driving footprint,
/// not intended to be geodesically exact across thousands of km). Same
/// visual/gamification result, zero new dependencies, no native-build
/// risk.
///
/// Pointy-top orientation, axial coordinates — see redblobgames.com's
/// hexagonal-grids reference for the formulas this mirrors.
///
/// Every method is `static` and touches no instance/DI state — safe to
/// call both from the main isolate (e.g. rendering the Territory page)
/// and as a `compute()` isolate entry point (e.g.
/// `TripStatsService`/`TerritoryStatsService` walking every waypoint of
/// every trip).
class HexGridService {
  const HexGridService._();

  static const double cellRadiusMeters = AppConstants.territoryCellRadiusMeters;
  static const double _metresPerDegLat = 111320;

  static double _metresPerDegLng(double latDeg) =>
      111320 * math.cos(latDeg * math.pi / 180);

  /// Area of one regular hexagon cell (circumradius = side length =
  /// [cellRadiusMeters]), in km².
  static const double cellAreaKm2 =
      (3 * 1.7320508075688772 / 2) * // 3√3/2
      cellRadiusMeters *
      cellRadiusMeters /
      1e6;

  /// Stable id for the hex cell containing [lat]/[lng] — the same
  /// real-world spot always maps to the same id, regardless of which
  /// waypoint or session produced it.
  static String cellIdFor(double lat, double lng) {
    final (q, r) = _latLngToAxial(lat, lng);
    return '$q,$r';
  }

  /// The 6 corner points (lat/lng, in order) of the hex cell identified
  /// by [cellId] (as returned by [cellIdFor]) — for rendering as a
  /// filled `Polygon`.
  static List<LatLng> cellCorners(String cellId) {
    final parts = cellId.split(',');
    final q = int.parse(parts[0]);
    final r = int.parse(parts[1]);
    final centerX = cellRadiusMeters * math.sqrt(3) * (q + r / 2);
    final centerY = cellRadiusMeters * 1.5 * r;
    // The y-axis inversion (below) doesn't depend on latitude, so we
    // can recover the true latitude first and then correctly invert x
    // with the right per-latitude longitude scale — no chicken/egg
    // problem despite the projection being latitude-dependent.
    final lat = centerY / _metresPerDegLat;
    final metresPerDegLng = _metresPerDegLng(lat);
    return [
      for (var i = 0; i < 6; i++)
        _cornerLatLng(centerX, centerY, i, metresPerDegLng),
    ];
  }

  static LatLng _cornerLatLng(
    double centerX,
    double centerY,
    int index,
    double metresPerDegLng,
  ) {
    final angleRad = math.pi / 180 * (60 * index - 30);
    final x = centerX + cellRadiusMeters * math.cos(angleRad);
    final y = centerY + cellRadiusMeters * math.sin(angleRad);
    return LatLng(y / _metresPerDegLat, x / metresPerDegLng);
  }

  static (int, int) _latLngToAxial(double lat, double lng) {
    final x = lng * _metresPerDegLng(lat);
    final y = lat * _metresPerDegLat;
    final qf = (math.sqrt(3) / 3 * x - 1 / 3 * y) / cellRadiusMeters;
    final rf = (2 / 3 * y) / cellRadiusMeters;
    return _cubeRound(qf, rf);
  }

  /// Rounds fractional axial coordinates to the nearest hex cell via
  /// cube-coordinate rounding (the standard technique — rounding q/r
  /// independently can land outside the intended cell).
  static (int, int) _cubeRound(double qf, double rf) {
    final xf = qf;
    final zf = rf;
    final yf = -xf - zf;
    var x = xf.round();
    var y = yf.round();
    var z = zf.round();
    final xDiff = (x - xf).abs();
    final yDiff = (y - yf).abs();
    final zDiff = (z - zf).abs();
    if (xDiff > yDiff && xDiff > zDiff) {
      x = -y - z;
    } else if (yDiff > zDiff) {
      y = -x - z;
    } else {
      z = -x - y;
    }
    return (x, z);
  }
}
