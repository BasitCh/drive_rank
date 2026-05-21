import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/services/public_profile_service.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Single source of truth for the *one* user-settings row.
///
/// Onboarding writes here progressively; the rest of the app reads. Reactive
/// callers should use [watch] — the live tracking screen, profile, paywall
/// state, and the router redirect all depend on this.
///
/// Identity: the row's `uid` field is the canonical user identity used by
/// every Firestore write (trips/leaderboard/friends/profile). It starts
/// life as `'local'` before Firebase Auth resolves, then `syncUid()` is
/// called from bootstrap once anonymous sign-in completes and the column
/// + all existing trip rows are migrated to the real Firebase Auth uid.
@lazySingleton
class UserSettingsRepository {
  UserSettingsRepository(this._db, this._locale);

  final AppDatabase _db;
  final LocaleService _locale;

  /// Initial uid used before Firebase Auth has resolved. Replaced by
  /// the Firebase uid via [syncUid] at bootstrap time.
  static const String _initialUid = 'local';

  /// Look up the [PublicProfileService] lazily via the DI container —
  /// bootstrap swaps the preview impl for the Firestore one once
  /// Firebase init succeeds, and we want every `_republishPublicProfile`
  /// call (including those that fire before Firebase comes online) to
  /// pick up the currently-registered implementation.
  PublicProfileService get _publicProfile => getIt<PublicProfileService>();

  /// Mirror the public-profile fields to Firestore. Best-effort:
  /// failures inside the service are logged and swallowed there.
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

  /// Returns the existing row, creating one with locale-derived defaults
  /// if none exists. Safe to call repeatedly. We look up by row count
  /// (there's only ever one) so this keeps working after [syncUid]
  /// changes the uid column from 'local' to the Firebase uid.
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

  /// Generic patcher — pass only the fields you want to change. Internally
  /// guarantees a row exists. Filters by primary key so it keeps working
  /// across [syncUid] uid changes.
  Future<void> patch(UserSettingsCompanion patch) async {
    final row = await read();
    await (_db.update(_db.userSettings)
          ..where((t) => t.id.equals(row.id)))
        .write(patch);
  }

  /// Migrate the local row + all existing trips to the Firebase Auth uid.
  /// Idempotent: no-op when [authUid] already matches the current row.
  ///
  /// Without this, every Firestore write that uses `settings.uid` would
  /// use the placeholder `'local'`, and the security rules
  /// (`request.auth.uid == uid`) would deny every request — which is
  /// exactly what the user was hitting before this fix.
  Future<void> syncUid(String authUid) async {
    if (authUid.isEmpty) return;
    final row = await read();
    if (row.uid == authUid) return;
    final oldUid = row.uid;

    if (kDebugMode) {
      debugPrint(
        '[UserSettingsRepository] migrating uid: $oldUid → $authUid',
      );
    }

    // user_settings.uid + trips.uid in a single transaction so we never
    // end up with the row pointing at one uid and trips at another.
    await _db.transaction(() async {
      await (_db.update(_db.userSettings)
            ..where((t) => t.id.equals(row.id)))
          .write(UserSettingsCompanion(uid: Value(authUid)));
      await (_db.update(_db.trips)
            ..where((t) => t.uid.equals(oldUid)))
          .write(TripsCompanion(uid: Value(authUid)));
    });
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
