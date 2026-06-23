import 'package:drive_rank/core/services/permission_service.dart';
import 'package:drive_rank/features/tracking/domain/entities/live_trip_stats.dart';
import 'package:flutter/foundation.dart';

/// Discrete phases of the live tracking screen.
///
/// The lifecycle is:
///   idle → starting → active ⇄ paused → stopping → idle
/// with `permissionDenied` and `error` as terminal branches that loop
/// back to `idle` once the user resolves them.
enum TrackingPhase {
  /// No trip in progress. Home page shows the Start Trip button + the
  /// free-trips-remaining counter. Default state on app launch — GPS
  /// must never be running.
  idle,

  /// User tapped Start Trip. We're requesting permission / spinning up
  /// the GPS and sensor streams. Brief — usually <1s.
  starting,

  /// A trip is recording. The hero number is live, the map strip is
  /// drawing the polyline, the End Trip button is visible.
  active,

  /// User tapped Pause. GPS + sensors are stopped, the duration ticker
  /// is frozen — but the trip is NOT ended: accumulated stats stay on
  /// screen and the user can Resume or End from here. Counts as the
  /// same trip when finally ended.
  paused,

  /// User tapped End Trip. Tearing down streams, persisting the trip
  /// row + waypoints to Drift. Brief — usually <500ms.
  stopping,

  /// Location permission is denied or location services are off at the
  /// OS level. The page shows a gate with a Grant Permission / Open
  /// Settings button.
  permissionDenied,

  /// The user tapped Start before they've ever seen the in-app
  /// Prominent Disclosure. Page renders a modal with the disclosure
  /// copy; tapping Continue acks the disclosure and continues the
  /// start sequence. Tapping Not now acks and bounces back to idle.
  /// Required by the Google Play User Data policy: the disclosure
  /// must precede the system permission dialog.
  needsLocationDisclosure,

  /// Something went wrong. Page shows the error message + a Retry
  /// button that re-emits StartRequested.
  error,
}

/// Origin story of the current `paused` state — drives the recovery
/// banner copy on the tracking page.
enum TripRecoveryStatus {
  /// No recovery happened; trip is fresh (also the default for any
  /// non-paused state).
  fresh,

  /// The user paused the trip explicitly. Standard pause/resume UX.
  userPaused,

  /// The bloc detected on cold start that a prior session's last
  /// snapshot was stale — the OS killed us mid-trip. The recovery
  /// banner explains and offers Resume / Save / Discard.
  interruptedByOs,
}

@immutable
class TrackingState {
  const TrackingState({
    required this.phase,
    required this.stats,
    required this.permissionStatus,
    required this.completedTripId,
    required this.shouldShowPaywall,
    required this.errorMessage,
    required this.recoveryStatus,
  });

  factory TrackingState.initial() => TrackingState(
    phase: TrackingPhase.idle,
    stats: LiveTripStats.initial(),
    permissionStatus: null,
    completedTripId: null,
    shouldShowPaywall: false,
    errorMessage: null,
    recoveryStatus: TripRecoveryStatus.fresh,
  );

  final TrackingPhase phase;
  final LiveTripStats stats;
  final LocationPermissionStatus? permissionStatus;

  /// Id of the just-saved trip. Set when `phase` transitions to `idle`
  /// after a successful stop — the page listens for this and pushes
  /// the user to `/trip-summary/<id>`. Cleared on the next `idle`.
  final int? completedTripId;

  /// True when the just-completed trip pushed the user over the
  /// free-trip limit (and they're not already Pro). The tracking page
  /// listens for this and routes /home → trip summary → paywall.
  final bool shouldShowPaywall;

  /// Human-readable error copy shown in the error-state gate.
  final String? errorMessage;

  /// Why we're in `paused` — used by the page to decide between the
  /// normal pause UI and the "your trip was interrupted" recovery
  /// banner.
  final TripRecoveryStatus recoveryStatus;

  bool get isRecording =>
      phase == TrackingPhase.active || phase == TrackingPhase.paused;

  TrackingState copyWith({
    TrackingPhase? phase,
    LiveTripStats? stats,
    LocationPermissionStatus? permissionStatus,
    int? completedTripId,
    bool? shouldShowPaywall,
    String? errorMessage,
    TripRecoveryStatus? recoveryStatus,
    bool clearCompletedTripId = false,
    bool clearError = false,
  }) {
    return TrackingState(
      phase: phase ?? this.phase,
      stats: stats ?? this.stats,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      completedTripId: clearCompletedTripId
          ? null
          : (completedTripId ?? this.completedTripId),
      shouldShowPaywall: shouldShowPaywall ?? this.shouldShowPaywall,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      recoveryStatus: recoveryStatus ?? this.recoveryStatus,
    );
  }
}
