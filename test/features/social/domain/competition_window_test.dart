import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('forPeriod — weekly', () {
    test('starts on Monday midnight and ends the following Monday', () {
      // 2026-09-03 is a Thursday.
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 9, 3, 14, 30),
      );
      expect(window.start, DateTime(2026, 8, 31));
      expect(window.end, DateTime(2026, 9, 7));
    });

    test('a Monday belongs to the week it starts, not the previous one', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 8, 31, 0, 1),
      );
      expect(window.start, DateTime(2026, 8, 31));
    });

    test('a Sunday belongs to the week that started six days earlier', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 9, 6, 23, 59),
      );
      expect(window.start, DateTime(2026, 8, 31));
      expect(window.end, DateTime(2026, 9, 7));
    });

    test('a week spanning a month boundary still lands on real dates', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 3, 2),
      );
      expect(window.start, DateTime(2026, 3, 2));
      expect(window.end, DateTime(2026, 3, 9));
    });

    test('the end boundary stays at local midnight across a DST '
        'transition — this is what calendar arithmetic buys over adding '
        'a 168-hour Duration, which would land an hour off', () {
      // US DST springs forward on 2026-03-08, mid-week.
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 3, 4),
      );
      expect(window.start, DateTime(2026, 3, 2));
      expect(window.end, DateTime(2026, 3, 9));
      expect(window.end!.hour, 0);
    });
  });

  group('forPeriod — monthly', () {
    test('covers the calendar month', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.monthly,
        DateTime(2026, 9, 17, 8),
      );
      expect(window.start, DateTime(2026, 9));
      expect(window.end, DateTime(2026, 10));
    });

    test('December rolls into next January rather than month 13', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.monthly,
        DateTime(2026, 12, 25),
      );
      expect(window.start, DateTime(2026, 12));
      expect(window.end, DateTime(2027));
    });

    test('the last instant of a month is inside it', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.monthly,
        DateTime(2026, 2, 28, 23, 59, 59),
      );
      expect(window.contains(DateTime(2026, 2, 28, 23, 59, 59)), isTrue);
      expect(window.contains(DateTime(2026, 3)), isFalse);
    });
  });

  group('forPeriod — allTime', () {
    test('has no upper bound, so the same inputs always give the same '
        'window — a now() end would make every recompute differ', () {
      final first = CompetitionWindow.forPeriod(
        LeaderboardPeriod.allTime,
        DateTime(2026, 9, 3),
      );
      final later = CompetitionWindow.forPeriod(
        LeaderboardPeriod.allTime,
        DateTime(2027, 5, 20),
      );
      expect(first.end, isNull);
      expect(first.start, later.start);
    });

    test('contains a future date', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.allTime,
        DateTime(2026, 9, 3),
      );
      expect(window.contains(DateTime(2030)), isTrue);
    });
  });

  group('contains', () {
    final window = CompetitionWindow(
      start: DateTime(2026, 9, 7),
      end: DateTime(2026, 9, 14),
    );

    test('is half-open: start is in, end is out', () {
      expect(window.contains(DateTime(2026, 9, 7)), isTrue);
      expect(window.contains(DateTime(2026, 9, 13, 23, 59, 59)), isTrue);
      expect(window.contains(DateTime(2026, 9, 14)), isFalse);
      expect(window.contains(DateTime(2026, 9, 6, 23, 59, 59)), isFalse);
    });
  });

  group('isoWeekKey', () {
    test('formats the week of the window start', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 9, 3),
      );
      expect(window.isoWeekKey, '2026-W36');
    });

    test('the same window always produces the same key — two different '
        'formatters disagreeing on an edge case is how a trophy gets '
        'awarded twice', () {
      final a = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 9, 3, 6),
      );
      final b = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 9, 5, 22),
      );
      expect(a.isoWeekKey, b.isoWeekKey);
    });

    test('a January 1st that falls in the previous ISO year is keyed to '
        'that year, not its own', () {
      // 2027-01-01 is a Friday, so its ISO week began 2026-12-28 and
      // belongs to 2026-W53.
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2027, 1, 1),
      );
      expect(window.isoWeekKey, '2026-W53');
    });

    test('a late-December date can belong to the next ISO year', () {
      // 2025-12-29 is a Monday whose week contains 2026-01-01, so it is
      // 2026-W01.
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2025, 12, 30),
      );
      expect(window.isoWeekKey, '2026-W01');
    });

    test('week numbers are zero-padded so keys sort lexicographically', () {
      final window = CompetitionWindow.forPeriod(
        LeaderboardPeriod.weekly,
        DateTime(2026, 1, 8),
      );
      expect(window.isoWeekKey, '2026-W02');
    });
  });
}
