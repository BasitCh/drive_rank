import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:flutter/foundation.dart';

/// Snapshot of an in-progress trip — what the live tracking page renders.
///
/// All speed/distance values are metric internally (km/h, km). The display
/// layer (`LocaleService`) converts on render.
@immutable
class LiveTripStats {
  const LiveTripStats({
    required this.currentSpeedKmh,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.distanceKm,
    required this.durationSeconds,
    required this.maxGforce,
    required this.hardCornersCount,
    required this.hardBrakesCount,
    required this.lastPoint,
    required this.points,
    this.stoppedSeconds = 0,
    this.stopCount = 0,
  });

  factory LiveTripStats.initial() => const LiveTripStats(
    currentSpeedKmh: 0,
    maxSpeedKmh: 0,
    avgSpeedKmh: 0,
    distanceKm: 0,
    durationSeconds: 0,
    maxGforce: 0,
    hardCornersCount: 0,
    hardBrakesCount: 0,
    lastPoint: null,
    points: <TripPoint>[],
    stoppedSeconds: 0,
    stopCount: 0,
  );

  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final double distanceKm;
  final int durationSeconds;
  final double maxGforce;
  final int hardCornersCount;
  final int hardBrakesCount;
  final TripPoint? lastPoint;
  final List<TripPoint> points;

  /// Total seconds spent in contiguous zero-speed runs of at least
  /// `AppConstants.stopMinDurationSeconds` — see `TrackingBloc._onPoint`.
  final int stoppedSeconds;

  /// Number of qualifying stops (see [stoppedSeconds]) this trip.
  final int stopCount;

  LiveTripStats copyWith({
    double? currentSpeedKmh,
    double? maxSpeedKmh,
    double? avgSpeedKmh,
    double? distanceKm,
    int? durationSeconds,
    double? maxGforce,
    int? hardCornersCount,
    int? hardBrakesCount,
    TripPoint? lastPoint,
    List<TripPoint>? points,
    int? stoppedSeconds,
    int? stopCount,
  }) {
    return LiveTripStats(
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      maxGforce: maxGforce ?? this.maxGforce,
      hardCornersCount: hardCornersCount ?? this.hardCornersCount,
      hardBrakesCount: hardBrakesCount ?? this.hardBrakesCount,
      lastPoint: lastPoint ?? this.lastPoint,
      points: points ?? this.points,
      stoppedSeconds: stoppedSeconds ?? this.stoppedSeconds,
      stopCount: stopCount ?? this.stopCount,
    );
  }
}
