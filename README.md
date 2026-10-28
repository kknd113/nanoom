# Nanoom — iPhone native starter

Brand confirmed on October 27, 2026: **Nanoom / 나눔**. Wordmark: **nanoom**. SwiftUI, iOS 18+, English UI, Korean content supported. Existing internal project, scheme, and type names retain `With`; the installed app name and visible wordmark use Nanoom.

## What is prepared

- **With.xcodeproj / WithDemo**: native local demo, no remote packages or accounts required.
- **WithLive.xcodeproj / WithLive**: separate Firebase adapter scaffold with Apple sign-in. Firebase is declared through Swift Package Manager at exact version **13.1.1**. Dependencies have **not** been downloaded or resolved in this environment.
- Person-first circle, prayer detail, reaction, author updates, My prayers, create/edit/delete in the demo.
- Local demo persistence, draft restoration, native sheets, haptics, dark mode, and an accessible grid alternative for large text / larger groups.
- Repository boundary, unit-test sources, and a deny-by-default Firestore rules draft.

## Start here

1. Open **Xcode** and complete first-launch setup if needed.
2. Select an installed iPhone simulator; the verified run used iPhone 18 Pro with iOS 27.0.
3. Open `With.xcodeproj`, select **WithDemo**, select an iPhone simulator, then Run.
4. Choose **Explore Grace Group**. This is an explicitly labeled sample group; no real login occurs.
5. Product → Test runs the repository tests once Xcode is ready.

**Demo build and simulator launch verified on October 27, 2026.** Xcode 27.1 / Swift 6.4 built WithDemo successfully. The app was installed and launched on iPhone 18 Pro (iOS 27.0), and its native welcome/composer UI was observed. All three repository tests passed. No source fixes were needed. The earlier macro/CoreSimulator errors came from restricted execution; running the Xcode tools with approved simulator access resolved them. The Firebase Live target and real-device behavior remain unverified.

## Validation completed

- Both project files, Info.plist, and entitlements passed `plutil -lint`.
- `xcodebuild -list` recognized WithDemo, WithTests, Debug/Release, and the shared WithDemo scheme.
- Generator runs using Node’s standard library without Homebrew, CocoaPods, or XcodeGen.
- Source references, shared schemes, color catalog JSON, and generated project structure were checked.
- Three simulator unit tests passed: author-only edits, append-only updates with persistence, and idempotent reaction membership.
- WithDemo built and launched successfully on iPhone 18 Pro / iOS 27.0.

## Live work still needed

See [SETUP.md](SETUP.md). The live target is an integration scaffold, not a production release. It currently reads one server-provisioned group and supports basic authenticated operations; it does not create/redeem group invitations or complete account deletion. Live prayer deletion is intentionally disabled until server-side cleanup is implemented.

Before real user testing: choose the display-name onboarding, implement session restoration, group creation/invite redemption/leave, recursive prayer deletion, Apple token revocation and account cleanup, and server-side notification delivery if desired. Validate the rules with the Firebase Emulator Suite. Live drafts are not persisted. The per-account UserDefaults draft store is enabled only for the local demo; choose a protected live draft strategy before adding persistence for real prayer content.

No cloud resources were created, no billing was enabled, no Apple agreements were accepted, and no system-wide tools were installed. Xcode 27.1 was already present.

## Source organization

- `Sources/App`: app entry and observable app state.
- `Sources/Domain`: backend-independent data types.
- `Sources/Data`: repository contract, local demo, guarded Firebase adapters.
- `Sources/Features`: welcome, circle, prayer detail, composer, personal prayers.
- `Sources/Design`: colors and reusable native controls.
- `Tests`: demo repository invariants.
- `Backend`: Firestore rules draft and emulator config.

`Scripts/generate-project.cjs` regenerates both Xcode projects and color catalogs after adding or removing Swift files. It does not run as a build phase. The app uses the native Xcode project directly.
