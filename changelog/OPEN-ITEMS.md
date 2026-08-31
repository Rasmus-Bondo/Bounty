# Open items — index

[Index](../CHANGELOG.md) · [Conventions](CONVENTIONS.md) · [Unreleased](UNRELEASED.md) · [Archive](open-items/ARCHIVE.md)

**Living document — not history.** One row per open item; the item itself lives in
`open-items/<id>-<slug>.md`. Edit rows freely, and **update an item in the same pass as the fix**.
The dated release files are immutable records of what went out; this is what is still wrong or
still owed.

**This file is an index and nothing else.** It was a single 2,755-line document until 2026-08-11,
which meant reading one item cost the whole file. Prose belongs in the item file, not here.

## How to use it

| You want to | Do this |
|---|---|
| See what is open | Read the tables below — one line each |
| Read one item | Open its `open-items/NNN-*.md` |
| Add an item | New file with the **next free id** (see below), then one row here |
| Close an item | Move its file to `open-items/archive/`, delete the row here, add a row to [ARCHIVE.md](open-items/ARCHIVE.md) |
| Know why a fix worked | The **release entry**, not the item file |

**Next free id: 133.** Ids are never reused and never renumbered — release entries cite them by
number. Ids 1–32 are the original launch report (there is no #2); 33+ were assigned when the
standing concerns became items on 2026-08-11.

## What goes in an item file

Keep it to the four things that only the item knows:

1. **Symptom** — what is wrong, in the reporter's terms.
2. **Repro** — or an explicit "never reproduced", which is itself a finding.
3. **The test that closes it** — the single most valuable line, because MCP playtesting is
   unavailable and closure is always a human run-through.
4. **A link to the release entry** that shipped the fix.

**Diagnosis does not go here.** It goes in the release entry. The old file grew to 217 KB mostly
by duplicating forensics that already existed one folder up — several items carried 60–130 lines
restating what their own release entry already said.

## Status and severity

`OPEN` · `INVESTIGATING` · `FIXED (unverified)` · `BUILT (unverified)` · `VERIFIED` · `WONTFIX` · `DEFERRED`

`FIXED (unverified)` means the code change is in Studio but nobody has played it. It becomes
`VERIFIED` only after a manual playtest confirms the behaviour — MCP playtesting is not available,
so verification is always a human step. `BUILT (unverified)` is the same state for a **feature**
rather than a fix: it exists end to end and nothing about it is signed off.

Severity is a triage guess, not the reporter's words: **P1** breaks a match or loses player value,
**P2** is visibly wrong in normal play, **P3** is polish.

---

## Launch issues — open (0)

**All 32 are closed.** The last ten were closed on 2026-08-11 by owner decision: no recurrence in
the ~2 weeks since the 2026-08-01 launch. Nine of those were still `FIXED (unverified)` and were
**never playtest-verified** — they were closed on elapsed time, and each one's file says so. If one
resurfaces, it comes back as a **new item with a new id**, not by reopening the old number.

They are in [ARCHIVE.md](open-items/ARCHIVE.md). Numbering still matters: **never renumber a launch
issue** — the Hotfix 3 and Hotfix 4 entries cite them by number, and there is no #2.

## Standing concerns from releases (16)

Raised by a release and outliving it. Tagged with the release that raised them.

**The unverified backlog was cleared on 2026-08-15.** All sixteen `FIXED (unverified)` and
`BUILT (unverified)` items behind Hotfix 15, 16, 17 and Update 1 were closed together by owner
decision, without a playtest — see the batch note in [ARCHIVE.md](open-items/ARCHIVE.md). What
remains below is work that is genuinely still wrong, not work awaiting a sign-off.

| # | Area / raised | Item | Sev | Status |
|---|---|---|---|---|
| [132](open-items/132-season-payout-mark-uses-a-numeric-profile-key.md) | ranked season rewards (2026-08-29) | `RankSeasonRewardService` marks a paid season with a **numeric** profile key, which DataStore's JSON round trip turns into a string one — so the mark is invisible on the next load and a top-100 winner is paid again on every rejoin. Unreachable on live until season 4 closes; **must be fixed before Sat 2026-09-12 20:00 CEST**, the first real payout | P1 | OPEN |
| [131](open-items/131-bram-first-person-shoot-throws-arms-too-high.md) | Hunter animation Tier C (2026-08-29) | Bram's first-person shoot throws the arms and gun too high. Clip ids and the Tier C migration are ruled out by measurement, and a cadence fit was tried and reverted; the item carries the numbers. Owner decided no replacement clip is coming, so the fix is in code | P2 | FIXED (partially verified) |
| [128](open-items/128-stun-haptics-two-implementations-pending-dev-soak.md) | Stun overlay (2026-08-27) | The stun's mobile haptics ship as two competing APIs (`HapticService:SetMotor` + `HapticEffect`) plus two `[StunHaptics]` console lines, because neither can be tested in Studio. Owes a DEV-Redwater handset soak, then deleting the losing path and the logging in both match places. **Not shippable to live as-is** — it prints on every stun | P3 | OPEN |
| [130](open-items/130-bundle-purchase-round-trip-not-playtested.md) | Trading Post BUNDLES (2026-08-29) | Page layout signed off by the owner across platforms; the purchase itself has never been fired by a real client, so the Token debit, the skin/boost grants and the panel's repaint off the server push are all unexercised. Owes a DEV round buying each of the three bundles | P2 | DEFERRED |
| [127](open-items/127-new-swap-hunter-panel-not-playtested.md) | Swap-panel redesign (2026-08-26) | Panel itself playtested and signed off 2026-08-26. Owes only the deletion of `StarterGui._LegacySwapHunterGui` from both match places — held deliberately until the release publishes and soaks, since it is the cheap half of the rollback path | P3 | DEFERRED |
| [126](open-items/126-frostbite-starterplayer-at-stock-defaults.md) | Hotfix 1.2 preflight (2026-08-24) | Frostbite's `StarterPlayer` sat at Roblox stock defaults on six properties where Redwater is configured — slope angle 89 vs 46, avatar appearance on, core nameplates and health bars over the custom ones. Applied and read back identical; owes a Frostbite round on a published server | P2 | FIXED (unverified) |
| [124](open-items/124-dev-tester-grant-cannot-be-tested-before-it-ships.md) | DEV tester grant (2026-08-23) | The six-account DEV top-up to 999,999 Cash/Tokens has never run — it gates on `env == "Dev"`, so it is unreachable from Studio and can only be verified after the DEV publish | P2 | BUILT (unverified) |
| [121](open-items/121-domination-built-not-playtested.md) | Domination build (2026-08-22) | Domination is built end to end in all three places but nobody has played it — `FORCE_GAMEMODE = "domination"` in Studio, checklist in the item | P1 | BUILT (unverified) |
| [123](open-items/123-frostbite-spawn-house-navmesh-islands.md) | Domination bot investigation (2026-08-22) | Frostbite spawn markers on navmesh islands: 7 / 12 red, 2 / 12 blue (Redwater is clean). Bots seated on the reachable ones since 2026-08-23; the geometry is still wrong | P2 | OPEN |
| [122](open-items/122-domination-deferrals-stat-card-xp-soak-pads-in-other-modes.md) | Domination build (2026-08-22) | Domination deferrals: Captures column on the stat card, XP-per-minute soak vs TDM (the pads-in-every-mode deferral closed 2026-08-22 — `CapturePointService` parks them outside Domination) | P3 | DEFERRED |
| [118](open-items/118-mobile-button-duplicate-fix-not-device-tested.md) | Hotfix 1.1 | Mobile cluster-button duplicate fix is not device-tested — needs a touch join straight into a match | P2 | FIXED (unverified) |
| [117](open-items/117-newplayer-funnel-call-site-timing-unverified-on-live.md) | Hotfix 1.1 | `NewPlayer` funnel call-site timing unverified — a mis-timed step is indistinguishable from real churn | P3 | BUILT (unverified) |
| [113](open-items/113-frostbite-vesper-perches-below-the-elevation-floor.md) | Frostbite bring-up | Four Frostbite Vesper perches sit below the elevation floor | P3 | OPEN |
| [112](open-items/112-lootbox-sounds-have-no-soundgroup.md) | sound-group sweep | Lootbox sounds have no SoundGroup — the last 10 in the experience | P3 | OPEN |
| [35](open-items/035-the-bot-scripting-layer-has-no-consumer-yet.md) | Hotfix 12 | The bot scripting layer has no consumer yet | P3 | OPEN |
| [50](open-items/050-two-waitforchild-calls-still-suppress-their.md) | Hotfix 10 | Two `WaitForChild` calls still suppress their warning by timing out into `nil` | — | OPEN |
| [51](open-items/051-dust-s-two-world-animation-ids-now-exist-in-four.md) | Hotfix 10 | Dust's two world-animation ids now exist in four places | — | OPEN |
| [70](open-items/070-workspace-tumbleweedspawns-has-duplicate-child.md) | Hotfix 2 | `Workspace.TumbleweedSpawns` has duplicate child names | — | OPEN |

## Open items — internal (14)

Not player-facing: tooling, data, infrastructure and deliberate deferrals.

| # | Area / raised | Item | Sev | Status |
|---|---|---|---|---|
| [129](open-items/129-dev-only-mock-season-schedule-must-be-removed.md) | ranked season rewards (2026-08-27) | DEV-only mock season schedule (`DEV_RANK_SEASONS`) is a test fixture for the 08-29 payout dry run — delete it and `seasonTable()` afterwards; DEV season numbers are shifted +2 against live until then | — | OPEN |
| [109](open-items/109-wallmap-is-resolved-by-a-string-literal-in-15-scripts.md) | Hotfix 17 | `WallMap` is resolved by a string literal in 15 scripts, so `MapConfig` cannot own it | — | DEFERRED |
| [106](open-items/106-redwater-script-count-dropped-13-since-2026-08-11.md) | Hotfix 16 | Redwater script count dropped 13 since 2026-08-11, only 2 explained | P2 | OPEN |
| [81](open-items/081-both-knowledge-graphs-key-nodes.md) | prose wikilink sweep | Both knowledge graphs key nodes on the lowercased FILE BASENAME, so same-named scripts merge into one node | — | OPEN |
| [82](open-items/082-historical-matchstart-breakdowns-are-unusable.md) | MatchStart Unknown fields | Historical `MatchStart` breakdowns are unusable for hunter pick rate, and cannot be repaired | — | OPEN |
| [83](open-items/083-config-min-players-1-makes-the-late-join-path.md) | MatchStart Unknown fields | `Config.MIN_PLAYERS = 1` makes the late-join path the normal one, not the exception | — | OPEN |
| [84](open-items/084-creator-hub-s-place-filter-does-not-split-custom.md) | MatchStart Unknown fields | Creator Hub's `Place` filter does not split custom events by emitting place | — | OPEN |
| [85](open-items/085-profile-schema-is-not-version-tracked-in-code.md) | Launch | Profile schema is not version-tracked in code | — | OPEN |
| [86](open-items/086-studio-playtests-use-the-live-player-data-store.md) | Launch | Studio playtests use the LIVE player data store | — | OPEN |
| [88](open-items/088-developer-products-are-universe-scoped.md) | Launch | Developer Products are universe-scoped | — | OPEN |
| [89](open-items/089-in-game-what-s-new-popup-and-a-discord-patch.md) | Launch | In-game "What's New" popup and a Discord `#patch-notes` channel | — | OPEN |
| [90](open-items/090-vorfader-s-live-profile-carries-deliberate-test.md) | quest-tab claim dots | VorFader's live profile carries deliberate test state, left in place on purpose | — | OPEN |
| [91](open-items/091-breach-carry-shared-geometry-refactor.md) | internal | Breach Carry shared-geometry refactor | — | DONE (unverified) |
| [92](open-items/092-match-players-into-redwater-by-ping.md) | internal | Match players into Redwater by ping — built 2026-08-15 as a hard region filter; no routing decision verified live | — | BUILT (unverified) |

---

## Provenance of the launch numbering

Kept because it explains gaps and duplicates that otherwise look like mistakes.

There is no **#2**. **#25** was added 2026-08-03 from live kick logs while working #17; it is a
*different* failure and #17's fix does not close it. **#26, #27 and #28** were added 2026-08-05
from the owner's own play, not the original report — **#26 and #28 shared a root cause** (the Alt
hold's saved camera/cursor snapshot surviving a character change) and were fixed together the same
day. **#26 was reopened 2026-08-11** after two shipped fixes and now records the `GuiButton.Modal`
reimplementation that replaced the mechanism entirely. **#29 and #30** were added 2026-08-05, also
from the owner's play; #29 was fixed and verified 2026-08-06. **#31** was added and closed
2026-08-07. **#32** was added 2026-08-07 and is the first entry that is a **regression from a
shipped feature** rather than a launch defect: the round loop (Hotfix 9) turned "session" and
"match" into different spans and left one per-match tally behind — worth reading before adding
anything to the round-start reset block.

*This file absorbed the old root `LAUNCH_ISSUES.md` on 2026-08-03; that file is gone. It was split
from one document into this index plus `open-items/` on 2026-08-11.*
