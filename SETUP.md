# DriveRank — Production Service Setup

This checklist gets the three external services wired up: **Firebase**, **OneSignal**, and **RevenueCat**. Local prep is already done — the code reads config files / env vars and silently falls back to preview implementations when anything is missing, so the app keeps booting cleanly throughout setup.

Follow the sections in order. Each one ends with a one-line verification you can run before moving on.

---

## Security ground rules

- **Never paste raw secrets into chat or commit them.** Every secret file or string below either lands in a path that `.gitignore` already covers, or in a Codemagic environment-variable group.
- The `.gitignore` already protects:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `.env`, `.env.local`, `.env.production`
- If you screen-share or screenshot a console page, blur the API keys.

---

## 1. Firebase

Used for: Auth (Google sign-in), Firestore (trip sync + leaderboards), Analytics, Crashlytics.

### 1a. Create the Firebase project

1. Go to **https://console.firebase.google.com/** and click **Add project**.
2. Project name: `drive-rank` (or anything you like). Disable Google Analytics if you want a faster setup — you can add it later.
3. After creation, in the project sidebar enable each of:
   - **Build → Authentication → Get started**, then **Sign-in method → Google → Enable**. Set the project support email.
   - **Build → Firestore Database → Create database → Production mode → choose your region**. Picking close to your largest user base matters; you can't change it later.
   - **Release & Monitor → Crashlytics → Enable**.

### 1b. Generate the platform config files

Run from the project root on your machine (this opens a browser window for Google auth):

```bash
# One-time install
dart pub global activate flutterfire_cli

# Reads your Firebase projects and writes:
#   lib/firebase_options.dart
#   android/app/google-services.json
#   ios/Runner/GoogleService-Info.plist
flutterfire configure \
  --project=drive-rank \
  --platforms=android,ios \
  --android-app-id=com.bytse.drive_rank \
  --ios-bundle-id=com.bytse.driveRank
```

> If `flutterfire` isn't on your `PATH`, add `~/.pub-cache/bin` to your shell rc.

The CLI will ask you to confirm the project + platforms — say yes. When it finishes, those three files exist. Two of them are gitignored, one (`firebase_options.dart`) **is** committed because it doesn't contain secret keys — only the public app identifiers.

> Important: `firebase_options.dart` is in `.gitignore` in this repo by default (defensive). After `flutterfire configure` you'll need to **either** remove that line from `.gitignore` so the file is committed, **or** keep treating it as a per-environment file generated at build time on Codemagic too. Either is valid; for a small team the commit-it route is simpler.

### 1c. Local verification

```bash
flutter run -d <your-android-device>
```

Look in the console for `[bootstrap] Firebase initialised`. If you see `[bootstrap] Firebase init skipped — preview services in use.`, the config files aren't being picked up — check that `lib/firebase_options.dart` exists and `main.dart` imports it (or that bootstrap defaults work without explicit options).

### 1d. Codemagic wiring

In the Codemagic UI:

1. **Settings → Teams → <your-team> → Environment variables** → New group named `firebase_credentials`.
2. Add the following variables to the group (mark all of them **Secure**):
   - `FIREBASE_SERVICE_ACCOUNT` — paste `google-services.json` base64-encoded. Encode locally:
     ```bash
     base64 -i android/app/google-services.json | pbcopy
     ```
   - `FIREBASE_IOS_PLIST` — paste `GoogleService-Info.plist` base64-encoded.
3. The reference to this group is already in `codemagic.yaml` under both `android-release` and `ios-release` workflows, and decode steps already write the files into the correct path during the build.

---

## 2. OneSignal

Used for: push notifications (trip recap reminders, leaderboard pings).

### 2a. Create the OneSignal app

1. Sign up at **https://onesignal.com/** and create an app.
2. Pick **Google Android (FCM)** as the first platform.
   - Open **Firebase Console → Project settings → Cloud Messaging** and copy the **Server key** (or upload the service account JSON for FCM V1).
   - Paste it into OneSignal's setup wizard.
3. Add **Apple iOS (APNs)** as a second platform.
   - You'll need to upload an APNs Auth Key (`.p8` file) from your Apple Developer account → **Certificates, Identifiers & Profiles → Keys**. Recommended over per-app push certificates.
4. In **Settings → Keys & IDs**, copy the **OneSignal App ID** (a UUID).

### 2b. Wire the keys

Local (running on a device):

```bash
flutter run -d <device> --dart-define=ONESIGNAL_APP_ID=<your-uuid-here>
```

If you want this pre-filled in your editor's run config:
- **VS Code**: add to `.vscode/launch.json` under `args` for the relevant launch config (`.vscode/` is gitignored by default, so safe).
- **Android Studio**: Run → Edit Configurations → Additional run args.

Codemagic:

1. New env group `onesignal_keys` (already referenced in `codemagic.yaml`).
2. Add `ONESIGNAL_APP_ID` — paste the UUID, mark **Secure**.

### 2c. Verification

After launching with the env var set, the console prints `[bootstrap] OneSignal initialised`. The first time the app starts it'll request notification permission on iOS / Android 13+.

---

## 3. RevenueCat

Used for: paywall pricing + entitlement checks.

### 3a. Create the RevenueCat project

1. Sign up at **https://app.revenuecat.com/**. Create a new project named `drive-rank`.
2. Inside the project, add an app for each platform:
   - **Apple App Store**: enter your bundle id `com.bytse.driveRank`. Upload a shared secret from App Store Connect (Users and Access → Keys → In-App Purchase).
   - **Google Play Store**: enter your package name `com.bytse.drive_rank`. Upload your Google service account JSON with billing scope (or follow RevenueCat's "Set up Google" prompt).
3. **Entitlements** → Create one named exactly `pro` (lowercase). This name is referenced in code; if you rename it, also update `RevenueCatPaywallService.entitlementId`.
4. **Products** (under each app):
   - Create `driverank_pro_annual` (Auto-renewable subscription, 1 year, **$14.99 / year**).
   - Create `driverank_pro_monthly` (Auto-renewable subscription, 1 month, **$2.99 / month**).
   - These IDs are referenced in code (`RevenueCatPaywallService.annualProductId` / `monthlyProductId`). If you rename them in the dashboard, update those constants too.
   - Each product must also exist in App Store Connect / Play Console with the exact same identifier — RevenueCat will warn you if it can't see them.
   - DriveRank's annual price ($14.99) is deliberately below TripRank's ~$21/yr benchmark — keep it cheaper. RevenueCat auto-converts to local currencies, no further work needed.
5. **Offerings** → Create an offering named `default`. Attach both products to it as packages. Mark the offering as current.
6. **API keys**: in **Project settings → API keys**, you'll see two **public** keys (one per app). These are safe to ship in the binary — they only let the SDK talk to RevenueCat as a client. Copy:
   - Android key (looks like `goog_xxxxxxxxxx`)
   - iOS key (looks like `appl_xxxxxxxxxx`)

### 3b. Wire the keys

Local:

```bash
flutter run -d <android-device> \
  --dart-define=REVENUECAT_API_KEY_ANDROID=goog_xxxxxxxxxx
```

On iOS use `REVENUECAT_API_KEY_IOS=appl_xxxxxxxxxx` instead. You can pass both at once — bootstrap picks the right one based on platform.

Codemagic:

1. New env group `revenuecat_keys` (already referenced in `codemagic.yaml`).
2. Add `REVENUECAT_API_KEY_ANDROID` and `REVENUECAT_API_KEY_IOS`, both **Secure**.

### 3c. Verification

After launching with the env var set, console prints `[bootstrap] RevenueCat initialised`. Open the paywall (Profile → Go Pro, or after 10 free trips) — the prices shown should now be the real prices set in App Store Connect / Play Console (not the preview tier table). Cancel the purchase dialog when it appears; running a real test purchase is a separate step (see RevenueCat's sandbox-tester docs).

---

## 4. Play Store / App Store publishing (Codemagic)

The `codemagic.yaml` already has `publishing.google_play` and `publishing.app_store_connect` blocks. To activate them:

### Google Play

1. Create the app draft in **Google Play Console** — package name must be exactly `com.bytse.drive_rank`. Fill the **App content** sections (privacy policy URL, data safety, etc.) — Google won't let you publish without these.
2. Create a **Service account** with **Release manager** role: **Setup → API access → Create new service account** → Google Cloud Console → grant **Service Account User** + **Editor**. Download the JSON.
3. Codemagic UI → env group `google_play` → add `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` with the JSON content, **Secure**.
4. First Codemagic build for `main` will push to the **internal** track as a **draft** (per the yaml). Promote to closed testing / production manually inside the Play Console for the first release.

### App Store Connect

1. Create the app in **App Store Connect** — bundle id `com.bytse.driveRank`, SKU `drive-rank`.
2. **Codemagic UI → Teams → Integrations → App Store Connect** → connect a key (you'll need an API key from App Store Connect → Users and Access → Integrations). The yaml's `integrations: app_store_connect: codemagic` line picks this up automatically.
3. The `ios-release` workflow only triggers on `v*` tags, so tag a release with `git tag v1.0.0 && git push --tags`.

---

## 5. Where to find things later

| What | Where |
|------|-------|
| Firebase project | console.firebase.google.com |
| Firestore data + rules | Firebase console → Build → Firestore |
| Crashlytics dashboard | Firebase console → Release & Monitor → Crashlytics |
| Analytics events | Firebase console → Analytics → Events |
| OneSignal dashboard | onesignal.com → your app → Audience / Messages |
| RevenueCat dashboard | app.revenuecat.com → drive-rank |
| Codemagic builds | codemagic.io → your project → Builds |
| Play Console | play.google.com/console → DriveRank |
| App Store Connect | appstoreconnect.apple.com → My Apps → DriveRank |

---

## 6. Troubleshooting checklist

- **`[bootstrap] Firebase init skipped`** — `lib/firebase_options.dart` missing or it references a project the device's Google services don't recognise. Re-run `flutterfire configure`.
- **`Google Sign-In failed` on Android only** — Open Firebase Console → Project settings → Your apps → Android app → **SHA certificate fingerprints** and add your debug SHA-1 (run `cd android && ./gradlew signingReport`). Without this, the Google sign-in popup closes immediately on Android.
- **`Google Sign-In failed` on iOS only** — `GoogleService-Info.plist` is missing `REVERSED_CLIENT_ID` or your Xcode project is missing the matching URL scheme. `flutterfire configure` writes the plist correctly; if you hand-edit it you'll need to also add the URL scheme manually in Xcode.
- **Paywall still shows preview prices after RevenueCat setup** — your offering isn't marked `current` in the dashboard, or your products aren't approved in App Store Connect / Play Console yet. Both are required.
- **OneSignal isn't getting push tokens** — on Android, FCM credentials in the OneSignal dashboard aren't matching the Firebase project that's actually installed. Re-upload the FCM v1 service account JSON from this project's Firebase Cloud Messaging settings.

---

## Quick recap of what bootstrap looks for

| Env var / file | Wires up |
|----|----|
| `lib/firebase_options.dart` + native config files | Firebase Auth, Firestore, Analytics, Crashlytics |
| `--dart-define=ONESIGNAL_APP_ID=...` | Push notifications |
| `--dart-define=REVENUECAT_API_KEY_ANDROID=...` | RevenueCat on Android |
| `--dart-define=REVENUECAT_API_KEY_IOS=...` | RevenueCat on iOS |

Any combination is valid — missing pieces fall back to the local-only preview services, the app continues to run.
