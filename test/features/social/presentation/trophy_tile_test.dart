import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/presentation/widgets/trophy_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A trophy grid has to be honest about three different situations, and
/// they must not look alike: earned, not-yet-earned, and can't-be-earned
/// -yet. Conflating the last two would set the user chasing something
/// unreachable.
void main() {
  Future<void> pump(
    WidgetTester tester,
    TrophyType type, {
    DateTime? unlockedAt,
    String? unlockedLabel,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrophyTile(
            type: type,
            unlockedAt: unlockedAt,
            unlockedLabel: unlockedLabel,
          ),
        ),
      ),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(TrophyTile),
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  group('an earned trophy', () {
    testWidgets('shows its title, description and unlock date', (tester) async {
      await pump(
        tester,
        TrophyType.roadWarrior,
        unlockedAt: DateTime(2026, 9, 3),
        unlockedLabel: '3 Sep',
      );
      expect(find.text(TrophyType.roadWarrior.title), findsOneWidget);
      expect(find.text(TrophyType.roadWarrior.description), findsOneWidget);
      expect(find.text('3 Sep'), findsOneWidget);
    });

    testWidgets('is promoted in teal and carries no lock', (tester) async {
      await pump(
        tester,
        TrophyType.roadWarrior,
        unlockedAt: DateTime(2026, 9, 3),
        unlockedLabel: '3 Sep',
      );
      expect(decorationOf(tester).color, isNot(AppColors.card));
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
    });

    testWidgets('an earned trophy that is normally unearnable still reads '
        'as earned rather than locked — the data wins over the '
        'capability flag', (tester) async {
      await pump(
        tester,
        TrophyType.firstWin,
        unlockedAt: DateTime(2026, 9, 3),
        unlockedLabel: '3 Sep',
      );
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(find.text('3 Sep'), findsOneWidget);
      expect(
        find.text(TrophyType.firstWin.unavailableReason!),
        findsNothing,
      );
    });
  });

  group('an unearned but earnable trophy', () {
    testWidgets('is muted, unlocked-icon-free, and says nothing about '
        'blockers because it has none', (tester) async {
      await pump(tester, TrophyType.consistent);
      expect(decorationOf(tester).color, AppColors.card);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(find.text(TrophyType.consistent.description), findsOneWidget);
    });
  });

  group("a trophy that can't be earned yet", () {
    testWidgets('is locked and states the reason', (tester) async {
      await pump(tester, TrophyType.firstWin);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('Needs friends'), findsOneWidget);
    });

    testWidgets('rank climber blames the lack of drivers, not friends',
        (tester) async {
      await pump(tester, TrophyType.rankClimber);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('Needs more drivers'), findsOneWidget);
    });

    testWidgets('is visually distinct from an earned one', (tester) async {
      await pump(tester, TrophyType.firstWin);
      final locked = decorationOf(tester).color;
      await pump(
        tester,
        TrophyType.firstWin,
        unlockedAt: DateTime(2026, 9, 3),
        unlockedLabel: '3 Sep',
      );
      expect(decorationOf(tester).color, isNot(locked));
    });
  });
}
