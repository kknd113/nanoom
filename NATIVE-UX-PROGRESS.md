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

## Review 5 · October 29, 02:13–02:25 LA

Expanded native coverage to the narrower **iPhone 17e / iOS 27.0** simulator with the existing Demo binary. Reviewed welcome, the people-first circle, floating actions and composer with the software keyboard. Used a synthetic multiline draft to confirm the disabled Share action and red counter at 2,002 characters, then the enabled action at exactly 2,000 after native keyboard deletion. The editor remained scrollable and the toolbar stayed reachable. No app source changes were justified by this pass.

A coordinate drag intended for the sheet reached the system notification/lock interface instead. During this automation attempt the simulator displayed black and stopped returning launch results; restarting only the disposable 17e simulator restored normal operation. The 2,000-character Demo draft was restored after restart. A later attempt visibly reached the system notification interface, so this is not evidence of a Nanoom crash. Direct Cancel → explicit discard → reopen empty composer (0/2000) was then verified. Sheet-drag dismissal on this device is **not** marked passed; use native accessibility targets or a manual gesture for that remaining check. No production data was involved and no prayer was submitted.

Returned Device Hub to the existing iPhone 18 Pro with the user's live account intact, then shut down only the extra 17e simulator. Screenshots: `../nanoom-small-welcome.png`, `../nanoom-small-composer.png`, `../nanoom-small-home.png`. No build/test rerun was needed because this pass changes review notes only. Next: final consistency/accessibility review and draft the morning handoff; continue scheduled reviews until 08:00 LA.

## Iteration 6 · October 29, 03:10 review

Found a draft-loss path during the flow/state review: `receiveInvitation` unconditionally cleared `composer`, bypassing the writer's discard confirmation. Incoming invitations now remain queued while a prayer, edit or update composer is open. Root navigation presents the queued invitation only after writing ends, keeping the current group and sheet identity stable in the meantime. This preserves the existing memory-only handling of live prayer drafts; no persistent live draft storage was added.

Added a regression covering all three composer routes: receipt retains the route and original group, stores the pending invitation, and defers presentation until the composer closes. **All 10 native tests passed** with zero failures and runtime warnings. Live simulator build, project reference validation and whitespace checks also passed. The case was discovered by code inspection and verified at the model/navigation-condition level; no synthetic deep link was delivered to the user's real live account.

Logs: `../../work/nanoom-native-ux-06-tests.log`, `../../work/nanoom-native-ux-06-live.log`. A draft morning handoff is in `NATIVE-UX-HANDOFF.md`; it must be refreshed at the final 08:00 LA review. Keep scheduled reviews active. Remaining focus: accessibility traversal and final consistency, without more decorative churn.

## Review 7 · October 29, 04:12 LA

Reviewed the source accessibility semantics for member selection, prayer cards/actions, composer input and photo positioning. Named controls, selected-member traits, the acknowledgment undo hint, photo movement actions and zoom slider labels remain present. This was a source-level consistency check, not a full VoiceOver listening/traversal test; that limit remains in the handoff. No additional app changes were justified.

Audited every local link in the draft handoff: all eight linked screenshots and both linked documents exist. The screenshots decode at their expected native simulator resolutions (1206 × 2622 or 1170 × 2532) and are not blank black captures. Screenshot paths refer to the local outputs folder, not files published in the GitHub repository; the handoff now makes this explicit. No build or test rerun was needed for documentation-only changes. The latest code remains the tested invitation-queue fix (10 passing native tests). Continue scheduled reviews until 08:00 LA.

## Review 8 · October 29, 05:11 LA

Reviewed composer cancellation alongside the previously tested pending-invitation condition. On the native iPhone 18 Pro Demo, changed writing produced the discard confirmation; dismissing the confirmation outside its popover preserved the draft and character count. Reopening Cancel and explicitly discarding returned to the circle, and reopening writing showed 0/2000. An unchanged empty composer closed directly. No prayer was submitted. The simulator keyboard automation emitted modified Unicode characters instead of the requested ASCII phrase, so this verifies cancellation/state preservation with synthetic text rather than English keyboard fidelity; the draft was fully discarded.

The native accessibility tree exposed the person buttons with selected state, the combined prayer card with its opening hint, Share a prayer, My prayers, the named editor and character counter. Composer toolbar actions were visible but not included by Device Hub in that sheet's accessibility snapshot; coordinate clicks were required. This is a tool-observation limit and does not establish either a VoiceOver pass or a VoiceOver failure. Full listening/traversal remains pending. Restored keyboard capture to its original off state and returned to the Live app with no account/data changes.

No new app issue was observed, and no source edits or redundant build/test reruns were justified. The invitation overlap behavior remains covered by the 10-test suite from iteration 6; this pass did not send a synthetic link to the live user. Continue scheduled reviews through 08:00 LA.

## Review 9 · October 29, 06:13 LA

Checked the shipped sRGB asset values with relative-luminance contrast arithmetic. Ink/Paper is 12.04:1 in light and 15.08:1 in dark; Accent/Paper is 5.00:1 and 9.83:1; Accent/Soft (avatar initials and the group privacy capsule) is 4.52:1 and 7.04:1. All six unrounded results exceed 4.5:1. [W3C's contrast explanation](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) supplies the reference threshold and cautions against rounding borderline failures. This is a limited palette check, not certification of the app: system semantic text, transparency composites, disabled states, images and actual physical display conditions were not measured by this calculation. No palette change was justified.

Confirmed both Xcode projects declare iOS 18.0 at project level and the only Liquid Glass API is inside the iOS 26 availability branch, after the Reduce Transparency branch. The fallback uses regularMaterial and a rounded stroke. Current SDK builds have already passed; this source check does not replace execution on an iOS 18 runtime. Updated the draft handoff with its current review time and direct implementation commit links. No app changes, Firebase operations or redundant tests were needed. Continue scheduled reviews until the final 08:00 LA handoff.

## Review 10 · October 29, 07:09 LA

Checked the current commit history against the validation logs. There have been documentation-only changes since the invitation-queue fix; its native test log records 10 tests with 0 failures and TEST SUCCEEDED, and the Live log records BUILD SUCCEEDED. Both logs contain Xcode's AppIntents metadata-extraction warning because these targets have no AppIntents.framework dependency; previous “0 runtime warnings” wording must not be read as a claim of completely warning-free builds. Project reference validation and whitespace checks passed again. No app edits or test rerun were justified.

Adjusted the existing automation to one final occurrence at 15:00 UTC / 08:00 LA with its original deadline retained, rather than relying on the next hourly interval landing before the cutoff. An initial proposal allowing a 09:00 cutoff was rejected by automatic approval review; no extension was applied. The accepted schedule is still ACTIVE and the final run must prepare the handoff and pause it. Current scope/data/billing safeguards remain unchanged. Do not mark the morning handoff complete during this 07:00 review.

## Follow-up · October 29, 07:35 LA

The user asked to continue after the status check. Opened the isolated Demo and verified Home → My prayers reaches its empty state (“Room for your story” and “Share your first prayer”) through the native accessibility tree. The first-prayer button action then timed out, and the next observation explicitly reported the Mac was locked and could not be automatically unlocked. Requested manual unlock through the in-chat question tool. Do not record the remaining author create/edit/update native walkthrough as passed. No draft was entered and no prayer was submitted in this attempt.

Independent source review confirms My prayers uses the composer for its first-prayer action, author detail exposes update/edit actions, and the editor initializes edits from the original prayer body. Existing isolated repository tests cover successive update persistence and rejection of editing another member's prayer; these are not a replacement for the interrupted native author walkthrough. No code changes were justified. The 08:00 final review remains scheduled; if the Mac is still locked, finish the handoff with that explicit limitation instead of claiming a UI pass or stopping unrelated documentation work.

## Final handoff · October 30, 10:06 LA resume

The final review was interrupted across the planned deadline by the locked Mac and an automatic approval review timeout on the read-only Git fetch. On resuming October 30, paused the existing automation successfully; the one permitted fetch retry succeeded. No timed-out operation was assumed unsafe and no additional user approval is now needed for that resolved fetch.

After the user confirmed unlock, native My prayers → Share your first prayer opened the correct composer. Input automation again produced unexpected text/IME behavior, and the tool reported that the app had changed during the attempt. Stopped editing to preserve the current draft; Capture Keyboard was observed restored to off. Did not tap Share, edit/delete any prayer, or complete the remaining native author-update walkthrough. This remains a documented verification limit rather than an app defect or passing test. No real Firebase account, prayer or photo was modified.

Final implementation remains the tested invitation-queue commit af738aa; later commits document reviews only. Existing evidence: 10 native tests passed, final Live/Demo builds passed, two simulator sizes plus light/dark and accessibility text reviews completed. No redundant rebuild was run for final documentation changes. Final handoff includes local screenshots, implementation commits, research sources and remaining physical-device/iOS 18/VoiceOver/author-flow limits. Overnight automation is PAUSED; no further scheduled design iterations are requested by this handoff.

## Design references

Facts: Apple's current guidance treats Liquid Glass as a navigation/control layer and favors standard controls adopting system design. The decision to keep Nanoom content calm and opaque is our product interpretation of that guidance.

- [Apple HIG · Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Apple · Liquid Glass overview](https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass)
- [WWDC25 · Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [WWDC25 · Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)

Limits: iOS 18 fallback compiles against the current SDK but has not yet been exercised on an iOS 18 runtime. Current visual verification uses iPhone 18 Pro and iPhone 17e / iOS 27 simulators. VoiceOver labels were inspected through accessibility state; a full VoiceOver listening audit remains outstanding. No claim of production readiness.

## Manual core-flow follow-up · October 30

At the user's request, completed a new real-Firebase verification pass after the overnight automation had stopped. Found and fixed a reproducible native read failure after account switching by replacing the Firestore client and its memory-only cache for a different UID, while waiting for existing group reads and guarding in-flight invitation work. No deployed rules or billing settings changed.

Final evidence: 19 real native SDK/AppModel checks, 58 independent JS rules checks and 10 native regression tests passed. Actual native UI verified author update/edit saves and reload after normal process restart, photo picker/crop/upload/removal, and OS invitation preview/join for an already joined account. All manifest-tracked accounts and document/index records from diagnostic runs and the final run were independently checked absent. See [CORE-FLOW-QA.md](CORE-FLOW-QA.md) for the precise scope, experimental diagnostic failure, screenshots, cleanup and remaining device/accessibility limits. This follow-up did not restart the overnight automation.
