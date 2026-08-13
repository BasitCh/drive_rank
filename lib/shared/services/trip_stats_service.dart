import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:injectable/injectable.dart';

/// Aggregations over the trips table — distinct from `TripRepository`
/// because these compute roll-ups (sums, maxes, most-active-day) rather
/// than returning rows.
@lazySingleton
class TripStatsService {
  TripStatsService(this._trips);

  final TripRepository _trips;

  /// Aggregates all trips for the given calendar month. Returns an empty
  /// report if there are none.
  Future<MonthlyReport> monthlyReport({
    required String uid,
    required int year,
    required int month,
  }) async {
    final trips = await _trips.getTripsInMonth(
      uid: uid,
      year: year,
      month: month,
    );
    if (trips.isEmpty) return MonthlyReport.empty(year, month);
    return _aggregateMonthly(trips, year, month);
  }

  /// Cross-trip totals for the profile screen.
  Future<LifetimeStats> lifetime({required String uid}) async {
    final all = await _trips.watchAll(uid: uid).first;
    if (all.isEmpty) return LifetimeStats.empty();
    var distance = 0.0;
    var topSpeed = 0.0;
    var bestG = 0.0;
    for (final t in all) {
      distance += t.distanceKm;
      if (t.topSpeedKmh > topSpeed) topSpeed = t.topSpeedKmh;
      if (t.maxGforce > bestG) bestG = t.maxGforce;
    }
    return LifetimeStats(
      tripCount: all.length,
      totalDistanceKm: distance,
      topSpeedKmh: topSpeed,
      bestGforce: bestG,
    );
  }

  MonthlyReport _aggregateMonthly(List<TripRow> trips, int year, int month) {
    var distance = 0.0;
    var duration = 0;
    var topSpeed = 0.0;
    var bestG = 0.0;
    final perWeekday = <int, int>{};
    for (final t in trips) {
      distance += t.distanceKm;
      duration += t.durationSeconds;
      if (t.topSpeedKmh > topSpeed) topSpeed = t.topSpeedKmh;
      if (t.maxGforce > bestG) bestG = t.maxGforce;
      perWeekday.update(t.startedAt.weekday, (n) => n + 1, ifAbsent: () => 1);
    }
    int? mostActive;
    var bestCount = -1;
    perWeekday.forEach((day, count) {
      if (count > bestCount) {
        bestCount = count;
        mostActive = day;
      }
    });
    return MonthlyReport(
      year: year,
      month: month,
      tripCount: trips.length,
      totalDistanceKm: distance,
      totalDurationSeconds: duration,
      topSpeedKmh: topSpeed,
      bestGforce: bestG,
      mostActiveWeekday: mostActive,
    );
  }
}
