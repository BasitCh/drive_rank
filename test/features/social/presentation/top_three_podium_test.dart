import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_participant_type.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/presentation/widgets/benchmark_badge.dart';
import 'package:drive_rank/features/social/presentation/widgets/top_three_podium.dart';
import 'package:drive_rank/shared/widgets/car_silhouette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The podium is what makes the screen read as a competition, so it's
/// also where a benchmark is most at risk of being mistaken for a
/// winner. These pin the two things that prevent that: every benchmark
/// tile stays labelled, and the trophy only goes gold for a real person.
void main() {
  LeaderboardPosition positionFor({
    required int rank,
    required String name,
    required double value,
    bool isBenchmark = false,
    bool isMe = false,
    String countryCode = '',
    String carMake = '',
    bool isStale = false,
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
        countryCode: countryCode,
        carMake: carMake,
        isStale: isStale,
      ),
    );
  }

  Future<void> pumpPodium(
    WidgetTester tester,
    List<LeaderboardPosition> positions, {
    void Function(LeaderboardEntry)? onCompare,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopThreePodium(
            positions: positions,
            formatValue: (v) => v.round().toString(),
            unitFor: (_) => 'KM',
            onCompare: onCompare,
          ),
        ),
      ),
    );
  }

  List<LeaderboardPosition> allBenchmarks() => [
    positionFor(rank: 1, name: 'Road Warrior', value: 574, isBenchmark: true),
    positionFor(
      rank: 2,
      name: 'Highway Hunter',
      value: 412,
      isBenchmark: true,
    ),
    positionFor(rank: 3, name: 'Road Explorer', value: 285, isBenchmark: true),
  ];

  Color trophyColour(WidgetTester tester) {
    final icon = tester.widget<Icon>(
      find.byIcon(Icons.emoji_events_rounded),
    );
    return icon.color!;
  }

  testWidgets('renders all three places with their ranks', (tester) async {
    await pumpPodium(tester, allBenchmarks());

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Road Warrior'), findsOneWidget);
    expect(find.text('Highway Hunter'), findsOneWidget);
    expect(find.text('Road Explorer'), findsOneWidget);
  });

  testWidgets('every benchmark tile keeps its label, podium or not',
      (tester) async {
    await pumpPodium(tester, allBenchmarks());
    expect(find.text(AppStrings.leaderboardBenchmark), findsNWidgets(3));
    // Gauge glyphs, never avatars.
    expect(find.byIcon(Icons.speed_rounded), findsNWidgets(3));
  });

  testWidgets('the trophy is muted while a benchmark leads — nobody has '
      'won a board whose leader never drove anywhere', (tester) async {
    await pumpPodium(tester, allBenchmarks());
    expect(trophyColour(tester), AppColors.textTertiary);
  });

  testWidgets('the trophy goes gold once a real driver takes first',
      (tester) async {
    await pumpPodium(tester, [
      positionFor(rank: 1, name: 'Basit', value: 600, isMe: true),
      positionFor(rank: 2, name: 'Road Warrior', value: 574, isBenchmark: true),
      positionFor(
        rank: 3,
        name: 'Highway Hunter',
        value: 412,
        isBenchmark: true,
      ),
    ]);
    expect(trophyColour(tester), AppColors.yellow);
  });

  testWidgets('the viewer on the podium is named YOU and carries no '
      'benchmark label', (tester) async {
    await pumpPodium(tester, [
      positionFor(rank: 1, name: 'Road Warrior', value: 574, isBenchmark: true),
      positionFor(rank: 2, name: 'Basit', value: 500, isMe: true),
      positionFor(
        rank: 3,
        name: 'Highway Hunter',
        value: 412,
        isBenchmark: true,
      ),
    ]);

    expect(find.text(AppStrings.leaderboardYou), findsOneWidget);
    expect(find.text('Basit'), findsNothing);
    expect(find.text(AppStrings.leaderboardBenchmark), findsNWidgets(2));
    expect(find.byIcon(Icons.speed_rounded), findsNWidgets(2));
  });

  group('a friend on the podium', () {
    testWidgets('gets their medal ring, their car and their flag — and '
        'none of the benchmark treatment', (tester) async {
      await pumpPodium(tester, [
        positionFor(
          rank: 1,
          name: 'hamza',
          value: 600,
          countryCode: 'PK',
          carMake: 'Toyota',
        ),
        positionFor(rank: 2, name: 'Basit', value: 500, isMe: true),
        positionFor(
          rank: 3,
          name: 'Road Warrior',
          value: 412,
          isBenchmark: true,
        ),
      ]);

      expect(find.text('hamza'), findsOneWidget);
      expect(find.text(AppStrings.leaderboardBenchmark), findsOneWidget);
      // One glyph, for the single benchmark. The friend gets a vehicle
      // from what they published; the viewer's would come from their
      // settings row, which this podium wasn't given — so exactly one
      // silhouette, and no glyph leaking onto a person.
      expect(find.byIcon(Icons.speed_rounded), findsOneWidget);
      expect(find.byType(CarSilhouette), findsOneWidget);
      // A real person at the top means somebody actually won.
      expect(trophyColour(tester), AppColors.yellow);
    });

    testWidgets('an old figure is marked in the badge slot, where a '
        'benchmark would be labelled', (tester) async {
      await pumpPodium(tester, [
        positionFor(
          rank: 1,
          name: 'hamza',
          value: 600,
          carMake: 'Toyota',
          isStale: true,
        ),
      ]);
      expect(find.byType(StaleBadge), findsOneWidget);
      expect(find.text(AppStrings.leaderboardBenchmark), findsNothing);
    });

    testWidgets('is tappable for a head-to-head, and the viewer is not — '
        'comparing yourself with yourself goes nowhere', (tester) async {
      final tapped = <String>[];
      await pumpPodium(
        tester,
        [
          positionFor(rank: 1, name: 'hamza', value: 600, carMake: 'Toyota'),
          positionFor(rank: 2, name: 'Basit', value: 500, isMe: true),
        ],
        onCompare: (entry) => tapped.add(entry.id),
      );

      await tester.tap(find.text('hamza'));
      await tester.pump();
      expect(tapped, ['hamza']);

      await tester.tap(find.text(AppStrings.leaderboardYou));
      await tester.pump();
      expect(tapped, ['hamza'], reason: 'the viewer must stay inert');
    });
  });

  group('a board with fewer than three entries', () {
    testWidgets('renders just the leader rather than crashing or inventing '
        'placeholders', (tester) async {
      await pumpPodium(tester, [
        positionFor(rank: 1, name: 'Basit', value: 42, isMe: true),
      ]);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      expect(find.text(AppStrings.leaderboardYou), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders two', (tester) async {
      await pumpPodium(tester, [
        positionFor(
          rank: 1,
          name: 'Road Warrior',
          value: 574,
          isBenchmark: true,
        ),
        positionFor(rank: 2, name: 'Basit', value: 42, isMe: true),
      ]);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders nothing at all for an empty board', (tester) async {
      await pumpPodium(tester, []);
      expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
