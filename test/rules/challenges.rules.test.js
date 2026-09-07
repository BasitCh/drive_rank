'use strict';

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, deleteDoc, updateDoc } = require('firebase/firestore');

// A challenge is the first record in this app whose outcome depends on
// two people's writes. Everything else is an account writing its own
// values and a reader ordering them; nobody's document decides anybody
// else's. So the deny side here is the point of the suite, and the
// single most important case is the last group: **B must not be able to
// write A's figure, in any shape.**

let testEnv;

const A = 'aaa-alice';
const B = 'bbb-bob';
const C = 'ccc-carol';

const pair = (x, y) => [x, y].sort();
const pairKey = (x, y) => pair(x, y).join('_');

const CHALLENGE = 'challenge-1';
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

/** Six hours — must equal kChallengeFinalizationGrace in Dart. */
const GRACE = 6 * HOUR;

function challengeDoc(overrides = {}) {
  const now = new Date();
  return {
    participants: pair(A, B),
    creatorUid: A,
    opponentUid: B,
    metric: 'distance',
    targetValue: 100,
    period: 'weekly',
    startAt: now,
    endAt: new Date(now.getTime() + 3 * DAY),
    status: 'pending',
    createdAt: now,
    updatedAt: now,
    ...overrides,
  };
}

const asUser = (uid) => doc(testEnv.authenticatedContext(uid).firestore(), 'challenges', CHALLENGE);
const progressAs = (uid, ownerUid) =>
  doc(
    testEnv.authenticatedContext(uid).firestore(),
    'challenges',
    CHALLENGE,
    'progress',
    ownerUid,
  );

/** Puts a friendship in place without going through the rules. */
async function seedFriendship(x, y) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'friendships', pairKey(x, y)), {
      uids: pair(x, y),
      createdAt: new Date(),
    });
  });
}

async function seedChallenge(overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(
      doc(ctx.firestore(), 'challenges', CHALLENGE),
      challengeDoc(overrides),
    );
  });
}

async function seedProgress(ownerUid, value) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(
      doc(ctx.firestore(), 'challenges', CHALLENGE, 'progress', ownerUid),
      { value, updatedAt: new Date() },
    );
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'drive-rank-challenges-test',
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

describe('opening a challenge', () => {
  beforeEach(() => seedFriendship(A, B));

  it('lets the creator open one against a friend', async () => {
    await assertSucceeds(setDoc(asUser(A), challengeDoc()));
  });

  it('refuses one against somebody you are not friends with — a random '
    + 'account must not be able to challenge you unbidden', async () => {
    await testEnv.clearFirestore();
    await assertFails(setDoc(asUser(A), challengeDoc()));
  });

  it('refuses one opened on somebody else\'s behalf', async () => {
    await assertFails(setDoc(asUser(B), challengeDoc()));
    await assertFails(setDoc(asUser(C), challengeDoc()));
  });

  it('refuses a challenge against yourself', async () => {
    await assertFails(
      setDoc(asUser(A), challengeDoc({ opponentUid: A, participants: [A, A] })),
    );
  });

  it('refuses participants that disagree with the named pair — the '
    + 'array is what every other rule reads', async () => {
    await assertFails(
      setDoc(asUser(A), challengeDoc({ participants: pair(A, C) })),
    );
  });

  it('refuses a status other than pending, so a challenge cannot be '
    + 'born already accepted', async () => {
    await assertFails(setDoc(asUser(A), challengeDoc({ status: 'active' })));
    await assertFails(setDoc(asUser(A), challengeDoc({ status: 'declined' })));
  });

  it('refuses a backdated startAt — the creator picks when to '
    + 'challenge, and must not also pick which of their past driving '
    + 'counts', async () => {
    const now = new Date();
    await assertFails(
      setDoc(
        asUser(A),
        challengeDoc({
          startAt: new Date(now.getTime() - 3 * DAY),
          endAt: new Date(now.getTime() + 3 * DAY),
        }),
      ),
    );
  });

  it('refuses an endAt so far out the challenge would never settle',
    async () => {
      const now = new Date();
      await assertFails(
        setDoc(
          asUser(A),
          challengeDoc({ endAt: new Date(now.getTime() + 500 * DAY) }),
        ),
      );
    });

  it('refuses an endAt at or before the start', async () => {
    const now = new Date();
    await assertFails(
      setDoc(asUser(A), challengeDoc({ endAt: now, startAt: now })),
    );
  });

  it('refuses a target of zero or less', async () => {
    await assertFails(setDoc(asUser(A), challengeDoc({ targetValue: 0 })));
    await assertFails(setDoc(asUser(A), challengeDoc({ targetValue: -5 })));
  });

  it('refuses unknown fields — including any attempt to smuggle in a '
    + 'winner', async () => {
    await assertFails(
      setDoc(asUser(A), challengeDoc({ winnerUid: A })),
    );
  });
});

describe('reading a challenge', () => {
  beforeEach(async () => {
    await seedFriendship(A, B);
    await seedChallenge();
  });

  it('lets both participants read it and nobody else', async () => {
    await assertSucceeds(getDoc(asUser(A)));
    await assertSucceeds(getDoc(asUser(B)));
    await assertFails(getDoc(asUser(C)));
  });
});

describe('answering a challenge', () => {
  beforeEach(async () => {
    await seedFriendship(A, B);
    await seedChallenge();
  });

  it('lets the opponent accept while the window is open', async () => {
    await assertSucceeds(
      updateDoc(asUser(B), { status: 'active', updatedAt: new Date() }),
    );
  });

  it('lets the opponent decline', async () => {
    await assertSucceeds(
      updateDoc(asUser(B), { status: 'declined', updatedAt: new Date() }),
    );
  });

  it('refuses an accept by the creator — you cannot accept your own '
    + 'challenge', async () => {
    await assertFails(
      updateDoc(asUser(A), { status: 'active', updatedAt: new Date() }),
    );
  });

  it('refuses an accept by an unrelated user', async () => {
    await assertFails(
      updateDoc(asUser(C), { status: 'active', updatedAt: new Date() }),
    );
  });

  it('lets the creator cancel, but not the opponent', async () => {
    await assertFails(
      updateDoc(asUser(B), { status: 'cancelled', updatedAt: new Date() }),
    );
    await assertSucceeds(
      updateDoc(asUser(A), { status: 'cancelled', updatedAt: new Date() }),
    );
  });

  it('treats answered challenges as terminal — nothing re-opens one',
    async () => {
      await assertSucceeds(
        updateDoc(asUser(B), { status: 'active', updatedAt: new Date() }),
      );
      await assertFails(
        updateDoc(asUser(B), { status: 'declined', updatedAt: new Date() }),
      );
      await assertFails(
        updateDoc(asUser(A), { status: 'cancelled', updatedAt: new Date() }),
      );
    });

  it('refuses completed and expired outright — an outcome is derived '
    + 'from the two frozen figures, never written, so there is no '
    + 'terminal state here for anybody to fabricate', async () => {
    await assertFails(
      updateDoc(asUser(A), { status: 'completed', updatedAt: new Date() }),
    );
    await assertFails(
      updateDoc(asUser(B), { status: 'completed', updatedAt: new Date() }),
    );
    await assertFails(
      updateDoc(asUser(B), { status: 'expired', updatedAt: new Date() }),
    );
  });

  it('never allows a delete, so a loss cannot be made to disappear',
    async () => {
      await assertFails(deleteDoc(asUser(A)));
      await assertFails(deleteDoc(asUser(B)));
      await assertFails(deleteDoc(asUser(C)));
    });

  describe('acceptance closes with the window', () => {
    beforeEach(async () => {
      const now = new Date();
      await seedChallenge({
        startAt: new Date(now.getTime() - 2 * DAY),
        endAt: new Date(now.getTime() - HOUR),
      });
    });

    it('refuses an accept after endAt — both participants have to agree '
      + 'to compete BEFORE the competition ends, or a challenge left '
      + 'pending until 23:59 Sunday could be accepted at 01:00 Monday '
      + 'and then have progress published during the grace, competing '
      + 'entirely after the window it was meant to measure', async () => {
      await assertFails(
        updateDoc(asUser(B), { status: 'active', updatedAt: new Date() }),
      );
    });

    it('still lets it be declined or cancelled — those only tidy a dead '
      + 'challenge away and cannot manufacture a result', async () => {
      await assertSucceeds(
        updateDoc(asUser(B), { status: 'declined', updatedAt: new Date() }),
      );
      await seedChallenge({
        startAt: new Date(Date.now() - 2 * DAY),
        endAt: new Date(Date.now() - HOUR),
      });
      await assertSucceeds(
        updateDoc(asUser(A), { status: 'cancelled', updatedAt: new Date() }),
      );
    });
  });
});

describe('the terms, once written', () => {
  beforeEach(async () => {
    await seedFriendship(A, B);
    await seedChallenge();
  });

  const mutations = {
    'the target': { targetValue: 1 },
    'the metric': { metric: 'consistency' },
    'the period': { period: 'monthly' },
    'the participants': { participants: pair(A, C) },
    'the opponent': { opponentUid: C },
    'the creator': { creatorUid: C },
    'the start': { startAt: new Date(Date.now() - 5 * DAY) },
    'the end': { endAt: new Date(Date.now() + 60 * DAY) },
    'createdAt': { createdAt: new Date(0) },
  };

  for (const [what, change] of Object.entries(mutations)) {
    it(`refuses a change to ${what}, by either party`, async () => {
      await assertFails(
        updateDoc(asUser(A), { status: 'cancelled', ...change }),
      );
      await assertFails(
        updateDoc(asUser(B), { status: 'active', ...change }),
      );
    });
  }
});

describe('progress — the security boundary of the phase', () => {
  beforeEach(async () => {
    await seedFriendship(A, B);
    await seedChallenge({ status: 'active' });
  });

  it('lets each participant write their own figure', async () => {
    await assertSucceeds(
      setDoc(progressAs(A, A), { value: 120, updatedAt: new Date() }),
    );
    await assertSucceeds(
      setDoc(progressAs(B, B), { value: 90, updatedAt: new Date() }),
    );
  });

  it('REFUSES B writing A\'s figure — in any shape. This is the one '
    + 'that matters: it is the whole reason no winner is stored',
    async () => {
      await assertFails(
        setDoc(progressAs(B, A), { value: 0, updatedAt: new Date() }),
      );
      await assertFails(
        setDoc(progressAs(A, B), { value: 9999, updatedAt: new Date() }),
      );
      // …and not by updating an existing one either.
      await seedProgress(A, 500);
      await assertFails(
        updateDoc(progressAs(B, A), { value: 1, updatedAt: new Date() }),
      );
    });

  it('refuses a third party entirely', async () => {
    await assertFails(
      setDoc(progressAs(C, C), { value: 100, updatedAt: new Date() }),
    );
    await assertFails(
      setDoc(progressAs(C, A), { value: 0, updatedAt: new Date() }),
    );
    await seedProgress(A, 100);
    await assertFails(getDoc(progressAs(C, A)));
  });

  it('lets both participants read both figures — a result nobody can '
    + 'read is a result nobody can derive', async () => {
    await seedProgress(A, 120);
    await seedProgress(B, 90);
    await assertSucceeds(getDoc(progressAs(A, A)));
    await assertSucceeds(getDoc(progressAs(A, B)));
    await assertSucceeds(getDoc(progressAs(B, A)));
    await assertSucceeds(getDoc(progressAs(B, B)));
  });

  it('allows a figure to go DOWN — deleting a trip must lower it, '
    + 'which is this feature\'s load-bearing rule, so progress is '
    + 'deliberately not monotonic', async () => {
    await assertSucceeds(
      setDoc(progressAs(A, A), { value: 500, updatedAt: new Date() }),
    );
    await assertSucceeds(
      setDoc(progressAs(A, A), { value: 420, updatedAt: new Date() }),
    );
  });

  it('refuses a negative figure', async () => {
    await assertFails(
      setDoc(progressAs(A, A), { value: -1, updatedAt: new Date() }),
    );
  });

  it('refuses unknown fields, including a winner', async () => {
    await assertFails(
      setDoc(progressAs(A, A), {
        value: 100,
        updatedAt: new Date(),
        winner: A,
      }),
    );
  });

  it('refuses progress on a challenge nobody accepted — a pending '
    + 'challenge is not a competition', async () => {
    await seedChallenge({ status: 'pending' });
    await assertFails(
      setDoc(progressAs(A, A), { value: 100, updatedAt: new Date() }),
    );
  });

  it('refuses progress on a declined or cancelled challenge', async () => {
    await seedChallenge({ status: 'declined' });
    await assertFails(
      setDoc(progressAs(A, A), { value: 100, updatedAt: new Date() }),
    );
    await seedChallenge({ status: 'cancelled' });
    await assertFails(
      setDoc(progressAs(A, A), { value: 100, updatedAt: new Date() }),
    );
  });
});

describe('the finalization boundary', () => {
  beforeEach(() => seedFriendship(A, B));

  it('accepts a write during the grace — the competition is over but a '
    + 'drive taken immediately before endAt may still need publishing',
    async () => {
      const now = new Date();
      await seedChallenge({
        status: 'active',
        startAt: new Date(now.getTime() - 3 * DAY),
        // Closed an hour ago, so we are inside the six-hour grace.
        endAt: new Date(now.getTime() - HOUR),
      });
      await assertSucceeds(
        setDoc(progressAs(A, A), { value: 120, updatedAt: now }),
      );
    });

  it('accepts a write in the last minute of the grace', async () => {
    const now = new Date();
    await seedChallenge({
      status: 'active',
      startAt: new Date(now.getTime() - 3 * DAY),
      endAt: new Date(now.getTime() - GRACE + 60 * 1000),
    });
    await assertSucceeds(
      setDoc(progressAs(A, A), { value: 120, updatedAt: now }),
    );
  });

  it('REFUSES a write once the grace has elapsed — this is what stops a '
    + 'loser rewriting a settled result, and it is the same boundary '
    + 'kChallengeFinalizationGrace uses in Dart', async () => {
    const now = new Date();
    await seedChallenge({
      status: 'active',
      startAt: new Date(now.getTime() - 5 * DAY),
      endAt: new Date(now.getTime() - GRACE - 60 * 1000),
    });
    await assertFails(
      setDoc(progressAs(A, A), { value: 9999, updatedAt: now }),
    );
  });

  it('refuses it even to somebody who already had a figure there — the '
    + 'winner cannot change after the freeze', async () => {
    const now = new Date();
    await seedChallenge({
      status: 'active',
      startAt: new Date(now.getTime() - 5 * DAY),
      endAt: new Date(now.getTime() - GRACE - HOUR),
    });
    await seedProgress(A, 100);
    await assertFails(
      updateDoc(progressAs(A, A), { value: 9999, updatedAt: now }),
    );
  });

  it('still lets both sides read a frozen result', async () => {
    const now = new Date();
    await seedChallenge({
      status: 'active',
      startAt: new Date(now.getTime() - 5 * DAY),
      endAt: new Date(now.getTime() - GRACE - HOUR),
    });
    await seedProgress(A, 100);
    await seedProgress(B, 120);
    await assertSucceeds(getDoc(progressAs(A, B)));
    await assertSucceeds(getDoc(progressAs(B, A)));
  });
});

describe('unfriending does not cancel an active challenge', () => {
  it('leaves both sides able to publish and to read — an accidental '
    + 'unfriend, or a fallout mid-week, must not destroy a live '
    + 'competition or freeze one person\'s figure while the other\'s '
    + 'keeps moving. The friendship is a creation-time precondition '
    + 'only', async () => {
    await seedFriendship(A, B);
    await seedChallenge({ status: 'active' });
    await seedProgress(A, 100);

    // They fall out. The friendship goes; the challenge does not.
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await deleteDoc(doc(ctx.firestore(), 'friendships', pairKey(A, B)));
    });

    await assertSucceeds(
      setDoc(progressAs(A, A), { value: 140, updatedAt: new Date() }),
    );
    await assertSucceeds(
      setDoc(progressAs(B, B), { value: 90, updatedAt: new Date() }),
    );
    await assertSucceeds(getDoc(progressAs(A, B)));
    await assertSucceeds(getDoc(progressAs(B, A)));
    await assertSucceeds(getDoc(asUser(A)));
  });

  it('but a NEW challenge between them is refused, because creation is '
    + 'where the friendship is required', async () => {
    await assertFails(setDoc(asUser(A), challengeDoc()));
  });
});
