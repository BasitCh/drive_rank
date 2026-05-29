import 'package:flutter/foundation.dart';

/// Local-only roll-up the Personal Bests screen renders.
///
/// Every value is computed on demand from the trips table; nothing here
/// is denormalised or cached. Six values were chosen because they fit
/// cleanly in a 2×3 grid and each one reflects a different *kind* of
/// achievement (peak, endurance, cadence) — gives the user a real
/// rewarding hit without slipping into vanity-metric territory.
@immutable
class PersonalBests {
  const PersonalBests({
    required this.totalTrips,
    required this.topSpeedKmh,
    required this.longestTripKm,
    required this.totalDistanceKm,
    required this.bestAvgSpeedKmh,
    required this.totalDriveSeconds,
  });

  factory PersonalBests.empty() => const PersonalBests(
    totalTrips: 0,
    topSpeedKmh: 0,
    longestTripKm: 0,
    totalDistanceKm: 0,
    bestAvgSpeedKmh: 0,
    totalDriveSeconds: 0,
  );

  /// Number of trips saved on this device.
  final int totalTrips;

  /// Peak speed ever recorded across every trip (km/h).
  final double topSpeedKmh;

  /// Distance of the single longest trip (km).
  final double longestTripKm;

  /// Cumulative distance across every trip (km).
  final double totalDistanceKm;

  /// Highest average speed of any single trip (km/h). Filters out trips
  /// shorter than ~10 seconds so a one-second "End Trip" press right
  /// after Start doesn't spike the metric to whatever the GPS sample
  /// happened to read at that instant.
  final double bestAvgSpeedKmh;

  /// Cumulative drive time across every trip (seconds).
  final int totalDriveSeconds;

  bool get isEmpty => totalTrips == 0;
}
