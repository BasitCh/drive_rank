import 'dart:async' show unawaited;

import 'package:drift/drift.dart' show Value;
import 'package:drive_rank/core/database/app_database.dart'
    show UserSettingsCompanion;
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/paywall_service.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/cloud_sync_service.dart';
import 'package:drive_rank/shared/services/public_profile_service.dart';
import 'package:drive_rank/shared/services/sync_manager.dart';
import 'package:flutter/foundation.dart' show immutable;

enum CloudSignInOutcome { success, cancelled, failed }

@immutable
class CloudSignInResult {
  const CloudSignInResult({required this.outcome, this.tripsRestored = 0});

  final CloudSignInOutcome outcome;
  final int tripsRestored;
}

/// The account-switching safety check (see `performCloudSignIn` step 4) —
/// extracted as a pure function so the core invariant this whole feature
/// depends on ("Account A's local trips must never be claimed for a
/// different Account B") is directly unit-testable without mocking the
/// auth/settings services.
///
/// Local data is only safe to claim for the newly-signed-in account when
/// it was genuinely unclaimed (anonymous) immediately beforehand — i.e.
/// the settings row's uid still matches whatever anonymous session was
/// active right before `signInWithGoogle()` was called. If the settings
/// row's uid is anything else (a different, already-signed-in account's
/// uid, left behind by a previous sign-in that was never fully claimed
/// back), claiming it would silently re-tag and later upload that other
/// account's private trips under this one.
bool isSafeToClaimLocalData({
  required bool preSignInWasAnonymous,
  required String preSignInUid,
  required String currentSettingsUid,
}) {
  return preSignInWasAnonymous && currentSettingsUid == preSignInUid;
}

/// Maps a [ProEntitlementCheck] to the local `isPro` patch it should
/// produce — extracted as a pure function for the same testability
/// reason as [isSafeToClaimLocalData]. Null means "don't touch the local
/// flag" (the [ProEntitlementCheck.unknown] / network-error case — a
/// paying user must never be silently downgraded by a transient failure,
/// but a confirmed-inactive entitlement must always downgrade a stale
/// `true` left over from a different previously-signed-in account).
UserSettingsCompanion? proEntitlementPatch(ProEntitlementCheck check) {
  return switch (check) {
    ProEntitlementCheck.active => const UserSettingsCompanion(
      isPro: Value(true),
    ),
    ProEntitlementCheck.inactive => const UserSettingsCompanion(
      isPro: Value(false),
    ),
    ProEntitlementCheck.unknown => null,
  };
}

/// The full "sign in with Google and make this device whole" sequence —
/// shared by the post-onboarding sheet and the Settings entry point so
/// there's exactly one place this logic lives.
///
/// Order matters:
///  1. Reset sync status so a previous account's state never bleeds in.
///  2. Capture pre-sign-in identity (needed for the account-switching
///     guard below) *before* calling `signInWithGoogle()`.
///  3. Sign in.
///  4. Claim local data for this account only if it was genuinely
///     unclaimed (anonymous) beforehand — otherwise repoint the settings
///     row without touching the trips table, so a different account's
///     local trips are never migrated or uploaded under this one.
///  5. Pro entitlement — RevenueCat `identify` + a three-way check, never
///     Firestore.
///  6. Profile — pull if this account has synced before, else push.
///  7. Trips — pull first (so an empty local DB never pushes over a
///     non-empty cloud one), then push everything local.
Future<CloudSignInResult> performCloudSignIn() async {
  final auth = getIt<AuthService>();
  final settings = getIt<UserSettingsRepository>();
  final sync = getIt<SyncManager>();
  final cloud = getIt<CloudSyncService>();
  final paywall = getIt<PaywallService>();
  final publicProfile = getIt<PublicProfileService>();

  sync.resetForAccountChange();

  final preSignInUid = auth.currentUser.uid;
  final preSignInWasAnonymous = auth.currentUser.isAnonymous;

  final result = await auth.signInWithGoogle();
  if (result != SignInResult.success) {
    return CloudSignInResult(
      outcome: result == SignInResult.cancelled
          ? CloudSignInOutcome.cancelled
          : CloudSignInOutcome.failed,
    );
  }

  final authUser = auth.currentUser;

  // Account-switching guard — only claim local data for this account if
  // it was genuinely unclaimed immediately before. See
  // `isSafeToClaimLocalData`.
  final row = await settings.read();
  final safeToClaim = isSafeToClaimLocalData(
    preSignInWasAnonymous: preSignInWasAnonymous,
    preSignInUid: preSignInUid,
    currentSettingsUid: row.uid,
  );
  if (safeToClaim) {
    await settings.syncUid(authUser.uid);
  } else {
    await settings.reassignUidOnly(authUser.uid);
  }

  // Pro entitlement — RevenueCat remains the sole source of truth; no
  // Firestore involvement at all. See `proEntitlementPatch`.
  await paywall.identify(authUser.uid);
  final proPatch = proEntitlementPatch(await paywall.checkEntitlement());
  if (proPatch != null) await settings.patch(proPatch);

  // Profile — pull only if this account has synced before (a
  // `users/{uid}` doc already exists), otherwise push the local one
  // (whether just-onboarded or reassigned from a different prior
  // account, per the guard above).
  final remoteProfile = await cloud.fetchRemoteProfile(uid: authUser.uid);
  if (remoteProfile != null) {
    String? localPhotoPath;
    if (remoteProfile.carPhotoUrl != null) {
      localPhotoPath = await cloud.downloadProfilePhoto(
        remoteProfile.carPhotoUrl!,
      );
    }
    await settings.applyRemoteProfile(
      remoteProfile,
      localCarPhotoPath: localPhotoPath,
    );
  } else {
    final current = await settings.read();
    final photoUrl = await cloud.uploadProfilePhotoIfNeeded(
      authUser.uid,
      current.carPhotoPath,
    );
    await publicProfile.publish(
      PublicProfilePayload(
        uid: authUser.uid,
        username: current.username,
        carMake: current.carMake,
        carModel: current.carModel,
        carYear: current.carYear,
        countryCode: current.country ?? '',
        carPhotoUrl: photoUrl,
      ),
    );
  }

  // Trips — pull first, then push everything local that isn't in the
  // cloud yet.
  final restoredCount = await cloud.restoreTripsFromCloud(uid: authUser.uid);
  await sync.markAllUnsynced();
  unawaited(sync.syncNow());

  return CloudSignInResult(
    outcome: CloudSignInOutcome.success,
    tripsRestored: restoredCount,
  );
}
