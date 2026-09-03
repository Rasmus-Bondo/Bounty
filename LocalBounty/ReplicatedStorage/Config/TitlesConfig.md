---
tags: [replicatedstorage, modulescript, config, cosmetics, titles]
path: game.ReplicatedStorage.Config.TitlesConfig
type: ModuleScript
lines: 313
---

# TitlesConfig

Cosmetic TITLE catalog — which titles exist, how they look, and what each one costs. Single source of truth for the Collection TITLES tab and the Trading Post ACCESSORIES shop.

## What it does
1. `Titles` — an ordered list of `{ id, label, style, color, unlock }` per hunter. **Every title belongs to exactly one hunter and can only be equipped on that hunter.** Dust 8 · Vesper 7 · Bram 7 · Fortuna 6 = 28 total (4 free, 17 purchasable, 7 battle-pass). Each hunter's shop titles come first as a price ladder, then any battle-pass titles in pass-level order. Bram carries two at 600 Tokens — the ladder is a rough ordering, not one title per price A further 12 entries per ranked season are **injected at load** rather than authored here — see item 11.
2. The seven battle-pass titles (`drifter` L2, `gunhand` L7, `dustdevil` L17 → Dust; `marksman` L12, `star_sight` L22 → Vesper; `gunmetal` L27 → Bram; `devils_luck` free L27 → Fortuna) are the ids BattlePassConfig's `kind = "title"` rewards grant. The pass's **four latest title slots (paid L17, L22, L27 and free L27) hold one title per hunter**. **Level 27 still grants two** (`gunmetal` chrome paid, `devils_luck` glow free), but they are no longer the same hunter's titles the way `the_legend`/`high_roller` were, because one-per-hunter makes a same-hunter pair impossible; the paid/free contrast is carried on style instead. `gunhand` sits on both tracks at L7 but is granted once, because the tracks are linked for pass owners. They previously existed in no catalog at all, so the pass was advertising rewards that displayed nowhere — these entries are what make them real. Keep the levels in step with BattlePassConfig
3. `HunterOrder` — stable hunter ordering (`Dust, Vesper, Bram, Fortuna`). `Titles` is a dictionary, so anything presenting titles across hunters in a fixed order (the Trading Post grid) must iterate this instead of `pairs()`
4. `LabelById` / `EntryById` / `HunterById` — flattened lookups built once at load. `HunterOf(titleId)` reads the last of these; it is how a UI captions a title with its hunter without the hunter being duplicated into that UI's own config (the battle-pass reward cards do exactly this)
5. `IsValid(hunterName, titleId)` — true when the id belongs to that hunter. A catalog check only; CollectionService separately checks ownership
6. `UnlockOf(titleId)` — the unlock descriptor. Unknown ids and entries with no `unlock` field both read as `free`, so a config typo is generous rather than locking a player out of something visible
7. `RequirementText(titleId)` — `"600 CASH"` / `"800 TOKENS"` for purchasable, `"BOUNTY PASS L22"` for granted, nil when free. Centralised so the Collection row badge and the shop card phrase a price identically
8. `Purchasable()` — every title that is actually for sale (17), in hunter then ladder order, each tagged with its hunter. This is the Trading Post grid's source of truth: free titles need no shop card and battle-pass titles cannot be bought, so neither belongs in a shop. The Trading Post heads each card with `record.hunter`, so no qualified `"DUST: HIGH NOON"` helper is needed — the card body already renders the title itself
9. `id` is the stable key persisted in `profile.EquippedTitles[hunter]`; ids must stay stable across updates so players keep their selection **and their purchases**
10. `style` names a TitleStyles preset (plain / tint / gradient / shine / glow / smoke / fire / holo / chrome / bloodmoon / lightning / sandstorm) and `color` is the accent that preset builds from — both read by TitleRenderer, which is what actually resolves the preset (this module only stores the name, so there is no code-level link to TitleStyles)
11. **Ranked season titles are generated, not authored.** The top 3 of each closed ranked season are granted a title by RankSeasonRewardService, and a loop below `HunterOrder` injects them into every hunter's list *before* the flattened lookups are built — 3 places x 4 hunters = 12 entries per season, `s4_champion_dust` through `s4_contender_fortuna`. **One id per hunter is forced by `IsValid`**, which keys off `HunterById`: a single id listed under all four hunters would resolve to the LAST one and be equippable on Fortuna alone, so a title the winner can wear on whichever hunter they play has to exist four times. `SeasonTitleIds(season, place)` returns all four and is what the payout grants; `SeasonTitlePlaces` is the podium depth (3). Ids are season-stamped and never reused, and a season must never be **removed** from `TITLE_SEASONS` — dropping one deletes the catalog entries, which makes `IsValid` fail for every winner still wearing it and silently strips the title on their next load. Styles are a gold/silver/bronze podium on animated presets deliberately **not** one of the four reserved apexes (fire/lightning/bloodmoon/holo), so a season title cannot dilute a hunter's apex. They are `grant` unlocks, so `Purchasable()` still returns 17 — which is also why the **shop** needs no special case: every shop surface is built from `Purchasable()`. `hiddenUntilOwned = true` on each entry plus `IsHiddenUntilOwned(titleId)` is the **wardrobe** rule: an unowned season title is not shown at all, because it records a placement that already happened and can never be earned again, and 12 permanently-locked rows per season would bury each hunter’s real wardrobe within months. **Tier names are CHAMPION / ELITE / CONTENDER**, and the `%d` in each label is the **player-facing** season number (`GameEnvironment.getRankSeasonDisplay`) rather than the code one — code season 4 renders `SEASON 1 CHAMPION`, while its ids, its OrderedDataStore and its `RankRewards` profile key all stay on 4. That split is exactly why the id suffix keeps the code number: it has to match what `SeasonTitleIds(season, place)` is asked for

## Unlock model
| kind | meaning | ownership recorded in |
|------|---------|----------------------|
| `free` | always owned — exactly one per hunter (the plain one) | nothing, implicit |
| `purchase` | bought with `currency` for `price` in the Trading Post | `profile.OwnedTitles[id]` |
| `grant` | earned elsewhere (battle pass) | `profile.Cosmetics.Titles[id]` |

### Reserved apex styles

**Four styles are RESERVED — each used by exactly one title in the whole catalog, and each is that hunter's 600-Token apex:**

| hunter | apex title | style | price |
|--------|-----------|-------|-------|
| Dust | HIGH NOON | `fire` | 600 Tokens |
| Vesper | STORMCALLER | `lightning` | 600 Tokens |
| Bram | THE BUTCHER | `bloodmoon` | 600 Tokens |
| Fortuna | Wild Card | `holo` | 600 Tokens |

**There is no 800-Token rung any more** — 600 Tokens is the top of the shop, and the `TOKEN_800` constant is gone.

Every other style (`chrome`, `sandstorm`, `shine`, `glow`, `tint`, `smoke`, `gradient`, `plain`) is shared freely across hunters and rungs. Putting a second title on a reserved style is what makes the apex rung stop reading as an apex rung — and per TitleStyles' own notes, an apex style also has to carry a periodic **event**, not just a palette.

### Price no longer follows style

This file used to promise that price was a pure function of style (one table, one rung each). **That invariant is dead as of the 2026-07-27 reshuffle** — `glow` sits at 250 Tokens (`the_duelist`, `the_illusionist`), at 600 Tokens (`punisher`) *and* on the pass (`devils_luck`); `shine` spans 1500 Cash and a pass level; `chrome` and `sandstorm` are pass grants rather than apex styles. Do not infer a price from a style, and do not "fix" the catalog back into the old table — read `UnlockOf`. What still holds: exactly one free `plain` title per hunter, exactly one 600-Token apex per hunter, and prices as shared constants (`CASH_600`, `TOKEN_250`, …) so retuning a rung is a one-number edit.

The reshuffle moved fire up to the apex rung and dropped chrome and sandstorm, on the reasoning that the styles which *do something* (fire's tongues, holo's hue cycle) are the ones worth the top price. Titles that lost a style they no longer had exclusive claim to were **restyled rather than deleted**, keeping their id so nobody lost a purchase: `punisher` fire → glow, `star_sight` holo → chrome, `devils_luck` bloodmoon → glow. `the_butcher` is the one genuinely new title — Bram's bloodmoon apex, named so it is not a Fortuna-flavoured "devil's luck".

**Then the pass and the shop traded places at the top.** The four ex-600-Token titles (one per hunter) took the pass's four latest title slots, and the four they displaced briefly became 600-Token shop titles — but **all four have since been deleted outright:**

| moved into the pass | ← displaced → | fate of the displaced title |
|---|---|---|
| DUSTDEVIL → paid L17 | | DEAD SHOT (Vesper) → **deleted** |
| STAR SIGHT → paid L22 | | OUTLAW (Bram) → **deleted** |
| GUNMETAL → paid L27 | | THE LEGEND (Fortuna) → **deleted** |
| DEVIL'S LUCK → free L27 | | HIGH ROLLER (Fortuna) → **deleted** |

HIGH ROLLER went first (a static `gradient` priced identically to Wild Card's animated holo was the worst value on the rung); THE LEGEND, OUTLAW and DEAD SHOT followed on 2026-07-28, which also cleared the 600-Token crowding — that rung now holds 5 of the 17 purchasable titles (one apex per hunter, plus Bram's PUNISHER).

**These four ids are retired — `high_roller`, `the_legend`, `outlaw`, `dead_shot`.** Never reuse one for a new title: a profile that still carries it in `OwnedTitles` would silently own the replacement. Deleting a title is safe because `CollectionService.ensureTitles` resets any equipped id that fails `IsValid` back to `""` on the next lobby join, and Redwater's `TitleDisplayService` resolves an unknown id to an empty label — but the Tokens spent on it are **not** refunded, and the dead id stays in `OwnedTitles` as inert data. Check nothing references a title id before removing one.

## Dependencies
- **Requires:** [[GameEnvironment]]
- **Required by:** RankRewardsConfig (season title ids for the payout ladder), RankSeasonRewardService (grants the podium titles), CollectionService (ownership + validation + display label), Catalog (per-hunter list), State (free-title rule), Shop (purchase vs grant routing), Preview (nameplate label), TitleBuyController (shop grid + prices), TitleRenderer (id/label → style lookup), BattlePassClient (reward-card title text + its `HunterOf` caption), BattlePassService (`EntryById` validates a `title` reward id before writing `Cosmetics.Titles`), NewItemClient (`HunterOf` attributes an unseen title to a hunter so the hunter tile can aggregate it)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `getRankSeasonDisplay()` | The player-facing season number baked into each season title's label |
