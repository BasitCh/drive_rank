import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/tracking/domain/entities/trip_point.dart';
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
  });

  factory TripSummaryState.initial() => const TripSummaryState(
    status: TripSummaryStatus.loading,
    trip: null,
    points: <TripPoint>[],
    carLabel: '',
    errorMessage: null,
    isSharing: false,
  );

  final TripSummaryStatus status;
  final TripRow? trip;
  final List<TripPoint> points;
  final String carLabel;
  final String? errorMessage;
  final bool isSharing;

  TripSummaryState copyWith({
    TripSummaryStatus? status,
    TripRow? trip,
    List<TripPoint>? points,
    String? carLabel,
    String? errorMessage,
    bool? isSharing,
  }) {
    return TripSummaryState(
      status: status ?? this.status,
      trip: trip ?? this.trip,
      points: points ?? this.points,
      carLabel: carLabel ?? this.carLabel,
      errorMessage: errorMessage ?? this.errorMessage,
      isSharing: isSharing ?? this.isSharing,
    );
  }
}
