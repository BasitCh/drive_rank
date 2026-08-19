import 'package:drive_rank/core/services/active_trip_store.dart';
import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/shared/repositories/trip_repository.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:injectable/injectable.dart';

/// Orchestrates the "Delete my account" flow required by Google Play
/// policy: every piece of data DriveRank holds for this user, gone —
/// not just a soft reset of the onboarding flag.
///
/// Tears down, in order:
///  1. All trips + waypoints (waypoints cascade via the trips FK).
///  2. The in-progress/crash-recovery live trip row, if any.
///  3. The `device_trials` anti-abuse counter doc (best-effort).
///  4. The Firebase Auth account itself (best-effort — re-establishes
///     a fresh anonymous session regardless of outcome).
///  5. The local user-settings row (car, username, country, units…).
///
/// Steps 3–4 are best-effort and never abort the sequence — the local
/// wipe (1, 2, 5) is the part Play policy actually gates on, and it
/// must complete even if the device is offline.
@lazySingleton
class AccountDeletionService {
  AccountDeletionService(
    this._trips,
    this._settings,
    this._activeTrip,
    this._freeTripCounter,
    this._auth,
  );

  final TripRepository _trips;
  final UserSettingsRepository _settings;
  final ActiveTripStore _activeTrip;
  final FreeTripCounterService _freeTripCounter;
  final AuthService _auth;

  Future<void> deleteEverything() async {
    final uid = _auth.currentUser.uid;

    await _trips.deleteAllForUid(uid);
    await _activeTrip.clear();

    // Best-effort remote teardown — never blocks local completion.
    await _freeTripCounter.deleteRemote();
    await _auth.deleteAccount();

    await _settings.wipe();
  }
}
