import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter/foundation.dart';

/// A half-open `[start, end)` time range a competition metric is
/// aggregated over.
///
/// [end] is null for an open-ended window (`allTime`). That's deliberate
/// rather than using `DateTime.now()` as the upper bound: the whole
/// engine recomputes rather than increments, so a window that shifts
/// every time it's built would make the same inputs produce different
/// results on each run.
///
/// All arithmetic here is **calendar** arithmetic (`DateTime(y, m, d + 7)`),
/// never `Duration(days: 7)` — a duration adds 168 absolute hours and
/// lands an hour off across a DST transition, which silently moves a
/// week boundary.
@immutable
class CompetitionWindow {
  const CompetitionWindow({required this.start, this.end});

  /// The window covering [period] as of [nowLocal].
  ///
  /// Weeks start **Monday**, matching the history page's `thisWeek`
  /// filter. Days are truncated to local midnight.
  factory CompetitionWindow.forPeriod(
    LeaderboardPeriod period,
    DateTime nowLocal,
  ) {
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    return switch (period) {
      LeaderboardPeriod.weekly => CompetitionWindow(
        start: DateTime(today.year, today.month, today.day - (today.weekday - 1)),
        end: DateTime(
          today.year,
          today.month,
          today.day - (today.weekday - 1) + 7,
        ),
      ),
      LeaderboardPeriod.monthly => CompetitionWindow(
        start: DateTime(today.year, today.month),
        // Month 13 normalizes to next January — same idiom as
        // `TripRepository.getTripsInMonth`.
        end: DateTime(today.year, today.month + 1),
      ),
      LeaderboardPeriod.allTime => CompetitionWindow(
        start: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    };
  }

  final DateTime start;

  /// Exclusive upper bound, or null for an open-ended window.
  final DateTime? end;

  /// Whether [at] falls in `[start, end)`. Compares in local time —
  /// callers pass a trip's `startedAt`, which Drift returns as local.
  bool contains(DateTime at) {
    final local = at.toLocal();
    if (local.isBefore(start)) return false;
    final upper = end;
    return upper == null || local.isBefore(upper);
  }

  /// ISO-8601 week key for the window's start (e.g. `2026-W36`), used to
  /// scope a weekly trophy's identity. Not for display.
  String get isoWeekKey {
    // ISO weeks belong to the year containing their Thursday, which is
    // why this can't just read `start.year` — Jan 1 2027 falls in
    // 2026-W53, and Dec 29 2025 falls in 2026-W01.
    final thursday = DateTime(
      start.year,
      start.month,
      start.day - (start.weekday - 1) + 3,
    );
    final firstThursday = _firstThursdayOf(thursday.year);
    final week = 1 + thursday.difference(firstThursday).inDays ~/ 7;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// The Thursday of ISO week 1 of [year] — week 1 is by definition the
  /// week containing January 4th.
  static DateTime _firstThursdayOf(int year) {
    final jan4 = DateTime(year, 1, 4);
    return DateTime(year, 1, 4 - (jan4.weekday - 1) + 3);
  }

  /// Month key (e.g. `2026-09`), the monthly equivalent of [isoWeekKey].
  String get monthKey =>
      '${start.year}-${start.month.toString().padLeft(2, '0')}';
}
