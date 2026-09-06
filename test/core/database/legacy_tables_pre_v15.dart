import 'package:drift/drift.dart';

/// The pre-v15 `user_settings`, in its own file on purpose.
///
/// It cannot live in `legacy_tables.dart` beside the pre-v13 copy: two
/// table classes mapping to the same SQL name (`user_settings`) in one
/// imported library make drift **silently drop one** — no error, no
/// warning, the fixture just generates without a settings table and the
/// migration test fails with a confusing missing-getter. One frozen copy
/// per file keeps each fixture importing exactly the shape it needs.

/// `user_settings` as it stood through v14 — before v15 added
/// `username_claimed`.
///
/// Identical to the pre-v13 copy above plus `rankings_enabled`, which
/// v13 added. Frozen separately rather than parameterised because the
/// point of these fixtures is that they cannot drift with the live
/// definition.
@DataClassName('LegacyUserSettingsPreV15Row')
class LegacyUserSettingsPreV15 extends Table {
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
  BoolColumn get rankingsEnabled =>
      boolean().withDefault(const Constant(true))();
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
