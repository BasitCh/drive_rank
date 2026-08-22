import 'package:drift/drift.dart' show Value;
import 'package:drive_rank/core/services/paywall_service.dart';
import 'package:drive_rank/shared/services/cloud_sign_in_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isSafeToClaimLocalData — account-switching guard', () {
    test('anonymous device signing in for the first time is safe to claim', () {
      expect(
        isSafeToClaimLocalData(
          preSignInWasAnonymous: true,
          preSignInUid: 'anon-1',
          currentSettingsUid: 'anon-1',
        ),
        isTrue,
      );
    });

    test('a device already signed into Account A is NOT safe to claim for '
        'a different Account B (the leak this guard exists to prevent)', () {
      // Simulates: Anonymous -> sign in A -> sign out (fresh anon
      // session) -> sign in B. The settings row is still tagged with
      // A's uid (never migrated/deleted on sign-out), which does not
      // match the anonymous session active right before B's sign-in.
      expect(
        isSafeToClaimLocalData(
          preSignInWasAnonymous: true,
          preSignInUid: 'anon-2', // fresh session after A signed out
          currentSettingsUid: 'account-a-uid', // still A's, untouched
        ),
        isFalse,
      );
    });

    test('signing back into Account A later is unaffected either way — the '
        "guard only decides whether to migrate, and A's trips stay "
        'visible automatically once the uid matches again (see '
        'UserSettingsRepository.reassignUidOnly doc)', () {
      // Re-signing into A: current settings uid is B's (from the
      // previous switch), pre-sign-in session is a fresh anonymous one
      // post-B-signout. Still correctly "not safe to claim" — but this
      // is fine, because reassignUidOnly just repoints the uid column
      // and A's dormant trips reappear the moment it matches A again.
      expect(
        isSafeToClaimLocalData(
          preSignInWasAnonymous: true,
          preSignInUid: 'anon-3',
          currentSettingsUid: 'account-b-uid',
        ),
        isFalse,
      );
    });

    test('never safe to claim when not anonymous beforehand', () {
      expect(
        isSafeToClaimLocalData(
          preSignInWasAnonymous: false,
          preSignInUid: 'some-uid',
          currentSettingsUid: 'some-uid',
        ),
        isFalse,
      );
    });
  });

  group('proEntitlementPatch — three-way entitlement result', () {
    test('active entitlement sets isPro true', () {
      final patch = proEntitlementPatch(ProEntitlementCheck.active);
      expect(patch, isNotNull);
      expect(patch!.isPro, const Value(true));
    });

    test('inactive (successfully checked, no entitlement) sets isPro false '
        '— this is the case a plain restorePurchases() bool could not '
        'distinguish from a network error, and getting it wrong would '
        'leave a stale Pro flag active for a free account', () {
      final patch = proEntitlementPatch(ProEntitlementCheck.inactive);
      expect(patch, isNotNull);
      expect(patch!.isPro, const Value(false));
    });

    test('unknown (network/API error) returns null — local isPro state '
        'must be preserved untouched, never guessed at', () {
      expect(proEntitlementPatch(ProEntitlementCheck.unknown), isNull);
    });
  });
}
