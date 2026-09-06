'use strict';

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, deleteDoc, updateDoc } = require('firebase/firestore');

// The friendship rule is the one place in this app where a write is
// authorised by *another document*. That makes it the easiest rule to
// write in a way that looks right and is subtly wrong, so the deny side
// is tested at least as heavily as the allow side.

let testEnv;

const A = 'aaa-alice';
const B = 'bbb-bob';
const C = 'ccc-carol';

const pair = (x, y) => [x, y].sort();
const pairKey = (x, y) => pair(x, y).join('_');
const requestId = (from, to) => `${from}_${to}`;

function requestDoc(from, to, status = 'pending') {
  return {
    fromUid: from,
    toUid: to,
    status,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}

function friendshipDoc(x, y) {
  return { uids: pair(x, y), createdAt: new Date() };
}

/** Puts an accepted request in place without going through the rules. */
async function seedAccepted(from, to) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(
      doc(ctx.firestore(), 'friend_requests', requestId(from, to)),
      requestDoc(from, to, 'accepted'),
    );
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'drive-rank-friends-test',
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

describe('friend requests', () => {
  it('lets you send one, at the derived path', async () => {
    const db = testEnv.authenticatedContext(A).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'friend_requests', requestId(A, B)), requestDoc(A, B)),
    );
  });

  it('refuses a request you did not send', async () => {
    const db = testEnv.authenticatedContext(C).firestore();
    await assertFails(
      setDoc(doc(db, 'friend_requests', requestId(A, B)), requestDoc(A, B)),
    );
  });

  it('refuses a request whose id disagrees with its contents — the id is '
    + 'what the friendship rule looks up, so it has to be trustworthy',
  async () => {
    const db = testEnv.authenticatedContext(A).firestore();
    await assertFails(
      setDoc(doc(db, 'friend_requests', requestId(A, C)), requestDoc(A, B)),
    );
  });

  it('refuses befriending yourself', async () => {
    const db = testEnv.authenticatedContext(A).firestore();
    await assertFails(
      setDoc(doc(db, 'friend_requests', requestId(A, A)), requestDoc(A, A)),
    );
  });

  it('refuses a request that starts in any state but pending', async () => {
    const db = testEnv.authenticatedContext(A).firestore();
    await assertFails(
      setDoc(
        doc(db, 'friend_requests', requestId(A, B)),
        requestDoc(A, B, 'accepted'),
      ),
    );
  });

  it('lets both parties read it and nobody else', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'friend_requests', requestId(A, B)),
        requestDoc(A, B),
      );
    });
    const ref = (uid) =>
      doc(testEnv.authenticatedContext(uid).firestore(),
        'friend_requests', requestId(A, B));
    await assertSucceeds(getDoc(ref(A)));
    await assertSucceeds(getDoc(ref(B)));
    await assertFails(getDoc(ref(C)));
  });

  describe('the state machine', () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(
          doc(ctx.firestore(), 'friend_requests', requestId(A, B)),
          requestDoc(A, B),
        );
      });
    });

    const asUser = (uid) =>
      doc(testEnv.authenticatedContext(uid).firestore(),
        'friend_requests', requestId(A, B));

    it('lets the recipient accept or decline', async () => {
      await assertSucceeds(
        updateDoc(asUser(B), { status: 'accepted', updatedAt: new Date() }),
      );
    });

    it('refuses an accept by the sender — you cannot accept your own '
      + 'request', async () => {
      await assertFails(
        updateDoc(asUser(A), { status: 'accepted', updatedAt: new Date() }),
      );
    });

    it('refuses an accept by an unrelated user', async () => {
      await assertFails(
        updateDoc(asUser(C), { status: 'accepted', updatedAt: new Date() }),
      );
    });

    it('lets the sender cancel, and re-send after cancelling', async () => {
      await assertSucceeds(
        updateDoc(asUser(A), { status: 'cancelled', updatedAt: new Date() }),
      );
      await assertSucceeds(
        updateDoc(asUser(A), { status: 'pending', updatedAt: new Date() }),
      );
    });

    it('refuses a cancel by the recipient', async () => {
      await assertFails(
        updateDoc(asUser(B), { status: 'cancelled', updatedAt: new Date() }),
      );
    });

    it('treats accepted and declined as terminal', async () => {
      await assertSucceeds(
        updateDoc(asUser(B), { status: 'declined', updatedAt: new Date() }),
      );
      // No un-declining, by either party.
      await assertFails(
        updateDoc(asUser(B), { status: 'pending', updatedAt: new Date() }),
      );
      await assertFails(
        updateDoc(asUser(A), { status: 'pending', updatedAt: new Date() }),
      );
      await assertFails(
        updateDoc(asUser(B), { status: 'accepted', updatedAt: new Date() }),
      );
    });

    it('refuses any change to who the request is between — a mutable '
      + 'toUid would let an accepted request be redirected at somebody '
      + 'who never agreed to anything', async () => {
      await assertFails(
        updateDoc(asUser(B), { status: 'accepted', toUid: C }),
      );
      await assertFails(
        updateDoc(asUser(B), { status: 'accepted', fromUid: C }),
      );
      await assertFails(
        updateDoc(asUser(B), { status: 'accepted', createdAt: new Date(0) }),
      );
    });

    it('never allows a delete, so a decline cannot be made invisible',
      async () => {
        await assertFails(deleteDoc(asUser(A)));
        await assertFails(deleteDoc(asUser(B)));
      });
  });
});

describe('friendships', () => {
  it('can be created by either party once a request is accepted',
    async () => {
      await seedAccepted(A, B);
      const db = testEnv.authenticatedContext(B).firestore();
      await assertSucceeds(
        setDoc(doc(db, 'friendships', pairKey(A, B)), friendshipDoc(A, B)),
      );
    });

  it('can be created off a request accepted in the other direction — '
    + 'either of the two derived paths authorises it', async () => {
    await seedAccepted(B, A);
    const db = testEnv.authenticatedContext(A).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'friendships', pairKey(A, B)), friendshipDoc(A, B)),
    );
  });

  it('cannot be fabricated without any request at all', async () => {
    const db = testEnv.authenticatedContext(A).firestore();
    await assertFails(
      setDoc(doc(db, 'friendships', pairKey(A, B)), friendshipDoc(A, B)),
    );
  });

  it('cannot be created off a request that is only pending', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'friend_requests', requestId(A, B)),
        requestDoc(A, B),
      );
    });
    const db = testEnv.authenticatedContext(B).firestore();
    await assertFails(
      setDoc(doc(db, 'friendships', pairKey(A, B)), friendshipDoc(A, B)),
    );
  });

  it('cannot be created off a declined request', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'friend_requests', requestId(A, B)),
        requestDoc(A, B, 'declined'),
      );
    });
    const db = testEnv.authenticatedContext(B).firestore();
    await assertFails(
      setDoc(doc(db, 'friendships', pairKey(A, B)), friendshipDoc(A, B)),
    );
  });

  // The invariant most likely to be satisfied by a rule that merely
  // looks correct: "A appears in an accepted request" is not the same
  // claim as "A and C are entitled to be friends".
  it('refuses a borrowed acceptance — an accepted A↔B request does not '
    + 'entitle A to a friendship with C', async () => {
    await seedAccepted(A, B);
    const db = testEnv.authenticatedContext(A).firestore();
    await assertFails(
      setDoc(doc(db, 'friendships', pairKey(A, C)), friendshipDoc(A, C)),
    );
  });

  it('refuses a borrowed acceptance from the other side either — B↔C is '
    + 'not authorised by A↔B', async () => {
    await seedAccepted(A, B);
    const db = testEnv.authenticatedContext(B).firestore();
    await assertFails(
      setDoc(doc(db, 'friendships', pairKey(B, C)), friendshipDoc(B, C)),
    );
  });

  it('refuses a friendship the author is not part of, even a real one',
    async () => {
      await seedAccepted(A, B);
      const db = testEnv.authenticatedContext(C).firestore();
      await assertFails(
        setDoc(doc(db, 'friendships', pairKey(A, B)), friendshipDoc(A, B)),
      );
    });

  it('refuses a document whose key disagrees with its uids', async () => {
    await seedAccepted(A, B);
    const db = testEnv.authenticatedContext(A).firestore();
    await assertFails(
      setDoc(doc(db, 'friendships', pairKey(A, C)), friendshipDoc(A, B)),
    );
  });

  it('refuses unsorted uids, so one pair cannot occupy two documents',
    async () => {
      await seedAccepted(A, B);
      const db = testEnv.authenticatedContext(A).firestore();
      await assertFails(
        setDoc(doc(db, 'friendships', `${B}_${A}`), {
          uids: [B, A],
          createdAt: new Date(),
        }),
      );
    });

  it('refuses extra fields', async () => {
    await seedAccepted(A, B);
    const db = testEnv.authenticatedContext(A).firestore();
    await assertFails(
      setDoc(doc(db, 'friendships', pairKey(A, B)), {
        ...friendshipDoc(A, B),
        note: 'anything',
      }),
    );
  });

  it('is readable by its two members and nobody else', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'friendships', pairKey(A, B)),
        friendshipDoc(A, B),
      );
    });
    const ref = (uid) =>
      doc(testEnv.authenticatedContext(uid).firestore(),
        'friendships', pairKey(A, B));
    await assertSucceeds(getDoc(ref(A)));
    await assertSucceeds(getDoc(ref(B)));
    await assertFails(getDoc(ref(C)));
  });

  it('is immutable — an editable uids array would be a way to rewrite '
    + 'who is friends with whom', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'friendships', pairKey(A, B)),
        friendshipDoc(A, B),
      );
    });
    const db = testEnv.authenticatedContext(A).firestore();
    await assertFails(
      updateDoc(doc(db, 'friendships', pairKey(A, B)), { uids: [A, C] }),
    );
  });

  it('can be deleted by either member and by nobody else — unfriending '
    + 'is mutual because there is only one document', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'friendships', pairKey(A, B)),
        friendshipDoc(A, B),
      );
    });
    const ref = (uid) =>
      doc(testEnv.authenticatedContext(uid).firestore(),
        'friendships', pairKey(A, B));
    await assertFails(deleteDoc(ref(C)));
    await assertSucceeds(deleteDoc(ref(B)));
  });
});
