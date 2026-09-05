import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/rank_change.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/trip_summary/presentation/widgets/trip_competition_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The card shows exactly one headline, chosen by priority. These pin
/// that order, because a trip that did four things at once must not
/// announce all four — and the branch that matters most must win.
void main() {
  Target targetFor({DateTime? completedAt, double value = 100}) {
    final now = DateTime(2026, 9, 3);
    return Target(
      challenge: Challenge(
        id: 'target-1',
        creatorUid: 'user-1',
        metric: CompetitionMetric.distance,
        targetValue: 250,
        period: LeaderboardPeriod.weekly,
        startAt: DateTime(2026, 8, 31),
        endAt: DateTime(2026, 9, 7),
        status: ChallengeStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
      currentValue: value,
      completedAt: completedAt,
    );
  }

  Trophy trophyFor() => Trophy(
    id: 'roadWarrior:user-1:2026-W36',
    uid: 'user-1',
    type: TrophyType.roadWarrior,
    unlockedAt: DateTime(2026, 9, 3),
  );

  const rankChange = RankChange(
    metric: CompetitionMetric.distance,
    period: LeaderboardPeriod.weekly,
    previousRank: 7,
    newRank: 5,
    passedNames: ['Road Regular', 'Weekend Cruiser'],
  );

  Future<void> pump(
    WidgetTester tester, {
    RankChange? change,
    List<Target> completed = const [],
    List<Target> active = const [],
    List<Trophy> trophies = const [],
    bool isIneligible = false,
    VoidCallback? onViewRankings,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripCompetitionCard(
            rankChange: change,
            completedTargets: completed,
            activeTargets: active,
            unlockedTrophies: trophies,
            isIneligible: isIneligible,
            formatTargetRemaining: (_) => '150 km',
            onViewRankings: onViewRankings,
          ),
        ),
      ),
    );
  }

  group('rank movement', () {
    testWidgets('shows the from/to and the places gained', (tester) async {
      await pump(tester, change: rankChange);
      expect(find.text(AppStrings.tripRankMoved(7, 5)), findsOneWidget);
      expect(find.text(AppStrings.tripRankPlaces(2)), findsOneWidget);
    });

    testWidgets('names who was passed instead of asserting a bare count',
        (tester) async {
      await pump(tester, change: rankChange);
      expect(
        find.text(AppStrings.tripPassedMore('Road Regular', 1)),
        findsOneWidget,
      );
    });

    testWidgets('names a single overtake without an "and others" tail',
        (tester) async {
      await pump(
        tester,
        change: const RankChange(
          metric: CompetitionMetric.distance,
          period: LeaderboardPeriod.weekly,
          previousRank: 6,
          newRank: 5,
          passedNames: ['Road Regular'],
        ),
      );
      expect(find.text(AppStrings.tripPassed('Road Regular')), findsOneWidget);
    });

    testWidgets('outranks a completed target, a trophy and progress — '
        'movement is the headline when it happened', (tester) async {
      await pump(
        tester,
        change: rankChange,
        completed: [targetFor(completedAt: DateTime(2026, 9, 3))],
        trophies: [trophyFor()],
        active: [targetFor()],
      );
      expect(find.text(AppStrings.tripRankMoved(7, 5)), findsOneWidget);
      expect(find.text(AppStrings.tripTargetCompleted), findsNothing);
      expect(find.text(AppStrings.tripTrophyUnlocked), findsNothing);
    });
  });

  group('without rank movement', () {
    testWidgets('a completed target is the headline', (tester) async {
      await pump(
        tester,
        completed: [targetFor(completedAt: DateTime(2026, 9, 3))],
        trophies: [trophyFor()],
        active: [targetFor()],
      );
      expect(find.text(AppStrings.tripTargetCompleted), findsOneWidget);
      // …and the supporting line adds something instead of repeating the
      // headline, which is what this originally did.
      expect(find.text(AppStrings.tripTargetCompletedBody), findsOneWidget);
      expect(find.text(AppStrings.tripTrophyUnlocked), findsNothing);
    });

    testWidgets('a trophy comes next', (tester) async {
      await pump(tester, trophies: [trophyFor()], active: [targetFor()]);
      expect(find.text(AppStrings.tripTrophyUnlocked), findsOneWidget);
      expect(find.text(TrophyType.roadWarrior.title), findsOneWidget);
    });

    testWidgets('target progress is the fallback', (tester) async {
      await pump(tester, active: [targetFor()]);
      expect(find.text(AppStrings.targetsRemaining('150 km')), findsOneWidget);
    });
  });

  group('an ineligible trip', () {
    testWidgets('explains itself rather than showing nothing, which '
        'would leave the user wondering why the drive did nothing',
        (tester) async {
      await pump(tester, isIneligible: true);
      expect(find.text(AppStrings.tripNotEligibleTitle), findsOneWidget);
      expect(find.text(AppStrings.tripNotEligibleBody), findsOneWidget);
    });

    testWidgets('takes precedence over everything else — a trip that did '
        'not count cannot also claim it moved you', (tester) async {
      await pump(
        tester,
        isIneligible: true,
        change: rankChange,
        completed: [targetFor(completedAt: DateTime(2026, 9, 3))],
        trophies: [trophyFor()],
      );
      expect(find.text(AppStrings.tripNotEligibleTitle), findsOneWidget);
      expect(find.text(AppStrings.tripRankMoved(7, 5)), findsNothing);
      expect(find.text(AppStrings.tripTargetCompleted), findsNothing);
    });
  });

  testWidgets('renders nothing at all when the trip changed nothing',
      (tester) async {
    await pump(tester);
    expect(find.byType(Card), findsNothing);
    expect(find.text(AppStrings.tripCompetitionTitle), findsNothing);
  });

  testWidgets('offers a way to the rankings only when the caller wires '
      'one', (tester) async {
    await pump(tester, change: rankChange);
    expect(find.text(AppStrings.tripViewRankingsCta), findsNothing);

    var tapped = false;
    await pump(
      tester,
      change: rankChange,
      onViewRankings: () => tapped = true,
    );
    expect(find.text(AppStrings.tripViewRankingsCta), findsOneWidget);
    await tester.tap(find.text(AppStrings.tripViewRankingsCta));
    expect(tapped, isTrue);
  });
}
