import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class TrackingEvent {
  const TrackingEvent();
}

/// User tapped Start Trip on the idle home screen. The bloc resolves
/// permission, then spins up GPS / sensor streams. Never auto-fired.
class TrackingStartRequested extends TrackingEvent {
  const TrackingStartRequested();
}

/// User tapped End Trip on the live screen and confirmed the dialog.
/// The bloc tears down streams, persists the trip, and emits the
/// resulting tripId in `completedTripId` so the page can route to the
/// trip summary.
class TrackingStopRequested extends TrackingEvent {
  const TrackingStopRequested();
}

/// User tapped Grant Permission on the gate (permissionDenied phase).
class TrackingPermissionRequested extends TrackingEvent {
  const TrackingPermissionRequested();
}

/// App resumed from background — passively re-read the OS location
/// status. Unlike [TrackingPermissionRequested] this never prompts;
/// it just reflects what the OS already grants. Used after the user
/// returns from Settings so the permission gate drops back to idle if
/// they flipped the toggle on.
class TrackingPermissionRechecked extends TrackingEvent {
  const TrackingPermissionRechecked();
}

/// User tapped Pause during an active trip. Stops GPS + sensor streams
/// and freezes the ticker — the trip stays in progress until End.
class TrackingPauseRequested extends TrackingEvent {
  const TrackingPauseRequested();
}

/// User tapped Resume from a paused trip. Re-spins up streams and
/// shifts `_startedAt` so the duration ticker resumes from where it
/// stopped (paused time is not counted).
class TrackingResumeRequested extends TrackingEvent {
  const TrackingResumeRequested();
}

/// Internal — a new Kalman-filtered point arrived from `GpsService`.
class TrackingPointReceived extends TrackingEvent {
  const TrackingPointReceived(this.point);
  final TripPoint point;
}

/// Internal — a new g-force value arrived from `SensorService`.
class TrackingGforceReceived extends TrackingEvent {
  const TrackingGforceReceived(this.gforce);
  final double gforce;
}

/// Internal — duration ticker fired (once per second).
class TrackingTicked extends TrackingEvent {
  const TrackingTicked();
}

/// Reset to the idle state — used after the user finishes the trip
/// summary and returns to home so the next trip starts from a clean
/// slate.
class TrackingReset extends TrackingEvent {
  const TrackingReset();
}

/// Internal — fired by the bloc constructor on every cold start. If
/// the `ActiveTripStore` holds a snapshot from a previous (interrupted)
/// session, the bloc restores those stats into a `paused` state so the
/// user can tap Resume to continue tracking instead of losing the trip.
class TrackingRestoreFromCrash extends TrackingEvent {
  const TrackingRestoreFromCrash();
}
