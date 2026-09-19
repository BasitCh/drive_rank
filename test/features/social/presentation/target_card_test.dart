import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/domain/entities/target.dart';
import 'package:drive_rank/features/social/presentation/widgets/target_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Target targetFor({
    double value = 100,
    double target = 250,
    DateTime? completedAt,
  }) {
    final now = DateTime(2026, 9, 3);
    return Target(
      challenge: Challenge(
        id: 'target-1',
        creatorUid: 'user-1',
        metric: CompetitionMetric.distance,
        targetValue: target,
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

  Future<void> pump(
    WidgetTester tester,
    Target target, {
    VoidCallback? onCancel,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TargetCard(
            target: target,
            metricLabel: 'Distance · This week',
            formattedTarget: '250 KM',
            formattedRemaining: '150 km',
            windowLabel: 'Ends Sunday',
            onCancel: onCancel,
          ),
        ),
      ),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(TargetCard),
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  group('an active target', () {
    testWidgets('leads with what is left to do, not what is done — '
        '"150 km to go" is actionable where "100 of 250" is a readout',
        (tester) async {
      await pump(tester, targetFor());
      expect(find.text(AppStrings.targetsRemaining('150 km')), findsOneWidget);
      expect(find.text(AppStrings.targetsDone), findsNothing);
    });

    testWidgets('shows its metric, target and deadline', (tester) async {
      await pump(tester, targetFor());
      expect(find.text('Distance · This week'), findsOneWidget);
      expect(find.text('250 KM'), findsOneWidget);
      expect(find.text('Ends Sunday'), findsOneWidget);
    });

    testWidgets('offers a way out when the caller allows it', (tester) async {
      var cancelled = false;
      await pump(tester, targetFor(), onCancel: () => cancelled = true);
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(cancelled, isTrue);
    });

    testWidgets('has no cancel affordance when the caller offers none',
        (tester) async {
      await pump(tester, targetFor());
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });

  group('a completed target', () {
    testWidgets('is promoted and says it is done rather than showing a '
        'remaining figure', (tester) async {
      await pump(
        tester,
        targetFor(value: 300, completedAt: DateTime(2026, 9, 3)),
      );
      expect(find.text(AppStrings.targetsDone), findsOneWidget);
      expect(find.text(AppStrings.targetsRemaining('150 km')), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(decorationOf(tester).color, isNot(AppColors.card));
    });

    testWidgets('is not cancellable, because a finished result is '
        'history', (tester) async {
      var cancelled = false;
      await pump(
        tester,
        targetFor(value: 300, completedAt: DateTime(2026, 9, 3)),
        onCancel: () => cancelled = true,
      );
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(cancelled, isFalse);
    });
  });
}
