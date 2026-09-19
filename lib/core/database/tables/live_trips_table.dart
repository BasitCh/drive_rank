import 'package:drift/drift.dart';

/// Status of an in-progress trip — drives the recovery UX surface.
///
/// Persisted as the column's string `.name` so future enum values added
/// in code don't break old rows on read.
enum TripStatusEnum {
  /// Currently being tracked. Used while the bloc is in `active` or
  /// `paused` and the OS process is alive.
  active,

  /// The bloc detected on cold-start that a prior session's last
  /// waypoint is stale — the OS killed us (or the user force-quit)
  /// while a trip was active. The tracking page shows a recovery
  /// banner with Resume / Save / Discard options.
  interrupted,

  /// User tapped Resume from an interrupted state. Functionally the
  /// same as `active` for new waypoints; kept as a distinct value so
  /// debugging support cases can tell "trip recovered after a crash"
  /// apart from a clean run.
  recovered,

  /// Trip was saved to the `trips` table — the live row should have
  /// been deleted at this point; if it lingers with `completed`, that
  /// means the move-to-trips transaction crashed between the insert
  /// and the live-trip delete. The cleanup pass on next boot will
  /// remove these.
  completed,

  /// Save attempt errored. The live row is preserved so the user can
  /// retry without losing the data.
  failed,
}

/// The single source of truth for an in-progress trip.
///
/// One row at most (enforced by the bloc), updated every ~30s with
/// rolled-up stats while waypoints append to `LiveWaypoints` at the
/// 1Hz tick rate. The bloc / service writes to both atomically so a
/// process kill at any moment leaves the database in a consistent
/// state.
@DataClassName('LiveTripRow')
class LiveTrips extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// User id this trip belongs to. Mirrors `Trips.uid` so completed
  /// trips inherit ownership cleanly.
  TextColumn get uid => text()();

  /// Status — stored as the enum's `.name` so adding a new case in
  /// code doesn't break old rows. See [TripStatusEnum].
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Wall-clock start of the trip. Used for duration when ticking and
  /// preserved through Resume so paused intervals don't count.
  DateTimeColumn get startedAt => dateTime()();

  /// Most-recent rollup of stats. Recomputable from [LiveWaypoints]
  /// in the worst case, but cached here so the tracking page can
  /// render the recovery banner without a full waypoint scan.
  RealColumn get distanceKm => real().withDefault(const Constant(0))();
  RealColumn get topSpeedKmh => real().withDefault(const Constant(0))();
  RealColumn get avgSpeedKmh => real().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  RealColumn get maxGforce => real().withDefault(const Constant(0))();
  IntColumn get hardCornersCount => integer().withDefault(const Constant(0))();
  IntColumn get hardBrakesCount => integer().withDefault(const Constant(0))();

  /// Number of times this single trip had to recover from an
  /// interrupted state. Surfaced on the saved trip card later as the
  /// foundation for a "Trip Quality" badge.
  IntColumn get interruptionCount => integer().withDefault(const Constant(0))();

  /// True when the trip was sitting in `paused` at the moment the
  /// snapshot was taken — drives whether the recovery banner reads
  /// "you paused at 12:34" vs "your trip was interrupted at 12:34".
  BoolColumn get wasPaused => boolean().withDefault(const Constant(false))();

  /// When this row was last written. The bloc uses
  /// `now - updatedAt > 30s` as the heuristic for "the OS killed us
  /// before we could finish" and flips status → interrupted.
  DateTimeColumn get updatedAt => dateTime()();
}

/// Append-only waypoint log for the in-progress trip.
///
/// Cleared atomically with the [LiveTrips] row on a successful save /
/// reset. Tagged with [tripLocalId] so any future support for parallel
/// drafts (split a trip in two, etc.) doesn't need a schema change.
@DataClassName('LiveWaypointRow')
class LiveWaypoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripLocalId => integer()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get speedKmh => real()();
  RealColumn get accuracyMeters => real()();
  DateTimeColumn get timestamp => dateTime()();

  /// Whether the OS reported this fix as coming from a mock location
  /// provider. Persisted here — not just held in memory — so a trip
  /// interrupted and recovered mid-drive keeps its spoofing evidence;
  /// otherwise force-quitting the app would clear it. Recovery rebuilds
  /// `TripPoint`s from these rows (`ActiveTripStore.load`).
  BoolColumn get isMocked => boolean().withDefault(const Constant(false))();
}
