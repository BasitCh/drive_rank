import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum TripFilter { all, thisWeek, night, best }

@immutable
sealed class HistoryEvent {
  const HistoryEvent();
}

class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

class HistoryFilterChanged extends HistoryEvent {
  const HistoryFilterChanged(this.filter);
  final TripFilter filter;
}

class HistoryTripDeleted extends HistoryEvent {
  const HistoryTripDeleted(this.tripId);
  final int tripId;
}

class _HistoryRowsReceived extends HistoryEvent {
  const _HistoryRowsReceived(this.rows);
  final List<TripRow> rows;
}

@immutable
class HistoryState {
  const HistoryState({
    required this.isLoading,
    required this.filter,
    required this.allTrips,
    required this.freeTripsUsed,
  });

  factory HistoryState.initial() => const HistoryState(
    isLoading: true,
    filter: TripFilter.all,
    allTrips: <TripRow>[],
    freeTripsUsed: 0,
  );

  final bool isLoading;
  final TripFilter filter;
  final List<TripRow> allTrips;

  /// Synced to Firestore (survives reinstall) — see `UserSettingsRepository
  /// .syncFreeTripsWithCloud`. Trips themselves are local-only and don't
  /// survive a reinstall, so a nonzero count here alongside an empty
  /// [allTrips] means "this is a reinstall," not "first launch."
  final int freeTripsUsed;

  /// True when the local trip table is empty but the device's free-trial
  /// counter says otherwise — the signal a fresh install can't produce.
  bool get looksLikeReinstall => allTrips.isEmpty && freeTripsUsed > 0;

  List<TripRow> get visibleTrips {
    switch (filter) {
      case TripFilter.all:
        return allTrips;
      case TripFilter.thisWeek:
        final monday = _mondayOfThisWeek();
        return allTrips.where((t) => !t.startedAt.isBefore(monday)).toList();
      case TripFilter.night:
        return allTrips.where((t) => t.isNightDrive).toList();
      case TripFilter.best:
        final sorted = [...allTrips]
          ..sort((a, b) => b.topSpeedKmh.compareTo(a.topSpeedKmh));
        return sorted.take(10).toList();
    }
  }

  static DateTime _mondayOfThisWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  HistoryState copyWith({
    bool? isLoading,
    TripFilter? filter,
    List<TripRow>? allTrips,
    int? freeTripsUsed,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      filter: filter ?? this.filter,
      allTrips: allTrips ?? this.allTrips,
      freeTripsUsed: freeTripsUsed ?? this.freeTripsUsed,
    );
  }
}

@injectable
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc(this._trips, this._settings) : super(HistoryState.initial()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryFilterChanged>(_onFilter);
    on<HistoryTripDeleted>(_onDelete);
    on<_HistoryRowsReceived>(_onRows);
  }

  final TripRepository _trips;
  final UserSettingsRepository _settings;

  Future<void> _onStarted(
    HistoryStarted event,
    Emitter<HistoryState> emit,
  ) async {
    final settings = await _settings.read();
    emit(state.copyWith(freeTripsUsed: settings.freeTripsUsed));
    await emit.forEach<List<TripRow>>(
      _trips.watchAll(uid: settings.uid),
      onData: (rows) => state.copyWith(isLoading: false, allTrips: rows),
    );
  }

  void _onFilter(HistoryFilterChanged event, Emitter<HistoryState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  Future<void> _onDelete(
    HistoryTripDeleted event,
    Emitter<HistoryState> emit,
  ) async {
    await _trips.deleteTrip(event.tripId);
    // The watchAll() stream fires automatically and re-emits the new list.
  }

  void _onRows(_HistoryRowsReceived event, Emitter<HistoryState> emit) {
    emit(state.copyWith(allTrips: event.rows, isLoading: false));
  }
}
