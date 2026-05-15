import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:injectable/injectable.dart';

/// Single source of truth for the *one* user-settings row.
///
/// Onboarding writes here progressively; the rest of the app reads. Reactive
/// callers should use [watch] — the live tracking screen, profile, paywall
/// state, and the router redirect all depend on this.
@lazySingleton
class UserSettingsRepository {
  UserSettingsRepository(this._db, this._locale);

  final AppDatabase _db;
  final LocaleService _locale;

  /// Stable local anonymous UID until Firebase Auth swaps in (Session 5).
  static const String _anonymousUid = 'local';

  /// Returns the existing row, creating one with locale-derived defaults
  /// if none exists. Safe to call repeatedly.
  Future<UserSettingsRow> ensureExists() async {
    final existing = await (_db.select(_db.userSettings)
          ..where((t) => t.uid.equals(_anonymousUid)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final defaults = UserSettingsCompanion.insert(
      uid: _anonymousUid,
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
    return (_db.select(_db.userSettings)
          ..where((t) => t.uid.equals(_anonymousUid))
          ..limit(1))
        .watchSingle();
  }

  Future<UserSettingsRow> read() async {
    await ensureExists();
    return (_db.select(_db.userSettings)
          ..where((t) => t.uid.equals(_anonymousUid)))
        .getSingle();
  }

  /// True once the user finishes the 7-step onboarding flow.
  Future<bool> isOnboardingComplete() async {
    final row = await (_db.select(_db.userSettings)
          ..where((t) => t.uid.equals(_anonymousUid)))
        .getSingleOrNull();
    return row?.onboardingComplete ?? false;
  }

  /// Generic patcher — pass only the fields you want to change. Internally
  /// guarantees a row exists.
  Future<void> patch(UserSettingsCompanion patch) async {
    await ensureExists();
    await (_db.update(_db.userSettings)
          ..where((t) => t.uid.equals(_anonymousUid)))
        .write(patch);
  }

  // ---- Typed setters used by onboarding ----

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
