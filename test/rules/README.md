# Firestore security-rules tests

The Phase 4 trust model *is* `firestore.rules`: who may write a
competitive value, who may read one, and who may claim a username. None
of that is expressible in Dart, and none of it is verifiable by reading
the file, so it gets its own suite here.

These can't run inside `flutter test` — rules execute in the Firestore
emulator, not in the app — so they are Node, run through the Firebase
CLI.

## Run them

```sh
cd test/rules && npm install          # once
firebase emulators:exec --only firestore "npm --prefix test/rules test"
```

Run that second command from the repository root. `emulators:exec`
starts the emulator, runs the suite against it, and shuts it down, so
there is no long-running process to remember to kill.

Requires the Firebase CLI (`npm i -g firebase-tools`) and a JDK, which
the emulator needs. No Firebase login and no network are needed — the
emulator serves `firestore.rules` from disk.

## What the suite pins

Allow/deny pairs, because a rule that permits the right thing while also
permitting the wrong thing passes a one-sided test:

* a user writes their own public profile — and cannot write anyone
  else's
* a field outside the whitelist is rejected, so the public mirror can't
  become general-purpose user-writable storage
* any signed-in user reads any public profile; an unauthenticated client
  reads nothing
* a free username can be claimed, one already held cannot, and an
  existing claim can never be updated or deleted
* the pre-existing private boundary still holds: no user can read
  another's `users/{uid}` document or their trips

That last group is the regression net. It is the rule most likely to be
loosened by accident while adding a Phase 4 collection next to it.
