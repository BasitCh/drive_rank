import 'dart:async';

import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show TripRow, UserSettingsRow;
import 'package:drive_rank/features/social/data/services/challenge_progress_publisher.dart';
import 'package:drive_rank/features/social/data/services/challenge_sync_service.dart';
import 'package:drive_rank/features/social/data/services/social_directory.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/friend.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_scope.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/domain/repositories/social_repository.dart';
import 'package:drive_rank/features/social/domain/usecases/create_challenge.dart';
import 'package:drive_rank/features/social/domain/usecases/create_target.dart';
import 'package:drive_rank/features/social/domain/usecases/get_challenges.dart';
import 'package:drive_rank/features/social/domain/usecases/get_friends_leaderboard.dart';
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

class RankingsScopeChanged extends RankingsEvent {
  const RankingsScopeChanged(this.scope);
  final LeaderboardScope scope;
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

/// Answering a challenge somebody sent the viewer.
class RankingsChallengeAnswered extends RankingsEvent {
  const RankingsChallengeAnswered(this.view, {required this.accept});
  final ChallengeView view;
  final bool accept;
}

/// Withdrawing one the viewer sent that hasn't been answered.
class RankingsChallengeWithdrawn extends RankingsEvent {
  const RankingsChallengeWithdrawn(this.view);
  final ChallengeView view;
}

class RankingsChallengeCreated extends RankingsEvent {
  const RankingsChallengeCreated({
    required this.opponentUid,
    required this.metric,
    required this.period,
    required this.value,
  });
  final String opponentUid;
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

/// The accepted friendships changed — somebody was added or removed.
class _RankingsFriendsChanged extends RankingsEvent {
  const _RankingsFriendsChanged(this.friends);
  final List<Friend> friends;
}

/// Friends' published mirrors arrived, or one of them changed on the
/// friend's own device.
class _RankingsFriendProfilesChanged extends RankingsEvent {
  const _RankingsFriendProfilesChanged(this.profiles);
  final List<CompetitionMirror> profiles;
}

@immutable
class RankingsState {
  const RankingsState({
    required this.isLoading,
    required this.metric,
    required this.period,
    required this.scope,
    required this.rankingsEnabled,
    required this.tab,
    this.board,
    this.viewer,
    this.targets = const [],
    this.trophies = const [],
    this.qualifyingDayKeys = const {},
    this.friendProfiles = const [],
    this.hasFriends = false,
    this.challenges = const [],
  });

  factory RankingsState.initial() => const RankingsState(
    isLoading: true,
    metric: CompetitionMetric.distance,
    period: LeaderboardPeriod.weekly,
    scope: LeaderboardScope.global,
    rankingsEnabled: true,
    tab: RankingsTab.board,
  );

  final bool isLoading;
  final CompetitionMetric metric;
  final LeaderboardPeriod period;

  /// Who the board is ranking against.
  final LeaderboardScope scope;

  /// Friends' published mirrors, live while the friends scope is
  /// showing. A friend who has never published is simply absent — the
  /// board omits them rather than ranking them at zero.
  ///
  /// Kept in state because the compare sheet needs the friend's figures
  /// to build a head-to-head, and re-fetching one document on a tap
  /// would make the sheet open slower than the row it came from.
  final List<CompetitionMirror> friendProfiles;

  /// Head-to-head challenges, already settled.
  ///
  /// Settled here rather than in the widget so the boundary between
  /// "the competition ended" and "the result is final" is decided once,
  /// by `SettleChallenge`, and not re-derived by a card that could get
  /// it wrong differently.
  final List<ChallengeView> challenges;

  /// Whether the viewer has any accepted friendship at all.
  ///
  /// Separate from [friendProfiles] being empty, which those two
  /// situations would otherwise be indistinguishable from: "you have no
  /// friends yet" wants the invite prompt, "your friends haven't
  /// published anything" does not.
  final bool hasFriends;

  /// The viewer's settings row — their vehicle art and country for
  /// their own row on the board. Their own identity is read from here
  /// rather than from what they published, because settings is always
  /// the fresher of the two; a friend's comes off their mirror.
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
    LeaderboardScope? scope,
    bool? rankingsEnabled,
    Leaderboard? board,
    UserSettingsRow? viewer,
    RankingsTab? tab,
    List<Target>? targets,
    List<Trophy>? trophies,
    Set<int>? qualifyingDayKeys,
    List<CompetitionMirror>? friendProfiles,
    bool? hasFriends,
    List<ChallengeView>? challenges,
  }) => RankingsState(
    isLoading: isLoading ?? this.isLoading,
    metric: metric ?? this.metric,
    period: period ?? this.period,
    scope: scope ?? this.scope,
    rankingsEnabled: rankingsEnabled ?? this.rankingsEnabled,
    board: board ?? this.board,
    viewer: viewer ?? this.viewer,
    tab: tab ?? this.tab,
    targets: targets ?? this.targets,
    trophies: trophies ?? this.trophies,
    qualifyingDayKeys: qualifyingDayKeys ?? this.qualifyingDayKeys,
    friendProfiles: friendProfiles ?? this.friendProfiles,
    hasFriends: hasFriends ?? this.hasFriends,
    challenges: challenges ?? this.challenges,
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
    this._getFriendsLeaderboard,
    this._directory,
    this._getChallenges,
    this._createChallenge,
    this._challengeSync,
    this._challengeProgress,
  ) : super(RankingsState.initial()) {
    on<RankingsStarted>(_onStarted);
    on<RankingsMetricChanged>(_onMetricChanged);
    on<RankingsPeriodChanged>(_onPeriodChanged);
    on<RankingsScopeChanged>(_onScopeChanged);
    on<RankingsTabChanged>(_onTabChanged);
    on<RankingsTargetCreated>(_onTargetCreated);
    on<RankingsTargetCancelled>(_onTargetCancelled);
    on<RankingsChallengeAnswered>(_onChallengeAnswered);
    on<RankingsChallengeWithdrawn>(_onChallengeWithdrawn);
    on<RankingsChallengeCreated>(_onChallengeCreated);
    on<_RankingsSettingsChanged>(_onSettingsChanged);
    on<_RankingsTripsChanged>(_onTripsChanged);
    on<_RankingsFriendsChanged>(_onFriendsChanged);
    on<_RankingsFriendProfilesChanged>(_onFriendProfilesChanged);
  }

  final UserSettingsRepository _settings;
  final TripRepository _trips;
  final GetGlobalLeaderboard _getLeaderboard;
  final GetTargets _getTargets;
  final CreateTarget _createTarget;
  final SocialRepository _social;
  final GetQualifyingDays _getQualifyingDays;
  final GetFriendsLeaderboard _getFriendsLeaderboard;
  final SocialDirectory _directory;
  final GetChallenges _getChallenges;
  final CreateChallenge _createChallenge;
  final ChallengeSyncService _challengeSync;
  final ChallengeProgressPublisher _challengeProgress;

  StreamSubscription<UserSettingsRow>? _settingsSub;
  StreamSubscription<List<TripRow>>? _tripsSub;
  StreamSubscription<List<Friend>>? _friendsSub;
  StreamSubscription<List<CompetitionMirror>>? _profilesSub;

  String? _uid;
  String _displayName = '';

  /// The live selection.
  ///
  /// Held here rather than read out of `state` because two handlers can
  /// be in flight at once — a trips change and a chip tap, say — and a
  /// rebuild that started before the tap would otherwise finish and
  /// emit the *old* selection over the new one, stranding the board on
  /// a scope the chip no longer says. These fields move synchronously
  /// with the tap; `_rebuild` reads them, and discards its own result if
  /// they moved again while it was computing.
  CompetitionMetric _metric = CompetitionMetric.distance;
  LeaderboardPeriod _period = LeaderboardPeriod.weekly;
  LeaderboardScope _scope = LeaderboardScope.global;

  /// Published identities of anybody the viewer has a challenge with.
  final Map<String, CompetitionMirror> _opponentProfiles = {};

  /// The friends the viewer actually has, from the local table.
  List<String> _friendUids = const [];

  /// Which uid set [_profilesSub] is listening for, so a scope switch
  /// with nothing changed doesn't tear down a live listener and put the
  /// board back into a spinner.
  List<String>? _watchingProfilesFor;

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

      // The friends list is local and cheap, so it's watched regardless
      // of scope — it's what decides whether the friends board has an
      // empty state or a population, and it must be known before the
      // viewer taps the chip. Their *published figures* are the
      // expensive part and are only fetched once the scope is showing.
      await _friendsSub?.cancel();
      _friendsSub = _social
          .watchFriends(settings.uid)
          .listen((friends) => add(_RankingsFriendsChanged(friends)));

      // Challenges are created by the *opponent's* device as often as
      // by this one, so they need a listener rather than a poll — the
      // same reasoning friendships needed in 4b. Started here and
      // stopped in `close()`, so a Firestore subscription never
      // outlives the screen that wanted it.
      await _challengeSync.start();
    }

    await _rebuild(emit);
  }

  Future<void> _onTripsChanged(
    _RankingsTripsChanged event,
    Emitter<RankingsState> emit,
  ) => _rebuild(emit);

  Future<void> _onFriendsChanged(
    _RankingsFriendsChanged event,
    Emitter<RankingsState> emit,
  ) async {
    final uids = [
      for (final friend in event.friends) friend.friendUid,
    ]..sort();
    final changed = !_sameUids(uids, _friendUids);
    _friendUids = uids;

    // Only when it actually changed: the friends table emits on every
    // local write, and a state per emission would make "nothing
    // changed" indistinguishable from a rebuild to anything watching.
    if (uids.isNotEmpty != state.hasFriends) {
      emit(state.copyWith(hasFriends: uids.isNotEmpty));
    }

    // Only re-listen when the set actually changed, and only while the
    // friends board is what's showing.
    if (changed && _scope == LeaderboardScope.friends) {
      await _watchFriendProfiles();
    }
    if (_scope == LeaderboardScope.friends) await _rebuild(emit);
  }

  Future<void> _onFriendProfilesChanged(
    _RankingsFriendProfilesChanged event,
    Emitter<RankingsState> emit,
  ) async {
    emit(state.copyWith(friendProfiles: event.profiles));
    if (_scope == LeaderboardScope.friends) await _rebuild(emit);
  }

  Future<void> _onScopeChanged(
    RankingsScopeChanged event,
    Emitter<RankingsState> emit,
  ) async {
    if (event.scope == _scope) return;
    _scope = event.scope;

    if (event.scope == LeaderboardScope.global) {
      // Stop paying for reads the viewer isn't looking at. The cached
      // mirrors stay in state, so switching back renders immediately
      // and then corrects itself when the listener re-attaches.
      await _profilesSub?.cancel();
      _profilesSub = null;
      _watchingProfilesFor = null;
      await _rebuild(emit);
      return;
    }

    final needsProfiles =
        _friendUids.isNotEmpty &&
        !_sameUids(_watchingProfilesFor ?? const [], _friendUids);

    if (!needsProfiles) {
      // Either there is nothing to fetch or the listener is already
      // live: one emit, with the new scope and its board together.
      await _rebuild(emit);
      return;
    }

    // Show the spinner rather than a friends board with nobody on it —
    // an empty board that fills in a moment later reads as "you have no
    // friends", which is a different and wrong answer.
    emit(state.copyWith(scope: event.scope, isLoading: true));
    await _watchFriendProfiles();
  }

  Future<void> _watchFriendProfiles() async {
    await _profilesSub?.cancel();
    final uids = _friendUids;
    _watchingProfilesFor = uids;
    _profilesSub = _directory
        .watchProfiles(uids)
        .listen(
          (profiles) => add(_RankingsFriendProfilesChanged(profiles)),
          // A read that fails — offline, or rules refusing — must not
          // strand the board on a spinner. An empty list is the honest
          // answer: nothing was read.
          onError: (_) => add(const _RankingsFriendProfilesChanged([])),
        );
  }

  static bool _sameUids(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

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

  Future<void> _onChallengeAnswered(
    RankingsChallengeAnswered event,
    Emitter<RankingsState> emit,
  ) async {
    final status = event.accept
        // `active` is the accepted state — one vocabulary across the
        // rules, the entity and the database.
        ? ChallengeStatus.active
        : ChallengeStatus.declined;
    try {
      // Local first, as everywhere else here: it is what the UI reads.
      await _social.updateChallengeStatus(
        challengeId: event.view.challenge.id,
        status: status,
      );
      await _directory.respondToChallenge(
        challengeId: event.view.challenge.id,
        response: status,
      );
      if (event.accept) {
        // Publish a figure straight away rather than waiting for the
        // next drive: accepting mid-window with nothing published looks
        // to the opponent exactly like an opponent who never answered.
        await _challengeProgress.publishNow();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Rankings] answering challenge: $e');
    }
    await _rebuild(emit);
  }

  Future<void> _onChallengeWithdrawn(
    RankingsChallengeWithdrawn event,
    Emitter<RankingsState> emit,
  ) async {
    try {
      await _social.updateChallengeStatus(
        challengeId: event.view.challenge.id,
        status: ChallengeStatus.cancelled,
      );
      await _directory.respondToChallenge(
        challengeId: event.view.challenge.id,
        response: ChallengeStatus.cancelled,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Rankings] withdrawing challenge: $e');
    }
    await _rebuild(emit);
  }

  Future<void> _onChallengeCreated(
    RankingsChallengeCreated event,
    Emitter<RankingsState> emit,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    Challenge? local;
    try {
      local = await _createChallenge(
        creatorUid: uid,
        opponentUid: event.opponentUid,
        metric: event.metric,
        period: event.period,
        targetValue: event.value,
      );
      await _directory.createChallenge(local);
    } catch (e) {
      if (kDebugMode) debugPrint('[Rankings] creating challenge: $e');
      // **The local row must not outlive a failed remote write.** The
      // remote create can be refused — no friendship, or a clock the
      // rules disagree with — and a local-only challenge is invisible
      // to the person it names, unanswerable, and sits on the viewer's
      // screen forever waiting for a reply that cannot come. Exactly
      // the trap a friend request fell into on a real device.
      if (local != null) {
        try {
          await _social.updateChallengeStatus(
            challengeId: local.id,
            status: ChallengeStatus.cancelled,
          );
        } catch (rollback) {
          if (kDebugMode) debugPrint('[Rankings] rollback: $rollback');
        }
      }
    }
    await _rebuild(emit);
  }

  Future<void> _onMetricChanged(
    RankingsMetricChanged event,
    Emitter<RankingsState> emit,
  ) async {
    if (event.metric == _metric) return;
    _metric = event.metric;
    await _rebuild(emit);
  }

  Future<void> _onPeriodChanged(
    RankingsPeriodChanged event,
    Emitter<RankingsState> emit,
  ) async {
    if (event.period == _period) return;
    _period = event.period;
    await _rebuild(emit);
  }

  /// Recomputes the board and emits the new selection *with* it, in a
  /// single state.
  ///
  /// Emitting the selector change first and the board after would leave
  /// one frame where the pills say "longest trip" while the rows still
  /// show weekly distance — or "FRIENDS" over a board of benchmarks.
  /// Briefly, but visibly, a lie. The computation is local and cheap, so
  /// there's nothing to gain by showing the change early.
  Future<void> _rebuild(Emitter<RankingsState> emit) async {
    final uid = _uid;
    final nextMetric = _metric;
    final nextPeriod = _period;
    final nextScope = _scope;
    if (uid == null) {
      emit(
        state.copyWith(
          metric: nextMetric,
          period: nextPeriod,
          scope: nextScope,
        ),
      );
      return;
    }
    final board = switch (nextScope) {
      LeaderboardScope.global => await _getLeaderboard(
        uid: uid,
        displayName: _displayName,
        metric: nextMetric,
        period: nextPeriod,
      ),
      LeaderboardScope.friends => await _getFriendsLeaderboard(
        uid: uid,
        displayName: _displayName,
        metric: nextMetric,
        period: nextPeriod,
        // Filtered to who is *currently* a friend, not to whatever the
        // last snapshot held: unfriending somebody has to take them off
        // the board on the same frame, and a cached mirror belonging to
        // a stranger must never rank at all.
        friendProfiles: [
          for (final profile in state.friendProfiles)
            if (_friendUids.contains(profile.uid)) profile,
        ],
      ),
    };
    final targets = await _getTargets(uid: uid);
    final challenges = await _getChallenges(
      uid: uid,
      opponentProfiles: _opponentProfiles,
    );
    // Names for anybody newly on the other side of a challenge. Fetched
    // once each and kept, so a card never shows a raw uid twice.
    for (final view in challenges) {
      if (_opponentProfiles.containsKey(view.opponentUid)) continue;
      final profile = await _directory.profileFor(view.opponentUid);
      if (profile != null) _opponentProfiles[view.opponentUid] = profile;
    }
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
    // The selection moved while this was computing, so a newer rebuild
    // is already on its way. Emitting now would put one scope's rows
    // under another scope's chip — briefly, but visibly, a lie.
    if (nextMetric != _metric ||
        nextPeriod != _period ||
        nextScope != _scope) {
      return;
    }
    emit(
      state.copyWith(
        isLoading: false,
        metric: nextMetric,
        period: nextPeriod,
        scope: nextScope,
        board: board,
        targets: targets,
        trophies: trophies,
        qualifyingDayKeys: days,
        challenges: challenges,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _settingsSub?.cancel();
    await _tripsSub?.cancel();
    await _friendsSub?.cancel();
    await _profilesSub?.cancel();
    await _challengeSync.stop();
    return super.close();
  }
}
