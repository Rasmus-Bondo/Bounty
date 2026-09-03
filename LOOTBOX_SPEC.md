# Lootbox Chests — build spec

Status: **approved design, not built**. Written 2026-09-02 for a cold session to implement.
Scope: Bounty (lobby) owns the whole feature. Redwater / Frostbite get **three** things — the launch
migration (§7), the Wallet reasons (§8), and the tutorial-completion chest grant (§7a). Everything
else is lobby-only.

---

## 1. What a chest is

A chest is opened in a full-screen 3D scene in the lobby. The chest lands in front of the player;
they press SHOOT repeatedly; each landed bullet advances a **stage** (1-5 = Common -> Legendary) and
recolours the chest glow. When the run ends they press OPEN and the loot floats out.

**The stage reached IS the box's tier**, and it drags lower-tier filler with it. Stage 1 yields
exactly one Common — that is the guaranteed-item rule, and it falls out of the existing structure
rather than needing a special case.

| Stage | Tier | Items dropped |
|---|---|---|
| 1 | Common | 1 Common |
| 2 | Uncommon | 1 Common + 1 Uncommon |
| 3 | Rare | 1-2 Rare + 1 (Common\|Uncommon) |
| 4 | Epic | 1 Epic + 2-3 (Common\|Uncommon\|Rare) |
| 5 | Legendary | 1-2 Legendary + 2-3 (Common\|Uncommon\|Rare\|Epic) |

That table is already implemented in the prototype's `getLootRarityDrops(finalStage)`. Keep it.

**Sources of chests:** one free chest per account level, and a 100-Token purchase.

**Chests are bought inside the chest menu, NOT in the Trading Post.** The purchase control is
`ChestPurchaseFrame.BuyButtonTokens`, already authored in the prototype alongside
`ItemPriceTokenText`, `OwnedButton` and `AfterPurchaseText`. The player buys standing in front of
the chest and then shoots it. LOOT is its own top-level bottom-bar destination — do not add a
Trading Post tab for this, and do not route the purchase through `StarterGui.Shop`. The only thing
the Trading Post contributes is the price an item sells for, which §5 reads to size a duplicate
refund.

**A bought chest BANKS.** `PurchaseLootboxEvent` spends the Tokens and does `Unopened += 1` —
nothing opens. Buying and opening are two separate acts, so a player can stock up and open a run of
them, and the purchase cannot be lost to a disconnect mid-animation. The prototype's
PURCHASE -> "ITEM IS NOW AVAILABLE" -> SHOOT flow still reads correctly: the chest is now available
*to open*, and the SHOOT button is what opens it.

---

## 2. The prototype, and the two things wrong with it

### There are TWO ChestControllers, and neither one is simply "the" copy

Merge them by hand. Taking either wholesale loses something real.

| | `Bounty - UI Update` | **live Bounty** |
|---|---|---|
| Path | `StarterGui.LootboxMenu.Canvas.ChestController` | `StarterGui.LootboxMenu.Canvas.HuntersBuyFrame.CanvasMiddle.BuyHunterFrame.PurchaseFrameRobux.TextButton.ChestController` |
| Lines | 2,201 | 2,055 |
| Enabled | yes | **no** |
| Entry point | full `ChestFlow` UI — buy/shoot buttons, `OddsFrame`, purchase states | bare `local button = script.Parent` |
| `ChestShootPart` | `Workspace:WaitForChild("ChestShootPart")` | **`Workspace.PersistentMarkers.ChestShootPart`** |
| `EXTRA_BULLET_CHANCE` | 0.8 | 0.1 |

**Take the UI-Update copy as the base — it has the entire purchase/odds/shoot UI layer the live one
lacks — and port the live copy's streaming fix into it.** That fix is not cosmetic; its own comment
records the bug it closes:

> *"A loose BasePart at Workspace root does not replicate to a client until it streams in, and this
> wait is at the top of the file, so the whole chest controller stalled on it after a join."*

`Workspace.PersistentMarkers` (a Persistent Model) already exists in live Bounty and already holds
`ChestShootPart`. **Do not import `ChestShootPart` from the UI-Update place** — that is the loose
root-level part the fix exists to get away from.

`SkinMenu` is likewise already Persistent in live Bounty and already holds `PreviewPart`. Both
controllers still reach it with a raw `WaitForChild`; the house helper is
`ReplicatedStorage.Modules.WaitForRequired`, which waits unbounded without the engine's 5-second
"Infinite yield possible" warning and is what every other lobby script uses for a Persistent model
(`CameraFolder`, `SkinMenu`, `PlayModel`, `FeaturedItems`, `VaultDoor`, `InviteButtons`). Convert
both waits to it while merging.

Everything else is shared: chest landing animation, revolver spin, laser beam, camera shake, bullet
holes, drag-to-rotate preview, loot reveal, 10 SFX. Supporting assets in the UI-Update place that
**do** need importing: `ReplicatedStorage.Lootbox` (WorkingChest + SmokeLand + LaserBeam +
LootTemplate) and `ReplicatedStorage.LootboxSFX`.

**Two defects are in both copies and must be fixed on the way in.**

### 2.1 The client decides its own loot

`luckRandom = Random.new()` lives in the LocalScript. The client rolls the rarity, the item count and
the items. An exploiter rewrites one local and mints legendaries.

**Fix — the client replays a server decision, it does not make one.** On OPEN the client fires the
server, the server rolls tier + items + dupe conversions and replies with the resolved list; the
client then plays the animation so that it lands **exactly `tier` bullets** and reveals **exactly the
items it was given**. All the feel constants (`FIRST_SHOOT_STEP_DURATION`, the tilt, the highlight
flash) stay client-side and untouched. Only `getLootRarityDrops`, the extra-bullet roll and
`getRandomRarityFromList` lose their RNG — they become "read the next entry from the server payload".

### 2.2 The displayed odds are not the real odds

`OddsFrame` is painted 50/35/10/4/1. Neither copy produces that. Both roll a "keep going?" chain
after each landed bullet, so `P(stage k) = c^(k-1)` — and the two copies disagree on `c`:
UI-Update's 0.8 gives **41% Legendary**, live Bounty's 0.1 gives **0.1%**. Neither is the panel.
The chain goes away entirely with the server roll; the odds table below replaces it.

---

## 3. Odds

**Base roll, in `LootboxConfig`:**

| Tier | Base |
|---|---|
| Common | 52% |
| Uncommon | 30% |
| Rare | 14% |
| Epic | 3.2% |
| Legendary | 0.8% |

**Pity, persisted per player:**
- 20 chests without Epic-or-better -> next chest is forced Epic+, split 80/20 Epic/Legendary.
- 100 chests without a Legendary -> next chest is forced Legendary.
- Both counters reset on the tier that satisfies them. A Legendary satisfies the Epic+ counter too.
- **Every chest counts, free and bought alike.** One pair of counters per player, incremented on
  each open regardless of where the chest came from. A player banking 20 free chests and cashing the
  guarantee is expected and fine. Super chests (§7b) are a fixed outcome and sit outside the system
  entirely: they neither advance the counters nor consume a guarantee.

**Effective rates, which is what the UI must display:**

| Tier | Displayed |
|---|---|
| Common | 50% |
| Uncommon | 29% |
| Rare | 13% |
| Epic | 6% |
| Legendary | 2% |

**Do not "correct" the config to match the label.** The pity counters are what lift Epic 3.2 -> ~5.7
and Legendary 0.8 -> ~1.9; the displayed numbers are the effective ones because that is what a player
actually experiences and what Roblox's odds-disclosure rule is about. Derivation, so the next person
can re-check it: effective Epic+ rate is `1 / E[min(G, 20)]` where `G ~ Geom(0.04)`, and
`E[min(G,n)] = (1 - (1-p)^n) / p = (1 - 0.96^20) / 0.04 = 13.95`, giving 7.2% Epic+; the Legendary
counter then lifts 1.43% to 1.87% the same way. Verify with a 1e6-trial simulation before shipping
and put the measured numbers on the panel.

---

## 4. Pools

Cash / Tokens / potions are always fresh grants. Titles / emotes / skins can duplicate — see §5.

**A title rolls for any hunter, unweighted.** Titles equip on exactly one hunter, so a Dust main can
draw a Bram title and get nothing they can wear. That is accepted as bad luck — no weighting toward
owned or equipped hunters, no restriction of the pool. Do not "fix" it later without saying so; it
is a decision, not an oversight.

| Tier | Pool |
|---|---|
| Common | Cash 150-300 · potion `xp_25_15` / `cash_25_15` |
| Uncommon | Cash 500-900 · Tokens 15-25 · potion `xp_25_30` / `cash_25_30` · Title (§4b) |
| Rare | Cash 1,250-2,000 · Tokens 50-75 · potion `xp_25_60` / `cash_25_60` · Emote · Title (§4b) |
| Epic | Hero Skin (§4a) · Tokens 125-200 · Title (§4b) |
| Legendary | Hero Skin (§4a) · Weapon Skin (§4a) · Tokens 375 |

### Emotes are Rare only

All 11 purchasable emotes cost **2000 Cash, flat** — there is no price ladder to tier them by
(verified 2026-09-02). Splitting them across Rare and Epic would therefore be arbitrary, and an
emote is worth far less than the hero skins and 600-Token titles sitting in Epic. So the whole emote
pool lives in Rare, and Epic keeps its floor high. Duplicate refund is 700 Cash for every emote.

Pool: `EmoteConfig.isPurchasable(id)` — the 11 ids, which by construction excludes the 5 pass emotes
and the 2 default-owned ones.

### Weighting inside a tier

**`LootboxConfig` carries a weight per pool entry.** The tier odds in §3 decide *which* tier; these
decide which of that tier's entries you get. Default: **uniform across the categories listed for the
tier, then uniform within a category** — so an Epic roll is 1/3 hero skin, 1/3 Tokens, 1/3 title, and
the hero-skin third splits evenly across the two Epic skins. Tune from there; the point is that the
weights are data, not an accident of table order.

**The cosmetic pools are small and finite** — 6 hero skins, 4 weapon skins, 17 titles, 11 emotes. A
committed player owns all of them within months, after which every cosmetic roll is a duplicate and
chests pay out purely in currency at the §5 rate. That is the intended long-run behaviour, not a
failure state, but it means the 35% refund is effectively the endgame payout and should be read that
way when tuning.

**The pool is an explicit allowlist in `LootboxConfig`, never "everything in the folder."** The
codebase already carries five separate "this is not for sale" guards, and a chest is a sixth sales
channel that would walk straight through all of them:

- `BattlePassConfig.isExclusiveSkin` — season showpiece skins
- `StoreConfig.isBundleExclusive` — Robux bundle grants
- `GroupPerkConfig.isGroupSkin` — Dust `Wraith`
- `LimitedStockConfig` — Fortuna `PrestigeCard`
- `SkinCatalog` `CodeOnly` — Dust `BetaRevolver`
- `TitlesConfig` `hiddenUntilOwned` — ranked season titles

**Two of those are named explicitly because they are easy to miss — they are the only exclusions
that are a single item rather than a category, and they hit two different pools:**

- **Dust `Wraith` — out of the HERO skin pool.** Group-perk only; Outlaw Syndicate membership is
  the sole way in and it is for sale in no currency. It is one of Dust's four skins, so removing it
  takes Dust down to three candidates before the pass/bundle exclusions are applied.
- **Dust `BetaRevolver` — out of the WEAPON skin pool**, both the Legendary pool in §4 and the
  super-chest pool in §7b. Redemption-code supply only since 2026-08-27. It sits in the ordinary
  `WeaponSkins.Dust` folder next to `HellFire` and `Icefang`, so anything enumerating that folder
  picks it up.

**Nothing the Bounty Pass grants may ever come out of a chest — and the pass grants three kinds of
thing, not one.** Excluding only `isExclusiveSkin` leaves the other two wide open:

- **Skins** — `BattlePassConfig.isExclusiveSkin(character, skin, "hunterSkin")` / `"gunSkin"`.
- **Titles** — the 7 pass titles (`drifter`, `gunhand`, `dustdevil`, `marksman`, `star_sight`,
  `gunmetal`, `devils_luck`). They carry `unlock.kind = "grant"`, so the safe filter is
  `TitlesConfig.Purchasable()` — build the title pool from that and only that. It returns the 17
  genuinely-for-sale titles and excludes pass, free and ranked-season titles by construction.
- **Emotes** — the 5 pass emotes (`cowboy_dance`, `showdown`, `lasso_dance`, `hit_the_beat`,
  `take_the_l`). They have `unlockText` and no `price`, so build the emote pool from
  `EmoteConfig.isPurchasable(id)` — 11 ids — and only that.

**Fortuna's `PrestigeCard` is out too.** It is a limited Robux run governed by `LimitedStockConfig`,
and DataService does not require that module — the gun-skin purchase path only refuses it because it
was pulled from `TOKEN_WEAPON_SKIN_PRICES`. A chest granting it would mint past the 100 cap with
nothing to stop it, since `GrantWeaponSkin` takes no stock check.

Also excluded: default skins and default weapon skins, and the 4 free / 2 default-owned entries that
every player already has.

### 4a. The skin lists — settled 2026-09-02

Instance names, not display names. Verified against live Bounty's `ReplicatedStorage.Characters` and
`ReplicatedStorage.WeaponSkins`, and against every §4 exclusion predicate.

**Hero skins**

| Tier | Skin | Hunter | Token price |
|---|---|---|---|
| Epic | `BluefrostDust` | Dust | 300 |
| Epic | `UnmaskedVesper` | Vesper | 300 |
| Legendary | `CrimsonRevenant` | Dust | — |
| Legendary | `IvoryGambler` | Fortuna | 500 |
| Legendary | `FrostveilVesper` | Vesper | 600 |
| Legendary | `DirewolfBram` | Bram | 600 |

**Weapon skins**

| Tier | Skin | Hunter | Token price |
|---|---|---|---|
| Epic | `Icefang` | Dust | 600 |
| Epic | `FrozenHand` | Fortuna | 600 |
| Legendary | `FrostbiteGrudgekeeper` | Bram | 600 |
| Legendary | `Frostpiercer` | Vesper | 400 |

**The hero tiers track Token price (300 = Epic, 500-600 = Legendary); the weapon tiers deliberately
do not** — `Frostpiercer` is 400 and Legendary while `Icefang` and `FrozenHand` are 600 and Epic.
That is a judgement about the skins, not an error. Do not "correct" it, and do not derive a new
skin's tier from its price without asking.

**Every hero skin in live Bounty is now accounted for**, which is the check that says nothing was
forgotten:

| Skin | Where it went |
|---|---|
| `BluefrostDust`, `UnmaskedVesper` | Epic |
| `CrimsonRevenant`, `IvoryGambler`, `FrostveilVesper`, `DirewolfBram` | Legendary |
| `Wraith` | excluded — group perk |
| `SummerDust`, `SummerVesper`, `SummerFortuna` | excluded — battle pass (free L10, paid L20, paid L30) |

Same for weapon skins: the four above, plus the four defaults (`DefaultRevolver`, `DefaultSniper`,
`Grudgekeeper`, `DefaultCard`), plus `BetaRevolver` (code-only), `PrestigeCard` (limited run) and
**`HellFire` (battle pass, paid L29)**. `HellFire` looks like an omission from the Legendary list and
is not one — it is a pass reward, so §4 excludes it either way.

**Three of these sit close to a bundle rule and are still legal** — check before assuming otherwise:
`FrostveilVesper`, `BluefrostDust` and `DirewolfBram` are all granted by `BundleConfig`'s Token
bundles, and `FrostveilVesper` and `Frostpiercer` also appear in a `StoreConfig` Robux bundle. They
carry `SoldSeparately = true` there, and `StoreConfig`'s own comment says `isBundleExclusive` must
not claim them. All four have a `TOKEN_SKIN_PRICES` entry, so they are individually purchasable and
a chest granting one undercuts nothing.

### 4b. The title lists — settled 2026-09-02, with 11 removals

Ids, not labels. All 17 entries of `TitlesConfig.Purchasable()`, and nothing else.

| Tier | Dust | Vesper | Bram | Fortuna |
|---|---|---|---|---|
| Uncommon | `the_duelist` | `eagle_eye` | `iron_buck`, `breacher` | — |
| Rare | `deadeye`, `quickdraw` | `horizon_fang`, `dead_silent` | `wrecking_ram`, `punisher` | `the_dealer`, `ace_of_pain`, `the_illusionist` |
| Epic | `high_noon` | `stormcaller` | `the_butcher` | `wild_card` |

**11 titles from the original list were removed, and they were removed by rules already settled in
this spec — not by preference.**

**The 7 battle-pass titles are out.** Every one of `drifter` (pass L2), `gunhand` (L7), `dustdevil`
(L17), `marksman` (L12), `star_sight` (L22), `gunmetal` (L27) and `devils_luck` (free L27) was in the
original tiering, and together they are *exactly* the pass's full title set. §4 says nothing the
Bounty Pass grants may come out of a chest. They almost certainly came off the wardrobe screen, which
shows owned pass titles next to bought ones with nothing to tell them apart.

**The 4 free titles are out**: `the_gunslinger` (Dust), `longshot` (Vesper), `the_bruiser` (Bram),
`lady_luck` (Fortuna) — one per hunter, the plain gold one. Every player owns them from account
creation, so each would be a guaranteed duplicate that converts to currency the instant it drops
(§5). They are not loot, they are a refund with extra steps.

**`the_butcher` was added** (Bram, `bloodmoon`, 600 Tokens). It was the only purchasable title in the
catalog missing from the original tiering, and Epic is where it belongs — see below.

**Epic is the four reserved apexes, one per hunter.** `TitlesConfig` names `fire`, `lightning`,
`bloodmoon` and `holo` as the four apex styles, and forbids ranked season titles from using them "so
a season title cannot dilute a hunter's apex". The Epic row above is exactly those four —
`high_noon` fire, `stormcaller` lightning, `the_butcher` bloodmoon, `wild_card` holo — and all four
are 600 Tokens. `gunmetal` was the original Bram Epic; it is `chrome`, a pass title, and not an apex.
Replacing it with `the_butcher` makes the row internally consistent and removes the pass conflict in
one move.

**Uncommon vs Rare is by taste, not price** — `eagle_eye` (600 Cash) is Uncommon while `deadeye`
(600 Cash) is Rare, and `the_duelist` (250 Tokens) is Uncommon while `dead_silent` (250 Tokens) is
Rare. Deliberate, same as the weapon tiers in §4a. Do not derive a new title's tier from its price.

**Fortuna has no Uncommon title.** Her two cheapest (`the_dealer`, `ace_of_pain`) are both tiered
Rare, so an Uncommon title roll can never produce a Fortuna one. Left as specified; say if the
Uncommon row should pull one of them down.

`LootboxService` must **assert** every rolled item against those predicates at grant time, not just
trust the allowlist — otherwise a catalog addition six months from now silently leaks a pass skin
into a 100-Token box. Fail the roll and re-roll within the tier if an assert trips, and `warn`.

Hero skins for hunters the player does not own are fine — `DataService.GrantHunterSkin` deliberately
allows it and the skin waits in inventory (Fortuna's pass skin already relies on this).

---

## 5. Duplicates

Duplicates **are** rolled — owned items are not excluded from the pool. When one comes up:

**Refund 35% of the item's shop price, in the currency it is sold in**, floored to a whole number
(`math.floor`). Items with no shop price are not in the pool at all (§4), so "what does this refund"
has no edge case.

**Every skin in the pool is Token-priced**, so no skin ever refunds Cash. Verified against
`TOKEN_SKIN_PRICES` and `TOKEN_WEAPON_SKIN_PRICES`: the Cash path in `PurchaseSkinEvent` is a
1000-Cash *default* for skins absent from that table, and none of the ten in §4a are absent.

| Duplicate | Shop price | Refund |
|---|---|---|
| `BluefrostDust`, `UnmaskedVesper` | 300 Tokens | **105 Tokens** |
| `CrimsonRevenant`, `IvoryGambler` | 500 Tokens | **175 Tokens** |
| `FrostveilVesper`, `DirewolfBram` | 600 Tokens | **210 Tokens** |
| `Frostpiercer` | 400 Tokens | **140 Tokens** |
| `Icefang`, `FrozenHand`, `FrostbiteGrudgekeeper` | 600 Tokens | **210 Tokens** |
| Title `unlock = CASH_600` | 600 Cash | **210 Cash** |
| Title `unlock = CASH_1500` | 1500 Cash | **525 Cash** |
| Title `unlock = TOKEN_250` | 250 Tokens | **87 Tokens** (87.5 floored) |
| Title `unlock = TOKEN_600` | 600 Tokens | **210 Tokens** |
| Emote | `EmoteConfig` `price` (Cash) | **35% of it, floored** |

`TOKEN_250` is the only fractional case in the whole table. Derive these at runtime from the configs
rather than hardcoding the numbers — the table is here to be checked against, not copied in.

**Floor in `LootboxService`, before the value reaches Wallet.** `Wallet.award` and `Wallet.spend`
both open with `amount = math.floor((tonumber(amount) or 0) + 0.5)` — that is round-half-**up**, not
truncation. Handing Wallet a raw `250 * 0.35` would bank **88**, not the 87 above. Flooring first
means no fraction ever reaches it and the number shown to the player is the number granted. Do not
delete the floor on the assumption that Wallet handles it; it handles it differently.

**Signatures, read from live Bounty 2026-09-02:**

```lua
Wallet.award(player, data, currency, amount, reason, itemSku)  -- returns newBalance
Wallet.spend(player, data, currency, amount, reason, itemSku)  -- returns ok, balance
```

`spend` returns **two** values and returns `false, balance` when the player cannot afford it — it
does not error and does not deduct. The purchase path must branch on that first return, not assume
success.

**A duplicate is worth more than the chest that produced it.** A 210-Token refund against a
100-Token box is deliberate: it keeps a repeat Legendary from feeling like a wasted pull.

The reveal still shows the real item and then converts it on screen — that reads as a near-miss,
which is honest and feels better than a silent swap.

Only titles, emotes, hero skins and weapon skins can duplicate. Cash, Tokens and potions stack.

---

## 6. Country restriction

`PolicyService:GetPolicyInfoForPlayerAsync(player).ArePaidRandomItemsRestricted`. Nothing in the
codebase calls PolicyService today; this is the first use.

- Called **on the server**, on join, `pcall`'d, cached per player for the session.
- **Fails closed**: if the call errors, treat the player as restricted for the paid path.
- Blocks **only the 100-Token purchase**. The free per-level chest is not a paid random item, so a
  restricted player keeps every chest their levels earn and can open them normally.
- Enforced in the spend handler. Hiding the button is presentation, not enforcement — the server
  refuses the remote regardless of what the client shows.
- The flag is pushed to the client so `BuyButtonTokens` can read `UNAVAILABLE IN YOUR REGION` instead
  of a price.
- The odds panel stays visible for everyone. Odds disclosure is required, and it is also just good.

---

## 7. Launch migration — **DATA-AFFECTING, ONE-WAY**

Every account's Level and XP reset to 1 / 0. Everyone who has played before is paid a launch bundle.

**Stamp:** `profile.Data.LootboxLaunchV1` (boolean, added to the template, backfilled by
`:Reconcile()`). Runs on profile load, right after Reconcile, before anything reads XP. Skipped
forever once stamped.

**Veteran test** — reuse the four signals the tutorial grandfather rule already uses:
`MatchesPlayed > 0` or `TotalPlaytime > 0` or `Level > 1` or `XP > 0`.

**Actions:**
1. Everyone: `data.XP = 0`, `data.Level = 1`, then `DataService.updateLeaderstats(player)`.
2. Veterans only: `Lootboxes.Unopened += 5`; `Boosts.Inventory.xp_25_30 += 3`;
   `Wallet.award(player, data, "Tokens", 200, "lootbox_launch_grant")`.
3. Everyone: `data.Lootboxes.LevelClaimed = 1` — they are level 1 now, so the per-level grant in §8
   cannot double-pay.
4. Stamp `LootboxLaunchV1 = true`.

**This block must exist in BOTH Bounty and Redwater (and therefore Frostbite), byte-identical.**
Same reason `Screened` and `JourneyId` are in both: a follow-joiner's first profile load can happen
in the match place, and whichever place loads first seals the stamp. Bounty-only would let a
match-first player earn XP for a round and then have it wiped on their return to the lobby.

**It cannot be undone by reverting a place.** Flag the release data-affecting. Do not bump
`DATA_VERSION` — that wipes everything including purchases; this is a targeted field reset.

**Check before shipping:** whether anything reads Level for display ranking
(`CanvasLeft.4Leaderboard`). Nothing *gates* on Level in either place — verified by grep, 2026-09-02
— but a leaderboard that sorts on it will show everyone at 1 on launch day, which is expected but
should be a deliberate choice.

---

## 7a. Tutorial completion chest

Finishing the onboarding lesson grants **1 chest**, once per account.

**Where:** Redwater's `ServerScriptService.Onboarding.TutorialDirector`, in `payOut`, inside the
existing branch at line ~1539:

```lua
if outcome == "Completed" or outcome == "Ceiling" then
```

That branch already exists for exactly this shape of grant, and its own comment says why it is the
right place: *"Awarded in Redwater BEFORE the teleport: this server holds the session lock, so the
grant survives a failed return teleport."* A chest written here is in the profile before the player
is sent back to Bounty, so a teleport failure cannot eat it. `Ceiling` (the hard time limit) counts
as finishing — the player sat through the lesson.

**Guard:** its own flag, `Lootboxes.TutorialChestPaid`, in the profile template (both places,
byte-aligned). Set it in the same write.

**Do NOT gate on `Tutorial.Completed`.** It is true for three populations, only one of which
finished anything:
- players who pressed **skip** — `TutorialDispatchService` line 458 sets `Completed = true` when
  `Skipped` is true;
- **grandfathered veterans** — `DataService.onPlayerAdded` line 570 sets it silently for the whole
  existing player base, which would hand every veteran a chest on load *and* collide with the §7
  launch migration;
- players who actually completed the lesson.

**Do NOT gate on `Tutorial.BonusPaid` either.** The completion award is paid **per step**, and the
**first** instalment burns `BonusPaid` (`awardCurrencies`, line 1041) precisely so an abandoned run
cannot come back for a second pot. Riding that flag would pay a chest to someone who quit at step 2.

**Note for testing:** `TEST_ACCOUNT_BONUS_REPLAY` is ON as of 2026-08-17 and is flagged in
`TutorialDirector` as needing to go back to false before the next publish. It only lifts the
`BonusPaid` once-only rule, so it will not re-grant a chest gated on `TutorialChestPaid` — if you
want listed test accounts to re-earn the chest while iterating, clear that flag on the test profile
instead of widening the guard.

**The lesson only ever runs in Redwater, so this grant exists in exactly one place.** Both
`TutorialDispatchService` and `TutorialReplayService` teleport to `GameEnvironment.redwaterPlaceId`
— a fixed destination, not a map choice (verified 2026-09-02). Frostbite never hosts a tutorial, so
even if `/mirror` copies `TutorialDirector` there, the branch is unreachable and cannot silently
skip a grant.

**It is a SUPER chest, not an ordinary one** — see §7b. Grant it as `Lootboxes.SuperUnopened += 1`,
not `Unopened`. No new remote: the player teleports back to Bounty, the profile loads, and
`LootboxStateEvent` reports it.

---

## 7b. The Super Lootbox

A distinct box type with a **fixed** outcome, not a tier roll. One per account, from the tutorial only.

**Guaranteed: 1 weapon skin**, drawn from Dust / Vesper / Bram. Fortuna is out — her only
non-default skins are `PrestigeCard` (limited Robux run, §4) and `FrozenHand`.

The live pool is exactly **four** entries. Verified against live Bounty's
`ReplicatedStorage.WeaponSkins`, 2026-09-02:

| Hunter | Skin | Excluded siblings |
|---|---|---|
| Dust | `HellFire` | `DefaultRevolver` (default), `BetaRevolver` (code-only) |
| Dust | `Icefang` | |
| Vesper | `Frostpiercer` | `DefaultSniper` (default) |
| Bram | `FrostbiteGrudgekeeper` | `Grudgekeeper` (default) |

> **Bram's default is `Grudgekeeper` in live Bounty, not `DefaultShotgun`.** The UI-Update place has
> a folder named `DefaultShotgun`; live has `Grudgekeeper`, which is what `DataService`'s
> `DEFAULT_WEAPON_SKINS` names. Read the pool off **live Bounty**, never the UI-Update place.

Every one of the four is a 400-600 Token shop item, so this is a strong first-session reward. That is
the intent — it is the payoff for finishing the lesson.

**Max one skin, so the filler carries none.** Plus 3 further items drawn from the Common / Uncommon /
Rare pools in §4 **minus every skin entry** — Cash, Tokens, potions, an emote, a title. The §4
exclusion asserts still apply to the filler.

**Prefer an unowned skin.** This is the one place where excluding owned items is correct: the
guarantee is the whole point, and a guaranteed duplicate is a broken promise. Roll among the four the
player does not own; only if all four are owned does it fall through to the §5 dupe conversion. A
genuine first-timer owns none of them, so this is a safety net for test replays and wiped profiles.

**Presentation:** always play the full 5-stage run — five landed bullets, the Legendary glow, the
gold reveal. No new art, and the fixed outcome is exactly what that animation was built to sell.

---

## 7c. Straight to the chest after the tutorial

A player returning from the lesson lands in the lobby with the LOOT menu already open, camera at
`CameraPartLoot`, super chest waiting.

**The host is `StarterGui.TutorialCompleteGui.TutorialCompleteController`.** It already reads
`TeleportService:GetLocalPlayerTeleportData()`, and its header records the sequencing that matters:
the TRAINING COMPLETE card appears *"once the lobby intro has finished"*. So the intro gate is
already solved there — chain the hand-off onto the card's dismissal rather than inventing a second
gate. Order: lobby intro -> TRAINING COMPLETE card (reward numbers) -> LOOT menu.

**Drive it from the profile, not from TeleportData.** Add `superPending` to the `LootboxStateEvent`
payload (`SuperUnopened > 0`). Two reasons:

1. **TeleportData would have to be written in two places or it silently half-works.**
   `TutorialDirector` sets the return payload at `teleportOptions:SetTeleportData({...})` *and*
   stamps the same fields in `stampReturnTeleportData`, because EXIT TRAINING teleports through
   `LeaveToLobbyService`, which resends whatever payload the player **arrived** with. Its own
   comment spells the trap out: *"Both must be here AND in stampReturnTeleportData."* A flag added
   to only one is invisible to exactly the players who left early — and that is the path a confused
   first-timer takes.
2. A profile-driven flag survives a quit. If the player closes the game before opening the chest,
   the next join routes them again. TeleportData is gone by then.

**Route through `MenuHandlerScript`'s own transition** — the camera move plus the
`BlackBarMenuCovered` fire, the same path the LOOT button takes. Do **not** just set
`ChestMenu.Enabled = true`: the lobby's menu state is read from `SelectedMenuFrame`, and a direct
enable leaves the menu system believing the player is still on HOME, so the next tab press hands off
from the wrong frame.

**Clear `superPending` when the chest is opened, not when the menu opens** — a player who backs out
to look around should still be sent back to it on their next join.

---

## 8. Server

### `ReplicatedStorage.Config.LootboxConfig` (ModuleScript, **NOT mirrored**)
Lobby-only, like `SkinCatalog` and `StoreConfig`. Client-readable so the odds panel paints from
config instead of hardcoded text. Holds: tier odds, drop-count table, pools, dupe refund rate, price
(100 Tokens), pity thresholds.

### `ServerScriptService.PlayerServices.LootboxService` (ModuleScript)

**Start it in `Main`'s upper block, beside `BoostService` / `CollectionService` / `BundleService`
(lines ~40-43) — not appended to the bottom of the list.** `Main` carries an explicit comment on
that block: *"START ORDER IS LOAD-BEARING FOR THESE TWO … Anything added below that creates a remote
a client WaitForChilds on belongs up here."* `LootboxService` creates five such remotes, and the
chest client waits on them. Started at the bottom, its listener is deaf for most of server boot —
the exact shape of the `SkinDataEvent` bug below.

Requires `DataService`, `Wallet`, `LootboxConfig`, `BoostConfig`, `TitlesConfig`, `EmoteConfig`,
`SkinCatalog`, and the five exclusion configs from §4.

| Remote | Direction | Purpose |
|---|---|---|
| `RequestLootboxState` | <- Client | Pull half of the join handshake |
| `LootboxStateEvent` | -> Client | Unopened count, XP-to-next-chest, restricted flag, pity counters |
| `PurchaseLootboxEvent` | <- Client | Policy gate, then `Wallet.spend(..., 100, "lootbox_tokens")` |
| `OpenLootboxEvent` | <- Client | Roll + grant; replies with the resolved item list |
| `LootboxResultEvent` | -> Client | The resolved tier and items for the client to replay |

**Pair the push with the pull.** This codebase has been bitten three separate times by push-only join
state (`SkinDataEvent` most recently, which rendered every owned skin as LOCKED for a whole session).
Every other join-time push in Bounty has a `Request*` companion; this one gets it on day one.

Grants route through the existing APIs: `DataService.GrantHunterSkin` / `GrantWeaponSkin`,
`CollectionService.grantEmote`, `OwnedTitles`, `Boosts.Inventory`, and **`Wallet` for every single
Cash/Token movement** — never a raw `data.Cash` / `data.Tokens` write.

### Profile template addition (both places, byte-aligned)
```
Lootboxes = {
    Unopened          = 0,     -- chests held, unopened
    LevelClaimed      = 0,     -- highest level already paid out
    Opened            = 0,     -- lifetime, for analytics
    PityEpic          = 0,     -- chests since last Epic+
    PityLegendary     = 0,     -- chests since last Legendary
    SuperUnopened     = 0,     -- §7b super chests held, counted separately
    TutorialChestPaid = false, -- §7a, written in REDWATER
}
```

`OpenLootboxEvent` carries the box **type** (`"standard"` / `"super"`); the server validates the
matching counter is above zero rather than trusting the client's word for which box it is opening.
The bubble count in §9 is `Unopened + SuperUnopened`.
Plus the `LootboxLaunchV1` stamp from §7.

### Free chest accrual
No Redwater hook needed. Level derives from persisted `data.XP` via `DataService.getLevelFromXP`, so
on profile load and after any XP write the lobby computes `owed = Level - LevelClaimed`, adds it to
`Unopened`, and sets `LevelClaimed = Level`. Idempotent, survives teleports, and needs nothing in the
match places.

### Wallet reasons — add to **BOTH** copies
`lootbox_tokens` (Sink) · `lootbox_reward` (Source) · `lootbox_duplicate` (Source) ·
`lootbox_launch_grant` (Source). An unmapped reason does not error — it silently mislabels itself as
"Gameplay" in analytics, so a missing entry will never announce itself.

---

## 9. Client / UI

### Name collision — read this before importing anything

**`StarterGui.LootboxMenu` ALREADY EXISTS in live Bounty and it is NOT the chest.** It contains a
`HuntersBuyFrame` surface, and `CollectionClient` line 72 does
`playerGui:WaitForChild("LootboxMenu")` **with no timeout**. Importing the prototype over that name
destroys the instance the collection client blocks on, and the entire collection menu hangs forever
with no error.

**Import the chest GUI as `ChestMenu`.** Leave the existing `LootboxMenu` alone.

### The LOOT button already exists and is already wired — to the wrong place, in two scripts

`MainMenuGui.CanvasBottom.Frame["2LootFrame"]` is authored and live, sitting between HOME and
COLLECTION. Routing it is a two-script job.

**1. Camera — `MainMenuGui.CanvasBottom.MenuHandlerScript`.** It owns the `cameraParts` map (line 48)
and flies the camera to the mapped part, yaw-rotated 180 degrees (`getFinalCameraCFrame`, line 507 —
every camera part in this lobby faces away from its subject).

```lua
["2LootFrame"] = cameraFolder:WaitForChild("CameraPartCollection"),   -- line 50
```

**must become `CameraPartLoot`** — the authored destination, at
`Workspace.CameraFolder.CameraPartLoot`.

> **This is broken right now, independently of the lootbox work.** `CameraPartCollection` does not
> exist in `CameraFolder` (verified 2026-09-02; the 14 children are `CameraPart`, `CameraPartLoot`,
> `CameraPartActualCollection`, `CameraPartActualCollectionWeapon`, `CameraPartShop`,
> `CameraPartHunter`, `CameraPartHunterCloseup`, `CameraPartFeatured`,
> `CameraPartFeaturedCloseup`, `CameraPartFeaturedCheckPointCloseup`, `CameraPartVaultDoor`,
> `CameraPartVaultInside`, `CameraPartTeam`, `IntroCameraPart`). That is a no-timeout `WaitForChild`
> inside the table constructor, so `MenuHandlerScript` yields forever at load and the entire main
> menu never initialises. Fix this first and playtest it on its own — it is not a lootbox bug and
> should not wait on a lootbox release.

**2. Menu surface — `StarterPlayerScripts.CollectionClient`.**

> **This is NOT the Collection menu.** The COLLECTION tab (`3CollectionFrame`) is served by a
> different script and a different ScreenGui entirely —
> `StarterGui.CollectionGui.CollectionGuiController`, whose own header says it "opens on the
> bottom-bar Collection tab (3CollectionFrame)" and flies the camera to
> `CameraPartActualCollection`. `CollectionClient` is a **second, separate 3D hunter surface** that
> happens to use similar function names. Do not confuse the two while editing.

`CollectionClient` owns `LootboxMenu.Canvas.HuntersBuyFrame` plus the world-adorned `HunterListMenu`
and `EquipHunterMenu` (Adornee `SkinMenu.InfoSkinFrame` / `UnlockSkinFrame`). It has **exactly two
entry points, and both are `2LootFrame`** — verified 2026-09-02:

- line ~773, the `BlackBarMenuCovered` listener that `MenuHandlerScript` fires mid-transition:
  `if destinationFrameName == "2LootFrame" then openCollectionWithDelay(0)` — its only branch;
- line ~1065, `findBottomMenuButton("2LootFrame")` -> `MouseButton1Click` ->
  `openCollectionAfterCameraTween()`.

It closes when `SelectedMenuFrame` moves off `2LootFrame`.

**So re-pointing the LOOT tab leaves that entire surface with no door** — not just `HuntersBuyFrame`
but the whole 3D hunter-buy experience `CollectionClient` drives. `CollectionClient` is enabled and
live today. Decide before touching it: rehome it to another tab, retire it if the Trading Post
(`StarterGui.Shop`, which replaced `ReworkReworkedBuyMenu` on 2026-08-23) already covers what it
does, or keep a way in. Confirm with the owner before deleting anything.

The chest scene's own props (`ChestShootPart`, and the chest spawned by `ChestController`) must be
positioned to frame correctly from `CameraPartLoot`, not from wherever they sit in the UI-Update
place. Expect to re-place them by eye once the camera move works.

### Notification bubble on the LOOT button

When `Unopened > 0`, a bubble with the **count** sits over `2LootFrame`.

**Clone `CanvasLeft.Frame["3Daily"].DailyNotiFrame`** into `2LootFrame` and rename it
`LootNotifFrame`. It is a `Frame` + `TextLabel` + `UICorner` + `UIStroke`, authored `Visible = false`,
and it is already the house style for this exact thing. Clone it rather than re-typing its property
values — a value read off an existing instance is not necessarily reproducible by assigning it
(UI_STYLE_GUIDE §1.1). `2Quests.QuestNotifFrame` is the same pattern, and
`5TradingPostFrame.NewItemFrame` is the precedent for one on the **bottom** bar specifically.

**One difference from the sources you are cloning: theirs says `!`, this one says a number.** So:
- Leave the label `TextScaled` and let it size itself. Do **not** script-sync the label size from
  `TextBounds` — `TextBounds` reports different metrics on real phones than in Studio, and a
  script-driven fit that looks right in the viewport will not be right on device.
- Check two and three digits, not just one. A player who has not opened the menu in a while can
  easily be holding 12+ chests, and the launch migration hands veterans 5 on day one.
- Cap the display at something like `99+` so the bubble geometry has a hard upper bound.

**Driven by the chest client controller**, from the `LootboxStateEvent` payload — same shape as
`DailyLoginController`, which owns both the daily panel and its bubble and refreshes them together.
Connect the remote handler **before** any scene construction: the bubble must be correct on a cold
join even though the chest scene has never been opened, and this codebase's repeated join-state bug
is a handler that connects after a long build and misses the push (see §8).

`MenuHandlerScript` resolves `NewItemFrame` with `FindFirstChild` at line 68 — resolve
`LootNotifFrame` the same way if the menu script needs it, so a missing bubble degrades to "no
bubble" rather than hanging the menu.

### To import
**Almost nothing needs importing.** Live Bounty already has the whole asset side — verified
2026-09-02:

| Asset | Status in live Bounty |
|---|---|
| `ReplicatedStorage.Lootbox` | **present and complete** — `WorkingChest`, `SmokeLand`, `LaserBeam`, `LootTemplate`, `WoodSplint` |
| `ReplicatedStorage.LootboxSFX` | **present** |
| `Workspace.PersistentMarkers.ChestShootPart` | **present**, and its placement is the streaming fix in §2 |
| `Workspace.SkinMenu.PreviewPart` | **present**, Persistent |

So the import is **GUI only**: the chest UI that live Bounty's `LootboxMenu` lacks —
`ChestPurchaseFrame` (with `OddsFrame`, `BuyButtonTokens`, `ItemPriceTokenText`, `OwnedButton`),
`CanvasMiddle` (`ShootButton`), `ChestProgress` — plus `StarterGui.ChestAward`. Import those under
the new `ChestMenu` name (§9), never over the live `LootboxMenu`.

**The 45 KB `import_rbxm` cap is no longer a problem, because the thing that blew past it does not
need importing.** For the record: `WorkingChest` exports at **1,619,021 bytes** — 36x the cap, and
not splittable in any useful way. GUI frames are small and import fine.

> **Cleanup worth doing while you are in there.** `ReplicatedStorage.Lootbox` holds **three** copies
> of the chest — `WorkingChest`, `WorkingChestBackup` and `WorkingChestBackup2` — at roughly 1.6 MB
> each. That is ~4.8 MB of ReplicatedStorage replicating to every client on join, on a game that has
> to run on phones, for two dev leftovers nothing references. Only `WorkingChest` is read (by both
> ChestControllers). Confirm with the owner, then delete the backups.

Every Sound in `LootboxSFX` must carry a `SoundGroup` (`SFX`) or it escapes all four settings
sliders — check the existing ones, since they are already in place and may never have been grouped.

### Price label
`ChestPurchaseFrame.ItemPriceTokenText` is authored as **"50"**. The price is 100 Tokens. Paint it
from `LootboxConfig` at runtime rather than retyping the string, so the label and the server's spend
can never disagree — the same reason the odds panel below is config-driven.

### Odds panel
`ChestPurchaseFrame.OddsFrame` has five labels (`1Common` .. `5Legendary`) with the percentages
inline in rich text. Repaint from `LootboxConfig` at runtime with the **effective** rates from §3, and
add a line for the pity guarantee — it is a selling point, not fine print.

### Progress bar
`ChestMenu.ChestProgress.ChestXPBar` and `StarterGui.ChestAward` both show XP toward the next level =
the next free chest. Feed from the same `LootboxStateEvent` payload.

---

## 10. Build order

1. `LootboxConfig` + profile template fields + Wallet reasons (both copies) — no behaviour yet.
2. Launch migration (§7) in both places, behind the stamp.

   > ⚠ **STUDIO WRITES THE LIVE DATASTORE.** There is no `IsStudio` branch in `DataService` — a
   > Studio session loads and saves the same `PlayerData_v2` profiles a live server does. So the
   > first time this migration runs in Studio it **permanently resets the XP and Level of whichever
   > real account is testing**, in live data, with no undo. Reverting the place does not restore
   > stored data.
   >
   > Test it on a throwaway account, or gate the write behind `GameEnvironment` until the logic is
   > proven. Back the profile up first — there is an established read/back-up/wipe/restore routine
   > for live profiles from edit mode. **Do not run it once against your own account "just to see".**
3. `LootboxService`: state handshake, free accrual, purchase + policy gate.
4. Roll + grant + dupe conversion, with the §4 asserts. Simulate 1e6 opens and check the effective
   rates against §3 before wiring any UI.
5. Super chest: the fixed roll (§7b), then the grant in Redwater's `TutorialDirector` (§7a), then
   the post-tutorial routing in `TutorialCompleteController` (§7c).
6. Import the GUI as `ChestMenu`; strip the client RNG; drive the animation from `LootboxResultEvent`.
7. Re-point `2LootFrame` — camera part in `MenuHandlerScript`, surface in `CollectionClient`.
8. `LootNotifFrame` bubble, cloned from `DailyNotiFrame`.
9. `capture_device_matrix` on the FIRST draft of the menu, not the last (UI_STYLE_GUIDE §9). Include
   the bubble at 1, 2 and 3 digits.
10. Vault `.md` files for `LootboxConfig` + `LootboxService`, then `python update_bounty_graph.py`.
    `TutorialDirector.md` needs its Connections updated too.
11. `/mirror` (the migration, the Wallet reasons and the §7a grant are in all three places), then
    `/preflight`.

## 11. Open

### Settled — decided 2026-09-02, do not reopen without saying so

- **A title rolling for the wrong hunter is accepted bad luck.** No weighting, no pool restriction.
  Written into §4.
- **A bought chest banks** into `Unopened` rather than opening on purchase. Written into §1.
- **Pity counts every chest**, free and bought alike, on one pair of counters. Written into §3.
- **Dust `Wraith` and `BetaRevolver` are out**, of the hero and weapon pools respectively. They were
  already covered by the §4 predicates; now named outright so neither can be enumerated back in.
- **The Epic / Legendary skin lists are fixed.** Written into §4a, with every hero and weapon skin in
  the game accounted for as tiered or excluded.
- **Level 1 does not pay a chest.** After the reset everyone sits at level 1 with
  `LevelClaimed = 1`, so the first free chest arrives on reaching level 2. §7 already writes this.
- **The title lists are fixed at the 17 purchasable titles**, confirmed 2026-09-02 — the 7 pass and
  4 free titles stay out. Written into §4b.
- **Duplicates refund 35%** of the shop price, in the currency the item is sold in, floored. Every
  skin in the pool is Token-priced, so no skin refunds Cash. Written into §5.
- **The super chest needs no ownership check.** New players own Dust, Vesper and Bram by default, so
  a pool drawn from those three already respects ownership — every winnable skin is for a hunter the
  player can play on day one. Fortuna is the only bought hunter, and she is already out of §7b.

### Owner decisions — these change what gets built

1. **Confirm emotes are Rare-only and the default within-tier weighting** (§4). Both are written in
   as recommendations. All 11 emotes are the same price, so there is no ladder to split them by, and
   Epic reads better without one.
2. **Fix `MenuHandlerScript` line 50 first, as its own change.** `2LootFrame` maps to
   `CameraPartCollection`, which does not exist in `CameraFolder` — a no-timeout `WaitForChild`
   inside the `cameraParts` table constructor, so the whole main menu never initialises. It is live,
   it is unrelated to lootboxes, and the LOOT tab cannot be opened or tested until it is fixed.
   Ship it separately so a lootbox release does not carry a menu fix nobody expected.
3. Does `CollectionClient`'s 3D hunter surface get rehomed or retired when the LOOT tab is
   re-pointed? (§9)
4. Restricted-region players: BUY greyed with an explanation, or hidden entirely? Greyed is the
   recommendation — a missing control is more confusing than a disabled one.

Only 2 blocks anything, and it blocks the build rather than the design.

### Verified 2026-09-02 — these were open assumptions and are now closed

- **`Wallet.spend(player, data, currency, amount, reason, itemSku)` returns `ok, balance`** — two
  values, `false` when unaffordable, no error and no deduction. Both it and `award` round
  half-**up**. Written into §5.
- **The tutorial only runs in Redwater**, dispatch and replay alike, so §7a's grant has exactly one
  home and Frostbite cannot silently miss it. Written into §7a.
- **The asset import is GUI-only** — live Bounty already has `Lootbox`, `LootboxSFX`,
  `PersistentMarkers.ChestShootPart` and `SkinMenu.PreviewPart`. The 45 KB cap is moot.
  `WorkingChest` measures 1,619,021 bytes, and there are three copies of it in ReplicatedStorage.
  Written into §9.
- **`LootboxService` starts in `Main`'s upper block**, beside `BoostService` / `CollectionService` /
  `BundleService`, because it creates remotes the client waits on. Written into §8.

### Verified 2026-09-03 — the §3 effective odds, by simulation

1. **1e6 opens, base roll + both pity counters as specified.** Measured: Common 50.3%, Uncommon
   29.0%, Rare 13.5%, Epic 5.4%, Legendary 1.8% (Epic+ 7.16%, against the analytic 7.2%). Forced
   opens: 2.9% by the Epic counter, 0.43% by the Legendary counter. **So the §3 panel row should
   read 50 / 29 / 14 / 5 / 2, not 50 / 29 / 13 / 6 / 2** — Epic measures 5.4, not 6, and Rare sits
   on the 13.5 rounding boundary (show one decimal, or pick 14 so the row sums to 100). Script:
   `lootbox_sim.py` in the build session's scratchpad; re-run it whenever `LootboxConfig`'s base
   odds or pity thresholds change, and put the measured numbers on the panel.

### Not covered at all

1. **No Telemetry events are specified.** A monetised feature with a currency sink, a free faucet
   and a per-tier outcome is exactly what the `Telemetry` chokepoint exists for. Decide the event
   set before build step 3, not after.
2. **No rate limit on `OpenLootboxEvent` / `PurchaseLootboxEvent`.** Both are guarded by server
   state (`Unopened`, the Token balance), so neither is exploitable for free items — but a client
   firing in a loop still runs the roll and the grant path each time. A per-player debounce
   belongs here; `DataService`'s `SKIN_DATA_REQUEST_COOLDOWN` is the local precedent, including its
   lesson that a debounce must never suppress the payload.
