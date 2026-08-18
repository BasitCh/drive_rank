import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
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
  );

  final ProfileStatus status;
  final UserSettingsRow? settings;
  final LifetimeStats lifetime;
  final MonthlyReport currentMonth;

  /// Total km per month for the last 6 months, oldest first. Months
  /// with no trips are omitted — see `TripStatsService.monthlyDistanceTrend`.
  final List<MonthlyDistanceStat> monthlyTrend;

  ProfileState copyWith({
    ProfileStatus? status,
    UserSettingsRow? settings,
    LifetimeStats? lifetime,
    MonthlyReport? currentMonth,
    List<MonthlyDistanceStat>? monthlyTrend,
  }) {
    return ProfileState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      lifetime: lifetime ?? this.lifetime,
      currentMonth: currentMonth ?? this.currentMonth,
      monthlyTrend: monthlyTrend ?? this.monthlyTrend,
    );
  }
}

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._settings, this._stats) : super(ProfileState.initial()) {
    on<ProfileLoaded>(_onLoaded);
    on<_ProfileSettingsReceived>(_onSettings);
  }

  final UserSettingsRepository _settings;
  final TripStatsService _stats;

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
    emit(
      state.copyWith(
        status: ProfileStatus.ready,
        settings: row,
        lifetime: lifetime,
        currentMonth: monthly,
        monthlyTrend: trend,
      ),
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
