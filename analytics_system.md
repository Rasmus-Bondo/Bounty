# Analytics & Data Logging

Built 2026-07-27, ahead of launch. Purpose: find out whether **mobile players feel underpowered**, while the week-1 goal is 500 highly engaged users — fun over competitive.

Every number below can be split by platform. That was impossible before this system: the server has no view of input devices, so nothing knew who was on a phone.

---

## Three layers

**1. Free from Roblox, no code.** Average session time, DAU, D1/D7 retention, already broken down by device type on the Engagement and Retention pages. Deliberately not rebuilt.

**2. Onboarding funnel, steps 1-7** (pre-existing, untouched). Joined Lobby → Selected Hunter → Clicked Play → Joined Round → Shot the Gun → Hit a Player → Killed or Assisted. Fires once per player ever.

**3. New: 10 custom events + custom funnels.**

### Custom events

`CustomField01` is always the plain platform. Anywhere a hunter appears it is the composite `"Platform|Hunter"`, so a single field answers "Vesper on phones".

| Event | Value | CF02 | CF03 |
|---|---|---|---|
| `MatchStart` | 1 | Platform\|Hunter | 1st / 2nd / 3-5 / 6+ match ever |
| `MatchEnd` | seconds played | Completed / LeftEarly | 1st / 2nd / 3+ match this sitting |
| `MatchKills` | kills | 0 / 1-2 / 3-5 / 6+ | Platform\|Hunter |
| `MatchDeaths` | deaths | human count bucket | Platform\|Hunter |
| `MatchAccuracy` | accuracy % | Platform\|Hunter | 1st / 2nd / 3-5 / 6+ match ever |
| `MatchDamage` | damage dealt | Platform\|Hunter | — |
| `FirstKillTime` | seconds | Platform\|Hunter | 1st / 2nd / 3-5 / 6+ match ever |
| `HunterSwitch` | 1 | Platform\|FromHunter | ToHunter |
| `ClientPerf` | avg FPS | avg FPS bucket | worst-second FPS bucket |
| `SessionEnd` | seconds in place | Bounty / Redwater | Lobby / MidMatch / PostGame |

### `NewPlayer` funnel

`First Join → Tutorial Started → Tutorial Completed → Returned To Lobby → Queued For Match → Joined Match → Finished Match`

**The chart the game actually needed** — the whole first-time arc, end to end, split by platform. Added 2026-08-15, replacing `MatchLoop` (`Match Requested → Teleport Started → Joined Round → Round Started → Reached Buzzer`), which after a year read 100 / 99.98 / 99.48 / 98.38 / 41.88: a 1.6% loss over its first four steps, meaning teleport reliability is a settled question, and a last step already readable off `MatchEnd`'s Completed/LeftEarly with a platform breakdown attached. Steps 5 → 6 preserve the one thing it measured that nothing else does — the gap between pressing Play and arriving in a round, where a `TeleportInitFailed` after a clean `TeleportAsync` return is otherwise indistinguishable from lost interest.

**One funnel per ACCOUNT, not per session.** The id lives on the profile (`Tutorial.JourneyId`) rather than in TeleportData, so it survives teleports, rejoins and days without any plumbing at the call sites.

**The gate is the whole design, and it inverts rule 3 below.** Every other funnel here stays honest because each step is strictly implied by the ones after it. This one cannot be: "played a real match" does **not** imply "completed the tutorial" — grandfathered veterans, new players forwarded into a friend's match by FollowJoinService, dispatches that exhausted the retry ladder, and abandoners sitting at `Attempts >= 2` all reach the last three steps having never touched the first three. Logged naively, backfill would make the chart read *better* the more players skipped the lesson. So instead of relying on implication, `Telemetry.logJourneyStep` **enforces** it: `Tutorial.JourneyStep` records the highest step actually reached, and a step is refused unless it is exactly its successor. Backfill has nothing to fill in, and a player who plays a match without finishing the lesson simply stalls where they stopped — which is the truth.

**Cohort:** the id is minted on the grandfather screen's un-grandfathered branch (`DataService.onPlayerAdded`, in *both* places — a follow-joiner's first profile load happens in Redwater). An empty id means "not a new player" and drops every step, which is what keeps the existing player base out of a funnel they could never finish. Nothing is retroactive: only accounts created from the publish forward appear.

**Platform rides step 1 only**, like every funnel, so step 1 waits (up to 10s) for TelemetryClient's report before firing — a brand-new account has no persisted `LastPlatform` to fall back on, and an "Unknown" step 1 would cost exactly the phone-vs-desktop split this chart exists for.

---

## What we learn at launch

Sentences we'll be able to complete within a couple of days:

- Phone players complete their first match ___% of the time; desktop ___%.
- ___% of mobile first matches end with **zero kills** — the churn case an average hides.
- Mobile accuracy is ___% vs. desktop's ___%. The most direct read on aiming with a touchscreen.
- Median mobile player takes ___ seconds to their first kill.
- ___% of mobile players who finish a match start a second one, and ___% do it in the same sitting.
- ___ mobile players switch off Vesper mid-match vs. ___ off Dust. A swap costs a death, so this is revealed preference, not a proxy.
- ___% of phones run below 30 FPS.
- Of mobile players who quit, ___% do it mid-match rather than at the summary.

**The single most useful chart** is the onboarding funnel split by platform. The largest gap between two adjacent steps on phones is the number-one fix:

| Drop between | Diagnosis |
|---|---|
| 5 → 6 (shot, never hit) | Can't aim — tune aim assist |
| 6 → 7 (hit, never killed) | TTK or health |
| 7 → completion | Fun but won't stay six minutes — round length |
| completion → second match | Loop isn't pulling them back — rewards or lobby friction |

`ClientPerf` is the tiebreaker throughout: a mid-match quit on low FPS is a *technical* problem; the same quit on healthy FPS is a *design* problem.

## What we learn after launch week

- **Per-hunter balance by platform**, once sample sizes support it. Note the counter-intuitive part: Roblox skews heavily mobile, so **desktop is the thin cohort** — and desktop is the comparison baseline. If desktop cells get too sparse, collapse Phone+Tablet into one Touch bucket rather than dropping the hunter split.
- **Whether the `"Mixed"` cohort is large.** Players who switch hunters mid-match are reported as `Mixed` rather than attributed to one hunter. If `Mixed` turns out to be a big share of matches, that justifies upgrading to true per-hunter stat buckets in `RoundStatsService`.
- **Retention shape** from the lifetime match buckets on `MatchStart` — where players stop coming back.
- **Economy breakdowns**, now that `Wallet`'s custom fields are fixed: Cash/Token sources and sinks split by granular reason and by place.

---

## What this cannot tell us

- **Aggregates only.** No per-player drill-down, no raw event rows.
- **~Daily dashboard latency.** Not a live feed; plan the reaction cycle around it.
- **No backfill.** Data exists only from the publish forward.
- **A crash and a rage-quit look identical** — both are `LeftEarly`. `ClientPerf` partly disambiguates.
- **Historical economy events (2026-07-09 → 2026-07-27) have no reason or place breakdown.** `Wallet` was passing EnumItems where the engine expects string keys, so the fields were silently dropped. Currency, amount, balance, transactionType and SKU are all correct for that window. Partial recovery: gameplay earns that passed no SKU had their reason land in the **SKU** column instead.
- **Late joiners** get a `MatchStart` but no combat aggregates, so per-match kill/accuracy averages describe full rounds only.
- `MatchAccuracy` is skipped below 10 shots fired — accuracy off a handful of shots is noise.

---

## Where the code lives

| Script | Role |
|---|---|
| `ServerScriptService.PlayerServices.Telemetry` | The chokepoint. **Mirrored verbatim in all three places.** Owns every `LogCustomEvent`, the event-name registry, the `NewPlayer` and `Tutorial` funnels, rate budgets, and the Studio gate. Also fires `NewPlayer` step 1 itself, from its own `PlayerAdded` handler in Bounty — a call site in the lobby would race TutorialDispatchService, which can teleport a first-timer out before their lobby character ever spawns |
| `PlayerServices.DataService` | Mints `Tutorial.JourneyId` on the grandfather screen's un-grandfathered branch (both places) and stores `Tutorial.JourneyStep`. The arrow points this way on purpose: the data layer carries no dependency on analytics |
| `Onboarding.TutorialDirector` (Redwater) | `NewPlayer` steps 2-3, plus the `Tutorial` funnel and `TutorialRun` |
| `Onboarding.TutorialDispatchService` (Bounty) | `NewPlayer` step 4, off `TeleportData.tutorialComplete` on arrival |
| `StarterPlayerScripts.TelemetryClient` | Resolves platform (server can't) and samples FPS. Identical file in both places; the FPS half is inert in Bounty |
| `RoundSystem.RoundController` | The per-match emit block, the persisted match counters, and `NewPlayer` steps 6-7 |
| `PlayerServices.RoundStatsService` | Per-hunter tracking, `hunterLabel` / `"Mixed"`, time-to-first-kill |
| `PlayerServices.HunterSwitchService` | `HunterSwitch`, fired on apply rather than request |
| `Party.PartyService` (Bounty) | `NewPlayer` step 5, from the Play button and from `prepareGroupTeleport` (a friend join is queuing for a match too) |
| `PlayerServices.Wallet` | Economy events (pre-existing; custom-field bug fixed 2026-07-27) |

## Rules for changing it

1. **`Telemetry` is mirrored verbatim.** Event names, funnel names and the 8,000-custom-field-combination budget are per-*experience*, not per-place — as is the **10-funnel-per-experience cap**, of which 2 are used (`NewPlayer`, `Tutorial`) plus the separate built-in onboarding funnel. Edit all three copies in one pass and verify with a byte-length + checksum compare.
2. **Never log from a per-shot, per-hit or per-death path.** Add a counter to `RoundStatsService` and emit the aggregate at the buzzer. Logging from combat code is what tripped the AnalyticsService event cap in July.
3. **A funnel step is only valid if every later step logically requires it — or is refused when it doesn't.** Roblox backfills skipped steps, so a step that later steps don't imply gets marked complete for people who never did it. This is why match completion is *not* on the onboarding funnel: finishing a round does not imply getting a kill, and adding it would have marked every 0-kill mobile player as having killed someone — erasing exactly the cohort the chart exists to find. `NewPlayer` is the one funnel whose steps genuinely aren't implied, and it survives by enforcing the order against the profile instead of assuming it; copy that pattern rather than the assumption if you add a funnel spanning optional content.
4. **New event names must be added to the `EVENTS` registry** in both copies. An unregistered name warns and drops rather than silently minting a new one.
