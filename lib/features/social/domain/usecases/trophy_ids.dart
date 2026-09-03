/// The single place trophy identities are formed.
///
/// Trophy remote ids are **deterministic**, not random UUIDs, so a
/// repeated award for the same (type, user, period) collapses onto the
/// same row and is rejected by the unique index on
/// `trophies.remote_id`. That's what makes awarding safe from two trips
/// saved back-to-back, where a read-then-insert would let both through.
///
/// Every id must come from here. Two independently-written formatters
/// would eventually disagree on an ISO week edge case — a Jan 1 that
/// belongs to the previous year's W52/W53, or a 53-week year — and each
/// disagreement is a double-award.
library;

import 'package:drive_rank/features/social/domain/entities/competition_window.dart';
import 'package:drive_rank/features/social/domain/entities/trophy.dart';

/// Deterministic id for a trophy.
///
/// [window] scopes period-bound trophies (`roadWarrior:abc:2026-W36`);
/// omit it for lifetime trophies that can only ever be earned once
/// (`firstTarget:abc`).
String trophyRemoteId({
  required TrophyType type,
  required String uid,
  CompetitionWindow? window,
}) {
  if (window == null) return '${type.name}:$uid';
  return '${type.name}:$uid:${window.isoWeekKey}';
}
