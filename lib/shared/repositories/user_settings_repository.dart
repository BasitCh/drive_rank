import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/services/public_profile_service.dart';
import 'package:injectable/injectable.dart';

/// Single source of truth for the *one* user-settings row.
///
/// Onboarding writes here progressively; the rest of the app reads. Reactive
/// callers should use [watch] — the live tracking screen, profile, paywall
/// state, and the router redirect all depend on this.
@lazySingleton
class UserSettingsRepository {
  UserSettingsRepository(this._db, this._locale, this._publicProfile);

  final AppDatabase _db;
  final LocaleService _locale;
  final PublicProfileService _publicProfile;

  /// Mirror the public-profile fields to Firestore. Best-effort:
  /// failures inside the service are logged and swallowed there. We
  /// always read the *current* row before publishing so partial
  /// updates (e.g. only the car changed) still send a complete doc.
  Future<void> _republishPublicProfile() async {
    final row = await read();
    await _publicProfile.publish(
      PublicProfilePayload(
        uid: row.uid,
        username: row.username,
        carMake: row.carMake,
        carModel: row.carModel,
        carYear: row.carYear,
        countryCode: row.country ?? '',
      ),
    );
  }

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
  //
  // setCountry / setCar / setUsername all republish the public profile
  // doc to Firestore — those three fields are exactly what friend
  // search and the leaderboard read back.

  Future<void> setCountry(String countryCode) async {
    await patch(UserSettingsCompanion(country: Value(countryCode)));
    await _republishPublicProfile();
  }

  Future<void> setVehicleType(VehicleType type) =>
      patch(UserSettingsCompanion(vehicleType: Value(type.id)));

  Future<void> setCar({
    required String make,
    required String model,
    int? year,
  }) async {
    await patch(
      UserSettingsCompanion(
        carMake: Value(make),
        carModel: Value(model),
        carYear: Value(year),
      ),
    );
    await _republishPublicProfile();
  }

  /// Persists the absolute filesystem path to the user's uploaded car
  /// photo. Pass `null` to clear (e.g. user tapped Skip).
  Future<void> setCarPhotoPath(String? path) =>
      patch(UserSettingsCompanion(carPhotoPath: Value(path)));

  /// Persists the user's chosen username locally so leaderboard /
  /// stat-card surfaces can read it without re-hitting Firestore.
  /// The Firestore atomic reservation lives in `UsernameRepository`;
  /// the public `/users/{uid}` mirror is refreshed here.
  Future<void> setUsername(String username) async {
    await patch(UserSettingsCompanion(username: Value(username)));
    await _republishPublicProfile();
  }

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
