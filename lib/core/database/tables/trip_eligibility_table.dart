import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/tables/trips_table.dart';

/// Per-trip leaderboard-eligibility verdict — the social feature's own
/// record, kept out of [Trips] so competition state never touches the
/// production trip schema.
///
/// A trip is recorded in History regardless of what lands here;
/// ineligibility only excludes it from competition aggregates.
///
/// **Deliberately has no `uid` column.** Keyed on [tripId] alone, the row
/// stays correctly attached through both `UserSettingsRepository.syncUid`
/// (which rewrites `trips.uid` when the pre-auth `'local'` placeholder
/// collapses into a real account) and `reassignUidOnly` (which doesn't).
/// A uid column here would silently desynchronize on the first of those.
///
/// **Absent row means eligible.** Only trips saved through the tracking
/// stop flow on a build with the social processor get a row, so existing
/// history stays in competition without a backfill pass over every old
/// trip's waypoints. Readers must use `COALESCE(eligible, 1)`.
@DataClassName('TripEligibilityRow')
class TripEligibility extends Table {
  IntColumn get tripId =>
      integer().references(Trips, #id, onDelete: KeyAction.cascade)();

  /// The trip's `remoteId` at evaluation time. A cloud restore re-inserts
  /// a trip under a *new* autoincrement id, so [tripId] can't survive it;
  /// this lets a later phase re-associate the verdict by remote id.
  /// Nullable because `Trips.remoteId` is.
  TextColumn get tripRemoteId => text().nullable()();

  BoolColumn get eligible => boolean()();

  /// Comma-separated `EligibilityFailureReason.name`s, empty when
  /// eligible. Denormalized rather than a child table for the same
  /// reason as `Trips.roadSegmentIds` — it's always read with the row.
  TextColumn get failureReasons => text().withDefault(const Constant(''))();

  /// How many of the trip's samples the OS flagged as mocked. Kept as a
  /// count, not a bool, so the record says how much of the trip was
  /// spoofed rather than just that some of it was.
  IntColumn get mockedSampleCount => integer().withDefault(const Constant(0))();

  /// The device's UTC offset when this trip was recorded. Consistency
  /// buckets trips by local calendar day; without the offset captured at
  /// record time, a user who changes timezone silently re-buckets their
  /// whole history.
  IntColumn get startedAtUtcOffsetMinutes => integer()();

  DateTimeColumn get evaluatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {tripId};
}
