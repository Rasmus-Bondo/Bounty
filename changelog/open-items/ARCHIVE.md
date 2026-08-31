# Open items — archive

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md) · [Changelog index](../../CHANGELOG.md)

Closed items, kept so **"was that ever fixed?"** is answerable without re-auditing. Nothing here is
open work — this file exists to be searched, not read.

An item lands here when it reaches `VERIFIED`, `WONTFIX`, or a dated closure. Move the file into
`archive/`, delete its row from [OPEN-ITEMS.md](../OPEN-ITEMS.md), and add a row below **in the
same pass**. Ids are never reused, so a number here can never reappear as open work.

**Not everything here was verified, and the distinction is the point.** A `FIXED (unverified)` item
normally stays open because it still owes a playtest — but an owner may also close one on **elapsed
time without recurrence**, which is what happened to the last ten launch issues on 2026-08-11. Both
are legitimate closures; they are not the same evidence. **Every item states its own basis** in a
`**Closed …**` stamp under its title, so "was that ever actually tested?" is answerable per item.

The **sixteen items closed 2026-08-15** are the largest such batch: every unverified fix and feature
standing behind Hotfix 15, 16, 17 and Update 1, closed together by owner decision without a
playtest. Three of them (#111, #114, #115) had been live for a single day, so they were not closed
on elapsed time either — they were closed to stop tracking them. Anything that resurfaces from that
batch comes back as a **new id**, and #114's rollback hazard on Robux product `3708064902` outlives
its closure.

If a closed item resurfaces, raise it as a **new item with a new id** rather than reopening the old
number — the archive is a record of what was believed when, and rewriting it destroys that.

Prune a row once it has been settled long enough that nobody would ask.

---

## Launch issues (18)

| # | Area / raised | Item | Sev | Status |
|---|---|---|---|---|
| [10](archive/010-duplicate-kill-entries-in-the-kill-feed.md) | Kill feed | Same kill registers twice in a row | P2 | CLOSED 2026-08-11 — no recurrence since launch |
| [13](archive/013-players-sent-into-a-closing-redwater-match.md) | Matchmaking | Players routed into a closing Redwater match, caged 5–10s, bounced to Bounty | P1 | CLOSED 2026-08-11 — no recurrence since launch |
| [14](archive/014-mobile-kill-feed-names-truncate.md) | Mobile / kill feed | Names truncate with `…`; kill feed text should be smaller | P2 | CLOSED 2026-08-11 — no recurrence since launch |
| [17](archive/017-vesper-grapple-overshoots-the-platform.md) | Vesper | Grapple sometimes hurls the player far past the target platform | P2 | CLOSED 2026-08-11 — no recurrence since launch |
| [18](archive/018-titles-appear-before-the-nameplate-fades.md) | Titles | Deadeye title appears before the nameplate fades in | P3 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) |
| [19](archive/019-bots-vanish-instantly-when-a-player-joins.md) | Bots | Bots are kicked instantly when a player joins — should retire on next death instead | P2 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) — live, mid-round join 2026-08-05 |
| [20](archive/020-hunter-swap-menu-sometimes-doesn-t-appear.md) | Hunter swap | Hunter swap menu (kill-cam card row) sometimes doesn't appear | P2 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) — live 2026-08-05; timing race, so absence of the symptom over a full match is the available evidence |
| [22](archive/022-hunter-swap-card-viewports-show-default-skin.md) | Hunter swap | Kill-cam swap card viewports show the default skin instead of the player's equipped skin | P3 | CLOSED 2026-08-11 — no recurrence since launch |
| [23](archive/023-two-charging-brams-pin-each-other.md) | Bram | Two charging Brams pin each other — violent jitter + a ~3.8s mutual combat lock | P2 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) |
| [24](archive/024-dust-ult-fov-change-ends-before-the-ult-does.md) | Dust | FOV change during High Noon ult ends before the ult does — feels like the ult expired early | P2 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) |
| [25](archive/025-players-kicked-by-anti-cheat-while-frozen.md) | Anti-cheat / round end | Players kicked for movement while frozen for the victory showcase | P1 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) — live, full match to the buzzer 2026-08-05, no kicks during the showcase |
| [26](archive/026-pc-alt-has-to-be-pressed-twice-to-free-the-mouse.md) | PC input | Alt has to be pressed twice to free the mouse, and again after every death | P2 | CLOSED 2026-08-11 — no recurrence since launch |
| [27](archive/027-bram-s-last-call-aura-reads-as-a-bounty-aura.md) | Bram / bounty | Last Call's aura is mistaken for the bounty aura — the two need to look different | P3 | CLOSED 2026-08-11 — no recurrence since launch |
| [28](archive/028-holding-alt-through-a-kill-cam-respawn-strands.md) | PC input | Holding Alt through a kill-cam respawn strands the camera frozen for the rest of the life | P2 | CLOSED 2026-08-11 — no recurrence since launch |
| [29](archive/029-bounty-cards-swap-places-in-the-row.md) | Bounty list | Two bounties registered at almost the same time swap places in the card row | P3 | **VERIFIED** 2026-08-06 — owner sign-off |
| [30](archive/030-bounty-portrait-cards-are-too-heavy-on-a-phone.md) | Bounty list / mobile | Bounty portrait cards take too much of a phone screen — want smaller, transparent, or moved on mobile | P2 | CLOSED 2026-08-11 — no recurrence since launch |
| [31](archive/031-combat-text-sits-on-the-crosshair.md) | Combat feed / mobile + PC | Combat text sits on the crosshair; its black background is twice the width of the text | P2 | **VERIFIED** 2026-08-07 — owner sign-off, mobile + PC |
| [32](archive/032-stats-menu-never-resets-between-rounds.md) | Stats menu (M / mobile Stats button) | Per-match stats never reset between rounds — the panel accumulates every round the server has played | P2 | CLOSED 2026-08-11 — no recurrence since launch |

## Standing concerns (62)

| # | Area / raised | Item | Sev | Status |
|---|---|---|---|---|
| [125](archive/125-collection-previews-depend-on-an-animation-fetch-to-render.md) | Portrait render fix (2026-08-24) | Claimed the lobby's Collection / bundle previews rendered only because they play an idle track after stripping the rig's `Animate` script | P3 | **WITHDRAWN** 2026-08-24 — premise wrong, raised and closed same day. The failure needs a **Motor6D** rig; all fourteen lobby preview rigs are AnimationConstraint and render with their scripts destroyed (screenshot-verified). The three sites were hardened anyway; no behaviour changed |
| [119](archive/119-two-tutorial-test-switches-are-on.md) | Hotfix 1.2 | Three tutorial test switches were ON for the DEV soak — a repeat live payout, a forced tutorial mode, and a per-join offer card | P1 | **VERIFIED** 2026-08-17 — all three back to `false` before the live publish; owner joined live on the listed account and saw no offer card |
| [116](archive/116-vesper-s-world-hold-pose-doesn-t-grip-the-sniper.md) | owner report | Vesper's world hold pose doesn't grip the sniper | P2 | **VERIFIED** 2026-08-15 — owner playtest, 2 clients + server. Not a pose defect: the hold was not playing at all, fixed by `VesperWorldIdleClient` the same day |
| [115](archive/115-hunter-switch-across-a-map-move-is-unplayed.md) | Update 1 (2nd publish) | Hunter switch across a map move is unplayed — needs a live vote, party **and** solo | P1 | CLOSED 2026-08-15 — owner decision, **never verified**; live one day |
| [114](archive/114-bundle-processreceipt-is-unproven-against-a-real-purchase.md) | Update 1 | Bundle `ProcessReceipt` is unproven against a real purchase | P1 | CLOSED 2026-08-15 — owner decision, **never verified**; the revert hazard on product `3708064902` still stands |
| [111](archive/111-frostbite-vesper-hook-markers-without-standable-pads.md) | Frostbite bring-up | Frostbite Vesper hook markers without standable pads | P3 | CLOSED 2026-08-15 — owner decision, never verified; live one day |
| [110](archive/110-parked-dead-assets-are-unverified-in-a-running-game.md) | Hotfix 17 | Parked dead assets are unverified in a running game | P3 | CLOSED 2026-08-15 — owner decision, never verified |
| [108](archive/108-victory-podium-streaming-crash-fix-is-unplayed.md) | Hotfix 17 | Victory podium streaming-crash fix is unplayed | P1 | CLOSED 2026-08-15 — owner decision, never verified |
| [107](archive/107-round-start-leaver-abort-fix-is-unplayed.md) | Hotfix 17 | Round-start leaver-abort fix is unplayed | P1 | CLOSED 2026-08-15 — owner decision, never verified |
| [105](archive/105-ranked-season-3-boundary-is-unverified-on-live.md) | Hotfix 16 | Ranked season 3 boundary is unverified on live | P1 | CLOSED 2026-08-15 — owner decision, never verified; the 2026-08-14 boundary passed unobserved and cannot be re-run |
| [104](archive/104-bounty-music-retry-and-warn-path-is-unexercisable.md) | Hotfix 16 | Bounty music retry-and-warn path is unexercisable | P3 | CLOSED 2026-08-15 — owner decision, never exercised |
| [120](archive/120-frostbite-spawn-houses-are-tighter-than-redwater.md) | Unreleased | Team spawn markers landed on the roof, outside the walls, and inside decorative crates | P2 | **VERIFIED** 2026-08-19 — owner playtested all four houses |
| [103](archive/103-anti-cheat-delta-reweighting-is-unverified.md) | Hotfix 16 | Anti-cheat delta reweighting is unverified | P1 | CLOSED 2026-08-15 — owner decision, never verified; no false-positive kick reported |
| [102](archive/102-attribute-no-value-crash-fix-cannot-be-reproduced-in-studio.md) | Hotfix 16 | Attribute *no-value* crash fix cannot be reproduced in Studio | P1 | CLOSED 2026-08-15 — owner decision, never verified; error dashboard quiet since |
| [101](archive/101-animationtrack-leak-fix-is-unverified.md) | Hotfix 16 | AnimationTrack leak fix is unverified | P2 | CLOSED 2026-08-15 — owner decision, never verified |
| [100](archive/100-friend-join-and-tutorial-dispatch-fixes-are-unverified-on-live.md) | Hotfix 16 | Friend-join and tutorial-dispatch fixes are unverified on live | P1 | CLOSED 2026-08-15 — owner decision, never verified |
| [99](archive/099-the-breach-charge-pin-path-was-never-reproduced.md) | Hotfix 15 | The Breach Charge pin path was never reproduced | P1 | CLOSED 2026-08-15 — owner decision, never verified |
| [98](archive/098-join-lock-removal-is-unverifiable-in-studio.md) | Hotfix 15 | Join-lock removal is unverifiable in Studio | P2 | CLOSED 2026-08-15 — owner decision, never verified |
| [97](archive/097-fortuna-s-viewmodel-and-arm-fixes-are-unplayed.md) | Hotfix 15 | Fortuna's viewmodel and arm fixes are unplayed | P1 | CLOSED 2026-08-15 — owner decision, never verified |
| [96](archive/096-tutorial-welcome-and-outro-cards-are-unplayed-on-touch.md) | Hotfix 15 | Tutorial welcome and outro cards are unplayed on touch | P3 | CLOSED 2026-08-15 — owner decision, never verified |
| [87](archive/087-dev-staging-universe-not-yet-created.md) | Launch | DEV staging universe not yet created | — | **VERIFIED** 2026-08-14 → [Update 1](../2026-08-14-update-1.md) — separate universe, `GameEnvironment` rows, whole Update 1 flow verified on it pre-publish |
| [33](archive/033-onboarding-live-to-everyone-and-verified-end.md) | unreleased | Onboarding: live to everyone and verified end to end | — | CLOSED 2026-08-11 |
| [34](archive/034-auto-fire-now-shoots-through-wooden-cover.md) | Hotfix 12 | Auto-fire now shoots through wooden cover, and that is a feel change nobody has played | P2 | CLOSED 2026-08-11 |
| [36](archive/036-the-mobile-auto-fire-retune-has-not-been-played.md) | Hotfix 11 | The mobile auto-fire retune has not been played on a phone | P2 | CLOSED 2026-08-11 |
| [37](archive/037-vesper-s-firequality-0-55-is-a-first-guess.md) | Hotfix 11 | Vesper's `FireQuality = 0.55` is a first guess and the single lever if she reads wrong | P3 | CLOSED 2026-08-11 |
| [38](archive/038-the-animation-fetch-guard-did-not-cover-a-client.md) | Hotfix 10 | The animation fetch guard did not cover a *client's* fetch failure of a server-played clip | P3 | VERIFIED 2026-08-07 — owner sign-off, mobile + PC, |
| [39](archive/039-the-ultimate-ready-halo-was-observed-stuck.md) | Hotfix 9 | The ultimate-ready halo was observed stuck ON while the ultimate was not ready | — | CLOSED 2026-08-11 |
| [40](archive/040-mobile-aim-assist-still-tracks-an-invisible.md) | Hotfix 9 | Mobile aim assist still tracks an invisible Fortuna | — | CLOSED 2026-08-11 |
| [41](archive/041-the-ultimate-ready-glow-has-never-been-measured.md) | Hotfix 9 | The ultimate-ready glow has never been measured on a phone | — | CLOSED 2026-08-11 |
| [42](archive/042-bram-s-last-call-tile-pop-is-confirmed-on-mobile.md) | Hotfix 9 | Bram's Last Call tile pop is confirmed on mobile but not desktop | — | CLOSED 2026-08-11 |
| [43](archive/043-the-ultimate-half-of-the-hunter-hud.md) | Hotfix 9 | The ultimate half of the hunter HUD is still duplicated four times | — | CLOSED 2026-08-11 |
| [44](archive/044-fortuna-s-lag-compensation-has-never-run-against.md) | Hotfix 9 | Fortuna's lag compensation has never run against real latency | — | CLOSED 2026-08-11 |
| [45](archive/045-the-ultimate-s-card-ring-still-lags-its-own.md) | Hotfix 9 | The ultimate's card ring still lags its own damage | — | CLOSED 2026-08-11 |
| [46](archive/046-animationloader-s-retry-and-warn-path-has-never.md) | Hotfix 10 | `AnimationLoader`'s retry-and-warn path has never actually fired | — | CLOSED 2026-08-11 |
| [47](archive/047-mobile-auto-fire-shipped-without-the-lock.md) | Hotfix 10 | Mobile auto-fire shipped without the lock indicator it was built with | — | CLOSED 2026-08-11 |
| [48](archive/048-aim-assist-camera-magnetism-is-switched-off.md) | Hotfix 10 | Aim assist camera magnetism is switched off, not removed | — | CLOSED 2026-08-11 |
| [49](archive/049-killfeedclient-still-carries-the-uishadow-scale.md) | Hotfix 10 | `KillFeedClient` still carries the `UIShadow` scale-radius bug that Hotfix 10 fixed in `CombatFeedClient` | — | CLOSED 2026-08-11 |
| [52](archive/052-coderedemptionservice-is-a-17th-mirrored-module.md) | Hotfix 8 | `CodeRedemptionService` is a 17th mirrored module that no automated gate checks | — | CLOSED 2026-08-11 |
| [53](archive/053-hotfix-8-s-bram-charge-work-is-verified-by-probe.md) | Hotfix 8 | Hotfix 8's Bram charge work is verified by probe and simulation, never played | — | CLOSED 2026-08-11 |
| [54](archive/054-both-hotfix-7-fixes-are-replication-timing.md) | Hotfix 7 | Both Hotfix 7 fixes are replication-timing changes and neither is playtest | — | CLOSED 2026-08-11 |
| [55](archive/055-removing-vesper-s-undamped-sensitivity-warning.md) | Hotfix 7 | Removing Vesper's undamped-sensitivity warning removed the only signal for that condition | — | CLOSED 2026-08-11 |
| [56](archive/056-the-lobby-s-loading-screen-cover.md) | Hotfix 7 | The lobby's loading-screen cover is a coincidence of timing, not a gate | — | CLOSED 2026-08-11 |
| [57](archive/057-the-duplicate-kill-feed-line-is-guarded.md) | #10 | The duplicate kill-feed line is guarded, not diagnosed | — | CLOSED 2026-08-11 |
| [58](archive/058-high-noon-still-keeps-its-own-copy-of-the-post.md) | #3 | High Noon still keeps its own copy of the post-hit bookkeeping | — | CLOSED 2026-08-11 |
| [59](archive/059-more-bounty-targets-means-more-bounty-payouts.md) | #21 | More bounty targets means more bounty payouts — a balance question, not a bug | — | CLOSED 2026-08-11 |
| [60](archive/060-a-flagged-bot-briefly-pushes-the-arena-above.md) | #19 | A flagged bot briefly pushes the arena above its headcount target | — | CLOSED 2026-08-11 |
| [61](archive/061-vesper-s-bolt-cycle-layer-is-now-audible-during.md) | #4 | Vesper's bolt-cycle layer is now audible during Starfall | — | CLOSED 2026-08-11 |
| [62](archive/062-two-hotfix-6-handoffs-could-not-be-checked.md) | Hotfix 6 | Two Hotfix 6 handoffs could not be checked without playing them | — | CLOSED 2026-08-11 |
| [63](archive/063-the-quest-tab-dots-final-placement-is-confirmed.md) | Hotfix 6 | The quest tab dots' final placement is confirmed live | — | CLOSED |
| [64](archive/064-the-kill-feed-may-still-look-inset-on-a-real.md) | #14 | The kill feed may still look inset on a real phone, and that is the safe area, not the alignment | — | CLOSED 2026-08-11 |
| [65](archive/065-two-bram-tuning-values-are-provisional-pending.md) | #23 / #6 | Two Bram tuning values are provisional, pending play | — | CLOSED 2026-08-11 |
| [66](archive/066-three-panels-remain-in-the-old-grey-gothamssm.md) | Hotfix 6 | Three panels remain in the old grey/`GothamSSm` style | — | CLOSED 2026-08-11 |
| [67](archive/067-a-spawn-teleport-could-silently-fail-to-move.md) | standing concern | A spawn teleport could silently fail to move the player | — | CLOSED 2026-08-11 |
| [68](archive/068-rank-tiers-named-brackets-deferred.md) | Launch | Rank tiers (named brackets) deferred | — | CLOSED 2026-08-11 — deferred |
| [69](archive/069-boost-trading-post-deferred.md) | Launch | Boost trading post deferred | — | CLOSED 2026-08-11 — deferred |
| [71](archive/071-unbounded-client-waitforchild-calls-largely.md) | standing concern | Unbounded client `WaitForChild` calls — largely closed 2026-08-03, and the original bullet's inventory was wrong in three ways | — | CLOSED 2026-08-11 |
| [72](archive/072-asset-load-failures-rotate-rather-than-climb.md) | Hotfix 2 | Asset load failures rotate rather than climb | — | CLOSED 2026-08-11 |
| [73](archive/073-grapplehookservice-still-carries-its-own-grace.md) | Hotfix 2 | `GrappleHookService` still carries its own grace implementation | — | CLOSED 2026-08-11 |
| [74](archive/074-two-safety-valves-are-live-and-marked.md) | Hotfix 4 | Two safety valves are live and marked for deletion once verified | — | CLOSED 2026-08-11 |
| [75](archive/075-bounty-dead-ui-purge.md) | Hotfix 2 | Bounty dead-UI purge | — | RESOLVED |
| [76](archive/076-kill-feed-rows-do-not-hug-their-content-so-short.md) | #14 | Kill-feed rows do not hug their content, so short rows show a wide empty bar | — | CLOSED 2026-08-11 |
| [77](archive/077-a-steep-slope-still-stops-bram-without-ending.md) | standing concern | A steep slope still stops Bram without ending his charge | — | VERIFIED |
| [78](archive/078-botcombat-slampin-settles-only-bot-victims.md) | standing concern | `BotCombat._slamPin` settles only *bot* victims | — | CLOSED 2026-08-11 |

## Internal (2)

| # | Area / raised | Item | Sev | Status |
|---|---|---|---|---|
| [79](archive/079-redwater-startergui-three-screenguis-were-left.md) | internal | Redwater `StarterGui` — three ScreenGuis were left `Enabled = false` that must be `true` | — | VERIFIED |
| [80](archive/080-the-three-items-the-mobile-touch-ui-rebuild.md) | internal | The three items the mobile touch UI rebuild raised, and why two of them were not real | — | CLOSED |

## Resolved before the split (16)

Carried over from the old file's `Resolved` section on 2026-08-11.

| # | Area / raised | Item | Sev | Status |
|---|---|---|---|---|
| [1](archive/001-abilities-escaped-bram-s-charge-no-lockout-while.md) | Bram / abilities | Fortuna E, Dust Q, Vesper Q escape Bram's charge; no ability lockout while rammed or stunned | P1 | **VERIFIED** → [Hotfix 3](../2026-08-03-hotfix-3.md) |
| [3](archive/003-being-killed-by-high-noon-played-no-sound-at-all.md) | Audio | No sound at all plays on the victim when killed by High Noon | P2 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) |
| [4](archive/004-vesper-s-first-shot-after-her-ultimate.md) | Audio | First shot after Vesper ult activates has no sound | P2 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) |
| [5](archive/005-bram-s-charge-cooldown-started-on-the-keypress.md) | Bram | Charge cooldown starts on keypress instead of on charge end | P2 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) |
| [6](archive/006-bram-s-charge-could-be-cancelled-on-frame-one.md) | Bram | Charge can be cancelled instantly — needs a 1s cancel lockout | P2 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) |
| [7](archive/007-victory-win-3-matches-did-not-say-whether.md) | Quests | Week 1 "VICTORY — Win 3 matches" wording is ambiguous (1st vs top 3) | P3 | **VERIFIED** → [Hotfix 5](../2026-08-03-hotfix-5.md) |
| [8](archive/008-abilities-and-movement-during-the-match-summary.md) | Match flow | Abilities and movement still usable during match summary | P1 | **VERIFIED** → [Hotfix 4](../2026-08-03-hotfix-4.md) |
| [9](archive/009-bram-s-charge-forced-victims-through-walls.md) | Bram | Charging into a wall can leave the player stuck | P1 | **VERIFIED** → [Hotfix 3](../2026-08-03-hotfix-3.md) |
| [11](archive/011-owned-items-read-purchase-instead-of-equip.md) | Collection | Owned items show PURCHASE instead of EQUIP when arriving from Redwater | P1 | **VERIFIED** → [Hotfix 3](../2026-08-03-hotfix-3.md) |
| [12](archive/012-high-noon-locked-onto-spawn-protected-players.md) | Dust | High Noon can target spawn-protected (invincible) players | P1 | **VERIFIED** → [Hotfix 5](../2026-08-03-hotfix-5.md) |
| [15](archive/015-mobile-daily-reward-day-2-unclaimable-day-1.md) | Mobile / daily rewards | Day 2 impossible to claim, Day 1 difficult | P1 | **VERIFIED** → [Hotfix 3](../2026-08-03-hotfix-3.md) |
| [16](archive/016-sun-too-bright-players-invisible-on-platforms.md) | Lighting | Sun too bright — players on platforms are invisible from the ground | P1 | **VERIFIED** → [Hotfix 5](../2026-08-03-hotfix-5.md) |
| [21](archive/021-bots-on-a-kill-streak-never-got-a-bounty.md) | Bots / bounty | Bots on a kill streak don't get a bounty placed on them like players do | P2 | **VERIFIED** → [Hotfix 6](../2026-08-05-hotfix-6.md) |
| [93](archive/093-legacy-cash-developer-product-3601170442-retired.md) | resolved | Legacy Cash Developer Product `3601170442` retired — deactivated on the Creator Hub | — | RESOLVED |
| [94](archive/094-ranked-rp-runtime-round-trip.md) | Launch | Ranked RP runtime round-trip | — | RESOLVED |
| [95](archive/095-bram-s-stun-server-side-backstop.md) | Launch | Bram's stun server-side backstop | — | RESOLVED |
