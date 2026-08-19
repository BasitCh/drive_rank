import 'package:drive_rank/core/services/card_export_service.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_event.dart';
import 'package:drive_rank/features/trip_summary/presentation/bloc/trip_summary_state.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
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
    on<TripSummaryTransparentToggled>(_onTransparentToggled);
  }

  final TripRepository _trips;
  final UserSettingsRepository _settings;
  final CardExportService _exporter;

  /// The trip-summary page passes this key into the stat card's
  /// `RepaintBoundary`. The bloc grabs it for export.
  final GlobalKey cardBoundaryKey = GlobalKey();

  /// Boundary around the Speed Over Time chart card — shared alongside
  /// the stat card as a second image. Left uncaptured (silently
  /// skipped by the exporter) when the chart is hidden for a
  /// too-short trip.
  final GlobalKey chartBoundaryKey = GlobalKey();

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
    // The goal nudge shows "previous best -> next goal" — the current
    // personal-best trip, not necessarily *this* trip, since a user
    // browsing an old trip from History should still see today's real
    // best, not this one trip's numbers passed off as their record.
    final bestSpeed = await _trips.getPersonalBest(uid: settings.uid);
    final bestDistance = await _trips.getLongestTrip(uid: settings.uid);

    emit(
      state.copyWith(
        status: TripSummaryStatus.ready,
        trip: trip,
        points: points,
        carLabel: carLabel,
        speedGoalKmh: settings.speedGoalKmh,
        distanceGoalKm: settings.distanceGoalKm,
        bestTopSpeedKmh: bestSpeed?.topSpeedKmh,
        bestDistanceKm: bestDistance?.distanceKm,
        vehicleType: VehicleType.fromId(settings.vehicleType),
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
      await _exporter.captureMultipleAndShare([
        cardBoundaryKey,
        chartBoundaryKey,
      ]);
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

  void _onTransparentToggled(
    TripSummaryTransparentToggled event,
    Emitter<TripSummaryState> emit,
  ) {
    emit(state.copyWith(isTransparent: event.transparent));
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
