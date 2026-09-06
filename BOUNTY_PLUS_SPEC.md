# BOUNTY+ SPEC

Adding **Bounty+** — a permanent-perk purchase sold from a frame on the left of the LOOT area.

Designed 2026-09-06. The owner answered the three open questions in that session; their answers are
recorded in §2 together with the alternatives that were rejected, so a fresh session does not
re-litigate them.

**Status: BUILT 2026-09-06.** Everything below shipped to the three places and is described in
`changelog/UNRELEASED.md`, which is now the authority on what exists — this file is the design
record, kept for the rationale in §2 and §8. Two things are deliberately still open: the one-time
grant has never been run against a real profile (Studio writes the live store), and the covered
wagon's wooden body is an invisible stand-in Part because its union is 178 KB of baked CSG. The
three "Owner's call" items in §11 were reviewed and left as they are.

The original status note, for context:

> **Not built**, with one exception. No code exists in any shipping place — not the config,
> not the services, not the earn-site edits, and the card has not been imported into Bounty.

The exception is the card's own artwork in the **UI-Update place** (`place:112014319307228`, which
never ships): its `GOLDEN OUTLAW TITLE` row was added and the five perk rows re-laid on 2026-09-06,
so the import in §7 carries six labels and needs no post-import fixup. Revert values are in §7.
A temporary `__BPStaging` folder was also created there to measure export sizes, and destroyed
again.

---

## 1. What ships

One purchase. On buying it a player gets, once:

| Grant | Amount | Where it lands |
|---|---|---|
| Tokens | 1000 | `Wallet.award(..., "Tokens", 1000, "bountyplus_grant")` |
| Chests | 5 standard | `LootboxService.grantChests(player, data, 5)` |
| Title | "GOLDEN OUTLAW", 4 ids | `CollectionService.grantTitle` x4 — see §8 |

and, permanently, for as long as they own the pass:

| Perk | Value |
|---|---|
| Account XP | +25% |
| Cash | +10% |

**Tokens are never multiplied.** The card promises "+25% BONUS XP" and "+10% BONUS CASH" and
nothing about Tokens; boosting Token payouts would be a perk nobody was sold.

---

## 2. Decisions already made — do not re-open

### 2a. It is a GAME PASS, not a developer product

The owner's brief said "Developer product with id 1968529393". **It is not.** The id resolves only
as `Enum.InfoType.GamePass`:

```
Name        BOUNTY+
Creator     Outlaw Syndicate (group 647193849)
Created     2026-09-06T13:37:51Z
TargetId    1968529393        <- this is what you prompt with
ProductId   3711612302        <- NOT what you prompt with; ignore it
IsForSale   false
Description Become a Bounty+ Hunter with bonus XP, extra rewards, VIP cosmetics,
            and faster progression. Bounty+ does not increase damage, health,
            or combat power.
```

`GetProductInfoAsync(1968529393, Enum.InfoType.Product)` fails with *"Item not found in batch
response"* — that failure is the diagnosis, not a transient error. The authored frame is even named
`GamepassPurchaseFrame`, which agrees.

Owner confirmed: **use the pass.** The rejected alternative was creating a real developer product
and routing it through `StoreService.processReceipt` like the Outlaw Starter Pack — rejected
because a pass gives one-per-account and permanent ownership from Roblox itself, which is exactly
what the card's "PERMANENT BOOSTS" and its `OwnedButton` state promise, at no code cost.

So: `PromptGamePassPurchase(player, 1968529393)`,
`MarketplaceService.PromptGamePassPurchaseFinished`, `UserOwnsGamePassAsync`. **`ProcessReceipt` is
not involved and `StoreConfig` gains nothing.**

> **BLOCKER FOR THE OWNER: the pass is off-sale.** `IsForSale = false`,
> `UserBasePriceInRobux = 0`, `Sales = 0`. Until it is priced and put on sale on the Creator
> Dashboard, `PromptGamePassPurchase` cannot complete and the price label has nothing to show.
> Build against it anyway — everything except an actual purchase can be tested.

### 2b. The boosts apply everywhere XP and Cash are EARNED

The owner chose the broad scope over "match earns only, like potions". The narrow option would have
been one edit (`BoostService.getMultiplier`); the broad one touches five services. The owner took
the broad one knowing that, so do not quietly narrow it back.

"Earned" is drawn at fixed curated payouts. The line, with the reasoning:

| Site | Place | Wallet reason | Boosted? | Why |
|---|---|---|---|---|
| `ProgressionService.addRewards` | Redwater / Frostbite | `kill`, `assist`, `bounty_*`, `round_complete`, `time_alive`, `domination_*` | **XP + Cash** | The gameplay earn. Already a chokepoint. |
| `QuestService` single claim + complete-all bonus | Bounty | `quest` | **XP + Cash** | Earned by playing. |
| `DailyRewardService` claim | Bounty | `daily_reward` | **XP + Cash** | Recurring play reward. Its Token grants are NOT boosted. |
| `LootboxService.grantItem` cash roll | Bounty | `lootbox_reward` | **Cash** | Chest payouts, named in the option the owner picked. Its Token roll is NOT boosted. |
| `LootboxService` duplicate refund | Bounty | `lootbox_duplicate` | no | A conversion of something already owned, not an earn. |
| `BattlePassService` | Bounty | `battlepass` | no | Curated track payout; inflating it re-tunes a shipped system. |
| `RankSeasonRewardService` | Bounty | `rank_season_reward` | no | Curated top-100 payout. |
| `CodeRedemptionService` | Bounty | `code` | no | Already opts out of boosts deliberately (`noBoost = true` on the Redwater path). |
| `BundleService` | Bounty | `bundle_cash` | no | Contents of a thing already paid for. |
| IAP / `refund` / `admin_grant` / `dev_tester_grant` / `lootbox_launch_grant` | both | — | no | Not earns. |

**The stack is ADDITIVE, matching what is already there.** `BoostService.getMultiplier` is
documented as `1 + potion% + friend%`; the pass becomes a third term, so a 25% potion plus the pass
is x1.50, not x1.5625. In Bounty, quests and dailies have no other multiplier at all today
(`QuestConfig` line 84 says so explicitly), so there the pass term is the whole multiplier — a bare
x1.25 / x1.10. Additive in both places; consistent.

### 2c. The price label is fetched live, with the Robux ICON

The frame's `ItemPriceRobuxText` is authored as the static string **"399 BOBUX"**. Replace it with
`GetProductInfoAsync(1968529393, Enum.InfoType.GamePass).PriceInRobux`.

Draw the currency as the **Robux image asset, never the glyph** — see `project_robux_price_icon`:
glyph metrics differ between Studio and the live client. `ShopCore.attachRobuxPrice`
(`StarterGui.Shop.Modules.ShopCore`) already does exactly this and is the thing to reuse or copy;
`ShopCore.getProductPrice` has the caching + waiter pattern, but note it hardcodes
`Enum.InfoType.Product` and so **cannot be used unchanged for a pass**.

Until the owner prices the pass the fetch returns nil. Show nothing rather than a zero.

---

## 3. Ownership: how it is resolved, and why a profile stamp exists

`UserOwnsGamePassAsync` is a web call and it can fail. Both failure directions are bad:

* Fail **open** (assume owned) and a web hiccup hands the perk to everyone.
* Fail **closed** (assume not owned) and a paying player silently loses their +25% for a whole
  round, with nothing in the UI to explain it.

So ownership is resolved once and then **remembered in the profile**:

```
data.BountyPlus = {
    Owned     = true,        -- set only after a confirmed positive web answer; never cleared
    Granted   = true,        -- the one-time 1000 Tokens + 5 chests have been paid
    GrantedAt = <os.time()>,
}
```

Rules:

* The live web check may only ever move ownership **nil/false -> true**. It never revokes. A pass
  is permanent short of a Roblox refund; treating a failed call as revocation is the bug.
* `data.BountyPlus.Owned` is the value every place trusts. Bounty writes it; Redwater and Frostbite
  read it off the shared profile, and may also run their own check to upgrade a profile that has
  not been to the lobby since the pass was bought.
* Publish it to the client as a **Player attribute** — `BountyPlusConfig.Attribute`, i.e.
  `player:SetAttribute("OwnsBountyPlus", true)`. The client needs it to draw boosted reward numbers
  (§5c) and to swap the panel to OWNED. Leave the attribute **nil** while unknown; nil must read as
  not-owned everywhere, so the multiplier helper is nil-safe on its first argument.

Retry the web call a few times with backoff before giving up on a join.

---

## 4. New shared config — `ReplicatedStorage.Config.BountyPlusConfig`

**MIRRORED. This makes the mirrored-module list 20 -> 21.** All three places read it: Bounty for the
panel and the lobby earns, Redwater/Frostbite for the multiplier.

Data only, plus pure helpers — no async, no service requires (the same shape as `FriendBonusConfig`).

```lua
BountyPlusConfig.GamePassId       = 1968529393
BountyPlusConfig.Attribute        = "OwnsBountyPlus"
BountyPlusConfig.XPBonusPercent   = 25
BountyPlusConfig.CashBonusPercent = 10
BountyPlusConfig.Grant = { Tokens = 1000, Chests = 5 }

-- Additive term for one earn kind ("xp" | "cash"), as a FRACTION, so callers can add it to an
-- existing additive stack. 0 when not owned, and nil-safe: ownership is nil until answered.
function BountyPlusConfig.bonusFraction(owns, kind) end

-- Convenience for the Bounty sites, which have no other multiplier: returns the boosted amount.
function BountyPlusConfig.apply(owns, kind, amount) end
```

`apply` is the ONE place rounding happens, so the number the client draws and the number the server
banks cannot disagree. Match the existing convention: `math.floor(x + 0.5)`, as `ProgressionService`
does.

**Everything that reads the percentages must go through this module.** The failure this prevents is
`EmoteConfig`'s: a mirrored constant restated in a second file drifts silently and nothing errors.

### Also mirrored: a new `Wallet` reason

`Wallet`'s `TRANSACTION_TYPE` gains `bountyplus_grant = "IAP"` — it is Robux-sourced Tokens, the
same category as `iap_token_bundle`. **Add it to all three copies in the same pass.** An unmapped
reason does not error, it silently books itself as "Gameplay" (CLAUDE.md, Economy).

---

## 5. Bounty (lobby)

### 5a. New service `ServerScriptService.PlayerServices.BountyPlusService`

**Bounty-only, NOT mirrored** — the same call `GroupPerkConfig` makes and for the same reason: the
purchase prompt and the chest grant only exist in the lobby, so a mirrored copy would be dead code
in Redwater that `/preflight` then has to keep in sync forever.

Responsibilities:

1. On profile load / `PlayerAdded`: resolve ownership (§3), stamp the profile, set the attribute.
2. Back-fill: if owned and `Granted` is not set, pay the one-time grant — Tokens, chests **and the
   four GOLDEN OUTLAW ids** (§8). This is what covers anyone who bought the pass before this code
   shipped, and anyone who buys it on the website.
3. `MarketplaceService.PromptGamePassPurchaseFinished`: on `wasPurchased`, re-resolve ownership,
   pay the grant, push state.
4. Expose `BountyPlusService.owns(player) -> boolean` for the lobby earn sites.
5. Push a small state remote for the panel (owned + whether the grant is paid), following the
   **`project_join_state_handshake`** rule: pair the push with a `RequestBountyPlusState` pull, or a
   state push that lands before the panel's listener exists is dropped for good.

Start it in `ServerScriptService.Main`. It must run **after** `DataService.Start()` (line 31) and
**after** `LootboxService.Start()` (line 48), because the grant calls `LootboxService.grantChests`.
Put it around line 49, beside `NewItemService.Start()`.

The grant must be **all-or-nothing and idempotent**: stamp `Granted` only once both the Tokens and
the chests have landed, so a failure half way is retried on the next join rather than banked.

### 5b. Boosting the lobby earn sites

* `QuestService` lines 163-165 (bonus claim) and 184-186 (single claim) — boost `reward.cash` and
  `reward.xp` before the `Wallet.award` / `data.XP` write. Both sites already recompute `data.Level`
  through `DataService.getLevelFromXP`; keep that.
* `DailyRewardService` lines 124-129 — boost the `cash` and `xp` grants. **Leave `tokens` alone.**
* `LootboxService.grantItem` lines 578-581 — boost `item.amount` when `item.kind == "cash"` only,
  and **write the boosted number into `resolved.amount` too**. The client replays `resolved`; if the
  server banks 110 and the reveal card says 100, the chest looks like it is short-changing the
  player. This is the one site where boosting silently breaks a display.

### 5c. Displayed reward numbers

The owner was warned that the broad scope means quest cards would understate what a Bounty+ player
actually receives, and took it anyway — but understating a perk the player paid for is the wrong
half of the tradeoff to leave in. Where a reward number is drawn from config, multiply it through
`BountyPlusConfig.apply` using the `OwnsBountyPlus` **attribute**, so the card and the grant agree.

Sites: the quest cards (daily/weekly plus the complete-all bonus), the daily-reward panel, and the
chest reveal (already covered by boosting `resolved.amount` in 5b).

This is why the attribute exists rather than a server-only flag.

### 5d. The panel — see §7

---

## 6. Redwater Canyon + Frostbite Claim

Kept in sync by `/mirror`, not by Packages — edit Redwater, then mirror the full gamemode tree.

* `ServerScriptService.PlayerServices.BoostService.getMultiplier` (Redwater line 50) gains a third
  additive term beside the potion and the friend bonus:

  ```lua
  mult += BountyPlusConfig.bonusFraction(owns, kind)
  ```

  Read ownership from `data.BountyPlus.Owned` (the profile is shared, so the lobby's answer is
  already there), with an optional live upgrade for a profile that predates the stamp. Keep the
  existing comment block honest — it currently says the stack is `1 + potion + friend`.

* `ProgressionService` needs **no change**: it already multiplies both `xp` and `cash` through
  `getMultiplier` (lines 206-207), and `noBoost = true` callers (code redemption) keep opting out,
  which is correct — a promo code is not an earn.

* A small ownership resolver is needed in these places too. Fold it into `BoostService.Start` or add
  a tiny place-local `BountyPlusService`; either way it is **not** the mirrored config, and
  Redwater's copy and Frostbite's copy must be byte-identical.

---

## 7. The UI — an import, not a build

The frame is **already authored and already positioned** in the UI-Update place
(`place:112014319307228`, see `project_ui_design_place`):

```
game.StarterGui.ChestMenu.Canvas.GamepassPurchaseFrame
    Position {-0.455, 0}, {0.515, 0}   AnchorPoint (0, 0.5)
```

which is the mirror image of the live chest panel at `{1.455}, {0.430}` anchor `(1, 0.5)` — the left
side of the loot area, which is what the owner asked for. **Do not re-derive these numbers and do
not retype properties**; import the instance.

Children, all authored: `Title` ("BOUNTY+"), `ItemPriceRobuxText` ("399 BOBUX"), `BuyButton`,
`OwnedButton` (hidden), `AfterPurchaseText`, and a `ViewportFrame` whose overlaid labels read
`PERMANENT BOOSTS` (header), `+25% BONUS XP`, `+10% BONUS CASH`, `1000` (with a token icon),
`x5 BASIC CHESTS` and `GOLDEN OUTLAW TITLE`. The five perk lines match §1 exactly — no copy needs writing.

**The title row was added and all five re-laid on 2026-09-06, in the UI-Update place**, so
the import carries six labels and needs no post-import fixup. What was done, and why those numbers:

* The four perk rows were hand-authored at pitches of 0.07494 / 0.07473 / 0.07472 — near-even but
  not even. All five now sit on one exact pitch of **0.073862**, keeping `XPHeader` at its authored
  0.455872 as the anchor, so the existing rows moved by at most 0.0028 and the new one does not
  read as bolted on.
* The floor is `ItemPriceRobuxText`, whose top is **0.81110** in ViewportFrame-local Y (parent
  centre 0.720324 minus half of 0.141, re-expressed against the viewport's 0.044386..0.790824 span).
  The last row's bottom lands at 0.79910 — a deliberate **0.012** margin. Do not shrink it.
* `TitleHeader` is a **clone of `CashHeader`**, not a new label: it inherits the font face, the
  UIStroke, `TextScaled`, `RichText` and the coloured-`<font>`-span pattern. Its text is
  `<font color="#E6BF5C">GOLDEN OUTLAW</font> TITLE` — `#E6BF5C` is the catalog's `GOLD`, the same
  accent the `gilded` preset builds from (§8d). The row NAMES the reward rather than its tier: it is
  the only place the card can say what the title actually reads. It is the longest string in the
  list so `TextScaled` renders it slightly smaller than its neighbours — that variance is already
  the authored condition here (`1000` renders far larger than `x5 BASIC CHESTS`).
* Verified by screenshot at 16:9 (`hd_1080`), 4:3 (`ipad_9th_generation`) and phone
  (`iphone_13`) — even spacing and clear of the price at all three. The row boxes overlap each
  other by 0.0218, which is the authored condition and harmless: `TextScaled` is bound by the box
  WIDTH on these strings, so the rendered glyphs sit well inside the box height.

To undo the re-lay, restore these authored Y scales under
`ChestMenu.Canvas.GamepassPurchaseFrame.ViewportFrame` and destroy `TitleHeader`
(`Permanent` was not moved):

```
XPHeader     0.455872267    CashHeader  0.530807734
TokensHeader 0.605535269    LootHeader  0.680262685
```

### 7a. It cannot be imported in one piece. Measured.

`export_rbxm` of the whole frame is **2,028,315 bytes**. The `import_rbxm` ceiling is roughly 45 KB,
and nearer 20 KB for GUI content (`reference_import_rbxm_size_limit`). Measured split:

| Piece | Export size | Plan |
|---|---|---|
| Frame with the viewport contents stripped ("chrome", 41 descendants) | **17.2 KB** | Import it. At 17 KB expect a first-try success or one retry. Measured before the title row; one more label puts it a few hundred bytes higher, nowhere near the ceiling. |
| `DisplayCharacter` (R15 MeshPart rig, 315 desc, accessories, WrapLayer, 15 AnimationConstraints) | **51.5 KB** | Over the ceiling. Split into body-parts and accessories bags, or rebuild from its `HumanoidDescription`. |
| 6 x `ChestTest` (543 desc) | **1.62 MB** | Never import. Bounty already has `ReplicatedStorage.Lootbox.WorkingChest` (103 desc) — clone it six times and restore the pose. Verify it really is the same chest first; the UI-place copies are 89-90 desc, so they are a different revision. |
| 38 `Coin` UnionOperations | **141 KB** | Export ONE coin (a few KB), import, clone it 38x onto the recorded CFrames. |
| `Tall Cactus` MeshPart plus one 6-descendant `Model` | small | Export together with the single coin. |

**Before stripping anything, record every child's `GetPivot()` and `GetScale()` in the source
place** and keep the table — that is the only thing that makes the rebuild reproducible. Note the
`Model:ScaleTo` trap in `reference_model_pivot_and_scale_gotchas`: `ScaleTo` is absolute, not
relative.

Stage the imports under a `ZZ_BPStaging` folder and reparent only after comparing child counts —
never import straight over the target.

### 7b. Viewport traps

* **`CurrentCamera` is nil and must stay nil.** The frame auto-frames its contents; adding a Camera
  un-matches the authored composition (`reference_viewportframe_autoframes_without_camera`).
* `DisplayCharacterAnimator` **disables** the rig's `Animate` LocalScript and plays
  `rbxassetid://110021104195913` on a loop at Idle priority. Disabling is correct — never **destroy**
  it, Motor6D rigs stop drawing entirely (`project_viewport_animate_script_render`).
* The rig must be assembled **inside the `WorldModel`**, not posed in Workspace and moved. A
  `WorldModel` plus a playing idle is the proven path for a Humanoid rig here; an anchored static
  world model leaves layered clothing undeformed (`project_lootbox_chests`, round 5).

### 7c. The panel needs the same UIScale treatment the chest panel just got

`ChestController` lines 74-130 (added 2026-09-06) grow `ChestPurchaseFrame` with a single `UIScale`
about its **top-right** corner, because the authored fraction reads 125 x 162 px on a landscape
Galaxy A06. The Bounty+ panel is the same authored size on the opposite side and will read exactly
as small.

Give it the mirror treatment — grow about the **top-left** corner — and re-derive the bound against
the nav diamonds' **left** edge rather than copying `PANEL_SAFE_SCALE = 1.2` blind. The existing
comment explains why one number does not fit every aspect; the same reasoning applies mirrored.

### 7d. Wiring

Fold the panel's behaviour into the existing `ChestController`
(`StarterGui.ChestMenu.Canvas.ChestController`, 3683 lines) rather than adding a second controller —
`project_ui_design_place` warns that prototype controllers must be folded in and deleted, and two
owners of purchase state desync the moment a request is refused. `DisplayCharacterAnimator` is fine
to keep as its own small script; it owns nothing but the animation.

Buy button -> `PromptGamePassPurchase`. Swap `BuyButton` -> `OwnedButton` on the `OwnsBountyPlus`
attribute (and on its `AttributeChanged` signal, so the panel flips the moment the purchase lands).

---

## 8. The GOLDEN OUTLAW title

Answers the "VIP cosmetics" promise in the pass's own store description. Owner chose, 2026-09-06:
**a new bespoke style preset**, and one shared label — first "BOUNTY+", then changed to
**"GOLDEN OUTLAW"** the same day. Nothing had shipped, so the ids were renamed with it rather than
left as `bountyplus_*`; the catalog's convention is that an id echoes its label.

### 8a. It has to exist four times

**All titles are hunter-locked and there is no account-wide tier.** One was built once and rejected
outright ("titels are still locked to a hunter") — do not reintroduce the concept.

`TitlesConfig.IsValid` keys off `HunterById`, which the file builds by iterating `HunterOrder`, so a
single id listed under all four hunters resolves to the **last** one and would be equippable on
Fortuna alone. A title the owner can wear on whichever hunter they play therefore needs four ids:

```
golden_outlaw_dust   golden_outlaw_vesper   golden_outlaw_bram   golden_outlaw_fortuna
```

all sharing `label = "GOLDEN OUTLAW"`. This is exactly what the season titles do
(`s4_champion_dust`, ...) and `RankSeasonRewardService` already grants all four in one loop — copy
that shape. **Ids are never reused**, for the same reason the ex-pass ids are retired.

Author them with a small loop over `HunterOrder`, placed **after** the season-title injection block
and **before** the flattened `LabelById` / `EntryById` / `HunterById` lookups are built, or they will
not resolve. Do not fold them into the season loop; that one is season-stamped.

### 8b. Unlock descriptor

A `grant`, the same kind the battle pass uses — add a helper beside `pass(level)`:

```lua
local function bountyPlus()
    return { kind = "grant", source = "bountyplus", detail = "BOUNTY+" }
end
```

* `TitlesConfig.Purchasable()` already filters to `kind == "purchase"`, so **no shop card appears**
  by itself. Correct — it is not for sale separately.
* `RequirementText` returns `detail`, so the wardrobe badge reads "BOUNTY+". **The badge names the
  SOURCE, not the title** — exactly as the pass titles' badges read "BOUNTY PASS L17" while the
  title itself is called DUSTDEVIL. So the row shows GOLDEN OUTLAW with a BOUNTY+ badge beside it.
* **Not `hiddenUntilOwned`.** Season titles hide because a placement can never be earned again;
  GOLDEN OUTLAW can always be earned by buying the pass, so an unowned row carrying a BOUNTY+ badge
  is the advert. Do not copy the season flag across.
* The catalog invariant now has a **third** granter (battle pass, rank season, Bounty+). Verify
  **both** directions: everything marked `grant` is awarded by some granter, and everything a
  granter awards is marked `grant`. A one-directional check passes happily on a half-migrated
  catalog.

### 8c. Granting it costs no new plumbing

`CollectionService.grantTitle(player, titleId)` writes `profile.Cosmetics.Titles`, and
`CollectionService.titleOwned` already reads that bucket — the same one battle-pass grants use.
So the wardrobe, the equip gate and Redwater's three display surfaces all work with **zero further
changes**. `CollectionService.equipTitle` is the only ownership gate in the game; do not add a
second one anywhere.

The grant is **one-way and permanent** — a Roblox refund does not strip the title. That matches
`GroupPerkConfig`, where leaving the group keeps the skin, and it is deliberate.

### 8d. The `gilded` preset — TitleStyles 12 -> 13

Named for the LOOK, not the tier. Every preset in the file is a look name — plain, chrome,
bloodmoon, sandstorm — so `vip` (the first choice) would have been the only one naming a price
bracket, and price is explicitly not a function of style in this catalog.

**Build it out of `hue`, which is already implemented and used by nothing.** Verified 2026-09-06:
`hue { period, saturation, value }` is documented in the TitleStyles schema (line 110) and
implemented in `TitleRenderer` (`ReplicatedStorage.Modules.TitleRenderer`, line 1049, the `elseif
preset.hue then` branch) — and **no preset in the catalog uses it**.

That matters more than it looks: it makes the new style **data-only**. `TitleStyles` is the single
file that changes and `TitleRenderer` — also mirrored, also three copies — stays byte-identical.
Adding a new *mechanism* to the renderer would triple the risk for the same visual result.

Design, and why it is not a recolour of something already worn:

* **Fixed gold glyphs under a slowly cycling prismatic aura.** Gold is the pass's own brand colour
  and the catalog default. Everything else either cycles the **glyphs** (holo), rakes a band across
  them (chrome / bloodmoon / sandstorm) or strobes the whole word (lightning). **Nothing moves
  colour through the halo.** So it reads as genuinely new without touching a reserved apex.
* **Give it a periodic `flash` glint**, so it satisfies the catalog rule that an apex owns an EVENT
  rather than just a palette. Keep `punch <= 1.0` and `threshold <= 0.66` — `flash.threshold` is
  compared against `math.noise() + 0.5`, which occupies roughly 0.2-0.8 in practice, so chrome's
  0.80 fired at 1% strength over five seconds, i.e. never.
* **Two bloom layers, not three.** The 3-layer stack is the one whose outer dilation bridges the
  gaps between glyphs and boxes the word up into a coloured lozenge.
* `animated = true`, so it registers with the shared stepper.
* `gilded` joins the RESERVED list beside fire / lightning / bloodmoon / holo: one title, one
  style, no recolours. A second title on it is what would stop it feeling like an apex.

Two traps, both already written down elsewhere and both easy to walk into here:

1. **Omit `stroke`.** `hue` drives the colour of BOTH the tight stroke and every bloom layer
   (TitleStyles header note, line 121), so a preset cannot have a fixed dark rim under a
   colour-cycling aura. Leave `stroke` off and let the host label's own authored black TextStroke
   supply the rim — every surface that shows a title sets one.
2. **Do not "fix" it later by removing the aura.** Holo carries no aura *by user instruction*,
   because rainbow glyphs plus a coloured halo muddy each other. `gilded` is the **inverse** — fixed
   gold glyphs, cycling halo — and is not the combination that was rejected.

Verify it the way every other preset defect was found, by picture and by sampling, never by reading
the source: rebuild the style board with all **13** presets at 16 / 24 / 42 px and screenshot it,
then sample the ghost's `TextTransparency` over several seconds to prove the flash event actually
fires.

---

## 9. Traps that cost time to find

1. **The id is a pass, not a product** (§2a). `GetProductInfoAsync(..., InfoType.Product)` fails;
   `InfoType.GamePass` succeeds. The pass's own `ProductId` field (3711612302) is a decoy.
2. **The pass is off-sale.** Nothing can be bought until the owner prices it.
3. **2 MB of viewport content** (§7a). Do not discover this by trying to import the frame.
4. **`resolved.amount`** in `LootboxService.grantItem` — boost it or the reveal lies (§5b).
5. **Tokens are not boosted.** Three of the sites hand out both Cash and Tokens from the same loop;
   it is one `if` away from boosting the wrong one.
6. **`ChestMenu` is the LOOT tab, `LootboxMenu` is the dead old one.** Both still exist in Bounty and
   both sit `Enabled = false` at rest. Never build over `LootboxMenu` — `CollectionClient` blocks on
   that name with a no-timeout `WaitForChild` (`project_lootbox_chests`).
7. **A disabled `ScreenGui`'s geometry is stale.** `ChestMenu` is disabled at rest, and
   `CurrencyHudController` already works around this when it measures `ChestPurchaseFrame` for the
   LOOT currency chips. Adding a second panel to the same Canvas must not break that measurement.
8. **Studio writes the LIVE data store** (`project_studio_live_datastore`). The one-time grant is
   real Tokens on a real profile. Back up the test profile before exercising the grant path.
9. **One title id under four hunters silently becomes a Fortuna-only title** (§8a). It does not
   error; `HunterById` just keeps the last hunter that claimed the id.
10. **`hue` and `stroke` are mutually exclusive** (§8d). Authoring both gives GOLDEN OUTLAW a rim
    that cycles with the aura instead of the fixed dark edge that keeps it legible.

---

## 10. Build and verify, in order

1. `BountyPlusConfig` into all three places; byte-length plus checksum compare.
2. `Wallet` reason into all three copies; compare again.
3. `TitlesConfig` (four ids) and `TitleStyles` (the `gilded` preset) into all three places; compare
   again. Assert the catalog count went 28 -> 32 and the preset count 12 -> 13 **through a fresh
   `require`** — the plugin VM's require cache is stale and once reported 27 titles when the source
   had more (`feedback_plugin_require_cache`).
4. `BountyPlusService` in Bounty plus `Main` wiring. Verify ownership resolution and the attribute
   with a `loadstring` probe before any grant runs.
5. The grant path, against a **backed-up** test profile. Confirm idempotence: run it twice, get 1000
   Tokens, 5 chests and 4 title ids once. Then check the title is equippable on all four hunters and
   shows in the wardrobe with a BOUNTY+ badge rather than a price.
6. Redwater `BoostService`, then `/mirror` to Frostbite. Verify with `BoostService.getMultiplier`
   directly rather than by playing a round.
7. The five earn sites (§5b), each checked by reading the profile before and after.
8. Rebuild the style board — all **13** presets at 16 / 24 / 42 px in one ScreenGui — and screenshot
   it. Sample the `gilded` ghost's `TextTransparency` over several seconds to prove the flash fires.
9. Import the chrome (§7a), rebuild the viewport, screenshot-verify per
   `feedback_ui_screenshot_verify`.
10. `capture_device_matrix` on the FIRST draft, not the last (UI_STYLE_GUIDE §9) — phone, tablet and
    windowed PC, checking the panel against the nav diamonds.
11. Preview to the owner and get sign-off **before** vault/graph/changelog work
    (`feedback_preview_before_writeup`). The style board is part of that preview.
12. Vault `.md` for every new script in `LocalBounty/`, then `python update_bounty_graph.py`. Verify
    the new edges with a `_src` grep.
13. `/changelog`. **Mark the release data-affecting** — the grant writes Tokens, chests and title
    ownership that reverting a place cannot undo.
14. Update the mirrored-module list from 20 to 21 in `CLAUDE.md`, `changelog/CONVENTIONS.md`, and
    whatever `/mirror` and `/preflight` read.

---

## 11. Left open

* **"Faster progression"** in the store description is still unclaimed. The +25% XP arguably covers
  it; if the owner meant something more, it is not in this spec.
* **"PERMANENT BOOSTS" is now the wrong header for the list under it.** It was already only true of
  the first two rows — Tokens and chests are one-time grants — and the title row makes it three of
  five that are not boosts. Pre-existing, not introduced by the re-lay, and it is the owner's copy
  to change. Owner's call.
* **The panel has no card behind it.** `ChestPurchaseFrame` on the right draws a navy rounded panel
  with a UIStroke; `GamepassPurchaseFrame` has a UICorner and UIGradient but reads as transparent
  over the world, so white perk text sits directly on the sky and, at 4:3, on the rig's gold coins.
  Deliberate or not, it is visibly asymmetric with the panel opposite it. Owner's call.
* **The panel is as small as the chest panel was before its UIScale** (§7c). Confirmed by the same
  device matrix: legible at 16:9, cramped at 4:3, small on a phone. The mirrored UIScale in §7c is
  what fixes it; the re-lay does not.
* **The price.** The card art says 399; the pass has no price set. The label is live-fetched, so the
  art will simply follow whatever the owner sets.
