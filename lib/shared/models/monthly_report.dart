import 'package:flutter/foundation.dart';

/// Aggregated stats for one calendar month — the data the monthly report
/// card and the "Driving Wrapped" full page render from.
@immutable
class MonthlyReport {
  const MonthlyReport({
    required this.year,
    required this.month,
    required this.tripCount,
    required this.totalDistanceKm,
    required this.totalDurationSeconds,
    required this.topSpeedKmh,
    required this.bestGforce,
    required this.mostActiveWeekday,
  });

  factory MonthlyReport.empty(int year, int month) => MonthlyReport(
    year: year,
    month: month,
    tripCount: 0,
    totalDistanceKm: 0,
    totalDurationSeconds: 0,
    topSpeedKmh: 0,
    bestGforce: 0,
    mostActiveWeekday: null,
  );

  final int year;
  final int month;
  final int tripCount;
  final double totalDistanceKm;
  final int totalDurationSeconds;
  final double topSpeedKmh;
  final double bestGforce;

  /// `DateTime.weekday` value (1=Mon … 7=Sun), or null if no trips.
  final int? mostActiveWeekday;

  bool get isEmpty => tripCount == 0;
}

/// Cross-month rollup for the profile screen's hero numbers.
@immutable
class LifetimeStats {
  const LifetimeStats({
    required this.tripCount,
    required this.totalDistanceKm,
    required this.topSpeedKmh,
    required this.bestGforce,
    this.totalDurationSeconds = 0,
    this.totalStoppedSeconds = 0,
    this.totalStopCount = 0,
    this.bestZeroToHundredSeconds,
    this.totalLeftTurns = 0,
    this.totalRightTurns = 0,
    this.totalLaneChanges = 0,
    this.totalHardBrakes = 0,
    this.bestMaxAcceleration = 0,
    this.bestMaxDeceleration = 0,
    this.bestCorneringSpeedKmh = 0,
  });

  factory LifetimeStats.empty() => const LifetimeStats(
    tripCount: 0,
    totalDistanceKm: 0,
    topSpeedKmh: 0,
    bestGforce: 0,
  );

  final int tripCount;
  final double totalDistanceKm;
  final double topSpeedKmh;
  final double bestGforce;

  final int totalDurationSeconds;
  final int totalStoppedSeconds;
  final int totalStopCount;

  /// Fastest 0→100 km/h run across every trip, or null if the user has
  /// never reached 100 km/h from a standstill.
  final double? bestZeroToHundredSeconds;

  final int totalLeftTurns;
  final int totalRightTurns;
  final int totalLaneChanges;

  /// Lifetime sum of the existing (g-force-based) hard-brake counter —
  /// already tracked per-trip, just not surfaced on Profile until now.
  final int totalHardBrakes;

  final double bestMaxAcceleration;
  final double bestMaxDeceleration;
  final double bestCorneringSpeedKmh;

  /// Average trip length — `totalDistanceKm / tripCount`, 0 when there
  /// are no trips.
  double get avgTripLengthKm => tripCount == 0 ? 0 : totalDistanceKm / tripCount;
}

/// One point on the profile's "last 6 months" distance trend chart.
@immutable
class MonthlyDistanceStat {
  const MonthlyDistanceStat({
    required this.year,
    required this.month,
    required this.distanceKm,
  });

  final int year;
  final int month;
  final double distanceKm;
}
