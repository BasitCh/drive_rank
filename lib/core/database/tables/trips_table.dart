import 'package:drift/drift.dart';

/// One row per recorded trip.
///
/// All speeds and distances are stored in **metric** (km, km/h). The display
/// layer converts to imperial via `LocaleService` when needed — keeps DB
/// simple and leaderboard comparisons globally fair.
@DataClassName('TripRow')
class Trips extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Owning user id (Firebase Auth UID, or anonymous local UID).
  TextColumn get uid => text()();

  RealColumn get topSpeedKmh => real()();
  RealColumn get avgSpeedKmh => real()();
  RealColumn get distanceKm => real()();

  IntColumn get durationSeconds => integer()();
  IntColumn get stoppedSeconds => integer().withDefault(const Constant(0))();

  RealColumn get maxGforce => real().withDefault(const Constant(0))();
  IntColumn get hardCornersCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get hardBrakesCount =>
      integer().withDefault(const Constant(0))();

  /// Fuel cost in the user's local currency at trip time. Null if the user
  /// hasn't configured fuel price/consumption — the UI shows "—" then.
  RealColumn get fuelCostLocal => real().nullable()();
  TextColumn get localCurrencyCode => text().nullable()();

  TextColumn get weatherCondition => text().nullable()();
  RealColumn get weatherTempC => real().nullable()();

  BoolColumn get isNightDrive => boolean().withDefault(const Constant(false))();

  /// Map theme used to render this trip's route — kept so the share card
  /// can re-render in the original theme even if the user changed it later.
  TextColumn get mapTheme => text().withDefault(const Constant('regular'))();

  /// ISO 3166-1 alpha-2 country code where the trip occurred.
  TextColumn get country => text().nullable()();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
