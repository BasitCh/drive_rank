import 'dart:async';

import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show TripRow, UserSettingsRow;
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/create_target.dart';
import 'package:drive_rank/features/social/domain/usecases/get_global_leaderboard.dart';
import 'package:drive_rank/features/social/domain/usecases/get_qualifying_days.dart';
import 'package:drive_rank/features/social/domain/usecases/get_targets.dart';
import 'package:drive_rank/features/social/presentation/widgets/rankings_tab_bar.dart';
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

class RankingsTabChanged extends RankingsEvent {
  const RankingsTabChanged(this.tab);
  final RankingsTab tab;
}

class RankingsTargetCreated extends RankingsEvent {
  const RankingsTargetCreated({
    required this.metric,
    required this.period,
    required this.value,
  });
  final CompetitionMetric metric;
  final LeaderboardPeriod period;
  final double value;
}

class RankingsTargetCancelled extends RankingsEvent {
  const RankingsTargetCancelled(this.targetId);
  final String targetId;
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
    required this.tab,
    this.board,
    this.viewer,
    this.targets = const [],
    this.trophies = const [],
    this.qualifyingDayKeys = const {},
  });

  factory RankingsState.initial() => const RankingsState(
    isLoading: true,
    metric: CompetitionMetric.distance,
    period: LeaderboardPeriod.weekly,
    rankingsEnabled: true,
    tab: RankingsTab.board,
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

  /// Which surface is showing.
  final RankingsTab tab;

  /// Personal targets with their progress recomputed — head-to-head
  /// challenges are excluded upstream, since nothing can supply an
  /// opponent's value yet.
  final List<Target> targets;

  /// Every trophy this user has actually unlocked. The grid pairs these
  /// against `TrophyType.values` so unearned ones still show.
  final List<Trophy> trophies;

  /// Which days of the *current week* had a qualifying drive, keyed the
  /// way `CompetitionTrip.localDayKey` keys them. Always the week, never
  /// the selected period: the streak strip is a week's worth of dots and
  /// only renders on a weekly board.
  final Set<int> qualifyingDayKeys;

  RankingsState copyWith({
    bool? isLoading,
    CompetitionMetric? metric,
    LeaderboardPeriod? period,
    bool? rankingsEnabled,
    Leaderboard? board,
    UserSettingsRow? viewer,
    RankingsTab? tab,
    List<Target>? targets,
    List<Trophy>? trophies,
    Set<int>? qualifyingDayKeys,
  }) => RankingsState(
    isLoading: isLoading ?? this.isLoading,
    metric: metric ?? this.metric,
    period: period ?? this.period,
    rankingsEnabled: rankingsEnabled ?? this.rankingsEnabled,
    board: board ?? this.board,
    viewer: viewer ?? this.viewer,
    tab: tab ?? this.tab,
    targets: targets ?? this.targets,
    trophies: trophies ?? this.trophies,
    qualifyingDayKeys: qualifyingDayKeys ?? this.qualifyingDayKeys,
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
  RankingsBloc(
    this._settings,
    this._trips,
    this._getLeaderboard,
    this._getTargets,
    this._createTarget,
    this._social,
    this._getQualifyingDays,
  ) : super(RankingsState.initial()) {
    on<RankingsStarted>(_onStarted);
    on<RankingsMetricChanged>(_onMetricChanged);
    on<RankingsPeriodChanged>(_onPeriodChanged);
    on<RankingsTabChanged>(_onTabChanged);
    on<RankingsTargetCreated>(_onTargetCreated);
    on<RankingsTargetCancelled>(_onTargetCancelled);
    on<_RankingsSettingsChanged>(_onSettingsChanged);
    on<_RankingsTripsChanged>(_onTripsChanged);
  }

  final UserSettingsRepository _settings;
  final TripRepository _trips;
  final GetGlobalLeaderboard _getLeaderboard;
  final GetTargets _getTargets;
  final CreateTarget _createTarget;
  final SocialRepository _social;
  final GetQualifyingDays _getQualifyingDays;

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

  /// Switching surface doesn't recompute anything — the board, targets
  /// and trophies are all already in state, and a tab tap that showed
  /// a spinner for data it already had would just look slow.
  void _onTabChanged(RankingsTabChanged event, Emitter<RankingsState> emit) {
    if (event.tab == state.tab) return;
    emit(state.copyWith(tab: event.tab));
  }

  Future<void> _onTargetCreated(
    RankingsTargetCreated event,
    Emitter<RankingsState> emit,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    await _createTarget(
      uid: uid,
      metric: event.metric,
      period: event.period,
      targetValue: event.value,
    );
    await _rebuild(emit);
  }

  Future<void> _onTargetCancelled(
    RankingsTargetCancelled event,
    Emitter<RankingsState> emit,
  ) async {
    // Cancelled rather than deleted: the row stays as a record that it
    // was set and abandoned, and `GetTargets` filters it out.
    await _social.updateChallengeStatus(
      challengeId: event.targetId,
      status: ChallengeStatus.cancelled,
    );
    await _rebuild(emit);
  }

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
    final targets = await _getTargets(uid: uid);
    final trophies = await _social.getTrophies(uid);
    // Always this week's, whatever period the board is showing — the
    // strip describes a week by construction.
    final days = await _getQualifyingDays(
      uid: uid,
      window: CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime.now(),
      ),
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: false,
        metric: nextMetric,
        period: nextPeriod,
        board: board,
        targets: targets,
        trophies: trophies,
        qualifyingDayKeys: days,
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
