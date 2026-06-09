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
    );
  }
}
