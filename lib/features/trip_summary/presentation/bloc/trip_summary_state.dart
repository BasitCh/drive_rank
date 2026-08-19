import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:flutter/foundation.dart';

enum TripSummaryStatus { loading, ready, notFound, deleted, error }

@immutable
class TripSummaryState {
  const TripSummaryState({
    required this.status,
    required this.trip,
    required this.points,
    required this.carLabel,
    required this.errorMessage,
    required this.isSharing,
    required this.speedGoalKmh,
    required this.distanceGoalKm,
    required this.bestTopSpeedKmh,
    required this.bestDistanceKm,
    this.isTransparent = false,
    this.vehicleType = VehicleType.car,
  });

  factory TripSummaryState.initial() => const TripSummaryState(
    status: TripSummaryStatus.loading,
    trip: null,
    points: <TripPoint>[],
    carLabel: '',
    errorMessage: null,
    isSharing: false,
    speedGoalKmh: null,
    distanceGoalKm: null,
    bestTopSpeedKmh: null,
    bestDistanceKm: null,
    isTransparent: false,
    vehicleType: VehicleType.car,
  );

  final TripSummaryStatus status;
  final TripRow? trip;
  final List<TripPoint> points;
  final String carLabel;
  final String? errorMessage;
  final bool isSharing;

  /// The user's currently selected vehicle (Settings) — drives which
  /// icon animates along the route on the replay screen.
  final VehicleType vehicleType;

  /// The user's current "beat this" targets (see `GoalCalculator`) —
  /// always the live/current goal, not a snapshot from when this trip
  /// was driven, so revisiting an old trip's summary shows today's
  /// goal rather than a stale one.
  final double? speedGoalKmh;
  final double? distanceGoalKm;

  /// The current all-time-best trip's stats — the "previous" half of
  /// the goal nudge. Not necessarily this trip's own stats.
  final double? bestTopSpeedKmh;
  final double? bestDistanceKm;

  /// Whether the shareable stat card exports with a transparent
  /// background (for Instagram Stories overlays).
  final bool isTransparent;

  TripSummaryState copyWith({
    TripSummaryStatus? status,
    TripRow? trip,
    List<TripPoint>? points,
    String? carLabel,
    String? errorMessage,
    bool? isSharing,
    double? speedGoalKmh,
    double? distanceGoalKm,
    double? bestTopSpeedKmh,
    double? bestDistanceKm,
    bool? isTransparent,
    VehicleType? vehicleType,
  }) {
    return TripSummaryState(
      status: status ?? this.status,
      trip: trip ?? this.trip,
      points: points ?? this.points,
      carLabel: carLabel ?? this.carLabel,
      errorMessage: errorMessage ?? this.errorMessage,
      isSharing: isSharing ?? this.isSharing,
      speedGoalKmh: speedGoalKmh ?? this.speedGoalKmh,
      distanceGoalKm: distanceGoalKm ?? this.distanceGoalKm,
      bestTopSpeedKmh: bestTopSpeedKmh ?? this.bestTopSpeedKmh,
      bestDistanceKm: bestDistanceKm ?? this.bestDistanceKm,
      isTransparent: isTransparent ?? this.isTransparent,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }
}
