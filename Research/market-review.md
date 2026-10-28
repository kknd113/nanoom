# Nanoom: market review and next move

Research date: October 27, 2026. Desk research from product documentation and store listings, not private retention/revenue data or a representative user study. “Strength” and “risk” below are product hypotheses grounded in documented behavior; they do not establish that a competitor is succeeding or failing commercially.

## Recommendation

Win one narrow job: help a real small group remember and care for each person between meetings. Keep the people-first circle. Test with 3–5 existing Korean church groups of roughly 5–10 people before adding a content library, church administration tools or a public feed. Korean prayer text already works; validate whether English navigation creates friction for these groups before deciding to remain English-only.

The strongest substitute is the group's existing KakaoTalk conversation, not another prayer app. Nanoom must make an ongoing prayer easier to find and update than a message buried in chat. A separate app adds installation and habit-switching costs; beautiful UI alone will not overcome that.

## Competitive evidence

| Service | Documented approach | Why it may work | Where Nanoom could fit |
|---|---|---|---|
| Echo Prayer | Invitation-only groups and larger ministry feeds. Joining/contributing is free; creating groups/feeds requires ECHO+. Personal prayer lists and reminders also exist. | Distinguishes intimate groups from broadcast ministry; a leader can pay while participants join free. | Charging the organizer before a first group is active may slow trials. This is a hypothesis, not observed churn. Nanoom should make the first circle and participation free during discovery. |
| PrayerMate | Rotating person/topic index cards; shared lists and publishing feeds. Its privacy policy describes group sharing and on-device encryption of synced list data. | Reduces “who should I pray for?” decisions and supports a focused prayer practice. | List maintenance and list/category vocabulary may feel task-oriented to someone casually sharing a difficult weekday. Nanoom can lead with a person and a short update rather than list administration. |
| YouVersion | Prayer requests are private by default and selectively shared with friends. Optional Prayer Chains permit onward sharing. Notifications identify who prayed; updates/comments support follow-up. | Existing Bible-app habits and friend relationships can provide distribution. Private defaults make scope explicit. | The documented prayer-sharing path runs through several navigation steps. Nanoom can place a circle's people and sharing action directly on the first screen. YouVersion already has updates and prayer acknowledgments; these are useful basics, not unique differentiation. |
| Hallow | Church/community tab with requests, small groups and shared prayer challenges; parish partnerships and a large prayer/audio library. | Group challenges provide a time-bound reason to return together; partnerships can supply distribution and context. | Institutional setup and content breadth serve a wider mission than Nanoom's weekday small-group care. A lighter, self-serve circle may suit groups that do not want a parish-wide rollout. This does not imply Hallow is a poor small-group product. |
| Pray.com | Free prayer requests and communities alongside premium audio content, daily/nightly prayer and Bible stories. Official help explains skipping trial offers to access free features. | Audio has recurring individual uses beyond group activity; free community participation broadens entry. | Trial/premium choices may distract a person whose sole aim is sharing one prayer with friends. Keep Nanoom's core care loop free of upsells during pilot testing. |
| Existing KakaoTalk / text chat | A substitute inferred from Nanoom's target audience and its current sharing channel, not measured in this study. | Already installed, socially established, low effort to send a message. | Requests can be hard to find among logistics; old requests lack a clear, visible follow-up. Validate this pain through interviews rather than assume it. |

Sources for the table:

- [Echo official user guide](https://www.echoprayer.com/user-guide) and [ECHO+ organizer/participant model](https://www.echoprayer.com/echo-plus).
- [PrayerMate developer listing](https://play.google.com/store/apps/details?id=net.geero.prayermate), [shared lists overview](https://blog.prayermate.net/blog/en/introducing-the-new-look-prayermate-publishing-platform-36216f334bc9/), and [privacy policy](https://www.prayermate.net/pages/app_privacy_policy). The shared-list article is historical; do not treat its screenshots as a current UI audit.
- [YouVersion sharing and privacy behavior](https://help.youversion.com/l/en/article/bdgy3q6m3k-share-a-prayer-with-friends-on-android). This source describes Android, so the navigation comparison is not a measured iPhone tap-count comparison.
- [Hallow community tab](https://help.hallow.com/en/articles/3949390-overview-of-the-church-tab), [church tab FAQ](https://help.hallow.com/en/articles/9677170-church-tab-faqs), and [parish offering](https://try.hallow.com/forparishes).
- [Pray.com free versus premium](https://help.pray.com/hc/en-us/articles/4416621897105-Is-Pray-com-free) and [subscription features](https://help.pray.com/hc/en-us/articles/15255693841565-Pray-com-Subscription-Plans).

## Why prayer-sharing products can struggle — hypotheses to test

1. **An empty circle has no value.** Someone must recruit the existing group. Measure invitation acceptance and whether at least two people participate, rather than treating an individual signup as activation.
2. **A new post is not the same as ongoing care.** Content can disappear into a stream. Make a person's current prayer and latest update easy to return to. Do not add a complex story system; the user already rejected that direction.
3. **Sensitive content raises the cost of a mistake.** Clear sharing scope, predictable deletion and private avatars matter. Do not equate access-controlled data with end-to-end encryption; Nanoom currently uses Firebase access control and transport security, not E2EE.
4. **Notifications can become social pressure.** An optional gentle reminder may help; streaks, rankings and missed-prayer warnings may turn care into obligation. Test opt-in reminders after the sharing loop works.
5. **Another communication inbox creates work.** Keep chat/logistics in KakaoTalk. Nanoom should make remembering prayer and seeing a meaningful update easier, rather than copy all messaging features.
6. **Organizer friction limits participation.** A shared link should survive sign-in and lead to an explicit group confirmation. Avoid requiring participants to paste a long code.

## Next product moves, in order

**1. Make the first shared moment reliable.** Finish invite-link handoff, optional photo setup and native authentication QA. Keep malformed, expired and revoked invitations understandable. A real account must remain signed in after relaunch.

**2. Complete trust/lifecycle requirements before broad distribution.** Account deletion, group leave/member removal, full data cleanup, recovery states, privacy disclosures and actual-device testing. These outrank decorative features. Do not increase database permissions to work around errors.

**3. Run a two-week pilot.** Proposed targets, not industry benchmarks: at least 70% of invited participants join within 48 hours; at least 60% of circles have 3 distinct members sharing/updating/praying in week two; most participants can find a friend's latest prayer in under 10 seconds during a usability session. Revise targets after seeing the first cohort. Report group-level participation rather than prayer-count leaderboards.

**4. Add one useful return cue.** If pilot interviews show people forget to return, test one optional weekly recap or reminder, with quiet hours and easy opt-out. If they return but cannot find current needs, improve update visibility first. Avoid building both without evidence.

**5. Decide language and sign-in from pilot friction.** iPhone launch: Apple login once the developer membership is ready; email remains the free development method. Ask Korean participants to complete join/share/update tasks using the current English UI. Add Korean UI if observed comprehension issues justify it; preserve free-text language choice either way.

## Questions to ask without leading the participant

- “Show me how your group shared and followed up on a prayer last week.”
- “Where would you look for the latest update about that person?”
- “What would make you uncomfortable posting this here?”
- “Open this invitation and show me what you expect next.”
- “What would make you keep using KakaoTalk instead?”

No users were contacted, surveys sent, or analytics SDKs added for this report. Feature overlap is substantial; Nanoom's proposed edge is a focused experience for an already-trusting small circle, not the invention of prayer sharing itself.
