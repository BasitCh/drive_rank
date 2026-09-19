import 'package:drift/drift.dart';

/// Frozen copies of table definitions as they stood at an earlier
/// schema version, for the migration fixtures to build a faithful "old"
/// database from.
///
/// **The rule these exist to enforce:** a fixture that imports the live
/// table classes only stays faithful while those tables are untouched.
/// The moment a migration alters one, the fixture silently becomes
/// "old version plus future columns" and the test stops proving
/// anything — or, as happened when v12 added `live_waypoints.is_mocked`,
/// fails outright with a duplicate-column error. So whenever a
/// migration changes an existing table, freeze that table's previous
/// shape here and point the older fixtures at the frozen copy.
///
/// Tables no migration has altered are still imported live, since a
/// frozen duplicate that can't drift is just noise.

/// `live_waypoints` as it stood through v11 — before v12 added
/// `is_mocked`.
@DataClassName('LegacyLiveWaypointPreV12Row')
class LegacyLiveWaypointsPreV12 extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripLocalId => integer()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get speedKmh => real()();
  RealColumn get accuracyMeters => real()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  String get tableName => 'live_waypoints';
}

/// `trophies` as it stood at v11 — before v12 added the unique index on
/// `remote_id`. Frozen so the v11 → v12 test actually exercises the
/// `CREATE UNIQUE INDEX` step instead of finding it already there.
@DataClassName('LegacyTrophyV11Row')
class LegacyTrophiesV11 extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text()();
  TextColumn get uid => text()();
  TextColumn get type => text()();
  DateTimeColumn get unlockedAt => dateTime()();
  TextColumn get metadataJson => text().nullable()();

  @override
  String get tableName => 'trophies';
}

/// `user_settings` as it stood through v12 — before v13 added
/// `rankings_enabled`.
@DataClassName('LegacyUserSettingsPreV13Row')
class LegacyUserSettingsPreV13 extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uid => text()();
  TextColumn get username => text().withDefault(const Constant(''))();

  TextColumn get carMake => text().withDefault(const Constant(''))();
  TextColumn get carModel => text().withDefault(const Constant(''))();
  IntColumn get carYear => integer().nullable()();
  TextColumn get carColour => text().nullable()();
  TextColumn get carPhotoPath => text().nullable()();
  TextColumn get vehicleType => text().withDefault(const Constant('car'))();

  TextColumn get country => text().nullable()();
  TextColumn get unitSystem => text().withDefault(const Constant('metric'))();

  TextColumn get fuelType => text().nullable()();
  RealColumn get fuelConsumption => real().nullable()();
  RealColumn get fuelPricePerUnit => real().nullable()();
  TextColumn get currencyCode => text().nullable()();

  TextColumn get selectedMapTheme =>
      text().withDefault(const Constant('regular'))();
  RealColumn get minTripLengthMeters =>
      real().withDefault(const Constant(500))();

  IntColumn get freeTripsUsed => integer().withDefault(const Constant(0))();
  IntColumn get freeTripLimit => integer().nullable()();

  BoolColumn get isPro => boolean().withDefault(const Constant(false))();
  BoolColumn get onboardingComplete =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get oemAdviceShown =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get bgLocationDisclosureAcked =>
      boolean().withDefault(const Constant(false))();

  RealColumn get speedGoalKmh => real().nullable()();
  RealColumn get distanceGoalKm => real().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  String get tableName => 'user_settings';
}
