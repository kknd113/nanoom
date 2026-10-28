# Nanoom live setup

Configured October 27, 2026. Firebase project `nanoom-kknd113`; iOS app `1:174996274388:ios:ae7702791dcc44edf50f41`; bundle ID `com.kknd113.nanoom`; Standard Firestore `(default)` in `us-west2`, confirmed `freeTier: true`. Billing was not enabled.

## Local run

Open WithLive.xcodeproj and Run WithLive on an installed iPhone simulator. This uses the real cloud service. Continue with email → create account → create group. A second account can join using a creator-issued code from group settings. Pull down to fetch other people's changes. Quit/relaunch restores the Firebase account session.

The Firebase configuration at `Configuration/GoogleService-Info.plist` is intentionally Git-ignored. On another machine, authenticate with the Firebase CLI and download it:

```sh
npx -y firebase-tools@latest login
npx -y firebase-tools@latest apps:sdkconfig IOS 1:174996274388:ios:ae7702791dcc44edf50f41 --project nanoom-kknd113 > Configuration/GoogleService-Info.plist
```

The file reference is already in the Live target's resources. FirebaseCore/Auth/Firestore 13.1.1 are linked through SPM with `-ObjC`. Package.resolved records the tested dependency graph. Live signing does not use the Apple sign-in entitlement. For physical iPhone testing choose your own Xcode Personal Team; device provisioning restrictions still apply. TestFlight/App Store delivery requires paid Apple membership.

Build:

```sh
xcodebuild -project WithLive.xcodeproj -scheme WithLive -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath work/LiveDerivedData CODE_SIGNING_ALLOWED=NO build
```

The local sample remains available separately as With.xcodeproj / WithDemo. Scripts/generate-project.cjs only regenerates that demo project; the configured Live project is maintained through native Xcode/Swift tooling.

## Backend configuration

Backend/firebase.json enables email/password and points to the deployed rules/index definitions. Deploy explicitly from Backend:

```sh
npx -y firebase-tools@latest deploy --only auth,firestore --project nanoom-kknd113
```

No Cloud Functions, SMS or billing-dependent services were provisioned. Basic group operations use client SDK atomic batches protected by rules. A membership-index document alone grants no access; the matching member document must be created with a valid invitation or as the creator of a new group. Email remains inside Firebase Auth and is not copied to shared documents. Shared member records contain only display names, invitation IDs and join timestamps.

## Verification

43 real-cloud checks passed using synthetic accounts. Backend/tests/live-smoke.mjs accepts FIREBASE_CONFIG JSON and CLEANUP_FILE environment variables and requires the Firebase JS client SDK. It creates a uniquely named `verification-*` group, uses no real prayer data, never sends email and deletes its Auth accounts in finally. Remove the reported synthetic group and private membership-index records with trusted Firebase CLI `firestore:delete <path> --recursive --force` after a run. Do not run this against user data or substitute existing user IDs.

Covered: real app queries, atomic group creation/join, invite expiry constraints and revocation, outsider/unauthenticated access, fake membership index, private user records, ownership spoofing, immutable fields, unknown/missing fields, create/update length/type validation, append-only author updates, reaction duplication/self-reaction, deleted/orphan thread access and revival denial. No counters, role transitions, arrays or user-controlled external paths exist in this schema. These checks do not prove abuse resistance or exhaustively prove security.

I've set up prototype Security Rules to keep the data in Firestore safe. They are designed to be secure for authenticated private groups, invitation-bound membership, and author-owned prayer changes. However, you should review and verify them before broadly sharing your app. If you'd like, I can help you harden these rules.

## Remaining work

- Account deletion and group leave/removal with correct lifecycle handling.
- Recursive physical cleanup: soft-deleted prayer bodies are erased, but child updates remain stored and blocked by rules. A trusted cleanup service is needed for full erasure.
- Realtime listeners, paging beyond the first 100 prayer documents and explicit group selection.
- Anti-abuse/App Check rollout and broader emulator/rules regression coverage.
- Live private drafts, real-device/offline QA, final icon/privacy disclosures and store readiness.

Auth state persists securely through the SDK. Firestore persistence is memory-only to avoid retaining prayer content on disk; signing out clears app-visible group state. No service-account credentials, login tokens or passwords belong in Git.
