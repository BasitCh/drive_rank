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
    this.leftTurnCount = 0,
    this.rightTurnCount = 0,
    this.laneChangeCount = 0,
    this.maxAccelerationMps2 = 0,
    this.maxDecelerationMps2 = 0,
    this.topCorneringSpeedKmh = 0,
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
    leftTurnCount: 0,
    rightTurnCount: 0,
    laneChangeCount: 0,
    maxAccelerationMps2: 0,
    maxDecelerationMps2: 0,
    topCorneringSpeedKmh: 0,
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

  /// Heading-based turn-direction counts — additive to, not a
  /// replacement for, [hardCornersCount]. See
  /// `AppConstants.turnHeadingDeltaThresholdDeg`.
  final int leftTurnCount;
  final int rightTurnCount;

  /// Heuristic lane-change count — see
  /// `AppConstants.laneChangeHeadingDeltaMinDeg`.
  final int laneChangeCount;

  /// Peak acceleration/deceleration (m/s²), derived from Δspeed/Δt —
  /// not the accelerometer. See `AppConstants.maxPlausibleAccelMps2`.
  final double maxAccelerationMps2;
  final double maxDecelerationMps2;

  /// Fastest speed recorded at the instant of any detected turn.
  final double topCorneringSpeedKmh;

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
    int? leftTurnCount,
    int? rightTurnCount,
    int? laneChangeCount,
    double? maxAccelerationMps2,
    double? maxDecelerationMps2,
    double? topCorneringSpeedKmh,
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
      leftTurnCount: leftTurnCount ?? this.leftTurnCount,
      rightTurnCount: rightTurnCount ?? this.rightTurnCount,
      laneChangeCount: laneChangeCount ?? this.laneChangeCount,
      maxAccelerationMps2: maxAccelerationMps2 ?? this.maxAccelerationMps2,
      maxDecelerationMps2: maxDecelerationMps2 ?? this.maxDecelerationMps2,
      topCorneringSpeedKmh:
          topCorneringSpeedKmh ?? this.topCorneringSpeedKmh,
    );
  }
}
