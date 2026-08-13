import 'package:drive_rank/features/trip_insights/domain/entities/insights_bundle.dart';
import 'package:flutter/foundation.dart';

enum InsightsStatus { loading, ready, notFound, error }

@immutable
class InsightsState {
  const InsightsState({
    required this.status,
    required this.bundle,
    required this.isSharing,
    required this.errorMessage,
  });

  factory InsightsState.initial() => const InsightsState(
    status: InsightsStatus.loading,
    bundle: null,
    isSharing: false,
    errorMessage: null,
  );

  final InsightsStatus status;
  final InsightsBundle? bundle;

  /// True while the composite social card is being rendered + shared.
  /// Drives the Share button's spinner state.
  final bool isSharing;

  final String? errorMessage;

  InsightsState copyWith({
    InsightsStatus? status,
    InsightsBundle? bundle,
    bool? isSharing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InsightsState(
      status: status ?? this.status,
      bundle: bundle ?? this.bundle,
      isSharing: isSharing ?? this.isSharing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
