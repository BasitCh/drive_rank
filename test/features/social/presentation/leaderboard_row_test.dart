import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_participant_type.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/presentation/widgets/leaderboard_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The visual-review gate, encoded.
///
/// The one question this screen has to answer is whether a normal user
/// can tell a benchmark from a person at a glance. These assert the two
/// independent signals that make that true — the identity glyph and the
/// label — so a later refactor can't quietly drop one and leave the
/// board ambiguous.
void main() {
  LeaderboardPosition positionFor({
    required int rank,
    required String name,
    required double value,
    bool isBenchmark = false,
    bool isMe = false,
  }) {
    return LeaderboardPosition(
      rank: rank,
      entry: LeaderboardEntry(
        id: name,
        displayName: name,
        value: value,
        participantType: isBenchmark
            ? LeaderboardParticipantType.benchmark
            : LeaderboardParticipantType.realUser,
        isCurrentUser: isMe,
      ),
    );
  }

  Future<void> pumpRow(
    WidgetTester tester,
    LeaderboardPosition position, {
    String? subtitle,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LeaderboardRow(
            position: position,
            formattedValue: position.entry.value.round().toString(),
            unitLabel: 'KM',
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }

  /// The row's own decoration — what carries the promotion.
  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(LeaderboardRow),
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  group('a benchmark row', () {
    testWidgets('is labelled BENCHMARK', (tester) async {
      await pumpRow(
        tester,
        positionFor(
          rank: 4,
          name: 'Daily Driver',
          value: 190,
          isBenchmark: true,
        ),
      );
      expect(find.text(AppStrings.leaderboardBenchmark), findsOneWidget);
      expect(find.text('Daily Driver'), findsOneWidget);
    });

    testWidgets('shows a gauge glyph for its identity and never a vehicle '
        'or avatar — a benchmark has no likeness because it is not a '
        'person', (tester) async {
      await pumpRow(
        tester,
        positionFor(
          rank: 4,
          name: 'Daily Driver',
          value: 190,
          isBenchmark: true,
        ),
      );
      expect(find.byIcon(Icons.speed_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsNothing);
    });

    testWidgets('says what it is on its second line', (tester) async {
      await pumpRow(
        tester,
        positionFor(
          rank: 4,
          name: 'Daily Driver',
          value: 190,
          isBenchmark: true,
        ),
        subtitle: AppStrings.rankingsPaceReference,
      );
      expect(find.text(AppStrings.rankingsPaceReference), findsOneWidget);
    });

    testWidgets('is never labelled YOU and is never promoted', (tester) async {
      await pumpRow(
        tester,
        positionFor(
          rank: 5,
          name: 'Road Regular',
          value: 120,
          isBenchmark: true,
        ),
      );
      expect(find.text(AppStrings.leaderboardYou), findsNothing);

      final decoration = decorationOf(tester);
      expect(decoration.color, AppColors.card);
      expect((decoration.border! as Border).top.width, 1);
    });
  });

  group("the viewer's own row", () {
    testWidgets('is labelled YOU and never BENCHMARK', (tester) async {
      await pumpRow(
        tester,
        positionFor(rank: 4, name: 'Basit', value: 417, isMe: true),
      );
      expect(find.text(AppStrings.leaderboardYou), findsOneWidget);
      expect(find.text(AppStrings.leaderboardBenchmark), findsNothing);
    });

    testWidgets('carries the promoted teal border and fill — so "this is '
        'me" survives even if the label is missed', (tester) async {
      await pumpRow(
        tester,
        positionFor(rank: 4, name: 'Basit', value: 417, isMe: true),
      );
      final decoration = decorationOf(tester);
      final border = decoration.border! as Border;
      expect(border.top.color, AppColors.teal);
      expect(border.top.width, 1.5);
      expect(decoration.color, isNot(AppColors.card));
    });

    testWidgets('never shows the benchmark glyph', (tester) async {
      await pumpRow(
        tester,
        positionFor(rank: 4, name: 'Basit', value: 417, isMe: true),
      );
      expect(find.byIcon(Icons.speed_rounded), findsNothing);
    });

    testWidgets('keeps its rank number', (tester) async {
      await pumpRow(
        tester,
        positionFor(rank: 4, name: 'Basit', value: 417, isMe: true),
      );
      expect(find.text('4'), findsOneWidget);
    });
  });

  group('another real person', () {
    testWidgets('gets a rank number and no marker at all', (tester) async {
      await pumpRow(tester, positionFor(rank: 6, name: 'Hamza', value: 300));
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Hamza'), findsOneWidget);
      expect(find.text(AppStrings.leaderboardYou), findsNothing);
      expect(find.text(AppStrings.leaderboardBenchmark), findsNothing);
      expect(find.byIcon(Icons.speed_rounded), findsNothing);
    });
  });

  testWidgets('a mixed list labels every benchmark and exactly one YOU',
      (tester) async {
    final positions = [
      positionFor(rank: 4, name: 'Daily Driver', value: 190, isBenchmark: true),
      positionFor(rank: 5, name: 'Basit', value: 150, isMe: true),
      positionFor(
        rank: 6,
        name: 'Road Regular',
        value: 120,
        isBenchmark: true,
      ),
      positionFor(rank: 7, name: 'Hamza', value: 90),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final position in positions)
                LeaderboardRow(
                  position: position,
                  formattedValue: position.entry.value.round().toString(),
                  unitLabel: 'KM',
                ),
            ],
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.leaderboardBenchmark), findsNWidgets(2));
    expect(find.text(AppStrings.leaderboardYou), findsOneWidget);
    // One gauge glyph per benchmark, and none for the two people.
    expect(find.byIcon(Icons.speed_rounded), findsNWidgets(2));
  });
}
