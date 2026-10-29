# Native UX iteration · October 28–29, 2026

The user requested continued native UI/UX iteration until tomorrow morning. Hourly reviews are scheduled through **October 29 at 08:00 America/Los_Angeles**. This is an initial iteration, not the final morning handoff. Preserve the people-first circle and approved Held n identity.

## Iteration 1 · October 28 evening

- Reduced the home introduction so people and their prayers appear sooner. The selected prayer is a single readable card, with separate access to more prayers.
- Added a floating action dock for sharing and personal prayers. Glass is reserved for controls; prayer content uses stable opaque reading surfaces. iOS 26+ uses native glass, iOS 18–25 uses system material, and Reduce Transparency uses an opaque fallback.
- Restored visible native navigation in prayer detail and My prayers. Added a calmer author/date hierarchy, update timeline, explicit prayer acknowledgment action and undo hint.
- Simplified composer copy, added a real placeholder and keyboard dismissal control. Changed text requires explicit discard; saving blocks dismissal. Live prayer drafts remain memory-only.
- Kept optional profile photos, invitations, authentication, Firebase rules and billing configuration unchanged.

Validation: both Live and Demo simulator builds passed; all **9 existing native tests passed**, 0 failures, 0 runtime warnings in the test result. Project source/reference validation and whitespace checks passed. Native simulator walkthrough covered home → detail → back, composer input → Cancel → discard confirmation → home, and light/dark home appearance. Synthetic Demo content only was used for interactions. The installed Live build preserves the user's existing account and data.

Local screenshots are one directory above this repository: `nanoom-native-ux-home.png`, `nanoom-native-ux-detail.png`, `nanoom-native-ux-dark.png`. These show sample content, not production prayer data. Build/test logs are under `../../work/nanoom-native-ux-01-*`.

## Next scheduled reviews

1. Accessibility Dynamic Type: circle grid fallback, long names, action dock labels, composer with software keyboard, detail scrolling. Inspect at a small phone size when available. Fix observed clipping rather than adding decorative changes.
2. Invitation and profile navigation: native sheet hierarchy, explicit cancel/back, long group names, loading/error states. Use synthetic fixtures; do not revoke real invitations or edit real photos/prayers.
3. Motion and state transitions: Reduce Motion/Transparency, returning from detail, empty circle, author updates and acknowledgment feedback. Verify light/dark contrast.
4. Rebuild only changed targets; run relevant regression tests when behavior changes. Push tested changes through the GitHub plugin. Use expected branch head to preserve concurrent edits.
5. At the morning review, write a concise handoff with actual screenshots, commits, checks and remaining limits; then pause the heartbeat. Do not stop follow-ups after this first successful pass.

## Iteration 2 · October 28, 23:06–23:15 LA

Observed at the largest accessibility text size: the home action dock clipped its primary label, the adaptive avatar grid truncated even short names, and the welcome view compressed its copy and button into unreadable fragments. With the software keyboard visible, the composer initially placed its input behind the keyboard.

Fixes: accessibility text sizes now use full-width member rows and vertically arranged home actions. Primary buttons allow multiline text and proper inner padding. Welcome content scrolls and preserves full headings. The composer scrolls, scales its editor height with Dynamic Type, stacks privacy/counter labels when needed, and brings the editor into view on focus or keyboard-driven size changes. Shorter placeholder copy avoids a paragraph of oversized example text. Standard-size circular navigation and horizontal actions remain in place.

Validation: final Demo and Live simulator builds passed; project validation and whitespace checks passed. Actual native walkthrough at the largest accessibility size verified full names/actions, welcome scrolling to its complete button, composer with the software keyboard visible and its input above it, synthetic draft editing and explicit discard. Only local Demo content was used; no live account or prayer data changed. Original simulator text size (`large`) was restored. These are layout changes; the 9 native regression tests passed in iteration 1 and were not redundantly rerun in this pass.

Screenshots: `../nanoom-accessibility-before.png` records the original clipping; `../nanoom-accessibility-home.png` records the corrected full-name rows and stacked actions. Continue next with invitation/profile flows, long group/member names and reduced motion/transparency; a full VoiceOver audio audit and older/smaller runtime coverage remain pending. Hourly follow-ups remain active until the morning handoff.

## Iteration 3 · October 29, 00:11–00:18 LA

Reviewed profile photo settings at standard and maximum accessibility text sizes. Its native Form, full photo actions and back navigation remained usable, so no cosmetic changes were made there.

Invitation presentation now scrolls, gives the group name its own readable heading, and states the circle's visibility before joining. This applies the Partiful reference's contextual welcome principle as our design hypothesis. Loading, success and error states share the same native component. Failure copy now includes a connection/retry path rather than implying every failure is an expired link. Joining disables both duplicate joining and dismissal; invitation preview requests ignore canceled, superseded or departed-screen results.

Validation: normal Demo and Live builds passed, and a separate Demo build with `SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG` enabled the opt-in simulator presentation fixtures. Native walkthrough verified the shared invitation component with a long synthetic group name, maximum accessibility text, scrolling to Join/Not now, plus loading and failure presentations. Native regression suite passed again (9 tests). No real invitations were issued, revoked or joined; no live photo, account or prayer data changed. Original text size (`large`) was restored.

Fixture launch: use the DEBUG-enabled Demo build with `--preview-circle-invitation`; append `--preview-invite-error` or `--preview-invite-loading` for those states. These fixtures review presentation only: their Join/Retry/Not now closures deliberately have no effects, and the fixture branch is excluded from Firebase builds and Release builds. Default Demo launches still show normal onboarding. Actual server invitation behavior retains the existing repository/rules and previous cloud checks; no new end-to-end live join was performed this pass.

Screenshots: `../nanoom-invite-iteration-3.png`, `../nanoom-invite-accessibility.png`, `../nanoom-invite-error.png`, `../nanoom-profile-accessibility.png`. Logs: `../../work/nanoom-native-ux-03-*`. Next review: reduced motion/transparency, detail updates and acknowledgment feedback. Keep hourly reviews active through the final morning handoff.

## Iteration 4 · October 29, 01:09 review

Native Demo walkthrough verified Daniel's prayer, its author update, acknowledgment and undo. At maximum accessibility text, the completed action and its lengthy undo explanation occupied nearly half the reading viewport. Accessibility-size actions now use shorter visible copy (I prayed / Prayed, Tap to undo, Add update) while preserving the person's full name and undo hint in accessibility labels. The saving state also has an explicit accessibility label. Standard-size personal wording stays unchanged.

Verified the real simulator Settings values before changing them: Reduce Motion = off, Reduce Transparency = off. Enabled both temporarily through Settings → Accessibility, reviewed member selection/navigation and the native detail with an opaque action surface, and checked dark appearance and scrolling through the update at maximum text size. Restored both switches to off and text size/appearance to large/light. The synthetic acknowledgment was undone, returning the Demo prayer to its initial state. No live data changed. No issue requiring additional motion or material changes was observed; this was a visual walkthrough and source review, not frame-by-frame animation measurement or a physical-device haptic test.

Both final Demo and Live builds passed, as did project reference validation and whitespace checks. Existing 9 regression tests passed in iteration 3; this pass changes view copy/layout and accessibility labels only, so the suite was not repeated.

Screenshots: `../nanoom-prayer-dock-before.png`, `../nanoom-prayer-dock-accessibility.png`, `../nanoom-prayer-reduced-transparency-dark.png`. Build logs: `../../work/nanoom-native-ux-04-*`. Next reviews should prioritize a smaller phone viewport/long content and final flow consistency rather than more decoration. Full VoiceOver audio and physical-device checks remain outstanding. Morning handoff is still due at 08:00 LA; keep follow-ups active.

## Design references

Facts: Apple's current guidance treats Liquid Glass as a navigation/control layer and favors standard controls adopting system design. The decision to keep Nanoom content calm and opaque is our product interpretation of that guidance.

- [Apple HIG · Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Apple · Liquid Glass overview](https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass)
- [WWDC25 · Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [WWDC25 · Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)

Limits: iOS 18 fallback compiles against the current SDK but has not yet been exercised on an iOS 18 runtime. Current visual verification uses iPhone 18 Pro / iOS 27 simulator. VoiceOver labels were inspected through accessibility state; a full VoiceOver listening audit remains outstanding. No claim of production readiness.
