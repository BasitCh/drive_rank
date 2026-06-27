import 'dart:async';

import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/features/trip_insights/data/insights_repository.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_event.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Owns the Trip Insights lifecycle.
///
/// Single precomputation pass on `InsightsLoaded`. The share button
/// transitions through a brief `isSharing = true` window so the page
/// can render a spinner; the actual capture + share_plus call lives on
/// the page (it needs a `BuildContext` + `RepaintBoundary` key). The
/// bloc just persists the intent + emits telemetry.
@injectable
class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  InsightsBloc(this._repo, this._telemetry)
      : super(InsightsState.initial()) {
    on<InsightsLoaded>(_onLoaded);
    on<InsightsShareRequested>(_onShareRequested);
    on<InsightsShareFinished>(_onShareFinished);
  }

  final InsightsRepository _repo;
  final TelemetryService _telemetry;

  Future<void> _onLoaded(
    InsightsLoaded event,
    Emitter<InsightsState> emit,
  ) async {
    try {
      final bundle = await _repo.load(event.tripId);
      if (bundle == null) {
        emit(state.copyWith(status: InsightsStatus.notFound));
        return;
      }
      emit(state.copyWith(
        status: InsightsStatus.ready,
        bundle: bundle,
        clearError: true,
      ));
      unawaited(
        _telemetry.track(
          TelemetryEvents.insightsViewed,
          properties: <String, Object?>{
            'has_chart': bundle.chartEligible,
            'has_records': bundle.recordsEligible,
            'segment_count': bundle.segments.length,
          },
        ),
      );
    } catch (e) {
      emit(state.copyWith(
        status: InsightsStatus.error,
        errorMessage: 'Could not load insights: $e',
      ));
    }
  }

  Future<void> _onShareRequested(
    InsightsShareRequested event,
    Emitter<InsightsState> emit,
  ) async {
    if (state.status != InsightsStatus.ready || state.isSharing) return;
    emit(state.copyWith(isSharing: true));
    unawaited(_telemetry.track(TelemetryEvents.insightsShared));
  }

  Future<void> _onShareFinished(
    InsightsShareFinished event,
    Emitter<InsightsState> emit,
  ) async {
    emit(state.copyWith(isSharing: false));
  }
}
