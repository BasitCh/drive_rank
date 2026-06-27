import 'package:flutter/foundation.dart';

@immutable
sealed class InsightsEvent {
  const InsightsEvent();
}

/// Fired by `TripInsightsPage` on first build — kicks off the
/// precomputation pass.
class InsightsLoaded extends InsightsEvent {
  const InsightsLoaded(this.tripId);
  final int tripId;
}

/// User tapped the single composite "Share Insights" button.
class InsightsShareRequested extends InsightsEvent {
  const InsightsShareRequested();
}

/// Internal — the share pipeline finished (either success or cancelled).
/// Flips `isSharing` back to false so the button re-enables.
class InsightsShareFinished extends InsightsEvent {
  const InsightsShareFinished();
}
