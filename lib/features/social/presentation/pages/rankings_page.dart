import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsRow;
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/social/domain/entities/account_label.dart';
import 'package:drive_rank/features/social/domain/entities/benchmark_tier.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_scope.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/domain/usecases/compare_with_opponent.dart';
import 'package:drive_rank/features/social/presentation/bloc/rankings_bloc.dart';
import 'package:drive_rank/features/social/presentation/widgets/compare_sheet.dart';
import 'package:drive_rank/features/social/presentation/widgets/create_target_sheet.dart';
import 'package:drive_rank/features/social/presentation/widgets/leaderboard_row.dart';
import 'package:drive_rank/features/social/presentation/widgets/my_rank_hero.dart';
import 'package:drive_rank/features/social/presentation/widgets/rankings_tab_bar.dart';
import 'package:drive_rank/features/social/presentation/widgets/selector_chip.dart';
import 'package:drive_rank/features/social/presentation/widgets/targets_tab.dart';
import 'package:drive_rank/features/social/presentation/widgets/top_three_podium.dart';
import 'package:drive_rank/features/social/presentation/widgets/trophies_tab.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The rankings board, global or friends.
///
/// Structured like `HistoryPage` — no AppBar, a fixed header and pinned
/// selectors above a scrolling list — so it feels like a sibling of the
/// other tab screens rather than a new kind of screen.
///
/// The friends scope is a third selector chip, not a fourth tab: the
/// podium, rows, rank card and compare sheet are identical either way,
/// and only the population differs.
class RankingsPage extends StatelessWidget {
  const RankingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RankingsBloc>(
      create: (_) => getIt<RankingsBloc>()..add(const RankingsStarted()),
      child: const _RankingsBody(),
    );
  }
}

class _RankingsBody extends StatelessWidget {
  const _RankingsBody();

  static const _metrics = <(CompetitionMetric, String)>[
    (CompetitionMetric.distance, AppStrings.rankingsMetricDistance),
    (CompetitionMetric.longestTrip, AppStrings.rankingsMetricLongestTrip),
    (CompetitionMetric.consistency, AppStrings.rankingsMetricConsistency),
  ];

  static const _periods = <(LeaderboardPeriod, String)>[
    (LeaderboardPeriod.weekly, AppStrings.rankingsPeriodWeek),
    (LeaderboardPeriod.monthly, AppStrings.rankingsPeriodMonth),
    (LeaderboardPeriod.allTime, AppStrings.rankingsPeriodAllTime),
  ];

  static const _scopes = <(LeaderboardScope, String)>[
    (LeaderboardScope.global, AppStrings.rankingsScopeGlobal),
    (LeaderboardScope.friends, AppStrings.rankingsScopeFriends),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<RankingsBloc, RankingsState>(
          builder: (context, state) {
            // The kill switch. The router also bounces a direct
            // navigation here and the nav bar hides the tab; all three
            // read the same settings flag, so this branch is the last
            // line of defence rather than an independent rule.
            if (!state.rankingsEnabled) {
              return const _RankingsMessage(
                icon: Icons.leaderboard_rounded,
                title: AppStrings.rankingsDisabledTitle,
                body: AppStrings.rankingsDisabledBody,
              );
            }

            final isBoard = state.tab == RankingsTab.board;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(),
                RankingsTabBar(
                  active: state.tab,
                  onChanged: (t) =>
                      context.read<RankingsBloc>().add(RankingsTabChanged(t)),
                ),
                const SizedBox(height: AppSpacing.md),
                // The metric and period filters belong to the board and
                // only the board — above Targets or Trophies they'd be
                // two rows of chrome that filter nothing.
                if (isBoard) ...[
                  _BoardSelectors(state: state),
                  const SizedBox(height: AppSpacing.md),
                  // Your standing stays pinned rather than scrolling
                  // with the board: it's the answer the screen exists
                  // to give, and as a scrolling child it slid out of
                  // view the moment the user looked down the list.
                  if (state.board?.me != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _MyRank(state: state),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
                Expanded(
                  child: switch (state.tab) {
                    RankingsTab.board => _Board(state: state),
                    RankingsTab.targets => _Targets(state: state),
                    RankingsTab.trophies => TrophiesTab(
                      trophies: state.trophies,
                      formatUnlockedAt: _formatDay,
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The board's two selectors, as chips rather than two rows of pills.
class _BoardSelectors extends StatelessWidget {
  const _BoardSelectors({required this.state});

  final RankingsState state;

  static String _metricLabel(CompetitionMetric metric) => switch (metric) {
    CompetitionMetric.distance => AppStrings.rankingsMetricDistance,
    CompetitionMetric.longestTrip => AppStrings.rankingsMetricLongestTrip,
    CompetitionMetric.consistency => AppStrings.rankingsMetricConsistency,
  };

  static String _periodLabel(LeaderboardPeriod period) => switch (period) {
    LeaderboardPeriod.weekly => AppStrings.rankingsPeriodWeek,
    LeaderboardPeriod.monthly => AppStrings.rankingsPeriodMonth,
    LeaderboardPeriod.allTime => AppStrings.rankingsPeriodAllTime,
  };

  Future<T?> _pick<T>(
    BuildContext context, {
    required String title,
    required List<(T, String)> options,
    required T active,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          SelectorSheet<T>(title: title, options: options, active: active),
    );
  }

  static String _scopeLabel(LeaderboardScope scope) => scope.label;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RankingsBloc>();
    return SelectorChipRow(
      chips: [
        SelectorChip(
          icon: Icons.people_alt_rounded,
          label: _scopeLabel(state.scope),
          onTap: () async {
            final picked = await _pick<LeaderboardScope>(
              context,
              title: AppStrings.rankingsScopeLabel,
              options: _RankingsBody._scopes,
              active: state.scope,
            );
            if (picked != null) bloc.add(RankingsScopeChanged(picked));
          },
        ),
        SelectorChip(
          icon: Icons.flag_rounded,
          label: _metricLabel(state.metric),
          onTap: () async {
            final picked = await _pick<CompetitionMetric>(
              context,
              title: AppStrings.createTargetMetricLabel,
              options: _RankingsBody._metrics,
              active: state.metric,
            );
            if (picked != null) bloc.add(RankingsMetricChanged(picked));
          },
        ),
        SelectorChip(
          icon: Icons.calendar_today_rounded,
          label: _periodLabel(state.period),
          onTap: () async {
            final picked = await _pick<LeaderboardPeriod>(
              context,
              title: AppStrings.createTargetPeriodLabel,
              options: _RankingsBody._periods,
              active: state.period,
            );
            if (picked != null) bloc.add(RankingsPeriodChanged(picked));
          },
        ),
      ],
    );
  }
}

/// Opens the head-to-head for whoever the viewer tapped.
///
/// Resolved through `getIt` rather than the bloc: this is a one-shot
/// read for a modal, and putting it in `RankingsState` would mean the
/// bloc had to model whether a sheet is open.
///
/// A friend's side comes from the mirror already in state rather than a
/// fresh fetch — it's the very snapshot their row was ranked on, so the
/// sheet can't contradict the board it opened from.
Future<void> _openCompare(
  BuildContext context,
  RankingsState state,
  LeaderboardEntry entry,
) async {
  final compare = getIt<CompareWithOpponent>();
  final uid = state.viewer?.uid ?? '';

  final Comparison? comparison;
  if (entry.isBenchmark) {
    comparison = await compare.againstBenchmark(
      uid: uid,
      benchmarkId: entry.id,
      period: state.period,
    );
  } else {
    final friend = state.friendProfiles
        .where((profile) => profile.uid == entry.id)
        .firstOrNull;
    if (friend == null) return;
    comparison = await compare.againstFriend(
      uid: uid,
      friend: friend,
      period: state.period,
    );
  }
  if (comparison == null || !context.mounted) return;
  // A local the closure can capture: a nullable captured by the sheet's
  // builder can't be promoted, however it was checked.
  final built = comparison;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bg2,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => CompareSheet(
      comparison: built,
      periodLabel: _BoardSelectors._periodLabel(state.period),
      metricLabel: _BoardSelectors._metricLabel,
      formatValue: (metric, value) {
        final format = _MetricFormat.of(metric);
        return '${format.value(value)} ${format.unit(value)}';
      },
      viewer: state.viewer,
      // Only a person can be challenged, and only from the friends
      // board — the sheet opens against a benchmark on the global one,
      // and a published constant cannot agree to a contest.
      onChallenge: entry.isBenchmark
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              _openChallengeSheet(context, entry.id);
            },
    ),
  );
}

/// Asks for the terms, then opens the challenge.
///
/// Reuses `CreateTargetSheet`'s pickers with all-time withheld: an
/// all-time window has no end, and a race with no finish line cannot be
/// settled, so offering it would be offering a button that throws.
Future<void> _openChallengeSheet(
  BuildContext context,
  String opponentUid,
) async {
  final bloc = context.read<RankingsBloc>();
  final request = await showModalBottomSheet<NewTargetRequest>(
    context: context,
    backgroundColor: AppColors.bg2,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const CreateTargetSheet(
      title: AppStrings.challengeCreateTitle,
      ctaLabel: AppStrings.challengeCreateCta,
      allowAllTime: false,
      deadlineFor: _Targets._deadlineFor,
    ),
  );
  if (request == null) return;
  bloc.add(
    RankingsChallengeCreated(
      opponentUid: opponentUid,
      metric: request.metric,
      period: request.period,
      value: request.value,
    ),
  );
}

class _MyRank extends StatelessWidget {
  const _MyRank({required this.state});

  final RankingsState state;

  @override
  Widget build(BuildContext context) {
    final board = state.board!;
    final format = _MetricFormat.of(state.metric);
    final window = CompetitionWindow.forPeriod(state.period, DateTime.now());
    final countdown = window.countdownAt(DateTime.now());

    return MyRankHero(
      board: board,
      formattedValue: format.value(board.me!.entry.value),
      unitLabel: format.unit(board.me!.entry.value),
      formatGap: format.gap,
      tier: BenchmarkTier.forValue(
        value: board.me!.entry.value,
        metric: state.metric,
        period: state.period,
      ),
      countdownLabel: countdown == null
          ? null
          : AppStrings.rankingsEndsIn(
              _formatDay(countdown.endsAfter),
              countdown.daysLeft,
            ),
      // Seven dots describe a week. On a monthly or all-time board they
      // would be answering a question nobody asked.
      weekDays: state.period == LeaderboardPeriod.weekly
          ? _weekDays(window, state.qualifyingDayKeys)
          : null,
    );
  }

  /// Monday-first booleans for the window's seven days.
  static List<bool> _weekDays(CompetitionWindow window, Set<int> driven) {
    return [
      for (var i = 0; i < 7; i++)
        driven.contains(
          _dayKey(
            DateTime(window.start.year, window.start.month, window.start.day + i),
          ),
        ),
    ];
  }

  /// The same key `CompetitionTrip.localDayKey` builds, so the strip and
  /// the consistency metric agree on what a day is.
  static int _dayKey(DateTime day) =>
      day.year * 10000 + day.month * 100 + day.day;
}

/// Formats one metric's numbers.
///
/// Consistency counts days, which don't convert between unit systems;
/// the other two are distances and go through `LocaleService` so they
/// honour km/mi. Built once per metric and shared by the rank card and
/// the rows so the two can't format the same number differently.
class _MetricFormat {
  _MetricFormat._({required this.isDays}) : _locale = getIt<LocaleService>();

  factory _MetricFormat.of(CompetitionMetric metric) =>
      _MetricFormat._(isDays: metric == CompetitionMetric.consistency);

  final bool isDays;
  final LocaleService _locale;

  String _daysUnit(num value) =>
      value == 1 ? AppStrings.rankingsUnitDay : AppStrings.rankingsUnitDays;

  String value(double v) =>
      isDays ? v.round().toString() : _locale.formatDistanceValue(v);

  String unit(double v) =>
      isDays ? _daysUnit(v) : _locale.distanceUnitLabel.toUpperCase();

  /// The shortened form for the podium and rows, where six figures have
  /// to be comparable at a glance. Day counts are already short enough
  /// to leave alone.
  String compact(double v) =>
      isDays ? v.round().toString() : _locale.formatDistanceCompact(v);

  String gap(double delta) {
    final magnitude = delta.abs();
    if (!isDays) {
      // A decimal place only earns its keep on a small gap: "111 km
      // behind" reads as a fact, "111.0 km behind" reads as a readout.
      return _locale.formatDistance(
        magnitude,
        fractionDigits: magnitude >= 10 ? 0 : 1,
      );
    }
    // Round a partial day up: "1 day behind" is truer than "0 days".
    final days = magnitude.ceil();
    return '$days ${_daysUnit(days).toLowerCase()}';
  }
}

/// "5 hours" / "40 minutes" — how long until a challenge's figures
/// freeze.
///
/// Coarse on purpose: the grace is hours long, and a ticking countdown
/// would imply the result is about to change when usually nothing more
/// is coming.
String _formatRemaining(Duration? left) {
  if (left == null || left <= Duration.zero) return '';
  if (left.inHours >= 1) {
    final hours = left.inHours;
    return hours == 1 ? '1 hour' : '$hours hours';
  }
  final minutes = left.inMinutes < 1 ? 1 : left.inMinutes;
  return minutes == 1 ? '1 minute' : '$minutes minutes';
}

/// Weekday/date label for a deadline or an unlock date.
///
/// Deliberately not `intl` — the app has no localized date formatting
/// anywhere, and a target deadline reads better as a weekday ("Sunday")
/// than a date when it's inside the coming week.
String _formatDay(DateTime day) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = day.toLocal();
  final now = DateTime.now();
  final withinAWeek = local.difference(now).inDays.abs() < 7;
  if (withinAWeek) return weekdays[local.weekday - 1];
  return '${local.day} ${months[local.month - 1]}';
}

/// The Targets tab, wired to the bloc.
///
/// All formatting is assembled here and handed down, so `TargetsTab` and
/// `TargetCard` never touch enums, `LocaleService` or dates.
class _Targets extends StatelessWidget {
  const _Targets({required this.state});

  final RankingsState state;

  static String _metricLabel(CompetitionMetric metric) => switch (metric) {
    CompetitionMetric.distance => AppStrings.rankingsMetricDistance,
    CompetitionMetric.longestTrip => AppStrings.rankingsMetricLongestTrip,
    CompetitionMetric.consistency => AppStrings.rankingsMetricConsistency,
  };

  static String _periodLabel(LeaderboardPeriod period) => switch (period) {
    LeaderboardPeriod.weekly => AppStrings.rankingsPeriodWeek,
    LeaderboardPeriod.monthly => AppStrings.rankingsPeriodMonth,
    LeaderboardPeriod.allTime => AppStrings.rankingsPeriodAllTime,
  };

  Future<void> _create(BuildContext context) async {
    final bloc = context.read<RankingsBloc>();
    final request = await showModalBottomSheet<NewTargetRequest>(
      context: context,
      backgroundColor: AppColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreateTargetSheet(deadlineFor: _deadlineFor),
    );
    if (request == null) return;
    bloc.add(
      RankingsTargetCreated(
        metric: request.metric,
        period: request.period,
        value: request.value,
      ),
    );
  }

  /// The deadline a period would inherit, so the sheet can show it
  /// without computing a date itself — `CompetitionWindow` stays the one
  /// definition of when a period ends.
  static String _deadlineFor(LeaderboardPeriod period) {
    final window = CompetitionWindow.forPeriod(period, DateTime.now());
    final end = window.end;
    if (end == null) return AppStrings.rankingsPeriodAllTime;
    // The window end is exclusive, so the last day you can drive on is
    // the day before it.
    return AppStrings.targetsEndsOn(
      _formatDay(end.subtract(const Duration(days: 1))),
    );
  }

  Future<void> _confirmCancel(BuildContext context, Target target) async {
    final bloc = context.read<RankingsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text(AppStrings.targetsCancelTitle),
        content: const Text(AppStrings.targetsCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              AppStrings.targetsCancelConfirm,
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(RankingsTargetCancelled(target.challenge.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    return TargetsTab(
      targets: state.targets,
      challenges: state.challenges,
      onCreate: () => _create(context),
      onCancel: (target) => _confirmCancel(context, target),
      onAcceptChallenge: (view) => context.read<RankingsBloc>().add(
        RankingsChallengeAnswered(view, accept: true),
      ),
      onDeclineChallenge: (view) => context.read<RankingsBloc>().add(
        RankingsChallengeAnswered(view, accept: false),
      ),
      onWithdrawChallenge: (view) => context.read<RankingsBloc>().add(
        RankingsChallengeWithdrawn(view),
      ),
      challengeMetricLabelFor: (view) =>
          '${_metricLabel(view.challenge.metric)} \u00b7 '
          '${_periodLabel(view.challenge.period)}',
      formatChallengeValue: (view, value) {
        final format = _MetricFormat.of(view.challenge.metric);
        return '${format.compact(value)} ${format.unit(value)}';
      },
      // When driving stops counting.
      challengeDeadlineFor: (view) => AppStrings.targetsEndsOn(
        _formatDay(
          view.challenge.endAt.subtract(const Duration(days: 1)),
        ),
      ),
      // How long until the figures freeze — deliberately a different
      // label from the deadline above, because they are different
      // moments and the card must not blur them.
      challengeRemainingFor: (view) => _formatRemaining(
        view.settlement.remainingUntilFinal(DateTime.now()),
      ),
      metricLabelFor: (t) =>
          '${_metricLabel(t.challenge.metric)} \u00b7 '
          '${_periodLabel(t.challenge.period)}',
      formatTarget: (t) {
        final format = _MetricFormat.of(t.challenge.metric);
        return '${format.value(t.targetValue)} ${format.unit(t.targetValue)}';
      },
      formatRemaining: (t) =>
          _MetricFormat.of(t.challenge.metric).gap(t.remaining),
      // A finished target's deadline is no longer the interesting date —
      // when it was reached is.
      windowLabelFor: (t) => t.completedAt != null
          ? '${AppStrings.targetsCompletedOn} ${_formatDay(t.completedAt!)}'
          : AppStrings.targetsEndsOn(
              _formatDay(t.challenge.endAt.subtract(const Duration(days: 1))),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Text(
        AppStrings.leaderboardTitle,
        style: AppTextStyles.sectionTitle,
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.state});

  final RankingsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    // "You have nobody to rank against" is a different answer from "you
    // haven't driven", and pointing the first at History would be no
    // help at all.
    if (state.scope == LeaderboardScope.friends && !state.hasFriends) {
      return _RankingsMessage(
        icon: Icons.group_add_rounded,
        title: AppStrings.rankingsNoFriendsTitle,
        body: AppStrings.rankingsNoFriendsBody,
        action: (
          AppStrings.rankingsNoFriendsCta,
          () => context.push(RouteNames.friends),
        ),
      );
    }

    final board = state.board;
    if (board == null || board.positions.isEmpty) {
      return const _RankingsMessage(
        icon: Icons.leaderboard_rounded,
        title: AppStrings.rankingsNoTripsTitle,
        body: AppStrings.rankingsNoTripsBody,
      );
    }

    final format = _MetricFormat.of(state.metric);
    final podium = board.positions.take(3).toList();
    final rest = board.positions.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        TopThreePodium(
          positions: podium,
          formatValue: format.compact,
          unitFor: format.unit,
          viewer: state.viewer,
          onCompare: (entry) => _openCompare(context, state, entry),
        ),
        if (board.isSparse) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _SparseNote(hasRankedDrives: board.me!.entry.value > 0),
          ),
        ],
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final position in rest) ...[
                  LeaderboardRow(
                    position: position,
                    formattedValue: format.compact(position.entry.value),
                    unitLabel: format.unit(position.entry.value),
                    subtitle: _subtitleFor(position, state.viewer),
                    viewer: state.viewer,
                    // Everyone but the viewer is a compare target.
                    // Tapping yourself would open you against yourself.
                    onTap: position.entry.isCurrentUser
                        ? null
                        : () => _openCompare(context, state, position.entry),
                  ),
                  const SizedBox(height: 5),
                ],
              ],
            ),
          ),
        ],
        if (board.benchmarksShown) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.rankingsBenchmarkFooter,
            textAlign: TextAlign.center,
            style: AppTextStyles.microLabel.copyWith(fontSize: 10),
          ),
        ],
        // The trust model, said to the people it applies to rather than
        // only in the code that implements it.
        if (state.scope == LeaderboardScope.friends) ...[
          const SizedBox(height: 6),
          Text(
            AppStrings.rankingsFriendsFooter,
            textAlign: TextAlign.center,
            style: AppTextStyles.microLabel.copyWith(fontSize: 10),
          ),
        ],
      ],
    );
  }

  /// The row's second line.
  ///
  /// A benchmark says what it is. The viewer's comes from their settings
  /// row, which is fresher than anything they published. A friend's
  /// comes from their mirror, through the very `AccountLabel.describe`
  /// the friend search uses — but **without the invite code**: a code
  /// disambiguates a stranger you're about to add, and is noise beside
  /// somebody you already chose.
  ///
  /// Nobody gets a placeholder. A driver who hasn't set a car reads as
  /// having no car, not as having a blank one.
  String? _subtitleFor(LeaderboardPosition position, UserSettingsRow? viewer) {
    final entry = position.entry;
    if (entry.isBenchmark) return AppStrings.rankingsPaceReference;

    if (!entry.isCurrentUser) {
      final label = AccountLabel.describe(
        countryCode: entry.countryCode,
        carMake: entry.carMake,
        carModel: entry.carModel,
        inviteCode: '',
        includeCode: false,
      );
      final published = entry.publishedAt;
      final age = published == null ? null : _agoLabel(published);
      final parts = [
        if (label.isNotEmpty) label,
        if (age != null) AppStrings.rankingsPublishedAgo(age),
      ];
      return parts.isEmpty ? null : parts.join('  ·  ');
    }

    if (viewer == null) return null;
    final car = [
      viewer.carMake,
      viewer.carModel,
    ].where((part) => part.isNotEmpty).join(' ');
    final country = countryFromCode(viewer.country ?? '');
    final parts = [
      if (country != null) '${country.flag} ${country.name}',
      if (car.isNotEmpty) car,
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  /// "today" / "yesterday" / "3 days ago" — day granularity, because
  /// the mirror is published a few times a day at most and "4 hours ago"
  /// would imply a precision the number doesn't have.
  static String _agoLabel(DateTime published) {
    final days = DateTime.now().difference(published).inDays;
    return days <= 0
        ? AppStrings.rankingsAgoToday
        : AppStrings.rankingsAgoDays(days);
  }
}

/// Shown while the viewer is the only real competitor.
///
/// Deliberately not an empty state — the board above it is populated
/// with benchmarks, so this explains the situation rather than
/// apologising for it. Kept to a single line: it appears on every
/// sparse board, and as a paragraph it pushed the podium itself below
/// the fold.
///
/// The copy splits on whether they've actually ranked anything yet —
/// the two situations look identical structurally but need opposite
/// advice.
class _SparseNote extends StatelessWidget {
  const _SparseNote({required this.hasRankedDrives});

  final bool hasRankedDrives;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tealDim,
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.teal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasRankedDrives
                  ? AppStrings.rankingsSparseRankedTitle
                  : AppStrings.rankingsSparseTitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The full-screen message shape shared by the disabled and no-trips
/// states — the 72×72 circle formula used by `OfflineState` and the
/// territory empty state.
class _RankingsMessage extends StatelessWidget {
  const _RankingsMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;

  /// An optional label and callback. Only the friends board has one: its
  /// emptiness has a fix, and a message that names the fix without
  /// offering it makes the user go looking for it.
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.teal, size: 34),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: action!.$2,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: 12,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(action!.$1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
