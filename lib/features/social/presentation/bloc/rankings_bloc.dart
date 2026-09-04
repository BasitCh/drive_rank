import 'dart:async';

import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show TripRow, UserSettingsRow;
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/domain/usecases/get_global_leaderboard.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@immutable
sealed class RankingsEvent {
  const RankingsEvent();
}

class RankingsStarted extends RankingsEvent {
  const RankingsStarted();
}

class RankingsMetricChanged extends RankingsEvent {
  const RankingsMetricChanged(this.metric);
  final CompetitionMetric metric;
}

class RankingsPeriodChanged extends RankingsEvent {
  const RankingsPeriodChanged(this.period);
  final LeaderboardPeriod period;
}

/// The settings row changed — carries the uid and the kill-switch flag,
/// both of which can move under a running screen.
class _RankingsSettingsChanged extends RankingsEvent {
  const _RankingsSettingsChanged(this.settings);
  final UserSettingsRow settings;
}

/// The user's trips changed, so their value needs recomputing.
class _RankingsTripsChanged extends RankingsEvent {
  const _RankingsTripsChanged();
}

@immutable
class RankingsState {
  const RankingsState({
    required this.isLoading,
    required this.metric,
    required this.period,
    required this.rankingsEnabled,
    this.board,
    this.viewer,
  });

  factory RankingsState.initial() => const RankingsState(
    isLoading: true,
    metric: CompetitionMetric.distance,
    period: LeaderboardPeriod.weekly,
    rankingsEnabled: true,
  );

  final bool isLoading;
  final CompetitionMetric metric;
  final LeaderboardPeriod period;

  /// The viewer's settings row — their vehicle art and country for
  /// their own row on the board. Only the viewer's identity is known
  /// locally; other real drivers arrive with the remote phase carrying
  /// their own.
  final UserSettingsRow? viewer;

  /// False when the kill switch is off — the page renders its disabled
  /// state and stops showing standings. Never inferred from a missing
  /// board; an empty board is a legitimate, different thing.
  final bool rankingsEnabled;

  final Leaderboard? board;

  RankingsState copyWith({
    bool? isLoading,
    CompetitionMetric? metric,
    LeaderboardPeriod? period,
    bool? rankingsEnabled,
    Leaderboard? board,
    UserSettingsRow? viewer,
  }) => RankingsState(
    isLoading: isLoading ?? this.isLoading,
    metric: metric ?? this.metric,
    period: period ?? this.period,
    rankingsEnabled: rankingsEnabled ?? this.rankingsEnabled,
    board: board ?? this.board,
    viewer: viewer ?? this.viewer,
  );
}

/// Drives the Rankings page.
///
/// Recomputes the board whenever the selected metric or period changes,
/// whenever the user's trips change, and whenever the settings row
/// changes — the last of those matters more than it looks: the uid is
/// rewritten mid-session when anonymous sign-in resolves, and the
/// kill-switch flag can flip under a live screen. `PersonalBestsRepository`
/// reads the uid once at subscription time and therefore keeps querying
/// a stale one afterwards; a screen showing competitive standing can't
/// afford that, so the trips subscription is torn down and rebuilt
/// whenever the uid actually changes.
@injectable
class RankingsBloc extends Bloc<RankingsEvent, RankingsState> {
  RankingsBloc(this._settings, this._trips, this._getLeaderboard)
    : super(RankingsState.initial()) {
    on<RankingsStarted>(_onStarted);
    on<RankingsMetricChanged>(_onMetricChanged);
    on<RankingsPeriodChanged>(_onPeriodChanged);
    on<_RankingsSettingsChanged>(_onSettingsChanged);
    on<_RankingsTripsChanged>(_onTripsChanged);
  }

  final UserSettingsRepository _settings;
  final TripRepository _trips;
  final GetGlobalLeaderboard _getLeaderboard;

  StreamSubscription<UserSettingsRow>? _settingsSub;
  StreamSubscription<List<TripRow>>? _tripsSub;

  String? _uid;
  String _displayName = '';

  Future<void> _onStarted(
    RankingsStarted event,
    Emitter<RankingsState> emit,
  ) async {
    await _settingsSub?.cancel();
    _settingsSub = _settings.watch().listen(
      (row) => add(_RankingsSettingsChanged(row)),
    );
  }

  Future<void> _onSettingsChanged(
    _RankingsSettingsChanged event,
    Emitter<RankingsState> emit,
  ) async {
    final settings = event.settings;
    _displayName = settings.username.isEmpty
        ? AppStrings.rankingsYouFallback
        : settings.username;

    final uidChanged = settings.uid != _uid;
    _uid = settings.uid;

    emit(
      state.copyWith(
        rankingsEnabled: settings.rankingsEnabled,
        viewer: settings,
      ),
    );

    if (uidChanged) {
      // Rebuild the trips subscription against the new uid rather than
      // leaving it querying the old one.
      await _tripsSub?.cancel();
      _tripsSub = _trips
          .watchAll(uid: settings.uid)
          .listen((_) => add(const _RankingsTripsChanged()));
    }

    await _rebuild(emit);
  }

  Future<void> _onTripsChanged(
    _RankingsTripsChanged event,
    Emitter<RankingsState> emit,
  ) => _rebuild(emit);

  Future<void> _onMetricChanged(
    RankingsMetricChanged event,
    Emitter<RankingsState> emit,
  ) async {
    if (event.metric == state.metric) return;
    await _rebuild(emit, metric: event.metric);
  }

  Future<void> _onPeriodChanged(
    RankingsPeriodChanged event,
    Emitter<RankingsState> emit,
  ) async {
    if (event.period == state.period) return;
    await _rebuild(emit, period: event.period);
  }

  /// Recomputes the board and emits the new selection *with* it, in a
  /// single state.
  ///
  /// Emitting the selector change first and the board after would leave
  /// one frame where the pills say "longest trip" while the rows still
  /// show weekly distance — briefly, but visibly, a lie. The
  /// computation is local and cheap, so there's nothing to gain by
  /// showing the change early.
  Future<void> _rebuild(
    Emitter<RankingsState> emit, {
    CompetitionMetric? metric,
    LeaderboardPeriod? period,
  }) async {
    final uid = _uid;
    final nextMetric = metric ?? state.metric;
    final nextPeriod = period ?? state.period;
    if (uid == null) {
      emit(state.copyWith(metric: nextMetric, period: nextPeriod));
      return;
    }
    final board = await _getLeaderboard(
      uid: uid,
      displayName: _displayName,
      metric: nextMetric,
      period: nextPeriod,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: false,
        metric: nextMetric,
        period: nextPeriod,
        board: board,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _settingsSub?.cancel();
    await _tripsSub?.cancel();
    return super.close();
  }
}
