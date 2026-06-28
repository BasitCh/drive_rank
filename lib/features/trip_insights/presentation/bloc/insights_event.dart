import 'package:drive_rank/features/trip_insights/domain/entities/card_kind.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class InsightsEvent {
  const InsightsEvent();
}

/// Fired by a card page on first build. Carries the [CardKind] so the
/// bloc emits the right `*_card_viewed` telemetry event.
class InsightsLoaded extends InsightsEvent {
  const InsightsLoaded({required this.tripId, required this.kind});
  final int tripId;
  final CardKind kind;
}

/// User tapped the card's Share CTA.
class InsightsShareRequested extends InsightsEvent {
  const InsightsShareRequested(this.kind);
  final CardKind kind;
}

/// Internal — the share pipeline finished (either success or cancelled).
/// Flips `isSharing` back to false so the button re-enables.
class InsightsShareFinished extends InsightsEvent {
  const InsightsShareFinished();
}
