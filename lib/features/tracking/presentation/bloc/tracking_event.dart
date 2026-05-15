import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class TrackingEvent {
  const TrackingEvent();
}

/// Page-init lifecycle event — checks/requests permission, then starts the
/// GPS and sensor streams.
class TrackingStarted extends TrackingEvent {
  const TrackingStarted();
}

/// User pressed the red "End Trip" button.
class TrackingStopRequested extends TrackingEvent {
  const TrackingStopRequested();
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

/// User tapped "Grant Permission" on the gate.
class TrackingPermissionRequested extends TrackingEvent {
  const TrackingPermissionRequested();
}

/// Resets the bloc back to a fresh starting state — used after the user
/// finishes a trip and navigates to the summary, so when they return to
/// the live page it's ready to record a new trip.
class TrackingReset extends TrackingEvent {
  const TrackingReset();
}
