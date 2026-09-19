import 'package:flutter/foundation.dart';

/// The minimal, drift-free view of a trip the competition calculators
/// need — so nothing in `domain/` imports Drift and a future
/// server-side aggregator can produce the same shape.
///
/// Carries no `uid` (the query that produces these is already
/// uid-scoped, and carrying it would invite uid logic into pure
/// calculators) and no `endedAt` (nullable in the schema, and unused —
/// [durationSeconds] is the authoritative active duration).
@immutable
class CompetitionTrip {
  const CompetitionTrip({
    required this.tripId,
    required this.startedAt,
    required this.distanceKm,
    required this.durationSeconds,
    required this.eligible,
    required this.utcOffsetMinutes,
  });

  final int tripId;

  /// Period attribution and day bucketing both key off this. Note it's
  /// **resume-adjusted** by the tracking bloc, so a trip paused
  /// overnight is attributed to the day it resumed, and waypoint
  /// timestamps are not guaranteed to fall inside the trip's span.
  final DateTime startedAt;

  final double distanceKm;

  /// Active duration — paused time excluded, stopped time included.
  final int durationSeconds;

  /// False only when a trip was affirmatively judged ineligible; a trip
  /// with no eligibility record reads as true.
  final bool eligible;

  /// The device's UTC offset when the trip was recorded, so day
  /// bucketing can stay stable if the user later changes timezone.
  final int utcOffsetMinutes;

  /// Local calendar day of [startedAt] as a canonical sortable key
  /// (`y*10000 + m*100 + d`).
  ///
  /// `.toLocal()` first: the value can arrive UTC-flavored (GPS
  /// timestamps) or local-flavored (rebuilt from Drift), and reading
  /// `.day` off a UTC-flavored `DateTime` yields the UTC calendar day.
  /// Same precaution as `BuildInsights._isSameLocalMonth`.
  int get localDayKey {
    final local = startedAt.toLocal();
    return local.year * 10000 + local.month * 100 + local.day;
  }
}
