---
tags:
  - shared
  - modulescript
  - config
  - cosmetics
path: game.ReplicatedStorage.Config.TitlesConfig
type: ModuleScript
lines: 313
---

# TitlesConfig

Cosmetic title catalog — display labels, visual styles and unlock costs. Mirrored verbatim from Bounty's `TitlesConfig` (the lobby owns, prices and equips titles; Redwater only displays them).

## What it does
1. `Titles` — an ordered list per hunter of `{ id, label, style, color, unlock }`. **Every title belongs to exactly one hunter.** Dust 8 · Vesper 7 · Bram 7 · Fortuna 6 = 28 total (4 free, 17 purchasable, 7 battle-pass). Ids are the stable keys persisted in `profile.EquippedTitles[hunter]`
2. Seven are battle-pass rewards (pass levels 2/7/12/17/22/27 — level 27 grants **two**, `gunmetal` (chrome) paid and `devils_luck` (glow) free). The pass's four latest title slots (paid 17/22/27, free 27) hold **one title per hunter**: DUSTDEVIL, STAR SIGHT, GUNMETAL, DEVIL'S LUCK. The rest are one free title per hunter plus the Trading Post ladder
2b. **Four styles are RESERVED, one per hunter, each used by exactly one title and each that hunter's 600-Token apex — the top shop rung, there is no 800 rung:** `fire` → Dust's HIGH NOON, `lightning` → Vesper's STORMCALLER, `bloodmoon` → Bram's THE BUTCHER, `holo` → Fortuna's Wild Card. Every other style is shared freely across hunters and rungs. Redwater renders all of these on nameplates, the kill cam and the match summary, so a reserved style is also a *recognition* cue mid-match — you should be able to tell a hunter's apex title at a glance
2c. **Price no longer follows style.** This file used to promise one rung per style; the 2026-07-27 reshuffle ended that — `glow` spans 250 Tokens, 600 Tokens and a pass grant. The 600-Token rung was crowded by the four ex-pass titles until all four (`high_roller`, then `the_legend`, `outlaw`, `dead_shot` on 2026-07-28) were **deleted**; it now holds 5 of the 17 purchasable titles. Those four ids are retired — never reuse one. Read `UnlockOf` rather than inferring from the style, though Redwater never needs to, since the lobby owns all pricing
3. `HunterOrder` / `LabelById` / `EntryById` / `HunterById` — flattened lookups built once at require time
4. `IsValid(hunterName, titleId)` — true when the id belongs to that hunter
5. `UnlockOf` / `RequirementText` / `Purchasable` — pricing and shop helpers. **Unused in Redwater**; they exist because the module is mirrored byte-for-byte, and the lobby is the only place that gates or sells anything
6. `style` names a TitleStyles preset (plain / tint / gradient / shine / glow / smoke / fire / holo / chrome / bloodmoon / lightning / sandstorm) and `color` is the accent that preset builds from — both read by TitleRenderer on the three Redwater title surfaces (this module only stores the preset name, so there is no code-level link to TitleStyles)
7. TitleDisplayService reads `LabelById` to turn an equipped title id into the label it publishes on the `EquippedTitle` attribute, and TitleRenderer reads the entry to pick each title's style
8. **Ranked season titles are generated, not authored.** A loop below `HunterOrder` injects the top-3 season titles into every hunter's list *before* the flattened lookups are built — 3 places x 4 hunters = 12 entries per season, `s4_champion_dust` through `s4_contender_fortuna`. One id **per hunter** is forced by `IsValid`, which keys off `HunterById`: a single id listed under all four hunters would resolve to the last one and be equippable on Fortuna alone. Redwater neither grants nor validates these — Bounty's RankSeasonRewardService pays them — but they must exist in this copy, because TitleDisplayService and TitleRenderer resolve a winner's equipped title through `LabelById` / `EntryById` here, and a missing entry would render the champion's title as blank. Each entry carries `hiddenUntilOwned = true`; `IsHiddenUntilOwned(titleId)` is read by Bounty's Collection wardrobe, not by anything here. Tier names are CHAMPION / ELITE / CONTENDER, and the `%d` in each label is the PLAYER-FACING season number (`GameEnvironment.getRankSeasonDisplay`) — code season 4 renders `SEASON 1 CHAMPION`, which is why this module now requires GameEnvironment

Redwater needs **no ownership logic**: Bounty's `CollectionService.equipTitle` is the only writer of `EquippedTitles`, so nothing unowned can reach the profile for Redwater to read back. A *deleted* id is the one case where the profile can name a title this catalog no longer has — TitleDisplayService resolves it through `LabelById[titleId] or ""`, so the player simply shows no title rather than erroring, and the lobby clears the stale id on their next join.

## Dependencies
- **Requires:** [[GameEnvironment]]
- **Required by:** TitleDisplayService, TitleRenderer

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `getRankSeasonDisplay()` | The player-facing season number baked into each season title's label |
