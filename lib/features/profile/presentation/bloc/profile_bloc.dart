import 'dart:async' show unawaited;

import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/features/trip_insights/domain/entities/speed_breakdown_slice.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:drive_rank/shared/models/territory_stats.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/territory_stats_service.dart';
import 'package:drive_rank/shared/services/trip_stats_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@immutable
sealed class ProfileEvent {
  const ProfileEvent();
}

class ProfileLoaded extends ProfileEvent {
  const ProfileLoaded();
}

class _ProfileSettingsReceived extends ProfileEvent {
  const _ProfileSettingsReceived(this.row);
  final UserSettingsRow row;
}

enum ProfileStatus { loading, ready }

@immutable
class ProfileState {
  const ProfileState({
    required this.status,
    required this.settings,
    required this.lifetime,
    required this.currentMonth,
    this.monthlyTrend = const <MonthlyDistanceStat>[],
    this.lifetimeSpeedBreakdown = const <SpeedBreakdownSlice>[],
    this.territory,
  });

  factory ProfileState.initial() => ProfileState(
    status: ProfileStatus.loading,
    settings: null,
    lifetime: LifetimeStats.empty(),
    currentMonth: MonthlyReport.empty(
      DateTime.now().year,
      DateTime.now().month,
    ),
    monthlyTrend: const <MonthlyDistanceStat>[],
    lifetimeSpeedBreakdown: const <SpeedBreakdownSlice>[],
    territory: null,
  );

  final ProfileStatus status;
  final UserSettingsRow? settings;
  final LifetimeStats lifetime;
  final MonthlyReport currentMonth;

  /// Total km per month for the last 6 months, oldest first. Months
  /// with no trips are omitted — see `TripStatsService.monthlyDistanceTrend`.
  final List<MonthlyDistanceStat> monthlyTrend;

  /// Lifetime speed-distribution breakdown across every trip — see
  /// `TripStatsService.lifetimeSpeedBreakdown`.
  final List<SpeedBreakdownSlice> lifetimeSpeedBreakdown;

  /// Null until the (isolate-computed) Territory Conquered summary
  /// finishes loading — the Profile card shows a lightweight loading
  /// state rather than blocking the rest of the page on it.
  final TerritoryStats? territory;

  ProfileState copyWith({
    ProfileStatus? status,
    UserSettingsRow? settings,
    LifetimeStats? lifetime,
    MonthlyReport? currentMonth,
    List<MonthlyDistanceStat>? monthlyTrend,
    List<SpeedBreakdownSlice>? lifetimeSpeedBreakdown,
    TerritoryStats? territory,
  }) {
    return ProfileState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      lifetime: lifetime ?? this.lifetime,
      currentMonth: currentMonth ?? this.currentMonth,
      monthlyTrend: monthlyTrend ?? this.monthlyTrend,
      lifetimeSpeedBreakdown:
          lifetimeSpeedBreakdown ?? this.lifetimeSpeedBreakdown,
      territory: territory ?? this.territory,
    );
  }
}

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._settings, this._stats, this._territoryStats)
    : super(ProfileState.initial()) {
    on<ProfileLoaded>(_onLoaded);
    on<_ProfileSettingsReceived>(_onSettings);
  }

  final UserSettingsRepository _settings;
  final TripStatsService _stats;
  final TerritoryStatsService _territoryStats;

  Future<void> _onLoaded(
    ProfileLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    await _settings.ensureExists();
    final row = await _settings.read();
    final lifetime = await _stats.lifetime(uid: row.uid);
    final now = DateTime.now();
    final monthly = await _stats.monthlyReport(
      uid: row.uid,
      year: now.year,
      month: now.month,
    );
    final trend = await _stats.monthlyDistanceTrend(uid: row.uid);
    final breakdown = await _stats.lifetimeSpeedBreakdown(uid: row.uid);
    emit(
      state.copyWith(
        status: ProfileStatus.ready,
        settings: row,
        lifetime: lifetime,
        currentMonth: monthly,
        monthlyTrend: trend,
        lifetimeSpeedBreakdown: breakdown,
      ),
    );
    // Territory Conquered walks every waypoint of every trip in an
    // isolate — slower than the rest of the load, so it's fetched
    // after the first emit rather than blocking the whole page on it.
    unawaited(
      _territoryStats
          .territory(uid: row.uid, countryCode: row.country)
          .then((t) {
            if (!isClosed) emit(state.copyWith(territory: t));
          }),
    );
    // Subscribe to settings changes so name/car edits show up immediately.
    await emit.forEach<UserSettingsRow>(
      _settings.watch(),
      onData: (r) => state.copyWith(settings: r),
    );
  }

  void _onSettings(_ProfileSettingsReceived event, Emitter<ProfileState> emit) {
    emit(state.copyWith(settings: event.row));
  }
}
