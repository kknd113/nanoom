# Nanoom live setup

Configured October 27, 2026. Firebase project `nanoom-kknd113`; iOS app `1:174996274388:ios:ae7702791dcc44edf50f41`; bundle ID `com.kknd113.nanoom`; Standard Firestore `(default)` in `us-west2`, confirmed `freeTier: true`. Billing was not enabled.

## Local run

Open WithLive.xcodeproj and Run WithLive on an installed iPhone simulator. This uses the real cloud service. Continue with email → create account → create group. A second account can join using a creator-issued link from group settings. The HTTPS page hands off through nanoom://join?code=…; after sign-in the app shows a group preview and explicit Join button. Pull down to fetch other people's changes. Quit/relaunch restores the Firebase account session.

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
  -derivedDataPath work/LiveDerivedData build
```

The local sample remains available separately as With.xcodeproj / WithDemo. Scripts/generate-project.cjs only regenerates that demo project; the configured Live project is maintained through native Xcode/Swift tooling.

## Simulator signing and Keychain

The Live simulator build must remain locally signed. Do **not** pass `CODE_SIGNING_ALLOWED=NO`: that removes the identity/Keychain entitlements Firebase Auth needs to persist sessions, producing `SecItemCopyMatching (-34018)` / Firebase error 17995. This does not require a paid Apple membership.

`Configuration/WithSimulator.entitlements` scopes Keychain access to the app's own bundle identifier. Conditional simulator build settings enable ad-hoc signing and this entitlement file. Physical-device builds still use the chosen development team and normal provisioning. `swift Scripts/configure-simulator-signing.swift` reapplies these settings using native plist APIs.

Debug simulator builds include an opt-in native Firebase verification. On a simulator with no account signed in, launch the app with `--verify-native-auth-create` to create a disposable synthetic account, sign out and sign back in. Wait for the `NANOOM_AUTH_CHECK PASS` log. Then terminate and relaunch with `--verify-native-auth-restore-and-clean`; it checks that the synthetic session survived process restart and deletes only that synthetic account. Normal accounts are never signed out or deleted by this verification. These switches are excluded from Release and physical-device builds.

## Backend configuration

Backend/firebase.json enables email/password and points to the deployed rules/index definitions. Deploy explicitly from Backend:

```sh
npx -y firebase-tools@latest deploy --only auth,firestore --project nanoom-kknd113
```

No Cloud Functions, SMS or billing-dependent services were provisioned. Basic group operations use client SDK atomic batches protected by rules. A membership-index document alone grants no access; the matching member document must be created with a valid invitation or as the creator of a new group. Email remains inside Firebase Auth and is not copied to shared documents. Shared member records contain only display names, invitation IDs and join timestamps.

## Verification

58 real-cloud checks passed using synthetic accounts. Backend/tests/live-smoke.mjs accepts FIREBASE_CONFIG JSON and CLEANUP_FILE environment variables and requires the Firebase JS client SDK. It creates a uniquely named `verification-*` group, uses no real prayer data, never sends email and deletes its Auth accounts in finally. Remove the reported synthetic group and private membership-index records with trusted Firebase CLI `firestore:delete <path> --recursive --force` after a run. Do not run this against user data or substitute existing user IDs.

Covered: real app queries, atomic group creation/join, invite expiry constraints and revocation, outsider/unauthenticated access, fake membership index, private user records, ownership spoofing, immutable fields, unknown/missing fields, create/update length/type validation, append-only author updates, reaction duplication/self-reaction, deleted/orphan thread access and revival denial. No counters, role transitions, arrays or user-controlled external paths exist in this schema. These checks do not prove abuse resistance or exhaustively prove security.

I've set up prototype Security Rules to keep the data in Firestore safe. They are designed to be secure for authenticated private groups, invitation-bound membership, and author-owned prayer changes. However, you should review and verify them before broadly sharing your app. If you'd like, I can help you harden these rules.

## Remaining work

- Account deletion and group leave/removal with correct lifecycle handling.
- Recursive physical cleanup: soft-deleted prayer bodies are erased, but child updates remain stored and blocked by rules. A trusted cleanup service is needed for full erasure.
- Realtime listeners, paging beyond the first 100 prayer documents and explicit group selection.
- Anti-abuse/App Check rollout and broader emulator/rules regression coverage.
- Live private drafts, real-device/offline QA, final icon/privacy disclosures and store readiness.

Auth state persists securely through the SDK. Firestore persistence is memory-only to avoid retaining prayer content on disk; signing out clears app-visible group state. No service-account credentials, login tokens or passwords belong in Git.

## Invitation links and profile photos

Share URLs use `https://nanoom-kknd113.web.app/join#<token>`. The token stays in the fragment, so it is not sent in Hosting requests or referrers. The static page has no analytics, third-party assets or database requests. It provides an explicit Open Nanoom link to `nanoom://join?code=<token>`. Links do not bypass authentication or the explicit Join confirmation. Invalid, expired and revoked tokens fail on the server.

This is the installed-app handoff available without paid Apple capabilities. Universal Links that open directly from HTTPS require a real Apple team/app association and remain a later distribution step. No deferred-install handoff is claimed: a person who has not installed Nanoom must obtain the private test build and reopen the invitation.

Only WithLive registers the nanoom URL scheme, through Configuration/WithLive-Info.plist. WithDemo uses the separate base Info.plist and must not intercept real invites. The exact app host/path and token format are allowlisted; arbitrary URLs and duplicate token parameters are rejected. Pending invitation tokens persist until explicit join or cancellation; they are not prayer content.

Profile photos live at groups/{groupID}/memberPhotos/{uid}, separate from member identity documents. Only members may read them, and only the member matching the document UID may create/update/delete them. Photos are optional and per circle. The native picker grants access only to selected items. ImageIO downsamples and normalizes orientation, then a crop editor renders a metadata-free 256px JPEG no larger than 64 KiB. The UI shows initials if no decodable image exists. Rules enforce byte type, maximum size, schema and timestamps; they do not inspect JPEG contents. Images are excluded from Firestore indexing.

Small avatars use existing Spark Firestore rather than provisioning Cloud Storage, which currently requires Blaze. This is suitable for the initial small-circle pilot; image transfer still counts against the project's normal Firestore quotas. Reassess storage and lazy photo loading before scaling. Photos remain access-controlled, not end-to-end encrypted.

Deployed classic Hosting source: Backend/Hosting. To deploy link-page changes from Backend: `npx -y firebase-tools@latest deploy --only hosting --project nanoom-kknd113`.
