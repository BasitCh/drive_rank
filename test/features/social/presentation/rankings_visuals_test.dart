import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/social/domain/entities/benchmark_tier.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_entry.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_participant_type.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_position.dart';
import 'package:drive_rank/features/social/presentation/widgets/leaderboard_row.dart';
import 'package:drive_rank/features/social/presentation/widgets/rank_identity.dart';
import 'package:drive_rank/features/social/presentation/widgets/top_three_podium.dart';
import 'package:drive_rank/features/social/presentation/widgets/week_streak_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserSettingsRow viewerRow({String? country = 'PK'}) => UserSettingsRow(
    id: 1,
    uid: 'user-1',
    username: 'basit',
    carMake: 'BMW',
    carModel: 'M3',
    vehicleType: 'car',
    country: country,
    unitSystem: 'metric',
    selectedMapTheme: 'regular',
    minTripLengthMeters: 500,
    freeTripsUsed: 0,
    isPro: false,
    rankingsEnabled: true,
    onboardingComplete: true,
    usernameClaimed: true,
    oemAdviceShown: false,
    bgLocationDisclosureAcked: true,
    createdAt: DateTime(2026),
  );

  LeaderboardPosition me(int rank, double value) => LeaderboardPosition(
    rank: rank,
    entry: LeaderboardEntry(
      id: 'user-1',
      displayName: 'basit',
      value: value,
      participantType: LeaderboardParticipantType.realUser,
      isCurrentUser: true,
    ),
  );

  LeaderboardPosition benchmark(int rank, String name, double value) =>
      LeaderboardPosition(
        rank: rank,
        entry: LeaderboardEntry(
          id: 'road_warrior',
          displayName: name,
          value: value,
          participantType: LeaderboardParticipantType.benchmark,
        ),
      );

  String fmt(double v) => v.toStringAsFixed(0);
  String unit(double v) => 'KM';

  group('LocaleService.formatDistanceCompact', () {
    final metric = LocaleService.forLocale(const Locale('en', 'DE'));
    final imperial = LocaleService.forLocale(const Locale('en', 'US'));

    test('leaves anything under a thousand exact — that is where the '
        'precision still means something', () {
      expect(metric.formatDistanceCompact(0), '0');
      expect(metric.formatDistanceCompact(412), '412');
      expect(metric.formatDistanceCompact(999), '999');
    });

    test('shortens a thousand and above', () {
      expect(metric.formatDistanceCompact(1000), '1k');
      expect(metric.formatDistanceCompact(1049), '1k');
      expect(metric.formatDistanceCompact(9743), '9.7k');
      // 9.95 is not exactly representable and lands just under, so this
      // rounds down. Pinned because it is the kind of thing that looks
      // like a bug later if nobody wrote it down.
      expect(metric.formatDistanceCompact(9950), '9.9k');
      expect(metric.formatDistanceCompact(9999), '10k');
    });

    test('drops a trailing .0 rather than showing 12.0k', () {
      expect(metric.formatDistanceCompact(12000), '12k');
    });

    test('converts before shortening, so an imperial user sees miles', () {
      // 9743 km ≈ 6054 mi — under 10k, unlike the metric figure.
      expect(imperial.formatDistanceCompact(9743), '6.1k');
      expect(imperial.formatDistanceCompact(1000), '621');
    });
  });

  group('the podium', () {
    Future<void> pump(
      WidgetTester tester, {
      required List<LeaderboardPosition> positions,
      void Function(LeaderboardEntry)? onCompare,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopThreePodium(
              positions: positions,
              formatValue: fmt,
              unitFor: unit,
              viewer: viewerRow(),
              onCompare: onCompare,
            ),
          ),
        ),
      );
    }

    testWidgets('gives each place its own medal ring, so the three tiles '
        'differ by more than height', (tester) async {
      await pump(
        tester,
        positions: [
          benchmark(1, 'Road Warrior', 574),
          benchmark(2, 'Highway Hunter', 412),
          me(3, 301),
        ],
      );

      final rings = tester
          .widgetList<RankIdentity>(find.byType(RankIdentity))
          .map((r) => r.ringColor)
          .toSet();
      expect(rings, hasLength(3), reason: 'three places, three colours');
      expect(rings, isNot(contains(null)));
    });

    testWidgets("shows the viewer's flag and never a benchmark's",
        (tester) async {
      await pump(
        tester,
        positions: [benchmark(1, 'Road Warrior', 574), me(2, 301)],
      );

      for (final identity
          in tester.widgetList<RankIdentity>(find.byType(RankIdentity))) {
        expect(
          identity.showFlag,
          identity.entry.isCurrentUser,
          reason: 'only the viewer has a known country',
        );
      }
      expect(find.text('🇵🇰'), findsOneWidget);
    });

    testWidgets('opens the head-to-head for a benchmark tile', (tester) async {
      LeaderboardEntry? compared;
      await pump(
        tester,
        positions: [benchmark(1, 'Road Warrior', 574), me(2, 301)],
        onCompare: (entry) => compared = entry,
      );

      await tester.tap(find.text('Road Warrior'));
      expect(compared?.displayName, 'Road Warrior');
    });

    testWidgets("does not open anything from the viewer's own tile — "
        'comparing yourself with yourself goes nowhere', (tester) async {
      var opened = false;
      await pump(
        tester,
        positions: [benchmark(1, 'Road Warrior', 574), me(2, 301)],
        onCompare: (_) => opened = true,
      );

      await tester.tap(find.text('YOU'));
      await tester.pump();
      expect(opened, isFalse);
    });
  });

  group('a leaderboard row', () {
    Future<void> pump(
      WidgetTester tester, {
      required LeaderboardPosition position,
      String? subtitle,
      VoidCallback? onTap,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeaderboardRow(
              position: position,
              formattedValue: '9.7k',
              unitLabel: 'KM',
              subtitle: subtitle,
              viewer: viewerRow(),
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    testWidgets('for a benchmark is tappable and still labelled as a '
        'pace reference', (tester) async {
      var tapped = false;
      await pump(
        tester,
        position: benchmark(4, 'Road Explorer', 285),
        subtitle: AppStrings.rankingsPaceReference,
        onTap: () => tapped = true,
      );

      expect(find.text(AppStrings.rankingsPaceReference), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.tap(find.byType(LeaderboardRow));
      expect(tapped, isTrue);
    });

    testWidgets('for the viewer has no tap target at all', (tester) async {
      await pump(tester, position: me(5, 301), subtitle: '🇵🇰 Pakistan  ·  BMW M3');

      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.byType(InkWell), findsNothing);
      expect(find.text('🇵🇰 Pakistan  ·  BMW M3'), findsOneWidget);
    });
  });

  group('the week streak', () {
    testWidgets('fills a dot per day driven and counts them', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeekStreakDots(
              days: [true, false, true, true, false, false, false],
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.rankingsStreakDays(3)), findsOneWidget);
      expect(find.text(AppStrings.rankingsStreakLabel), findsOneWidget);

      // Seven day initials, whatever their state.
      expect(find.text('M'), findsOneWidget);
      expect(find.text('S'), findsNWidgets(2));
    });

    testWidgets('says a single day in the singular', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeekStreakDots(
              days: [true, false, false, false, false, false, false],
            ),
          ),
        ),
      );
      expect(find.text('1 day driven'), findsOneWidget);
    });
  });

  group('the tier chip', () {
    testWidgets('names where you sit on the ladder', (tester) async {
      const tier = BenchmarkTier(cleared: 4, total: 6, nextName: 'X');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (_) => Text(
                tier.isTopped
                    ? AppStrings.rankingsTierTopped
                    : AppStrings.rankingsTier(tier.cleared, tier.total),
              ),
            ),
          ),
        ),
      );
      expect(find.text('TIER 4 / 6'), findsOneWidget);
    });
  });

  group('the countdown copy', () {
    test('reads as a last day rather than zero days left', () {
      expect(AppStrings.rankingsEndsIn('Sunday', 0), 'Ends Sunday · last day');
      expect(AppStrings.rankingsEndsIn('Sunday', 1), 'Ends Sunday · 1 day left');
      expect(
        AppStrings.rankingsEndsIn('Sunday', 4),
        'Ends Sunday · 4 days left',
      );
    });
  });
}
