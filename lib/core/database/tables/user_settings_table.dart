import 'package:drift/drift.dart';

/// Single-row user/profile/settings table.
///
/// One row per signed-in user (or anonymous local profile). Stores everything
/// the rest of the app needs to know about the user that isn't a trip:
/// car, country, units, fuel config, paywall state.
@DataClassName('UserSettingsRow')
class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uid => text()();
  TextColumn get username => text().withDefault(const Constant(''))();

  // Vehicle.
  TextColumn get carMake => text().withDefault(const Constant(''))();
  TextColumn get carModel => text().withDefault(const Constant(''))();
  IntColumn get carYear => integer().nullable()();
  TextColumn get carColour => text().nullable()();
  TextColumn get carPhotoPath => text().nullable()();
  TextColumn get vehicleType =>
      text().withDefault(const Constant('car'))(); // car | motorbike

  // Locale.
  TextColumn get country => text().nullable()(); // ISO 3166-1 alpha-2
  TextColumn get unitSystem =>
      text().withDefault(const Constant('metric'))(); // metric | imperial

  // Fuel (all nullable — feature is optional).
  TextColumn get fuelType =>
      text().nullable()(); // petrol | diesel | cng | electric
  RealColumn get fuelConsumption => real().nullable()(); // L/100km or mpg
  RealColumn get fuelPricePerUnit => real().nullable()(); // local currency
  TextColumn get currencyCode => text().nullable()(); // ISO 4217

  // App preferences.
  TextColumn get selectedMapTheme =>
      text().withDefault(const Constant('regular'))();

  /// Trips shorter than this (metres) are discarded on End, not saved.
  /// Default 500 m filters out accidental Start→End taps without
  /// eating a real short drive.
  RealColumn get minTripLengthMeters =>
      real().withDefault(const Constant(500))();

  // Paywall + onboarding state.
  IntColumn get freeTripsUsed => integer().withDefault(const Constant(0))();

  /// The free-trip allowance actually granted to THIS user, persisted at
  /// creation time rather than read from a global constant — so a later
  /// change to the default (3 → 1) can't retroactively cut an existing
  /// user's already-granted allowance. Null on rows created before this
  /// column existed; the migration backfills those to the old default
  /// (3) so nobody already using the app loses trips they were promised.
  /// New rows get the new default (1) explicitly at insert time.
  IntColumn get freeTripLimit => integer().nullable()();

  BoolColumn get isPro => boolean().withDefault(const Constant(false))();

  /// Whether the public rankings surfaces are available to this user.
  ///
  /// Defaults on. Persisted rather than held in memory so the last known
  /// answer survives a cold, offline launch, and so every consumer — the
  /// router redirect, the nav bar, the rankings screen itself — reads one
  /// reactive source instead of each deciding for itself. Read only via
  /// `UserSettingsRepository.watchRankingsEnabled()` /
  /// `isRankingsEnabled()`.
  ///
  /// Turning it off hides global rankings only; friends, challenges,
  /// personal targets, trophies and trip statistics all keep working.
  /// A later phase adds the remote channel that patches this column.
  BoolColumn get rankingsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get onboardingComplete =>
      boolean().withDefault(const Constant(false))();

  /// Set to true once we've shown the user the OEM battery-killer
  /// bottom sheet (Xiaomi / Oppo / Huawei / Vivo / etc). Persisted so
  /// the prompt fires at most once per install — repeatedly nagging a
  /// user who already saw it is worse UX than letting them figure out
  /// they need to whitelist DriveRank.
  BoolColumn get oemAdviceShown =>
      boolean().withDefault(const Constant(false))();

  /// Set once the user has been shown the in-app Prominent Disclosure
  /// for background location and either accepted or skipped it. Drives
  /// the gate in TrackingBloc that blocks Start until the disclosure
  /// has been surfaced at least once — Google Play policy compliance.
  BoolColumn get bgLocationDisclosureAcked =>
      boolean().withDefault(const Constant(false))();

  /// The user's current "beat this" targets, recomputed by
  /// `TrackingBloc` after every trip (see `GoalCalculator`). Null until
  /// the first trip completes. Only two fields, not a table, because
  /// there is exactly one active goal per metric at a time — no
  /// history of past goals is needed, `Trips` already has the record
  /// of what was actually driven.
  RealColumn get speedGoalKmh => real().nullable()();
  RealColumn get distanceGoalKm => real().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}
