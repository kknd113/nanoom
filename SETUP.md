# Nanoom — setup and handoff

The brand is Nanoom / 나눔. The existing `With` project and scheme names below are internal development identifiers. Final Bundle IDs have not been registered.

## 1. Run the verified native demo

Verified on October 27, 2026: Xcode 27.1, Swift 6.4, iPhone 18 Pro with iOS 27.0. The demo built and launched, and all three unit tests passed. Open Xcode and complete any first-launch setup on a new machine. No new agreement was accepted by the agent.

Then try:

```sh
xcodebuild -list -project With.xcodeproj
xcodebuild -showdestinations -project With.xcodeproj -scheme WithDemo
```

Pick an installed iPhone simulator in Xcode. Build and run WithDemo. For CLI tests, substitute an actual available simulator UUID:

```sh
xcodebuild test -project With.xcodeproj -scheme WithDemo \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UUID' \
  -derivedDataPath work/DerivedData CODE_SIGNING_ALLOWED=NO
```

The previous restricted-agent run failed to start Swift macro plugins and CoreSimulator services. A subsequent run with approved Xcode/Simulator access succeeded. If running inside a sandboxed agent, permit the normal Xcode tools to access those services rather than disabling compiler sandbox protections.

## 2. Connect the optional live project later

1. Enroll/select your Apple Developer team, choose the final bundle ID, and enable Sign in with Apple for that App ID.
2. Create a Firebase project and register that exact iOS bundle ID. Enable Apple under Firebase Authentication.
3. Open `WithLive.xcodeproj`. Xcode will download the declared Firebase SPM products: FirebaseCore, FirebaseAuth, FirebaseFirestore.
4. Add `GoogleService-Info.plist` to the **WithLive** target’s Copy Bundle Resources. The expected local path is `Configuration/GoogleService-Info.plist`; it is ignored by Git. No fake config is included.
5. Select your Team and actual bundle ID under Signing & Capabilities. The live target includes the Apple sign-in entitlement.
6. Test on a real iPhone. Apple identity tokens are exchanged with Firebase using a fresh secure nonce; users are identified by Firebase UID, never by email.

Current SDK version declaration was checked against [Firebase’s official releases](https://github.com/firebase/firebase-ios-sdk/releases/tag/13.1.1). Download and package resolution are pending, so there is no fabricated Package.resolved.

## 3. Provision only a private development group

Until invite redemption is implemented, a trusted admin/server must create:

```text
users/{uid}/groupMemberships/{groupID}
groups/{groupID}                         name
groups/{groupID}/members/{uid}           displayName, role
```

Use the authenticated account’s actual Firebase UID. Do not open database rules or let a client grant itself membership just to bypass onboarding. Group roles and denormalized membership records must be provisioned together by trusted code.

The adapter reads prayers and their update/reaction subcollections. No email or phone is copied into member documents. It currently refreshes on actions/pull-to-refresh and loads up to 100 prayers; realtime listeners and pagination remain work.

## 4. Finish before shipping

- Display-name confirmation and persisted auth-state restoration.
- Server-issued, expiring, revocable invitation tokens and authenticated redemption.
- Owner/member role boundaries and group leave/removal, tested against revoked membership.
- Recursive prayer cleanup and user account deletion, including Apple token revocation where required.
- Private per-account drafts and cache clearing on logout; do not use development UserDefaults for real prayer content.
- Permission-denial / offline / retry behavior, rules emulator tests, actual iPhone visual QA.
- App icon, final branding, privacy disclosures, and appropriate reporting/blocking behavior for shared user content.
- TestFlight and review configuration after choosing the final identity.

## References

- [Firebase Apple SDK setup](https://firebase.google.com/docs/ios/setup)
- [Apple authentication with Firebase](https://firebase.google.com/docs/auth/ios/apple)
- [Firestore rule conditions](https://firebase.google.com/docs/firestore/security/rules-conditions)
- [Apple account deletion guidance](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
