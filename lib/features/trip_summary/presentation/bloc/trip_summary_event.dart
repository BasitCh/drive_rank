import 'package:flutter/foundation.dart';

@immutable
sealed class TripSummaryEvent {
  const TripSummaryEvent();
}

class TripSummaryLoaded extends TripSummaryEvent {
  const TripSummaryLoaded(this.tripId);
  final int tripId;
}

class TripSummaryShareRequested extends TripSummaryEvent {
  const TripSummaryShareRequested();
}

class TripSummaryDeleteRequested extends TripSummaryEvent {
  const TripSummaryDeleteRequested();
}

/// Toggles whether the shareable stat card exports with a transparent
/// background (for overlaying on Instagram Stories) or the normal
/// opaque card gradient.
class TripSummaryTransparentToggled extends TripSummaryEvent {
  const TripSummaryTransparentToggled({required this.transparent});
  final bool transparent;
}
