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
