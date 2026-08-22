import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/constants/country_areas.dart';
import 'package:drive_rank/core/services/hex_grid_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/models/territory_stats.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:injectable/injectable.dart';

/// Aggregates "Territory Conquered" — every hex cell (see
/// `HexGridService`) the user has ever driven through, across all
/// trips. Walks every waypoint of every trip, so the actual cell-set
/// computation runs in a background isolate.
@lazySingleton
class TerritoryStatsService {
  TerritoryStatsService(this._trips);

  final TripRepository _trips;

  /// Full stats, including the visited cell ids — used by the
  /// full-screen Territory map page.
  Future<TerritoryStats> territory({
    required String uid,
    String? countryCode,
  }) async {
    final waypoints = await _allWaypoints(uid);
    if (waypoints.isEmpty) return TerritoryStats.empty();
    final cellIds = await compute(_visitedCellIds, waypoints);
    return _statsFrom(cellIds, countryCode);
  }

  Future<List<TripPoint>> _allWaypoints(String uid) async {
    final trips = await _trips.watchAll(uid: uid).first;
    final all = <TripPoint>[];
    for (final t in trips) {
      all.addAll(await _trips.getWaypoints(t.id));
    }
    return all;
  }

  TerritoryStats _statsFrom(Set<String> cellIds, String? countryCode) {
    final areaKm2 = cellIds.length * HexGridService.cellAreaKm2;
    final countryAreaKm2 = countryCode == null
        ? null
        : kCountryAreaKm2[countryCode];
    return TerritoryStats(
      cellCount: cellIds.length,
      areaKm2: areaKm2,
      percentOfEarth: areaKm2 / AppConstants.earthLandAreaKm2 * 100,
      percentOfCountry: countryAreaKm2 == null
          ? null
          : areaKm2 / countryAreaKm2 * 100,
      cellIds: cellIds.toList(growable: false),
    );
  }
}

/// Isolate entry point — pure, no DI/instance state. Maps every
/// waypoint to its hex-cell id and returns the distinct set.
Set<String> _visitedCellIds(List<TripPoint> waypoints) {
  final cells = <String>{};
  for (final p in waypoints) {
    cells.add(HexGridService.cellIdFor(p.lat, p.lng));
  }
  return cells;
}
