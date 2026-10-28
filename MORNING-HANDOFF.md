# Nanoom — morning handoff

Prepared October 28, 2026, Los Angeles time. The requested overnight implementation, brand exploration and competitor review are complete. This is a connected development build; the remaining release prerequisites are listed below.

## What you can try now

Open **WithLive.xcodeproj**, choose **WithLive**, and run on the iPhone simulator. The latest built app is installed. Your real account and group data were preserved.

1. Open group settings → **Create invite link** → **Share invite link**. A recipient opens the HTTPS page, taps **Open Nanoom**, signs in if needed, confirms the named circle and joins. The invitation survives login/relaunch. Links expire after seven days and can be revoked.
2. Open group settings → your profile → **Choose a photo**. Select one photo, position/zoom it, and save. Change/remove are available afterward. Photos are optional, compressed, and visible only within that circle; initials remain the fallback.
3. Sign out/relaunch while testing: a completed old refresh no longer restores private group UI, and a slower old refresh cannot overwrite a newer circle.

The first HTTPS handoff currently includes an explicit Open Nanoom button. Direct Universal Links and post-install invitation continuation await the real Apple team association/distribution setup. Do not confuse the separate WithDemo sample app with the live app.

## Branding

**Recommended direction: Held n** — a lowercase n shelters a small dot, connecting the name Nanoom with one person held in prayer. Two alternatives are included for comparison.

- [Visual board](Branding/index.html)
- [Brand rationale and voice](Branding/README.md)
- [Primary SVG](Branding/nanoom-mark.svg), [app-icon concept](Branding/nanoom-icon.svg), [black master](Branding/nanoom-mark-black.svg), [white master](Branding/nanoom-mark-white.svg)

The name stays **Nanoom / 나눔**. The existing installed wordmark remains in place; the symbols are reviewable original concepts, not a claim of trademark clearance. No marketing was published.

## Market research and recommendation

[Read the sourced competitor review](Research/market-review.md): Echo Prayer, PrayerMate, YouVersion, Hallow and Pray.com, plus the existing group-chat substitute. Documented features are separated from hypotheses about adoption/retention; no private metrics or invented success/failure claims are presented.

**Next move:** pilot the focused people-first experience with 3–5 existing Korean church small groups. Make finding a friend's current prayer and meaningful follow-up easier than scrolling through KakaoTalk. Complete trust/lifecycle requirements before broad distribution; use observed pilot friction to decide on Korean navigation, reminders and monetization.

[Concrete release-readiness plan](Research/release-readiness.md): membership leave/removal and ownership transfer, account deletion/full data cleanup, revocation UI, live updates/pagination, actual-device testing and distribution setup. Avoid building a large content library or another full chat app before the core care loop is validated.

## Validation and cost

- Live SwiftUI/Firebase build passed with Xcode 27.1 / Swift 6.4.
- Nine native tests passed across the relevant test runs, including invite parsing/persistence, photo persistence/removal/ownership and two asynchronous stale-response regressions.
- 58 real-cloud checks passed for private membership, invitations, prayer operations and photo access/ownership/type/size/schema validation. Backend rules were unchanged during the later client-state review, so those cloud checks were not needlessly repeated.
- Native Firebase signup/sign-in and session restoration were verified after fixing simulator Keychain signing.
- Native photo picker → crop → saved avatar display was visually checked with a synthetic image. OS-level invite routing, invalid-link recovery and actual creator invite generation were checked.
- Synthetic server test accounts, groups and membership indexes were cleaned up. No real prayer data was edited or removed.
- Firebase remains **Spark**, Standard Firestore in **us-west2**, with no billing account enabled. Small avatars use existing Firestore storage; no paid Cloud Storage service was provisioned.

## Pushed code

- [Invite links, profile photos, branding and research](https://github.com/kknd113/nanoom/commit/31fc083bfedeca9015af71818fce86e1f34f2a0d)
- [Stale-session fixes, crop accessibility and monochrome assets](https://github.com/kknd113/nanoom/commit/8fc422718e58daa029b418dbfff8e7412707a994)

See [SETUP.md](SETUP.md) for current configuration and limitations, and [OVERNIGHT-PROGRESS.md](OVERNIGHT-PROGRESS.md) for review notes/evidence paths. Local logs and screenshots are retained in the workspace; credentials and Firebase app configuration remain excluded from Git.

## Remaining release limits

Account deletion, group leave/member removal and recursive physical cleanup remain unimplemented. Soft-deleted prayer main text is erased, but blocked child records still require trusted cleanup. Updates use action/pull-to-refresh rather than live listeners, and queries are limited to 100 recent prayer documents. Photos are per-circle avatars, not global full-resolution profiles. Apple login is the chosen launch direction but the current free development flow uses email/password. Firestore rules are tested development rules, not a security certification or end-to-end encryption claim.

The overnight follow-up ends after this handoff, as requested. Further product work can proceed from the release-readiness plan without changing the completed branding/research decisions implicitly.
