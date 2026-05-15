import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:flutter/foundation.dart';

/// Phase of the live tracking screen.
enum TrackingPhase {
  /// Initial — bloc just constructed, nothing has resolved yet.
  initial,

  /// We need location permission and haven't asked / been denied.
  permissionRequired,

  /// Location services are off at the OS level.
  servicesDisabled,

  /// Streams are subscribed but no GPS fix yet.
  waitingForFix,

  /// Recording a trip.
  recording,

  /// User stopped the trip — final stats are exposed for navigation to
  /// the trip summary page.
  finished,
}

@immutable
class TrackingState {
  const TrackingState({
    required this.phase,
    required this.stats,
    required this.permissionStatus,
    required this.completedTripId,
  });

  factory TrackingState.initial() => TrackingState(
    phase: TrackingPhase.initial,
    stats: LiveTripStats.initial(),
    permissionStatus: null,
    completedTripId: null,
  );

  final TrackingPhase phase;
  final LiveTripStats stats;
  final LocationPermissionStatus? permissionStatus;
  final int? completedTripId;

  bool get isRecording => phase == TrackingPhase.recording;

  TrackingState copyWith({
    TrackingPhase? phase,
    LiveTripStats? stats,
    LocationPermissionStatus? permissionStatus,
    int? completedTripId,
  }) {
    return TrackingState(
      phase: phase ?? this.phase,
      stats: stats ?? this.stats,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      completedTripId: completedTripId ?? this.completedTripId,
    );
  }
}
