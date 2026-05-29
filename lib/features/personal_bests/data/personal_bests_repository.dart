import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/personal_bests/domain/personal_bests.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:injectable/injectable.dart';

/// Computes [PersonalBests] from the local Drift trips table.
///
/// MVP scope: everything is recomputed on demand — there's no caching
/// layer because the table is small (one row per trip) and the
/// aggregation is O(n) with tiny constants. If trips ever grow to
/// tens of thousands per user, swap this for a Drift query that
/// pushes max/sum/avg down to SQLite.
@lazySingleton
class PersonalBestsRepository {
  PersonalBestsRepository(this._trips, this._settings);

  final TripRepository _trips;
  final UserSettingsRepository _settings;

  /// Trips below this duration are dropped from the "best average
  /// speed" calc — they're nearly always GPS noise / user mistakes,
  /// and one spurious 200 km/h average from a 2-second trip would
  /// drown the real number.
  static const int _bestAvgMinDurationSeconds = 10;

  /// Reactive feed — emits a new [PersonalBests] every time the
  /// trips table changes. The bloc subscribes to this so the screen
  /// updates the instant a new trip lands without any explicit
  /// refresh signal.
  Stream<PersonalBests> watch() async* {
    final settings = await _settings.read();
    yield* _trips.watchAll(uid: settings.uid).map(_aggregate);
  }

  PersonalBests _aggregate(List<TripRow> trips) {
    if (trips.isEmpty) return PersonalBests.empty();

    var top = 0.0;
    var longest = 0.0;
    var totalKm = 0.0;
    var totalSec = 0;
    var bestAvg = 0.0;

    for (final t in trips) {
      if (t.topSpeedKmh > top) top = t.topSpeedKmh;
      if (t.distanceKm > longest) longest = t.distanceKm;
      totalKm += t.distanceKm;
      totalSec += t.durationSeconds;
      if (t.durationSeconds >= _bestAvgMinDurationSeconds &&
          t.avgSpeedKmh > bestAvg) {
        bestAvg = t.avgSpeedKmh;
      }
    }

    return PersonalBests(
      totalTrips: trips.length,
      topSpeedKmh: top,
      longestTripKm: longest,
      totalDistanceKm: totalKm,
      bestAvgSpeedKmh: bestAvg,
      totalDriveSeconds: totalSec,
    );
  }
}
