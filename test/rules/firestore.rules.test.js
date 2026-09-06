'use strict';

const fs = require('fs');
const path = require('path');
const assert = require('assert');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, deleteDoc, updateDoc } = require('firebase/firestore');

// Every value here is written by the owner's own client, so these tests
// verify ownership and shape — who may write what — and not that the
// numbers are true. Truthfulness is not enforceable client-side; see the
// trust-model note at the top of firestore.rules.

let testEnv;

const ALICE = 'alice-uid';
const BOB = 'bob-uid';

/** A valid public-profile document. */
function profile(overrides = {}) {
  return {
    username: 'alice',
    usernameLower: 'alice',
    carMake: 'BMW',
    carModel: 'M3',
    countryCode: 'PK',
    updatedAt: new Date(),
    distance_weekly: 301,
    distance_monthly: 1204,
    distance_allTime: 9743,
    longestTrip_weekly: 212,
    longestTrip_monthly: 212,
    longestTrip_allTime: 340,
    consistency_weekly: 4,
    consistency_monthly: 15,
    consistency_allTime: 220,
    ...overrides,
  };
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'drive-rank-rules-test',
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '../../firestore.rules'),
        'utf8',
      ),
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

afterEach(async () => {
  if (testEnv) await testEnv.clearFirestore();
});

describe('public_profiles — the mirror other people read', () => {
  it('lets a user publish their own', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'public_profiles', ALICE), profile()),
    );
  });

  it("refuses a write to somebody else's — the whole point of the model "
    + 'is that you can only overstate your own driving', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertFails(
      setDoc(doc(db, 'public_profiles', BOB), profile({ username: 'bob' })),
    );
  });

  it('refuses a field outside the whitelist, so the mirror cannot become '
    + 'general-purpose user-writable storage', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertFails(
      setDoc(
        doc(db, 'public_profiles', ALICE),
        profile({ arbitraryPayload: 'x'.repeat(1000) }),
      ),
    );
  });

  it('lets any signed-in user read any profile — this is the collection '
    + 'that exists to be read', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'public_profiles', ALICE), profile());
    });
    const db = testEnv.authenticatedContext(BOB).firestore();
    await assertSucceeds(getDoc(doc(db, 'public_profiles', ALICE)));
  });

  it('refuses an unauthenticated read', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'public_profiles', ALICE)));
  });

  it('lets a user delete their own, for account deletion', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'public_profiles', ALICE), profile());
    });
    const alice = testEnv.authenticatedContext(ALICE).firestore();
    const bob = testEnv.authenticatedContext(BOB).firestore();
    await assertFails(deleteDoc(doc(bob, 'public_profiles', ALICE)));
    await assertSucceeds(deleteDoc(doc(alice, 'public_profiles', ALICE)));
  });
});

describe('usernames — the document is the lock', () => {
  it('lets a user claim a free name', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'usernames', 'alice'), {
        uid: ALICE,
        claimedAt: new Date(),
      }),
    );
  });

  it('refuses a claim recorded under another uid — you cannot reserve a '
    + 'name on somebody else\'s behalf', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertFails(
      setDoc(doc(db, 'usernames', 'alice'), {
        uid: BOB,
        claimedAt: new Date(),
      }),
    );
  });

  it('refuses a second claim on a held name, which is what makes a '
    + 'username resolve to one person', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'usernames', 'alice'), {
        uid: ALICE,
        claimedAt: new Date(),
      });
    });
    const db = testEnv.authenticatedContext(BOB).firestore();
    await assertFails(
      setDoc(doc(db, 'usernames', 'alice'), {
        uid: BOB,
        claimedAt: new Date(),
      }),
    );
  });

  it('refuses update and delete even by the holder — reservations are '
    + 'permanent, so a handle in a friend list can never be re-claimed '
    + 'by a different person', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'usernames', 'alice'), {
        uid: ALICE,
        claimedAt: new Date(),
      });
    });
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertFails(updateDoc(doc(db, 'usernames', 'alice'), { uid: BOB }));
    await assertFails(deleteDoc(doc(db, 'usernames', 'alice')));
  });

  it('lets a signed-in user look a name up before claiming it', async () => {
    const db = testEnv.authenticatedContext(BOB).firestore();
    await assertSucceeds(getDoc(doc(db, 'usernames', 'alice')));
  });

  it('refuses an unauthenticated lookup', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'usernames', 'alice')));
  });
});

describe('the private boundary still holds', () => {
  // This group is the regression net. Adding public collections beside
  // the private ones is exactly when a read rule gets loosened by
  // accident, and nothing else in the codebase would notice.

  it("refuses a read of another user's users/{uid} document, which holds "
    + 'their PII', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', ALICE), {
        username: 'alice',
        usernameLower: 'alice',
        carMake: 'BMW',
        carModel: 'M3',
        carName: 'BMW M3',
        countryCode: 'PK',
        updatedAt: new Date(),
      });
    });
    const db = testEnv.authenticatedContext(BOB).firestore();
    await assertFails(getDoc(doc(db, 'users', ALICE)));
    await assertSucceeds(
      getDoc(doc(testEnv.authenticatedContext(ALICE).firestore(), 'users', ALICE)),
    );
  });

  it("refuses a read of another user's trips, waypoints included", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', ALICE, 'trips', 'trip-1'), {
        distanceKm: 212.4,
        startedAt: new Date(),
      });
    });
    const db = testEnv.authenticatedContext(BOB).firestore();
    await assertFails(getDoc(doc(db, 'users', ALICE, 'trips', 'trip-1')));
  });

  it('still denies everything outside the declared collections', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertFails(setDoc(doc(db, 'friends', 'anything'), { a: 1 }));
    await assertFails(getDoc(doc(db, 'leaderboards', 'global')));
  });

  it('the public mirror and the private profile are genuinely separate '
    + 'documents, so a mirror read cannot reach PII', async () => {
    // Seeded through the real write path rather than the privileged
    // escape hatch: Alice publishes both of her own documents exactly
    // as the app does, which makes this exercise the write rules too.
    const alice = testEnv.authenticatedContext(ALICE).firestore();
    await assertSucceeds(
      setDoc(doc(alice, 'public_profiles', ALICE), profile()),
    );
    await assertSucceeds(
      setDoc(doc(alice, 'users', ALICE), {
        username: 'alice',
        usernameLower: 'alice',
        carPhotoUrl: 'https://example.invalid/alice.jpg',
        updatedAt: new Date(),
      }),
    );

    const bob = testEnv.authenticatedContext(BOB).firestore();
    const mirror = await assertSucceeds(
      getDoc(doc(bob, 'public_profiles', ALICE)),
    );
    // The photo lives only on the private document. Bob can read the
    // mirror and still cannot reach it.
    assert.strictEqual(mirror.data().carPhotoUrl, undefined);
    assert.strictEqual(mirror.data().username, 'alice');
    await assertFails(getDoc(doc(bob, 'users', ALICE)));
  });
});
