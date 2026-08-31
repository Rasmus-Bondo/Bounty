---
name: project_battle_pass
description: "Battle pass — data-driven 30-level season, two linked tracks, both places; the grant-dispatch rule, season levers (SEASON_ID is volatile), economy rules, and the authored-GUI traps"
metadata:
  node_type: memory
  type: project
  originSessionId: a9dbbc27-3237-459a-8e3d-80847e4a1dcc
  modified: 2026-07-31T17:09:54.107Z
---

Season pass driven by a single data module **`BattlePassConfig`** (ReplicatedStorage, **mirrored verbatim in both places** — verify with a byte-length + checksum compare after editing either copy). UI is the authored `StarterGui.BattlepassGui` + `BattlePassClient` (Bounty only); the old code-built `BattlePassMenu` was deleted. The original design doc described a 40-level/4-week shape that was never shipped; **archived 2026-07-26 to `depricated/superseded-md-2026-07-26/battle_pass_design.md`** — the config is the only authority now.

**Structure:** `Config.PAID[1..30]` (needs Full Pass) + `Config.FREE` at **12 arbitrary levels** — 1, 5, 7, 10, 15, 18, 20, 23, 25, 27, 29, 30 (verified fresh-loaded from source 2026-07-26; it is *not* every-5th any more). `bp.claimed` is keyed `p<level>` / `f<level>`. UPGRADE PASS = `UpgradeBattlePassEvent` → `Wallet.spend(800 Tokens, "battlepass")`. Pass costs 800 Tokens against ~375 Tokens of pass content, so it is a **deliberate net Token sink** — the value is the Cash plus the extra cosmetics and boosts.

## Rules that are load-bearing

**0. A FAILED grant must not spend the claim** (fixed 2026-07-28). `tryGrant` used to stamp `bp.claimed[key] = true` whether or not `grantReward` succeeded, and the cosmetic branches only `warn()`ed — so the S3 hunter/gun skins were consumed-and-never-granted on every profile that passed L10/L20. Confirmed on live data: profile 30367244 had `claimed` = p10/f10/p20 with **no** SummerDust/SummerVesper in `OwnedSkins`, and the dead `Cosmetics.HunterSkins`/`GunSkins` buckets holding `the_deputy`/`iron_rose` (ids from a pre-S3 config). `grantReward` now **returns a boolean**, validates every id against its owning catalog (title→`TitlesConfig.EntryById`, boost→`BoostConfig.get`, emote/skins→the grant fn's own false return, currency→amount > 0, unknown kind→false), and `tryGrant` leaves the level claimable on failure. **The cosmetic is granted BEFORE any bundled currency** — a retryable claim that paid currency first would be a currency farm. `onClaimReward` now also re-sends state on a refusal, because the client stamps the card claimed optimistically.

**1. `grantReward` dispatches to the system that OWNS each inventory.** It used to write every cosmetic to `data.Cosmetics[bucket][id]` — and *nothing reads* Emotes/HunterSkins/GunSkins. Real ownership lives in `data.OwnedEmotes` (`CollectionService.grantEmote`), `data.OwnedSkins[char][skin]` (`DataService.GrantHunterSkin`) and `data.OwnedWeaponSkins` (`GrantWeaponSkin`). Combined with reward ids that existed in no catalog, a claim was consumed and the player got **nothing**. Now: title→`Cosmetics.Titles`, emote→grantEmote, hunterSkin/gunSkin→DataService, boost→`Boosts.Inventory`, cash/tokens→Wallet, and it **warns on a missing id**. `KIND_TO_BUCKET` is gone; the dead buckets (`Charms`/`KillEffects`/`Emotes`/`HunterSkins`/`GunSkins`) survive only so pre-S3 profiles load.

**2. The two tracks are LINKED for pass owners.** `BattlePassService.tryGrantBoth`: claiming either card at a level claims both when `bp.ownsFullPass`, guarded so a non-owner still claims only the free card. That's what enables levels that **split** one reward across tracks (L1 75+75 Cash) and levels that put the **same cosmetic** on both (L7 `gunhand`, L10 SummerDust) — the duplicate grant is idempotent, the point is one tap. The client mirrors it optimistically.

**3. NEVER bundle currency onto a cosmetic row** (`BattlePassConfig` rule 4c). Skin rows once carried a silent `tokens =`, and `grantReward` reads `tokens`/`cash` generically, so the pass paid 350 Tokens it never advertised — a card is captioned from `label`, and almost no authored card has an `AmountText` overlay to render an amount. The user summed the pass by hand and caught it. **When quoting economy totals, check the numbers are ones the player can actually SEE.** Every currency row is now `kind = "cash"`/`"tokens"` with the amount in the label.

**4. Anti-exploit: `BattlePassConfig.exclusiveSkins` + `isExclusiveSkin()`** are built FROM the tracks, and Bounty's `PurchaseSkinEvent` rejects a match. An unpriced skin otherwise falls through to the **1,000-Cash default price**, which would have sold the season's showpieces to anyone firing the remote. Gun skins need no guard (the token path requires an explicit `TOKEN_WEAPON_SKIN_PRICES` entry).

**5. Pass-exclusive cosmetics are made unbuyable by dropping their `price`** — `purchaseEmote` refuses price 0 — plus `unlockText = "BOUNTY PASS"` on the shop card and Collection tile. **If you move an emote onto the pass, something else must become `defaultOwned` in its place**: an emote with no price and no pass level is obtainable by nobody. (`take_the_l` went to PAID[28] and `wild_celebration` took its default slot; players holding the old one fall back to `DEFAULT_ID` gracefully.)

**6. Free-cell constraint:** two free levels must never share `(level-1) % 5` inside one section or they fight for the same grid cell. The authored FreeRewardTrack is five cells (`1Blank`..`4Blank` + a real card in `5Free`), so a mid-section free reward is that section's own `5Free` **cloned into the blank cell**. Fill cells **in order 1..5** because cell 5 IS the template, and set `LayoutOrder` explicitly on every cell (authored cells all sit at 0 and order by name, which "2Free" satisfies only by luck of the alphabet). The validation script checks the collision rule.

**7. Weekly quests are MANUALLY claimed** (user: "should not auto claim"). Redwater's `trackQuest` only sets `completed = true, claimed = false`; Bounty owns payout via `ClaimBattlePassQuestEvent`. **The one-time migration flag `bp.questClaimMigrated` must survive, never be recomputed** — it stamps `claimed = true` on already-completed quests, and without it every historic completion pays a second time. Byte-identical in both places. The WEEKLY tab is one scroll page per unlocked week. The old `QuestConfig` weekly system is disabled via `WEEKLY_COUNT = 0` (Fisher-Yates picks 0 → empty slots, safe).

## Season levers

- **`SEASON_ID`** (BattlePassConfig) → resets BP progress only, keeps token wallet + cosmetics. **Volatile — always read the live value before bumping**, it moved S3→S4→S5→S6 inside two weeks and a stale assumption here bumps from the wrong base. **S6** as of 2026-07-31 19:00 CEST, bumped to put pass progress on the same clean slate as the ranked reset. Note a rollover sets `ownsFullPass = false`, so the PAID track — which carries 3 of the 4 skin rewards — is unclaimable until the pass is re-bought or `BattlePassService.grantFullPass(player)` is called; nothing refunds the 800 Tokens, which is correct per-season behaviour but is the part of a bump that is easy to fire by accident.
- All 21 weekly quests together are **64,500 XP = level 25**, so quests alone never reach L29 (HellFire) or L30 (Summer Fortuna); those two need ~10,500 XP of real matches on top.
- **`DATA_VERSION`** (DataService, both places, currently `"v2"`) → full universe-wide wipe. The release-reset lever.
- **`SEASON_START = 1785517200`** (2026-07-31 17:00 UTC / 19:00 CEST) in both places — launch day, set. Weekly unlock is **cumulative** by design (week N stays visible once opened); week 2 opens 08-07 19:00 CEST, week 3 on 08-14. **`SEASON_START` and `TEST_ALL_WEEKS_UNTIL` must always move together**: the test lever reports *every* week unlocked, so leaving it open past a `SEASON_ID` reset hands each freshly-wiped profile all 21 quests instead of week 1's seven (and completions bank permanently) — while closing it alone makes `currentWeek()` return 0, which the client clamps to 1 and renders while the server refuses every claim. Backdating `SEASON_START` by hours is safe; by a week or more it trips the clamp to `TOTAL_WEEKS` and opens the season permanently.
- Rollover **keeps wallet + cosmetics** and forfeits unclaimed rewards — which is why battle-pass titles are permanent across seasons. Before re-diagnosing a "can equip what I don't own" report, read the live profile: a tester owning ids from an earlier season is expected, not a bug ([[project_title_styles]] has the DataStore-read recipe).

## Authored-GUI traps

- **The `and/or` nil pitfall.** `(track == "free") and Config.FREE[l] or Config.PAID[l]` falls through to PAID whenever FREE[l] is nil — use a `getReward()` helper. The same bug bit the Trading Post (`showTitles and nil or scrollingFrame` always yields the frame). Spell these out with if/else.
- **Markers sit at the CENTRE of their cell.** A section is 5 equal cells, so level `(s-1)*5+i`'s diamond is at 0.100/0.300/…/0.900 while a naive `frac` puts it at `i/5`. The XP spine ran half a level ahead and cards looked unlocked early; fixed by subtracting `HALF_LEVEL_XP`, plus a `finished` guard forcing the bar to 1 at max XP. **Any future "bar meets marker" UI here must account for centre-of-cell placement.**
- **A caption gets ONE line.** The box is 2 `TextScaled` lines tall but sits at the card's bottom edge, so a wrapped second line falls into the clip rect. `rewardName` strips `Hunter Skin: `/`Gun Skin: `/`Emote: ` prefixes (`PREFIXED_KINDS`) — the art already *is* the thing. **Verify line counts with `TextService:GetTextBoundsAsync`, not `TextLabel.TextBounds`**, which reports the full box for a TextScaled label.
- **Caption ZIndex matters:** the caption is a *sibling* of `RewardFrame` and on free cards is authored BEFORE it, so a 1.6× skin viewport drew straight over it. Paid cards only ever worked by being authored last.
- **Read font from `RewardName or TextLabel`** — only paid cards have `RewardName`, so free title cards silently fell back to the engine default and the same title rendered in two fonts across the tracks.
- **Title cards name their HUNTER** (`"<HUNTER> TITLE"` via `TitlesConfig.HunterOf`), because the card already draws the title as itself and the hunter is the fact that decides whether you can wear it.
- **`UIShadow`:** the authored `ReadyToClaim` glow is invisible at card size (BlurRadius 0.2, behind an opaque card carrying its own shadow at the same ZIndex). Overridden to 0.30 and **pulsed** — `UIShadow.Transparency` is tweenable. **`Spread` in scale units blows up into an opaque slab far larger than the card** — use offsets or leave it 0.

## Reward art

`applyRewardArt` binds art by kind: currency/emote → `Config.ICONS`; boost → a per-boost `icon` stored **on the BoostConfig entry** (no duplication with the Collection panel); **title → drawn as ITSELF** via `TitleRenderer.apply` into a runtime label (no title art exists); **skins → the real model** in a runtime `BPRewardViewport`. Rig framing 1.6×/FOV 28, but **guns need their own tuning (1.6× viewport at 0.58× camera distance)** because bounding-box framing fits a gun's longest axis and a revolver otherwise reads ~4× smaller than a rig.

**Emote framing must NOT come from `GetBoundingBox`.** The shop rig is already mid-animation when the pass clones it, so a box measured at clone time is whatever pose it was caught in — a crouch pulls the camera in and every standing frame renders headless. Aim at the **anchored HumanoidRootPart** with fixed numbers: distance 10.6, focus rise -0.41 (the root sits at the hips), FOV 36, viewport 1.5× at y-scale 0.4. `stripForDisplay(rig, false)` — anchoring anything but the root freezes the animation ([[project_viewport_rig_anchoring]]).

**`Animator:StepAnimations(dt)` WORKS in the plugin edit VM.** `LoadAnimation` + `Play` in edit mode leaves the rig in its authored pose, which is why the first screenshots showed four identical dummies; stepping manually gives real poses. Projecting bounding-box corners through the viewport camera each step measured worst reach over 24 samples × 4 emotes — reusable for any viewport-animation framing question.

## Watch / open

- Screenshot verification of this GUI **has** worked (CoreGui clone of BattlepassGui rendered fine in the edit viewport) — an earlier session concluded it didn't. Treat that as session-dependent, not settled.
- PAID[7] and PAID[18] duplicate the FREE row's cosmetic with no bundled currency, so a Full Pass owner's claim there is a no-op. Flagged to the user, not changed.
- **`EmoteConfig` has drifted between places before** (Redwater fell to 5 of 18 ids, silently collapsing 13 emotes to `electro_swing` at match end). All three shared configs — BattlePassConfig / BoostConfig / EmoteConfig — must stay byte-identical. Redwater has no `grantReward` (earning-only).
- Nothing here is runtime-playtested ([[feedback_no_mcp_playtest]]).

Related: [[project_title_styles]], [[project_emotes]], [[project_boost_potions]], [[project_economy_events]], [[project_daily_rewards]].
