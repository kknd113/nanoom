# Nanoom / 나눔

Native SwiftUI prayer circles for iPhone, iOS 18+. English interface, Unicode prayer content. Internal project/type names retain `With`; the installed app is Nanoom.

## Run the actual server-connected app

Open **WithLive.xcodeproj**, choose **WithLive** and an iPhone simulator, then Run. The local Firebase config is already linked. Choose **Continue with email**, create an account, and create a group or open a shared invitation link. The group creator can issue/share/revoke seven-day invitation links from group settings. HTTPS links open a small invitation page; Open Nanoom carries the invitation into the app. Sign in, confirm the group and join. Members refresh by pulling down on the home screen.

Backend: **nanoom-kknd113**, Firebase Spark, Firestore Standard `(default)`, **us-west2 (Los Angeles)**. No billing account was linked. Bundle ID: **com.kknd113.nanoom**. Email/password authentication requires no paid Apple membership for simulator testing. Apple sign-in code remains available internally but is not offered by this free testing flow.

[Open Firebase Console](https://console.firebase.google.com/project/nanoom-kknd113/overview)

## Implemented

- Real email account creation, sign-in, password reset and session restoration.
- Private group creation, atomic invitation redemption and private membership indexes.
- Expiring, revocable HTTPS invitation links backed by 128-bit codes, group preview/confirmation, and pending-invitation restoration through sign-in or app restart.
- Optional group-private profile photos: native Photos picker, drag/zoom crop, save/change/remove, 256px compressed avatars and initials fallback.
- Server-stored prayers, author edits/updates, unique member prayer reactions, My prayers.
- Soft deletion erases the main prayer text and prevents access to the deleted thread's updates/reactions.
- Firebase Auth persists the session; Firestore uses a memory-only cache. Signing out clears displayed group state.
- Native sheets, haptics, dark appearance and accessible grid for larger groups/text.

## Verified October 27, 2026

- Xcode 27.1 / Swift 6.4 builds the real **WithLive** app with Firebase Apple SDK **13.1.1**.
- Installed and launched on iPhone 18 Pro / iOS 27.0. Native email onboarding observed.
- Fixed missing simulator Keychain entitlements (Firebase 17995 / OSStatus -34018) by enabling app-scoped local signing. Native Firebase account creation, sign-out/sign-in and session restoration across process restart were verified; the synthetic account was deleted.
- **58 checks against the actual cloud backend** passed: multi-account sharing, invitation join/revocation, author ownership, schema/size/timestamp validation, reaction uniqueness, unauthenticated/outsider denial, deleted-thread denial, avatar ownership/size/schema/privacy validation and invitation-name spoof prevention.
- Synthetic verification accounts and their test group/index records were cleaned up.
- Seven native tests passed across the demo/domain suites, covering existing prayer behavior plus strict invite parsing, pending-link persistence and photo ownership/persistence/removal. Native photo picker → crop → saved avatar display was visually verified with a synthetic image.

## Limits before broader release

This is a connected development build, not an App Store release. Pull-to-refresh/action refresh is implemented; realtime listeners and pagination are pending. The adapter remembers the last created/joined group and reads up to 100 recent prayers, including hidden tombstones. Group switching, leaving/removing members, account deletion, recursive physical cleanup of deleted thread children, notifications and live draft persistence remain work. Do not distribute broadly until these lifecycle features and privacy disclosures are ready. Invitation codes are bearer secrets: recipients can join until expiry/revocation.

See [SETUP.md](SETUP.md) for configuration, verification and rule-review details, and [CI-CD.md](CI-CD.md) for the later automation plan.

## Overnight design and research

[Brand directions and SVG masters](Branding/README.md) · [Visual brand board](Branding/index.html) · [Sourced market review and next-move recommendation](Research/market-review.md). These are reviewable proposals; the installed app name/wordmark remain Nanoom.
