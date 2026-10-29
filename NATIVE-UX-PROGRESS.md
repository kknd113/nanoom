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

## Design references

Facts: Apple's current guidance treats Liquid Glass as a navigation/control layer and favors standard controls adopting system design. The decision to keep Nanoom content calm and opaque is our product interpretation of that guidance.

- [Apple HIG · Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Apple · Liquid Glass overview](https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass)
- [WWDC25 · Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [WWDC25 · Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)

Limits: iOS 18 fallback compiles against the current SDK but has not yet been exercised on an iOS 18 runtime. Current visual verification uses iPhone 18 Pro / iOS 27 simulator. VoiceOver labels were inspected through accessibility state; a full VoiceOver listening audit remains outstanding. No claim of production readiness.
