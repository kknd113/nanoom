# Nanoom: next implementation sequence

This plan follows the first live sharing/photo iteration. It is a proposed sequence, not a claim that these capabilities exist today. Preserve Firebase Spark and the current user's data.

## 1. Membership lifecycle before broader distribution

Define group creator responsibilities first: a creator cannot leave an active group without transferring ownership to an existing member or explicitly closing it. Members can leave their own group. A creator can remove another member. All transitions must revoke group and avatar access immediately, not just remove an entry from the UI.

The existing source of access is groups/{gid}/members/{uid}; users/{uid}/groupMemberships/{gid} is only a navigation index. A leave/removal implementation must update both together and prevent an old index from recreating membership. Protect ownerID against accidental client self-promotion. Ownership transfer needs a narrowly constrained atomic transition with proof that the recipient is an existing member, plus regression tests for creator removal and privilege escalation.

Revocation testing must include direct document reads, all collection queries the app uses, photo access, prayer updates/reactions, and any subsequent cached UI state. The current Firestore cache is memory-only; app state must also clear as soon as access is lost. Realtime membership detection is a useful prerequisite for prompt revocation UX.

## 2. Full erasure and account deletion

Current prayer deletion is a tombstone: main text is erased, child updates are blocked but still stored. Do not advertise it as full physical erasure. Decide whether leaving a group retains the member's authored prayers and how a person requests removal; make that behavior explicit before implementing it.

Account deletion needs authenticated reauthentication, a deterministic inventory of every membership, owned group, photo, authored prayer/update/reaction and invitation, and an idempotent cleanup/retry procedure. An abandoned partial deletion must not leave an ownerless active group or a still-readable profile photo. Apple token revocation becomes relevant when Apple login is enabled.

Spark does not provide a deployed Cloud Functions cleanup backend in our current setup. Do not silently enable billing to make this work. Options to evaluate: a trusted separately hosted cleanup endpoint with verified Firebase ID tokens, or a carefully designed client-authorized staged cleanup flow. The latter needs explicit authorization for deleting the relevant child records and robust recovery, not broad blanket deletes. Until a tested choice exists, keep broad distribution blocked and offer development-admin cleanup only through trusted tooling.

## 3. Live updates, then gentle return cues

Tie a membership listener and group/prayer listeners to the authenticated user's lifecycle; stop them and discard in-flight results on logout/group change. Avoid per-prayer unlimited listeners. Add pagination with stable timestamps/document IDs before claiming large-group support. Retain pull-to-refresh and clear failure states.

Only after a pilot shows a real return problem, test a single optional recap/reminder. No prayer streaks, public counts, ranking or pressure. Do not add a third-party analytics SDK or content logging just to measure the pilot; begin with usability sessions and consented aggregate event design.

## Acceptance criteria for the next release

- A removed member cannot read any former-group document or photo and sees no stale private UI after sign-out or session change.
- Leaving, creator transfer and retry states have adversarial rule tests.
- Account deletion has repeatable partial-failure recovery and verified full cleanup; privacy copy reflects actual behavior.
- Actual iPhone testing covers invitation handoff, picker cancellation, crop at large text sizes, photo removal and login persistence.
- Universal Links use the real Apple team association once available. Do not simulate a production association with a fabricated Team ID.

This is the recommended next move from the market review: improve trust and lifecycle reliability before expanding feature breadth or charging organizers.
