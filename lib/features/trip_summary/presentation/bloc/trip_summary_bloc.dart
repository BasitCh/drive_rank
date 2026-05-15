import 'package:drive_rank/core/services/card_export_service.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_event.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_state.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Powers the trip summary page.
///
/// Loads the trip row + waypoints from Drift, formats the user's car label
/// for the stat card, and routes share/delete actions through the
/// CardExportService and TripRepository.
@injectable
class TripSummaryBloc extends Bloc<TripSummaryEvent, TripSummaryState> {
  TripSummaryBloc(this._trips, this._settings, this._exporter)
    : super(TripSummaryState.initial()) {
    on<TripSummaryLoaded>(_onLoaded);
    on<TripSummaryShareRequested>(_onShare);
    on<TripSummaryDeleteRequested>(_onDelete);
  }

  final TripRepository _trips;
  final UserSettingsRepository _settings;
  final CardExportService _exporter;

  /// The trip-summary page passes this key into the stat card's
  /// `RepaintBoundary`. The bloc grabs it for export.
  final GlobalKey cardBoundaryKey = GlobalKey();

  Future<void> _onLoaded(
    TripSummaryLoaded event,
    Emitter<TripSummaryState> emit,
  ) async {
    final trip = await _trips.getById(event.tripId);
    if (trip == null) {
      emit(state.copyWith(status: TripSummaryStatus.notFound));
      return;
    }
    final points = await _trips.getWaypoints(event.tripId);
    final settings = await _settings.read();
    final carLabel = _formatCarLabel(
      settings.carMake,
      settings.carModel,
      settings.carYear,
    );

    emit(
      state.copyWith(
        status: TripSummaryStatus.ready,
        trip: trip,
        points: points,
        carLabel: carLabel,
      ),
    );
  }

  Future<void> _onShare(
    TripSummaryShareRequested event,
    Emitter<TripSummaryState> emit,
  ) async {
    if (state.isSharing) return;
    emit(state.copyWith(isSharing: true));
    try {
      await _exporter.captureAndShare(cardBoundaryKey);
    } finally {
      if (!isClosed) emit(state.copyWith(isSharing: false));
    }
  }

  Future<void> _onDelete(
    TripSummaryDeleteRequested event,
    Emitter<TripSummaryState> emit,
  ) async {
    final id = state.trip?.id;
    if (id == null) return;
    await _trips.deleteTrip(id);
    emit(state.copyWith(status: TripSummaryStatus.deleted));
  }

  static String _formatCarLabel(String? make, String? model, int? year) {
    final parts = <String>[
      if (make != null && make.isNotEmpty) make,
      if (model != null && model.isNotEmpty) model,
      if (year != null) year.toString(),
    ];
    return parts.join(' ');
  }
}
