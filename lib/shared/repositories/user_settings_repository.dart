import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:injectable/injectable.dart';

/// Single source of truth for the *one* user-settings row.
///
/// Onboarding writes here progressively; the rest of the app reads.
/// Reactive callers should use [watch] — the live tracking screen,
/// profile, paywall state, and the router redirect all depend on this.
///
/// MVP scope: no cloud sync. The row is purely local. The `uid` field
/// is still kept for analytics attribution but isn't used as a foreign
/// key against any remote system.
@lazySingleton
class UserSettingsRepository {
  UserSettingsRepository(this._db, this._locale);

  final AppDatabase _db;
  final LocaleService _locale;

  /// Default uid for the local install. Stays as-is until the user
  /// goes through Firebase Auth, at which point the analytics layer
  /// is told the new uid (the settings row's `uid` column doesn't
  /// gate anything any more, so we don't bother migrating it).
  static const String _initialUid = 'local';

  /// Returns the existing row, creating one with locale-derived defaults
  /// if none exists. Safe to call repeatedly. We look up by row count
  /// (there's only ever one) rather than filtering by uid — the uid
  /// column isn't a foreign key in the MVP, it's just a label.
  Future<UserSettingsRow> ensureExists() async {
    final existing =
        await (_db.select(_db.userSettings)..limit(1)).getSingleOrNull();
    if (existing != null) return existing;

    final defaults = UserSettingsCompanion.insert(
      uid: _initialUid,
      country: Value(_locale.countryCode),
      unitSystem: Value(
        _locale.unitSystem == UnitSystem.imperial ? 'imperial' : 'metric',
      ),
      currencyCode: Value(_locale.defaultCurrencyCode),
      createdAt: DateTime.now(),
    );
    final id = await _db.into(_db.userSettings).insert(defaults);
    return (_db.select(_db.userSettings)
          ..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Stream<UserSettingsRow> watch() {
    return (_db.select(_db.userSettings)..limit(1)).watchSingle();
  }

  Future<UserSettingsRow> read() async {
    await ensureExists();
    return (_db.select(_db.userSettings)..limit(1)).getSingle();
  }

  /// True once the user finishes the 7-step onboarding flow.
  Future<bool> isOnboardingComplete() async {
    final row =
        await (_db.select(_db.userSettings)..limit(1)).getSingleOrNull();
    return row?.onboardingComplete ?? false;
  }

  /// Generic patcher — pass only the fields you want to change.
  /// Internally guarantees a row exists. Filters by primary key so it
  /// keeps working regardless of what the uid column is set to.
  Future<void> patch(UserSettingsCompanion patch) async {
    final row = await read();
    await (_db.update(_db.userSettings)
          ..where((t) => t.id.equals(row.id)))
        .write(patch);
  }

  // ---- Typed setters used by onboarding + settings ----
  //
  // MVP scope: these are local-only writes. Earlier versions also
  // mirrored country / car / username to a Firestore /users/{uid}
  // document for friend search — that whole feature is gone now,
  // so the setters do nothing more than patch the Drift row.

  Future<void> setCountry(String countryCode) =>
      patch(UserSettingsCompanion(country: Value(countryCode)));

  Future<void> setVehicleType(VehicleType type) =>
      patch(UserSettingsCompanion(vehicleType: Value(type.id)));

  Future<void> setCar({
    required String make,
    required String model,
    int? year,
  }) => patch(
    UserSettingsCompanion(
      carMake: Value(make),
      carModel: Value(model),
      carYear: Value(year),
    ),
  );

  /// Persists the absolute filesystem path to the user's uploaded car
  /// photo. Pass `null` to clear (e.g. user tapped Skip).
  Future<void> setCarPhotoPath(String? path) =>
      patch(UserSettingsCompanion(carPhotoPath: Value(path)));

  /// Persists the user's chosen username locally so the stat card,
  /// profile, and personal-bests surfaces can read it. No cloud
  /// uniqueness check in MVP — the field is purely cosmetic.
  Future<void> setUsername(String username) =>
      patch(UserSettingsCompanion(username: Value(username)));

  Future<void> setMapTheme(MapTheme theme) =>
      patch(UserSettingsCompanion(selectedMapTheme: Value(theme.id)));

  Future<void> setUnitSystem(UnitSystem unit) => patch(
    UserSettingsCompanion(
      unitSystem: Value(unit == UnitSystem.imperial ? 'imperial' : 'metric'),
    ),
  );

  Future<void> markOnboardingComplete() =>
      patch(const UserSettingsCompanion(onboardingComplete: Value(true)));

  // ---- Trip-counter helpers (used by the paywall in Session 4) ----

  Future<void> incrementFreeTripsUsed() async {
    final row = await read();
    await patch(
      UserSettingsCompanion(freeTripsUsed: Value(row.freeTripsUsed + 1)),
    );
  }
}
