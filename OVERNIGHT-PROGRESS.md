# Nanoom overnight progress

Updated October 27, 2026 (Los Angeles). Continue in this chat; preserve the user's real Firebase account/group data.

## Completed this iteration

- Shared HTTPS invitation links: static Hosting page → Open Nanoom → sign-in if needed → named group confirmation → explicit join. Pending token survives app/login recreation. Existing membership opens the same circle rather than failing a duplicate write. Last joined circle is remembered.
- Optional per-circle profile photo: system photo picker → downsample/orientation normalization → drag/zoom crop → 256px compressed image → group-private Firestore storage. Change/remove supported, initials fallback, no Cloud Storage/billing upgrade.
- Separated Live URL registration from the demo. Both targets build. Seven native tests pass, plus 58 real-cloud rules/behavior checks. Photo picker/crop/save/display visually verified using a synthetic image. Test accounts and fixture group/index records cleaned up.
- Hosting page deployed to nanoom-kknd113.web.app, with fragment-based token handoff, no analytics or third-party assets, strict CSP/referrer settings. No unauthenticated database access added.
- Three original SVG logo directions and a brand board under Branding/. Recommendation: Held n. Existing installed identity is preserved for review; these are not trademark-cleared assets.
- Sourced market comparison and prioritized product recommendation under Research/market-review.md. Distinguishes documented features from adoption/retention hypotheses; no invented market share or revenue claims.

## Evidence and locations

- Main native build log: workspace work/nanoom-invite-photo-build.log.
- Six-test suite: work/nanoom-invite-photo-tests.log; pending-link persistence test: work/nanoom-pending-invite-test.log.
- Real backend checks: work/firebase-invite-photo-check.log (58 PASS).
- User-facing screenshots beside this repository: nanoom-profile-photo.png, nanoom-invite-page.png, nanoom-brand-preview.png.
- SwiftUI views stay in the existing source files because the Xcode projects use explicit source references. Do not add a source file without native Xcode project inclusion.
- Live simulator build must remain signed; never use CODE_SIGNING_ALLOWED=NO for Firebase Auth. SETUP.md describes the corrected app-scoped Keychain entitlement.

## Overnight follow-up priorities

1. Finish/confirm OS-level invite handoff QA and empty/error/cancel states. Do not leave a test invitation pending in the user's session. Never sign out a real user for testing.
2. Review crop accessibility and loading/error behavior. Prefer targeted fixes backed by observed issues over adding unrelated features. Do not rerun broad checks after only docs change.
3. Refine logo legibility/monochrome export and evaluate the current three directions against competitor identities. Keep name Nanoom and avoid claiming legal clearance. The final icon/wordmark choice remains reviewable.
4. If time remains, inspect group lifecycle requirements (leave/removal/account deletion) and write a concrete next implementation plan before changing existing authorization. These require real cleanup design and are not magically solved by profile photos.
5. Morning handoff: link the brand board, market review, screenshots and pushed commits; state limitations plainly. No messages to other people, no external marketing, no billing changes.

## Known limits

- HTTPS uses an explicit Open Nanoom handoff; production Universal Links and deferred-install continuation are not configured without the real Apple team/app association.
- Profile photos are small Firestore byte blobs scoped to a circle, not full-resolution images or a global user avatar. This should be reassessed before large-scale use.
- Updates still refresh on actions/pull-to-refresh; realtime/pagination and membership lifecycle cleanup remain work.
- Account deletion, group leave/removal and full physical cleanup are still release prerequisites. No claim of E2EE or production security certification.
