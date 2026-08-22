import 'dart:async' show unawaited;

import 'package:drift/drift.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/services/public_profile_service.dart';
import 'package:injectable/injectable.dart';

/// Single source of truth for the *one* user-settings row.
///
/// Onboarding writes here progressively; the rest of the app reads.
/// Reactive callers should use [watch] — the live tracking screen,
/// profile, paywall state, and the router redirect all depend on this.
///
/// The `uid` column tracks the current Firebase Auth uid (anonymous or
/// signed-in) — see [syncUid] — and every trip/stats query is scoped by
/// it. It is a foreign key against the local `trips` table (both filtered
/// by the same uid) and against Firestore paths for cloud sync, but it is
/// NOT the Drift primary key — every method here still resolves the row
/// by primary key / `.limit(1)`, not by uid, so it keeps working across
/// a `syncUid`/`reassignUidOnly` call that changes the uid mid-session.
@lazySingleton
class UserSettingsRepository {
  UserSettingsRepository(this._db, this._locale, this._freeTripCounter);

  final AppDatabase _db;
  final LocaleService _locale;
  final FreeTripCounterService _freeTripCounter;

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
    final existing = await (_db.select(
      _db.userSettings,
    )..limit(1)).getSingleOrNull();
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
    return (_db.select(
      _db.userSettings,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  /// Guarantees the row exists before the stream starts — without this,
  /// a subscriber that races `ensureExists()` (e.g. right after sign-out
  /// triggers a bloc reload) can observe zero rows and `watchSingle()`
  /// throws `Bad state: Expected exactly one element, but got 0`.
  Stream<UserSettingsRow> watch() {
    return Stream.fromFuture(
      ensureExists(),
    ).asyncExpand((_) => (_db.select(_db.userSettings)..limit(1)).watchSingle());
  }

  Future<UserSettingsRow> read() async {
    await ensureExists();
    return (_db.select(_db.userSettings)..limit(1)).getSingle();
  }

  /// True once the user finishes the 7-step onboarding flow.
  Future<bool> isOnboardingComplete() async {
    final row = await (_db.select(
      _db.userSettings,
    )..limit(1)).getSingleOrNull();
    return row?.onboardingComplete ?? false;
  }

  /// Generic patcher — pass only the fields you want to change.
  /// Internally guarantees a row exists. Filters by primary key so it
  /// keeps working regardless of what the uid column is set to.
  Future<void> patch(UserSettingsCompanion patch) async {
    final row = await read();
    await (_db.update(
      _db.userSettings,
    )..where((t) => t.id.equals(row.id))).write(patch);
  }

  /// Mirrors the public-profile text fields to Firestore. Best-effort:
  /// failures inside the service are logged and swallowed there. Always
  /// reads the *current* row first so a partial update (e.g. only the
  /// car changed) still sends a complete doc.
  ///
  /// Resolved lazily via `getIt` rather than taken as a constructor
  /// dependency on purpose: this repository is constructed before
  /// bootstrap swaps the real `FirestorePublicProfileService` in for the
  /// no-op default, so a hard constructor reference would permanently
  /// point at the no-op.
  ///
  /// Text fields only — the car photo URL is not included here. Photo
  /// upload needs Firebase Storage access, which is a `CloudSyncService`
  /// concern (see the sign-in sequence), not something this Drift-only
  /// repository takes a dependency on.
  Future<void> _republishPublicProfile() async {
    final row = await read();
    await getIt<PublicProfileService>().publish(
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

  // ---- Cloud-sync identity ----

  /// Migrates the settings row AND every trip currently tagged with its
  /// old uid over to [authUid]. Safe/idempotent — no-ops if the row
  /// already matches.
  ///
  /// Called from two places: (1) bootstrap, right after anonymous
  /// sign-in resolves, collapsing the pre-auth `'local'` placeholder into
  /// the current session's uid; (2) after a successful Google sign-in,
  /// but ONLY when the local data being claimed was genuinely unclaimed
  /// (anonymous) immediately beforehand — see [reassignUidOnly] for the
  /// other branch. Callers own that safety check; this method just does
  /// the migration once told it's safe.
  Future<void> syncUid(String authUid) async {
    if (authUid.isEmpty) return;
    final row = await read();
    if (row.uid == authUid) return; // idempotent
    final oldUid = row.uid;
    await _db.transaction(() async {
      await (_db.update(_db.userSettings)..where((t) => t.id.equals(row.id)))
          .write(UserSettingsCompanion(uid: Value(authUid)));
      await (_db.update(_db.trips)..where((t) => t.uid.equals(oldUid)))
          .write(TripsCompanion(uid: Value(authUid)));
    });
  }

  /// Repoints the settings row to a different account's uid WITHOUT
  /// touching the trips table — used when signing into an account that is
  /// NOT the one this device's local data was already claimed by (see
  /// `syncUid`'s account-switching guard, applied by the caller before
  /// choosing between the two methods).
  ///
  /// Existing local trips are left exactly as they are, still tagged with
  /// the previous account's uid — not deleted, not migrated, simply no
  /// longer matched by any uid-scoped query once this row's uid changes,
  /// so they stop being shown or synced under the new identity. If that
  /// previous account signs back in later (via `syncUid` or this same
  /// method, whichever the guard picks), its trips become visible again
  /// automatically — the moment the settings row's uid matches theirs
  /// again, every uid-scoped query starts matching them, with no restore
  /// step required.
  Future<void> reassignUidOnly(String newUid) async {
    final row = await read();
    if (row.uid == newUid) return;
    await (_db.update(_db.userSettings)..where((t) => t.id.equals(row.id)))
        .write(UserSettingsCompanion(uid: Value(newUid)));
  }

  /// Overwrites local profile fields (username, car, country, photo) with
  /// a payload restored from Firestore — used only when the signing-in
  /// account is a *returning* one (a `users/{uid}` doc already exists),
  /// so there's no risk of discarding onboarding data the user just
  /// entered on this device (a first-time account has nothing to
  /// overwrite it with — see `CloudSyncService`/the sign-in sequence).
  ///
  /// [localCarPhotoPath] is the already-downloaded local file path for
  /// [PublicProfilePayload.carPhotoUrl] (downloading is the caller's job —
  /// this repository has no network/Storage access), or null if the
  /// remote profile has no photo.
  Future<void> applyRemoteProfile(
    PublicProfilePayload payload, {
    String? localCarPhotoPath,
  }) {
    return patch(
      UserSettingsCompanion(
        username: Value(payload.username),
        carMake: Value(payload.carMake),
        carModel: Value(payload.carModel),
        carYear: Value(payload.carYear),
        country: Value(payload.countryCode),
        carPhotoPath: localCarPhotoPath != null
            ? Value(localCarPhotoPath)
            : const Value.absent(),
      ),
    );
  }

  // ---- Typed setters used by onboarding + settings ----
  //
  // setCountry / setCar / setUsername all republish the public-profile
  // text fields to Firestore afterward (best-effort, no-op when signed
  // out / Firestore unavailable) — those are exactly the fields a
  // restored-on-a-new-device profile, and eventually a leaderboard,
  // read back.

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
  /// photo. Pass `null` to clear (e.g. user tapped Skip). Does not
  /// upload to Storage / republish the cloud profile photo — see
  /// `CloudSyncService` for that (Storage access lives there, not in
  /// this Drift-only repository).
  Future<void> setCarPhotoPath(String? path) =>
      patch(UserSettingsCompanion(carPhotoPath: Value(path)));

  /// Persists the user's chosen username locally so the stat card,
  /// profile, and personal-bests surfaces can read it. No cloud
  /// uniqueness check in MVP — the field is purely cosmetic.
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

  /// Trips shorter than [metres] are discarded on End, not saved — see
  /// `TrackingBloc._onStopRequested`.
  Future<void> setMinTripLengthMeters(double metres) =>
      patch(UserSettingsCompanion(minTripLengthMeters: Value(metres)));

  Future<void> markOnboardingComplete() =>
      patch(const UserSettingsCompanion(onboardingComplete: Value(true)));

  /// Records that we showed the OEM battery-killer bottom sheet, so
  /// the next trip start doesn't fire it again.
  Future<void> markOemAdviceShown() =>
      patch(const UserSettingsCompanion(oemAdviceShown: Value(true)));

  /// Flips the background-location Prominent Disclosure flag. Called
  /// when the user taps either Continue or Skip on the disclosure
  /// surface — both paths count as "we showed it"; the system
  /// permission grant is tracked separately by the OS.
  Future<void> markBgLocationDisclosureAcked() => patch(
    const UserSettingsCompanion(bgLocationDisclosureAcked: Value(true)),
  );

  /// Persists the user's next "beat this" targets — see
  /// `GoalCalculator`. Called by `TrackingBloc` right after a trip
  /// saves. Either value may be omitted if that metric's goal didn't
  /// change this trip — omitted means "leave the column alone"
  /// ([Value.absent]), not "clear it".
  Future<void> setGoals({double? speedGoalKmh, double? distanceGoalKm}) =>
      patch(
        UserSettingsCompanion(
          speedGoalKmh: speedGoalKmh != null
              ? Value(speedGoalKmh)
              : const Value.absent(),
          distanceGoalKm: distanceGoalKm != null
              ? Value(distanceGoalKm)
              : const Value.absent(),
        ),
      );

  // ---- Trip-counter helpers (used by the paywall in Session 4) ----

  Future<void> incrementFreeTripsUsed() async {
    final row = await read();
    final next = row.freeTripsUsed + 1;
    await patch(UserSettingsCompanion(freeTripsUsed: Value(next)));
    // Write-through to Firestore so the counter survives uninstall +
    // reinstall on the same device. Fire-and-forget on purpose: the
    // local write above is the canonical signal for any paywall logic,
    // and the Firestore SDK's offline persistence layer can stall the
    // outer Future for tens of seconds on flaky-or-no connectivity —
    // which was hanging the "Saving trip…" gate end-of-trip. A 3s
    // timeout caps the worst case for the background settle as well.
    unawaited(
      _freeTripCounter
          .setRemote(next)
          .timeout(const Duration(seconds: 3), onTimeout: () => false),
    );
  }

  /// Reconciles local Drift counter with the cloud counter for this
  /// device. Picks the larger of the two and ensures both sides match
  /// it — anti-abuse counter is monotonically increasing, so we never
  /// downgrade.
  ///
  /// Called from bootstrap after Firebase + anonymous auth are ready.
  /// Safe to call repeatedly; safe to call when Firebase isn't ready
  /// (the service no-ops on any error).
  /// Deletes the settings row entirely — car, username, country, unit
  /// preference, everything. Used only by account deletion; the next
  /// `ensureExists()`/`read()` call recreates a fresh locale-derived
  /// row, exactly like a brand-new install.
  Future<void> wipe() async {
    await _db.delete(_db.userSettings).go();
  }

  Future<void> syncFreeTripsWithCloud() async {
    final remote = await _freeTripCounter.pullRemoteUsed();
    if (remote == null) return; // offline / unsupported device — keep local
    final row = await read();
    final max = remote > row.freeTripsUsed ? remote : row.freeTripsUsed;
    if (max > row.freeTripsUsed) {
      await patch(UserSettingsCompanion(freeTripsUsed: Value(max)));
    }
    if (max > remote) {
      await _freeTripCounter.setRemote(max);
    }
  }
}
