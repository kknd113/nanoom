# Nanoom — iPhone native starter

Brand confirmed on October 27, 2026: **Nanoom / 나눔**. Wordmark: **nanoom**. SwiftUI, iOS 18+, English UI, Korean content supported. Existing internal project, scheme, and type names retain `With`; the installed app name and visible wordmark use Nanoom.

## What is prepared

- **With.xcodeproj / WithDemo**: native local demo, no remote packages or accounts required.
- **WithLive.xcodeproj / WithLive**: separate Firebase adapter scaffold with Apple sign-in. Firebase is declared through Swift Package Manager at exact version **13.1.1**. Dependencies have **not** been downloaded or resolved in this environment.
- Person-first circle, prayer detail, reaction, author updates, My prayers, create/edit/delete in the demo.
- Local demo persistence, draft restoration, native sheets, haptics, dark mode, and an accessible grid alternative for large text / larger groups.
- Repository boundary, unit-test sources, and a deny-by-default Firestore rules draft.

## Start here

1. Open **Xcode** and review/accept its license. The host currently reports an unaccepted Xcode license.
2. Complete Xcode’s first-launch setup; install an iOS Simulator runtime if prompted.
3. Open `With.xcodeproj`, select **WithDemo**, select an iPhone simulator, then Run.
4. Choose **Explore Grace Group**. This is an explicitly labeled sample group; no real login occurs.
5. Product → Test runs the repository tests once Xcode is ready.

**Build is not verified.** `xcodebuild -list` successfully loaded the project and found WithDemo/WithTests. A generic iOS Simulator build reached Swift compilation, then failed because this execution environment denies the nested sandbox used by Swift macro plugins (`sandbox-exec: sandbox_apply: Operation not permitted`; ObservationMacros/SwiftUIMacros malformed responses). CoreSimulator services were also unavailable. Separately, the system `swift --version` wrapper reported an unaccepted Xcode license. Review the license/setup in Xcode and build locally; the agent did not accept agreements. Unit tests and visual device QA are still pending.

## Validation completed

- Both project files, Info.plist, and entitlements passed `plutil -lint`.
- `xcodebuild -list` recognized WithDemo, WithTests, Debug/Release, and the shared WithDemo scheme.
- Generator runs using Node’s standard library without Homebrew, CocoaPods, or XcodeGen.
- Source references, shared schemes, color catalog JSON, and generated project structure were checked.
- Unit tests cover author-only edits, append-only updates with persistence, and idempotent reaction membership. Their execution is pending.

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
