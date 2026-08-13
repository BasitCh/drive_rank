import 'dart:async';

import 'package:drive_rank/core/services/telemetry_service.dart';
import 'package:drive_rank/features/trip_insights/data/insights_repository.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_event.dart';
import 'package:drive_rank/features/trip_insights/presentation/bloc/insights_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Owns the lifecycle for either social share card (Performance or
/// Journey). Both pages provide the same bloc with a different
/// `CardKind` on `InsightsLoaded` — the bloc routes telemetry to the
/// right per-card funnel without leaking card details into the data
/// layer.
///
/// Share capture lives on the page (it needs a `BuildContext` +
/// `RepaintBoundary` key). The bloc just persists the intent + emits
/// telemetry.
@injectable
class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  InsightsBloc(this._repo, this._telemetry) : super(InsightsState.initial()) {
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
      emit(
        state.copyWith(
          status: InsightsStatus.ready,
          bundle: bundle,
          clearError: true,
        ),
      );
      unawaited(_telemetry.track(event.kind.viewedEvent));
    } catch (e) {
      emit(
        state.copyWith(
          status: InsightsStatus.error,
          errorMessage: 'Could not load card: $e',
        ),
      );
    }
  }

  Future<void> _onShareRequested(
    InsightsShareRequested event,
    Emitter<InsightsState> emit,
  ) async {
    if (state.status != InsightsStatus.ready || state.isSharing) return;
    emit(state.copyWith(isSharing: true));
    unawaited(_telemetry.track(event.kind.sharedEvent));
  }

  Future<void> _onShareFinished(
    InsightsShareFinished event,
    Emitter<InsightsState> emit,
  ) async {
    emit(state.copyWith(isSharing: false));
  }
}
