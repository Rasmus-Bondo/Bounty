# Changelog — Bullets and Bounty

**INTERNAL. Not player-facing.** These files are the complete record, including place version
numbers and security fixes. The curated player-facing notes (game description, Discord
`#patch-notes`) are derived from them by hand — never paste one outright.

With no git repository, this is the project's only version history. Roblox place versions are the
rollback index; the entries below are how you know *which* version to roll back to.

**This file is an index and nothing else.** One row per release. The detail lives in
[`changelog/`](changelog/) — open only the release you need.

---

## Where to look

| I need… | Go to |
|---|---|
| What shipped in a given release | the release file in the table below |
| What is in flight right now | [changelog/UNRELEASED.md](changelog/UNRELEASED.md) |
| What is still broken or deferred | the [project board](https://github.com/users/Rasmus-Bondo/projects/1) — or run `/issues`. **Not** `changelog/OPEN-ITEMS.md`, which is a signpost and an old-id → issue mapping |
| Whether something was ever fixed | a closed issue on the board, or [changelog/open-items/ARCHIVE.md](changelog/open-items/ARCHIVE.md) for the 99 closed before 2026-08-31 |
| How to name a release, what the metadata fields mean, the 20 mirrored modules | [changelog/CONVENTIONS.md](changelog/CONVENTIONS.md) |
| To write an entry | run `/changelog` — it writes into `UNRELEASED.md` |
| To ship | run `/preflight` — it gates, rolls `UNRELEASED.md` into a dated file, and bumps the version |

---

## Releases

Newest first. A **rollback target** is the previous row's versions — that is where a revert of
any release lands. Revert **both** places, never one.

| Release | Date | Published | Data-affecting | What it was |
|---|---|---|---|---|
| [Hotfix 3.1](changelog/2026-09-09-hotfix-3-1.md) | 2026-09-09 | `Bounty r2762 · Redwater r3133 · Frostbite r735` | no | The onboarding tutorial loses its two menu steps and its walk to the third pad, ending instead on a 20-second live-fire fight with a TIME LEFT countdown under EXIT TRAINING and a red outline on the first bots it asks you to kill — with a second cut from the opening card, two and a half from the goodbye, and the Tutorial funnel retuned from eleven rows to eight. |
| [Update 3](changelog/2026-09-07-update-3.md) | 2026-09-07 | `Bounty r2759 · Redwater r3118 · Frostbite r727` | **yes — one-way** | Lootbox chests arrive as the lobby's LOOT tab with a full chest-opening scene and a one-way launch migration that resets every returning player's Level and XP, alongside BOUNTY+ as a permanent-perk game pass, a centre kill announcement and floating damage numbers replacing the combat feed in both match places, a level-up card, new-item bubbles chaining down the Collection, round XP and Cash credited as they are earned rather than at the buzzer, and an overhauled seven-day daily reward. |
| [Update 2](changelog/2026-08-29-update-2.md) | 2026-08-29 | `Bounty r2626 · Redwater r3063 · Frostbite r684` | **yes** | Team Deathmatch and Domination ship as the second and third gamemodes — two teams, one-way spawn houses on both maps, relative team colours and an end-of-match mode ballot — with QUICK PLAY as the lobby's new default, alongside four gun skins, a BUNDLES tab in the Trading Post, ranked season payouts to the top 100, first-person animation sets for every hunter, a match summary that happens on the map, and a combat anti-cheat running in detection only. |
| [Hotfix 1.2](changelog/2026-08-17-hotfix-1-2.md) | 2026-08-17 | `Bounty r2475 · Redwater r2726 · Frostbite r406` | **yes** | The onboarding tutorial becomes a skippable offer that pays its 250 Cash and 50 Tokens a step at a time and can be replayed from the lobby's CHANGE MODE picker — plus the TRAINING COMPLETE card and combat feed carrying the game's real currency icons, and fixes for the tutorial's Token award never reaching the completion card, the PLAY and CHANGE MODE signs being nearly unhittable on a 4:3 tablet, and a picker that ignored clicks outside it. |
| [Hotfix 1.1](changelog/2026-08-16-hotfix-1-1.md) | 2026-08-16 | `Bounty r2457 · Redwater r2712 · Frostbite r363` | **yes** | Players are no longer matchmade into a match on another continent, the onboarding tutorial moves into a purpose-built walled bowl, and the map vote folds into the match-summary screen — plus mobile touch buttons re-placed and re-sized from a real device, a seven-step first-time-player funnel replacing the retired `MatchLoop` one, Dead Eye no longer locking through wooden buildings, Vesper visibly holding her rifle on other players' screens, and bots no longer stranding on rocks. |
| [Update 1](changelog/2026-08-14-update-1.md) | 2026-08-14 | 1st: `Bounty r2433 · Redwater r2613 · Frostbite r332`<br>2nd: `Bounty r2440 · Redwater r2616 · Frostbite r341` — **roll back to the 2nd** | **yes** | Frostbite Claim ships as the second map — matchmaking assigns each match's map, players vote the next one at every round end, and a winning vote teleports the whole server — alongside a winter skins drop of three hunter skins and Vesper's first gun skin, a "Let the Hunt Begin" Robux bundle, per-map zone shapes, a look-around death cam when nothing killed you, 35 revolver sounds reattached to the volume sliders, and a DEV universe where all of it was verified before going live. |
| [Hotfix 17](changelog/2026-08-13-hotfix-17.md) | 2026-08-13 | `Bounty r2392 · Redwater r2554` | no | Redwater's zone geometry moves out of the round config into a new per-place `MapConfig` so the second map can declare its own, plus fixes for a player leaving at round start costing everyone behind them their fresh character and the end-of-match podium crashing when it streams in empty — and dead assets cut from both places' join-time download. |
| [Hotfix 16](changelog/2026-08-13-hotfix-16.md) | 2026-08-13 | `Bounty r2390 · Redwater r2545` | **yes** | Corpses stop healing themselves and dying a second time, joining a friend from the Roblox app stops answering "their match already ended" for four situations that were not that, and passive healing now pauses for five seconds after you take damage — plus completely silent movement, a second knocked off the respawn, and a ranked leaderboard season reset landing 14 August. |
| [Hotfix 15](changelog/2026-08-12-hotfix-15.md) | 2026-08-12 | `Bounty r2382 · Redwater r2518` | no | The training run ends on the live-fire fight instead of a two-minute free roam and opens on the Bounty logo card, matches accept players right to the buzzer, and group-perk skins unlock from the wardrobe where the player is standing — plus Dust no longer pinned unable to shoot after a Breach Charge, a reload lost to a stun retried instead of dropped, and 3,800 lines of dead Redwater code removed ahead of the second map. |
| [Hotfix 14](changelog/2026-08-11-hotfix-14.md) | 2026-08-11 | `Bounty r2354 · Redwater r2487` | **yes** | Onboarding opens to every new player — the training run now ends on a kill and hands the canyon over for two minutes, a player who joins a friend is never diverted into it, and the veteran check that would have locked those players out for good is now a one-time decision. |
| [Hotfix 13](changelog/2026-08-11-hotfix-13.md) | 2026-08-11 | `Bounty r2342 · Redwater r2458` | **yes** | The onboarding training run ships behind a test-account gate — built end to end across both places but reaching no players yet — alongside a hold-TAB stats panel, new first-person animation sets for Dust and Vesper, and fixes for Fortuna's mobile double jump and the training HUD leaking into real matches. |
| [Hotfix 12](changelog/2026-08-08-hotfix-12.md) | 2026-08-08 | `Bounty r2333 · Redwater r2345` | no | Mobile gains dedicated JUMP and RELOAD buttons and a single regrouped touch cluster, plus fixes for the SWAP HUNTER button vanishing mid-kill-cam, drifting ability icons and tablet layout — and a scripting layer for bots that is inert in an ordinary match. |
| [Hotfix 11](changelog/2026-08-07-hotfix-11.md) | 2026-08-07 | `Bounty r2328 · Redwater r2293` | no | Mobile auto-fire now takes the shots the server would actually score, sized to each hunter's own hit rules instead of one conservative value — plus the stats menu rebuilt in the game's visual language, and its counters starting each round from zero instead of accumulating. |
| [Hotfix 10](changelog/2026-08-07-hotfix-10.md) | 2026-08-07 | `Bounty r2327 · Redwater r2279` | **yes** | Mobile players now fire by holding the crosshair on an enemy, behind a new Auto Fire settings toggle — plus a mirrored animation loader that turns silent clip-download failures into real, retried, reported ones, and a combat reward feed moved off the crosshair. |
| [Hotfix 9](changelog/2026-08-06-hotfix-9.md) | 2026-08-06 | `Bounty r2317 · Redwater r2244` | no | Redwater Canyon now plays rounds continuously instead of closing after one, behind a rebuilt two-step match summary — plus readiness cues on every hunter HUD, Fortuna's cards landing the shots that look like hits, and bots that finally respect her invisibility. |
| [Hotfix 8](changelog/2026-08-05-hotfix-8.md) | 2026-08-05 | `Bounty r2314 · Redwater r2196` | no | Bram's Breach Charge geometry collapsed into one shared module, closing five charge defects that previously had to be fixed per-implementation — plus the bounty list rebuilt as portrait cards under the match timer, kill-cam swap cards showing equipped skins, and Alt no longer stranding the camera after a respawn. |
| [Hotfix 7](changelog/2026-08-05-hotfix-7.md) | 2026-08-05 | `Bounty r2308 · Redwater r2151` | no | Two warnings that each hid a real bug — the lobby's per-join weapon-grip warning, which was a replication-ordering race rather than the streaming problem Hotfix 5 fixed, and Vesper's spurious "undamped sensitivity" line. |
| [Hotfix 6](changelog/2026-08-05-hotfix-6.md) | 2026-08-05 | `Bounty r2304 · Redwater r2149` | **yes** | The largest launch-issue sweep yet — Bram's charge clash and cooldown, duplicate and truncated kill-feed lines, bots vanishing mid-fight, and anti-cheat kicks during the end-of-match summary — plus bots carrying bounties, per-tab quest dots in the lobby, and a leave-match popup rebuilt in the game's own style. |
| [Hotfix 5](changelog/2026-08-03-hotfix-5.md) | 2026-08-03 | `Bounty r2295 · Redwater r2113` | no | Launch-issue cleanup across both places — High Noon locking onto spawn-shielded players, Vesper's grapple overshooting the perch it hooked, and sun glare hiding players on high ground — plus a dead-UI purge in the lobby and a legacy Robux product that charged and granted nothing. |
| [Hotfix 4](changelog/2026-08-03-hotfix-4.md) | 2026-08-03 | `Bounty r2285 · Redwater r2096` | no | Redwater matches became reserved servers; Roblox's matchmaker can no longer place anyone in one. Four launch complaints closing on one root cause, plus abilities during the post-game showcase. |
| [Hotfix 3](changelog/2026-08-03-hotfix-3.md) | 2026-08-03 | `Bounty r2280 · Redwater r2086` | no | Breach Charge overhaul — victims locked out of acting, no longer shoved through geometry. Bounty daily-reward touch targets and Collection reading PURCHASE on owned items. |
| [Hotfix 2](changelog/2026-08-01-hotfix-2.md) | 2026-08-01 | `Bounty r2265 · Redwater r2055` | no | Launch-window error dashboard triage — dead lobby invite buttons, `LobbySpawns` streaming race, diagnosable anti-cheat kicks, Bram's charge kicking its own caster. |
| [Hotfix](changelog/2026-08-01-hotfix.md) | 2026-08-01 | `Bounty r2258 · Redwater r2048` | no | First post-launch patch — bot FX dropped on loading clients, 3D invite buttons streaming in late, Vesper's grapple getting its caster kicked. |
| [Launch](changelog/2026-07-31-launch.md) | 2026-07-31 | `Bounty r2255 · Redwater r2041` | **yes** | First public release. Two places under one experience: **Bounty** (lobby) and **Redwater Canyon** (FFA deathmatch). |

**A data-affecting release cannot be undone by reverting a place.** Reverting restores code, never
stored player data. Launch is marked yes because four groups of stored-data effects ship inside
that build — the battle-pass reset, ranked season 2, the limited-stock run and redemption codes.

Update 1 is marked yes for the narrowest reason on this table, and the hazard runs *opposite* to the
usual one. No schema bump, no new Wallet reason, no XP, RP or battle-pass change; items already
bought simply stay bought. It is flagged because the release opens the Robux bundle product
`3708064902`, and **reverting Bounty leaves that product live on the Creator Hub with no receipt
handler — buyers pay real money and get nothing. Deactivate the product before rolling back.**

Hotfix 10 is marked yes in the narrowest sense of all: no schema bump, no currency, XP or grant
change. It adds one `AutoFireEnabled` key to the profile's `Settings` sub-table, which reconciles
onto existing profiles and is safe to revert past. It is flagged only because the key is written by
**both** places, so a half-published experience would silently drop one side's writes of the
player's choice.

Hotfix 6 is marked yes in a much narrower sense: no schema, curve or reason-map change, but bots
can now carry bounties, so bounty Cash/XP and the `bountyClaim` quest and battle-pass track are
earned in a circumstance that did not exist before. A revert restores the code and leaves banked
progress intact — which is harmless here, unlike the Launch entries above.

---

## Two rules that never change

- **Never publish one place alone.** The mirrored modules make a half-published experience a live
  drift bug. Both places go out together, always.
- **Never patch-note an exploit fix.** Duplication bugs, anti-cheat changes and permission holes
  get full detail in these files and the words *"backend improvements"* in anything a player
  reads. Naming an exploit advertises that it existed and invites probing for the next one.

Everything else — the metadata block, the versioning scheme, the 20 mirrored modules — is in
[changelog/CONVENTIONS.md](changelog/CONVENTIONS.md).
