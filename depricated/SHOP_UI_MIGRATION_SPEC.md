# Trading Post UI Migration — Spec

**Status:** BUILT 2026-08-23; playtested live by the owner the same day in three rounds (§13, §14) —
every finding fixed and **confirmed working live 2026-08-23**; a real-phone pass is the only surface
not yet exercised. Written for a cold session to execute; executed the same day. Changelog entry in `changelog/UNRELEASED.md`; vault
files under `LocalBounty/StarterGui/Shop/`; backups in `backups/2026-08-23_*`. **Deviations from
the text below are listed in §12 at the end** — read that before trusting a section verbatim.
**Owner:** unassigned.
**Places affected:** Bounty (`131701626847012`) only. The source UI lives in a fourth place,
**Bounty - UI Update** (`112014319307228`), which is a design scratch place — read from it, never
publish it, never point anything at it.
**Live state was measured 2026-08-23** against both places. Re-verify anything you are about to edit;
peer sessions work this project concurrently.

---

## 1. What this is

A friend of the owner rebuilt the Trading Post as a flat 2D store — `StarterGui.Shop` (a ScreenGui
with a 1973-line `ShopController` LocalScript) plus `StarterGui.CurrencyShop` — in the scratch place.
It is a **presentation prototype**: every tween, hover and card ripple is finished, but purchases are
mocked in local tables, there are no remotes, and several panels are not wired at all. The job is to

1. copy both ScreenGuis and the five UI sounds into Bounty,
2. wire the prototype to the **existing** backend (remotes, attributes, configs — nothing server-side
   changes except where §5.6 says so), replacing `StarterGui.ReworkReworkedBuyMenu` as the screen the
   bottom nav's TRADING POST button opens, and
3. implement the friend's seven review comments (§4).

The old Trading Post is **five** LocalScripts totalling ~6k lines (`TradingPostController` 2384,
`HuntersBuyController`, `TitleBuyController`, `EmoteBuyController`, `AccessoryBuyPanel`). Their
*backend contracts* are what carries over (§5); their UI code does not. Read their vault `.md` files
only when §5 points you at one.

The friend's comments, verbatim in Danish, are in the owner's message of 2026-08-23; §4 carries the
translation and the instance each one resolves to.

---

## 2. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Does the new `Shop` replace `ReworkReworkedBuyMenu`, or coexist? | **Replace.** The bottom nav's `5TradingPostFrame` enables the new ScreenGui. The old ScreenGui stays in `StarterGui`, `Enabled = false`, untouched, for **one release** as the rollback, then is deleted with its vault files. Nothing may reference it in the meantime except MenuHandlerScript's disable-on-leave sweep (harmless). |
| 2 | Currency chips: the new `TopFrame` has its own chips + `+` buttons, but Bounty's chips are owned by `CurrencyHudGui` | **The new TopFrame chips are the live ones inside the shop.** They bind to `leaderstats.Cash/Tokens` exactly as `CurrencyHudController` does (comma grouping, scale-pop on change). `CurrencyHudGui` must **stop drawing its Trading Post row while the new Shop is enabled** (it keeps the Bounty Pass stack). The friend's comment 2 names "BuyCurrency i TopBar" as a click target, so these are meant to be real. *Rejected:* hiding the new chips and keeping the HUD row — the HUD row was positioned by mirroring the OLD canvas fit and would not sit in the new STORE bar. |
| 3 | Code redemption lives in Settings today (`RedeemCodeRequest` under `Events.SettingsEvents`) | **Keep both.** The Extras tab gets the new redeem box (comment 4); the Settings one is untouched. Same remotes, no server change. |
| 4 | Which titles cycle in the TITLES tile preview (comment 6) | `TitlesConfig.Purchasable()` in its own order, rendered styled through `TitleRenderer.apply`. Non-purchasable titles never preview — the tile advertises what the tab sells. |
| 5 | HUNTERS tab Robux button — standalone hunter or bundle? | **Standalone** `StoreConfig.DeveloperProducts.FortunaHunter` (3606060477). The FEATURED right panel says `BUNDLE` / `INCLUDES 400 [token]` and is the bundle (3605676843); the HunterPurchaseFrame says nothing about tokens. Both panels must read the real Robux price via `MarketplaceService:GetProductInfo` (memoised) instead of the authored `300 BOBUX`. |
| 6 | CurrencyShop purchase — the new `CurrencyShop.BottomFrame` row is `LowerOffer(-) · amount · IncreaseOffer(+)` and has **no BUY button** | **Add a BUY button** (owner, 2026-08-23), cloned from the new purchase-button template (`PurchaseableGradient` / `UnHoverGradient` / `TopBarFrame` / `UIShadow`), bound with the same *re-pressable* hover as comment 4's redeem button, carrying the Robux price from `GetProductInfo`, firing `MarketplaceService:PromptProductPurchase(localPlayer, offer.ProductId)`. *Rejected:* making the centre amount pill the button — no affordance, and nowhere for the Robux price. |
| 7 | The vault cinematic — today `+` runs a camera flight into the 3D vault (`CameraPartVaultDoor` → door animation → `CameraPartVaultInside`), drops physical coin stacks per tier, and shows the offer row over it | **Keep the cinematic and the coin piles** (owner, 2026-08-23); swap only the overlay — `BuyCurrencyFrameNew` + the re-laid chip column are replaced by `CurrencyShop.SideFrame` (chip column) + `CurrencyShop.BottomFrame` (offer row). The friend's "tween effekt, lidt ligesom vi allerede har i Bounty" = keep what is there and make the new overlay move like it. *Rejected:* flat overlay with no cinematic. |
| 8 | Equipping from the shop — the new UI has PURCHASE / OWNED only; the old Trading Post also had EQUIP / EQUIPPED | **Shop is buy-only; equip stays in the Collection menu** (`CollectionGui`) (owner, 2026-08-23). Do not invent an EQUIP state. The `OwnedButton` panels and OWNED card badges are the terminal state. |
| 9 | The BUNDLES tab — `5BUNDLES` is in the tab bar with no canvas; the old shop sold `StoreConfig.BundleProducts.LetTheHuntBegin` (3708064902) there | **Leave it visible and inert** (owner, 2026-08-23) — exactly the prototype's behaviour: the tab highlights and selects, the content area stays empty. Do not hide it and do not port the old bundle card. The bundle is unreachable from the shop until a canvas is designed; note that in the changelog entry as a known gap. |

All nine are settled — build them as written. Anything *not* covered here that changes what the
player sees or where they navigate is still the owner's call: ask before building it.

---

## 3. What moves, and where

### 3.1 Copy from `Bounty - UI Update` into Bounty

| Source (scratch place) | Destination (Bounty) | Notes |
|---|---|---|
| `StarterGui.Shop` (whole ScreenGui) | `StarterGui.Shop` | Rename is optional; keep `Shop`. Delete `Shop.TextButton` (the prototype's open/close toggle) after wiring the `.Enabled` path (§6). `Enabled = false` authored. |
| `StarterGui.CurrencyShop` | `StarterGui.CurrencyShop` | `Enabled = false` authored. It is the **vault overlay** (decision 7): keep it a sibling ScreenGui of `Shop` at the same `DisplayOrder` (0); the nav bar and other chrome are hidden by the vault's existing snapshot/restore, not by layering over them. |
| `ReplicatedStorage.SFX.UIButtonClick` (Folder, 5 Sounds) | `ReplicatedStorage.SFX.UIButtonClick` | Bounty has no such folder. **Set `SoundGroup = SoundService.SFX` on all five** — they are ungrouped in the scratch place, and an ungrouped Sound escapes every volume slider. Ids: `UIPurchaseButtonPrompt` 117649901456711 · `UIClick` 15675032796 · `UIDropDown` 109455895503216 · `UIHover` 10066931761 · `UIPurchaseSucces` 3295472928 (same id as Bounty's `ShopMenuSFX.PurchaseSucces`). |

Use `export_rbxm` / `import_rbxm` (or `:Clone()` across places is not possible — it is two DataModels).
After import, **verify in Bounty** that every `ViewportFrame.WorldModel` rig survived (the hunter cards
each carry an authored `Rig` with an `Animate` LocalScript; the controller replaces them at runtime
from `ReplicatedStorage.Characters`, so a missing rig is cosmetic, but a missing `WorldModel` breaks
`worldOf()`).

### 3.2 Do NOT copy

- `Workspace.EmotePreviewController`, the 16 emote rigs in the scratch Workspace, `Workspace.Dummy`,
  `StarterGui.ScreenGui / AnnouncerGui / KillCounterGui / DominationGui` — test harnesses and
  Redwater copies.
- `ReplicatedStorage.Characters` / `WeaponSkins` / `Emotes` from the scratch place — Bounty's own are
  the source of truth and are a superset (Bounty has FrozenHand, BetaRevolver, Icefang,
  Grudgekeeper, FrostbiteGrudgekeeper that the scratch place lacks; Bounty has no `Emotes` IntValue
  folder at `ReplicatedStorage` root — see §5.5 for where emote ids come from).

### 3.3 Already matching — nothing to do

`ReplicatedStorage.Characters.<Hunter>/Default/<Model>` and `/Skin/<SkinName>` have the same shape in
both places, so `defaultModel()`, `populate()` and `putModel()` work unchanged.
`ReplicatedStorage.WeaponSkins.<Hunter>/<Model>` matches too, **except** Bram: Bounty's default is
`Grudgekeeper`, not `Default…`, so `defaultWeapon()`'s `^default` match fails for him. Drive "which
model is the default" from `HuntersBuyController`'s `WEAPON_SKINS[hunter][1]` rule (index 1 = free
default) or from `WeaponDisplayConfig`, not from the name prefix.

---

## 4. The friend's seven comments → instances and behaviour

All paths below are under `StarterGui.Shop.Canvas` unless stated. `bindPurchaseHover(button, purchased)`
and `playUISound(name)` are the prototype's own helpers (ShopController ~L1617 and ~L173).

### 4.1 "Hover effekt på Prestige Knappen også"
`FeaturedCanvas.CanvasLeftLimited.BuyButton`. `CanvasLeftLimited` is a **third Featured panel**
(the Prestige Card: `SkinName` "Prestige Card", `AmountLeft` "99 / 100", `Limited`, `ItemPriceText`
"400 BOBUX", a `ViewportFrame.WorldModel.PrestigeCard` model) that the controller **does not
reference anywhere** — which is why it has no hover and no tween. Its `BuyButton` carries the full
purchase-button template, so `bindPurchaseHover` applies as-is. Its `purchased` callback is the
limited-stock flow (§5.3), not a local "owned" flip.

### 4.2 Sounds
Most of this is already in the prototype (`UI_SFX_CONTROLLER_V1` block): `UIHover` on tabs, hunter /
skin / extra cards, buy buttons and chip `+` buttons (rate-limited 45 ms); `UIClick` on card
activate, tab activate, chip `+`, back buttons; `UIDropDown` on a hero click in Hunters / Weapons
(and on the Extras category tiles, and delayed 0.14 s after a tab click for tabs 2–4);
`UIPurchaseSucces` on the mocked purchases. What is missing:

- **`UIPurchaseButtonPrompt` when a Robux purchase starts** — FEATURED bundle buy, HUNTERS
  `BuyButtonRobux`, Prestige Card buy, CurrencyShop BUY. Play it at the moment the prompt is
  requested (client-side `PromptProductPurchase`, or the `FireServer` for the server-prompted
  hunter / limited flows).
- **`UIPurchaseSucces` must move from "button clicked" to "server confirmed"** — `ShopPurchaseSuccessEvent`
  (§5.7). The prototype plays it on click because it has no server.
- `playUISound` must set `sound.SoundGroup = SoundService.SFX` (it does not today) — see §8.
- Purchase-button hover on the redeem button (4.4) and the Prestige button (4.1).

### 4.3 "Tween transition når Prestige Card menuen vises … og når den lukkes ved at gå i en anden tab"
`CanvasLeftLimited` must join the Featured reveal: `openShop()` and `showFeaturedContent()` slide
`CanvasLeft` / `CanvasRight` in from ±0.075 with a fade (`SIDE_TIME` 0.36, Quint Out); give the
Prestige panel the same treatment (slide from -0.075 like the left panel, staggered between the two,
its own `captureFadeTargets` map, and a `prepareClosedState` park position). **Also add the missing
Featured out-transition:** today `showSelector()` / `showWeaponsSelector()` / `showHome()` just set
`featuredCanvas.Visible = false`, so leaving FEATURED snaps. Route FEATURED through
`leaveCurrentShopContent` like the other tabs (fade + slide out ~0.2 s Quad In, then hide) so the
Prestige panel "closes" when another tab is chosen — that is the second half of the comment.

### 4.4 "Wire Codes … hover effekt på redeem knappen, samme skabelon som Bobux items"
`ExtrasCanvas.BackgroundStart.RedeemFrame.CodeRedeemBox` (TextBox, placeholder `ENTER CODE...`),
`BackgroundStart.RedeemButton` (full purchase-button template), `BackgroundStart.Header` ("Join our
Community Server to find the Codes!"). Hover = `bindPurchaseHover` **but it must stay active after a
click** — the helper sets `active = false` on `Activated` because it models a one-shot purchase;
write a `bindActionHover` variant (same visuals, no one-shot) and use it here and for the CurrencyShop
BUY. On activate: trim + uppercase the box text, fire `RedeemCodeRequest` (§5.6), lock the button
until the response or 5 s, `UIClick` on press.

### 4.5 Redeem feedback
`BackgroundStart.AfterRedemption` (TextLabel, authored "THE CODE WAS SUCCESFULLY REDEEMED", green
`0.33,1,0.50`, `TextScaled`, authored `Visible = true` — **author it `Visible = false`**). On
`RedeemCodeResponse {success, message}`:
- success → show it in its authored green with the server `message` (`"Redeemed! +100 Cash"` — it
  already says what was granted), clear the box, play `UIPurchaseSucces`, hide again after ~4 s.
- failure → show the server `message` in **red** (`Color3.fromRGB(255, 92, 92)` from the style guide
  §2.4 semantic set — check the token name there), hide after ~4 s. The server's strings are
  `"That code isn't valid."`, `"That code has expired."`, `"Already redeemed."`, `"Enter a code."`;
  display them as sent — they already distinguish invalid from expired, which is what the comment asks
  for. Do not invent client-side strings.
The label is `TextScaled` in a 0.036-tall slot: a long success message will shrink — verify at the
device matrix (§9) and clamp with `TextWrapped = false` + a `UITextSizeConstraint` if it gets small.

### 4.6 "Den gule cirkel" — sliding title previews
The yellow circle is a markup annotation on the **TITLES category tile**:
`ExtrasCanvas.Extras.2Titles.Canvas.TitlesScroll` (a 1×0.3 Frame at y 0.774, `ClipsDescendants =
false`) containing `TitlesScroll` (TextLabel, authored "LOREM IPSUM LOREM IPSUM", green, `TextScaled`).
Visible in the scratch place's edit screenshot as "M IPSUM LOREM" under TITLES. Behaviour: cycle
through decision 4's titles, each rendered with `TitleRenderer.apply(label, titleId)` (needs an
explicit `TextSize` — it reads `label.TextSize`, so turn `TextScaled` off and size it from the
frame's `AbsoluteSize.Y`, re-run on resize), sliding the outgoing label left and the incoming one in
from the right over ~0.35 s Quint Out, ~2.6 s dwell. Set `ClipsDescendants = true` on the
`TitlesScroll` frame so the slide is masked. Use two labels (clone the authored one once) and swap.
Run the loop only while the Extras home is visible (`extrasStart.Visible`), stop it on tab change
and on shop close. `TitleRenderer` is in `ReplicatedStorage.Modules`; animated presets self-correct
their fade, static ones do not (see memory `project_title_styles`) — apply the style **after** the
label is at its final transparency.

### 4.7 CurrencyShop
See §7.

---

## 5. Backend contracts (measured 2026-08-23 — verify names with `grep_scripts` before wiring)

Every remote below is in `ReplicatedStorage.Events`. **Most are created at runtime by the server
modules** (DataService L933–981, CollectionService L398, LimitedStockService L372–386) and do not
exist in edit mode — `WaitForChild` them; `FindFirstChild` at load returns nil. The authored ones are
`CharacterSelectEvent`, `SkinDataEvent`, `PurchaseSkinEvent`, `EquipSkinEvent`, `LimitedStockEvent`,
`RequestLimitedStockEvent`, `RequestLimitedPurchaseEvent`, and `SettingsEvents.RedeemCodeRequest /
RedeemCodeResponse`.

### 5.1 Hunters (HUNTERS tab, FEATURED left + right panels)
- Roster: `Dust`, `Vesper`, `Bram` free (`StoreConfig.FreeCharacters`), `Fortuna` paid. The card
  list `HuntersCanvas.Hunters.1DustFrame … 4BramFrame` is authored in that order.
- Owned: player attribute `Owns<Hunter>` (`OwnsFortuna`), `GetAttributeChangedSignal`. Free hunters
  are always owned.
- Buy with Cash: `PurchaseHunterEvent:FireServer("Fortuna")` — server charges 4,000
  (`StoreConfig.HunterCashPrices`, reason `hunter_cash`), equips, fires `SkinDataEvent` +
  `ShopPurchaseSuccessEvent`. Failure = `SkinDataEvent` resync only.
- Buy with Robux: client `MarketplaceService:PromptProductPurchase(localPlayer, productId)` with
  decision 5's ids; `ProcessReceipt` grants and fires `ShopPurchaseSuccessEvent(player, "Character",
  nil, productId)`.
- The prototype's `ownHunterOffer()` / `hunterPurchased` local flag and the Fortuna-only gating
  (`currentHunterName == "FORTUNA" and not hunterPurchased` hides the skins list) become
  `OwnsFortuna`-driven. The `3FortunaFrame` status re-labelling to OWNED stays but keys on the
  attribute.

### 5.2 Character skins (HUNTERS detail view)
- Catalog: **no config module** — `HuntersBuyController`'s hardcoded `SKINS[hunter]` (`Name`,
  `TokenPrice`; group-perk skins via `GroupPerkConfig`, battle-pass exclusives via
  `BattlePassConfig.isExclusiveSkin`, bundle exclusives via `StoreConfig.isBundleExclusive`). Lift
  that table into the new controller (or, better, into a `ReplicatedStorage.Config.SkinCatalog`
  ModuleScript — one home, both Collection and Shop read it; **not** on the mirrored-module list).
- Owned + equipped: `SkinDataEvent` push (on join and after every purchase / equip); pull once with
  `RequestSkinData:FireServer()` on load (join-time push can land before the LocalScript connects —
  memory `project_join_state_handshake`).
- Buy: `PurchaseSkinWithTokensEvent:FireServer(hunter, skin)` (Tokens; reason `skin_tokens`) or
  `PurchaseSkinEvent:FireServer(hunter, skin)` (Cash; reason `skin_cash`). Server decides currency
  by which remote; a token-only skin sent to the Cash remote is silently rejected.
- Card `StatusFrame.PurchaseText` + `TokenIcon` / `CashIcon` shows price + currency; `markSkinCardOwned`
  already repaints to OWNED.

### 5.3 Weapon skins (WEAPONS tab) + Prestige Card
- Catalog: `HuntersBuyController.WEAPON_SKINS[hunter]` (index 1 = free default), display tuning in
  `ReplicatedStorage.Config.WeaponDisplayConfig.get(hunter)`. Prices: `TOKEN_WEAPON_SKIN_PRICES` in
  DataService (Frostpiercer 400; Icefang / FrozenHand / FrostbiteGrudgekeeper / BetaRevolver 600).
- Owned + equipped: same `SkinDataEvent`; equipped gun = attribute `EquippedWeaponSkin_<Hunter>`.
- Buy: `PurchaseWeaponSkinWithTokensEvent:FireServer(hunter, skin)` (reason `weapon_skin_tokens`).
- **Prestige Card** (`LimitedStockConfig.Items.PrestigeCard`: Cap 100, Fortuna weapon skin,
  ProductId 3612243340): stock via `LimitedStockEvent` push `{[itemId] = remaining}` (join, every
  change, every 30 s) and `RequestLimitedStockEvent:FireServer()` pull on shop open; `nil` renders
  `--/100`, only a confirmed `0` is SOLD OUT. Buy: `RequestLimitedPurchaseEvent:FireServer("PrestigeCard")`
  — the **server** reserves a unit then prompts; 1 attempt / 5 s. Success arrives as
  `ShopPurchaseSuccessEvent(player, "LimitedItem", nil, productId)` + `SkinDataEvent`. The card's
  `AmountLeft` label ("99 / 100") is `remaining .. " / " .. cap`. It also appears in the WEAPONS →
  Fortuna skin list as a normal owned/unowned card whose buy path is this one, not the token remote.

### 5.4 Titles (EXTRAS → TITLES)
- Catalog: `TitlesConfig.Purchasable()` (16 of 26), `UnlockOf(id)` → `{kind, currency, price,
  hunter}`. Titles are hunter-locked; the card's `CharacterName` ("CharName") is the unlocking
  hunter.
- Owned: `TitleStateEvent {owned}` push + `RequestTitleState:FireServer()` pull. Equipped:
  attributes `EquippedTitle_<Hunter>` (not this payload).
- Buy: `PurchaseTitleEvent:FireServer(titleId)`; server picks Cash or Tokens from the config
  (reasons `title_cash` / `title_tokens`). `CosmeticPurchaseFrame` has `BuyButtonTokens` (hidden)
  and `BuyButtonCash` plus `ItemPriceCashText` with both icons — show the one the config says.
- Render the styled title in the card (`EmoteName` label is the title text slot in the authored
  `1Titles` template — rename it `TitleName` on copy if that is clearer; `TitlesDisplayFrame` is the
  slot for the styled preview) and in `ExtrasSelectedFrame.TitleName` via `TitleRenderer.apply` —
  same TextSize rule as 4.6.

### 5.5 Emotes (EXTRAS → EMOTES)
- Catalog: `EmoteConfig.list()` / `get(id)` (`price` Cash-only, `animationId`, `isDefaultOwned`,
  `isPurchasable`, `unlockTextOf`). 17 entries = 11 purchasable + 5 Bounty Pass + 1 always owned.
- Owned + equipped: `EmoteStateEvent {owned, equipped}` + `RequestEmoteState:FireServer()`.
- Buy: `PurchaseEmoteEvent:FireServer(emoteId)` (reason `emote_cash`).
- Preview: the authored `Emotes.1Skin … 3Skin` cards are templates (each has a `ViewportFrame.
  WorldModel.Rig`); clone one per catalog entry (`numbered()` ordering = `LayoutOrder`), strip the
  rig's `Animate` LocalScript, load the emote clip through `AnimationLoader` and loop it on the rig's
  Animator — the old `EmoteBuyController` did exactly this; its vault `.md` has the pitfalls
  (memory `project_animation_fetch_guard`: a pcall cannot detect a failed fetch). The selected emote
  also plays in `ExtrasSelectedFrame.ViewportFrame`.

### 5.6 Codes
`SettingsEvents.RedeemCodeRequest:FireServer(code)` → `SettingsEvents.RedeemCodeResponse`
`{success: bool, message: string}`. Strings in 4.5. No server change. (`CODES` is mirrored with
Redwater — irrelevant here, do not touch it.)

### 5.7 Success feedback
`ShopPurchaseSuccessEvent` has **two signatures**: no args (DataService / CollectionService paths —
hunter cash, skins, weapon skins, titles, emotes) and `(kind, amount, productId)` (StoreService's
ProcessReceipt — Robux hunter / bundle / limited / currency). Connect once, treat both: play
`UIPurchaseSucces`, run `playFeaturedTokenBurst` only for the bundle (`kind == "Character"` with the
bundle product id, or `"Bundle"`), and otherwise rely on the state pushes (`SkinDataEvent` /
`TitleStateEvent` / `EmoteStateEvent` / `leaderstats`) to repaint — never flip an "owned" flag from
the click. There is **no failure remote**: a purchase that fails resyncs the same state event with
nothing changed, so a buy button must re-enable on the next state push or after a ~5 s timeout.

### 5.8 Currency shop
`StoreConfig.CashProducts` (array of `{ProductId, CashAmount}`: 1k / 2k / 4.5k / 9k / 18k / 40k) and
`StoreConfig.TokenProducts` (`"1Offer" … "6Offer"` → `{ProductId, TokenAmount}`: 250 / 1k / 2k /
3.5k / 6k / 12k). Buy = `MarketplaceService:PromptProductPurchase(localPlayer, offer.ProductId)`;
`ProcessReceipt` credits and fires `ShopPurchaseSuccessEvent(player, "Cash"|"Tokens", amount,
productId)`; the chips repaint from `leaderstats`. Robux prices for display come from
`GetProductInfo` (memoise; it yields).

---

## 6. Navigation integration (how the new ScreenGui gets opened and closed)

`MenuHandlerScript` (`StarterGui.ReworkedMainMenuFolder.MainMenuGui.CanvasBottom`) owns the bottom
nav. Clicking `5TradingPostFrame` → `selectMenuFrame` writes `SelectedMenuFrame` on `MainMenuGui`,
flies the camera, fires `BlackBarMenuCovered("5TradingPostFrame")` at the covered instant, and
**enables the Trading Post ScreenGui**. It disables it again (at the covered instant) when any other
tab is chosen. Therefore:

- Point MenuHandlerScript at `StarterGui.Shop` instead of `ReworkReworkedBuyMenu` (grep it for the
  old name — enable, disable, the `not screenGui.Enabled` guard on `CurrencyVaultRequested`, the
  `VaultOnOpen` / `VaultReturnMenuFrame` attribute writes in `openCurrencyVaultFromMenu`).
- In ShopController replace `openButton.Activated` with `shopGui:GetPropertyChangedSignal("Enabled")`
  → `openShop()` / `closeShop()` (+ `prepareClosedState`). `closeShop` must also tear the currency
  shop down (§7) and stop the title preview loop (4.6). Also close on `MainMenuGui.Enabled → false`
  (teleport overlay) — the old controller did.
- The shop never fires `MenuCameraArrived` / `BlackBarMenuCovered` itself. To send the player to
  another page (currency shop GO BACK, decision 7) fire `MainMenuGui.MenuNavigateRequested` with the
  frame name.
- **Deep links** the old ScreenGui honoured, now to be read off `StarterGui.Shop` — re-point the
  writers: `TradingPostRequestedTab` + `AccessoryModeRequest` (written by the Collection menu's
  `Shop` module on a locked item: `CollectionGuiController/Shop.md`), `VaultOnOpen` + `VaultReturnMenuFrame`
  (MenuHandlerScript). Map old tab names to new indices (`1Featured`→1, hunters→2, skins→3,
  accessories/titles/emotes→4 + the category). All are **cleared on read**.
- `CurrencyHudGui`'s `CurrencyVaultRequested` bindable still fires from the Bounty Pass stack; the
  shop-closed listener in MenuHandlerScript keeps working. Inside the shop the new TopFrame `+`
  buttons call the currency shop directly (decision 2), and CurrencyHudController must not draw its
  Trading Post row while `Shop.Enabled` (listen to that property; it already has a `VaultLayout`
  attribute hook you can model on).
- `DisplayOrder`: old shop was 0 (below `MainMenuGui` 8 — the panel is bounded above the nav bar, so
  it never needed to cover it). Keep 0 for `Shop`. Live `MainMenuGui` is 8 (style guide §7 says 1 —
  the live value is authoritative; fix the guide in passing).

---

## 7. CurrencyShop (comment 7)

Authored tree (scratch place, both `Canvas` children are scale-sized; `IgnoreGuiInset = true`,
`ScreenInsets = DeviceSafeInsets`):

```
CurrencyShop.Canvas
  SideFrame (0.185×0.331 at 0.156, 0.553)        -- left column, the two chips with "+"
    CurrencyCashFrame / CurrencyTokenFrame        -- same chip template as Shop.TopFrame
  BottomFrame (0.25×0.12 at 0.5, 0.722)          -- the offer row
    CurrencyCashFrame (hidden) / CurrencyTokenFrame   -- one row per currency mode
      LowerOffer (-) · CurrencyAmount ("49,339") · IncreaseOffer (+)   -- + icon
```

Behaviour to wire (mirrors the old `BuyCurrencyFrameNew`, survey of TradingPostController §11–12):
- `offerIndex` starts at 1 on every entry and on every currency switch; `+` = `math.min(#offers,
  i+1)`, `-` = `math.max(1, i-1)` — **clamp, no wrap**; old code played a tick sound even when the
  index did not move — play `UIClick` only when it moved, and dim the button at the end (new
  behaviour, small, worth it).
- `CurrencyAmount` shows the **amount granted** for the offer (`CashAmount` / `TokenAmount`, comma
  grouped); a Robux price label must exist somewhere — the authored row has none, so the BUY button
  (decision 6) carries `"<robux> R$"` via `GetProductInfo`, or the amount pill shows both. Ask if
  unsure — this is a visible-layout call.
- Side chips: the player's **balances** (leaderstats), same binding as the TopFrame chips; their `+`
  switches currency mode (Cash ↔ Tokens) with the old "no door replay" rule — swap mode, reset to
  offer 1, re-deal the coin piles if decision 7 keeps them.
- Tween: the "tween effekt lidt ligesom vi allerede har i Bounty" is the old `revealCashVaultPage`
  staggered reveal — chips column first, then the offer row, each a slide+fade (0.22–0.36 Quint Out,
  style guide §6); stepping the offer scale-pops the amount (UIScale, Back Out 0.16) and, if the 3D
  piles stay, re-syncs them. The Shop's `canvas` fades out / the CurrencyShop fades in on entry and
  the reverse on GO BACK.
- Entry points: TopFrame chip `+` (inside the shop), `CurrencyHudGui` `+` on Bounty Pass / Home via
  MenuHandlerScript's `VaultOnOpen` path (§6), Collection deep links if any (grep `VaultOnOpen`).
- Exit: a GO BACK control — **the authored CurrencyShop has none**; clone the new return-button
  template (`HunterSelectedFrame.ReturnToHuntersFrame`) and place it under the side column. Two
  destinations as before: `VaultReturnMenuFrame` set → `MenuNavigateRequested(thatFrame)`; else back
  to the shop tab the player came from.
- `UIPurchaseButtonPrompt` on BUY; `UIPurchaseSucces` on `ShopPurchaseSuccessEvent("Cash"|"Tokens")`.

The cinematic stays (decision 7): reuse the old controller's vault code paths (`openCashVaultPage`,
`syncMoneyStacksToOffer`, `cleanupMoneyStacks`, `resetVaultDoor`, the chrome snapshot/restore) by
**moving** them into a new `ShopVaultController` ModuleScript under `Shop` rather than re-deriving
them — the traps (`MoneySpawnPart` in `PersistentMarkers`, `VaultDoor` Persistent, the
`cashVaultToken` invalidation, the four exit paths) are all in `TradingPostController.md` items
11–12 and 15. The BUY button (decision 6) goes in `BottomFrame` to the right of `IncreaseOffer`, or
below the row if the 0.25-wide frame cannot take a fourth element at 4:3 — measure, don't guess.

---

## 8. Sounds

`playUISound` in the prototype clones from `ReplicatedStorage.SFX.UIButtonClick` into `SoundService`
with **no SoundGroup**. Add `sound.SoundGroup = SoundService:FindFirstChild("SFX")` (style guide §8
idiom) — the templates get the group too (§3.1), but belt-and-braces on the clone is the project
rule. Keep the 45 ms hover rate limit. Do not re-use `ShopMenuSFX.TabsSelect` / `Unhover` — the
friend picked the five new cues deliberately.

---

## 9. Layout, devices, verification order

- `Shop.Canvas` is `1×1` scale with **no aspect constraint**, so every child stretches with the
  window. The friend authored against ~16:9 (edit viewport 1658×678 ≈ 2.45:1 in the screenshots,
  so check what a 16:9 window does first). The old shop solved this with a 16:9
  `UIAspectRatioConstraint` (`FitWithinMaxSize`) on its canvas plus a fit that pins the drawn band
  between the Roblox topbar inset and the nav bar's `0.80` line (`TradingPostController.md` items 9,
  9b — including the touch-only height cap). Expect to need the same: drawn content spans y
  `0.078 .. 0.761` of the canvas (TopFrame top to content bottom); the nav bar's buttons start at
  viewport `0.80`.
- **Run `capture_device_matrix` on the FIRST Bounty draft** (style guide §9), not after wiring. Three
  things to look at: the STORE bar vs the topbar inset, content bottom vs the nav bar on a 2.16:1
  phone, and the 4:3 tablet stretch.
- Touch targets: chip `+` buttons must stay ≥ 44 px (the HUD's Row layout is 39 px and the Stack
  48 px for exactly this reason — `CurrencyHudController.md`).
- Verification is a manual checklist, not MCP playtests (memory `feedback_no_mcp_playtest`): every
  buy path with a DEV profile, both Robux prompts cancelled and completed, a sold-out Prestige Card
  (`LimitedStock_v1` is live data — use `project_live_profile_surgery` discipline), code redeem
  success / invalid / expired / repeated, tab switching mid-animation (the `busy` flags), shop
  open→close→open, `+` from Bounty Pass landing in the currency shop and GO BACK returning there.
- Syntax-check every edited script with `loadstring` before reporting (memory `feedback_verify_code`);
  `set_script_source` needs the whole file (memory `feedback_never_partial_overwrite`).

---

## 10. Retirement, docs, changelog

- `ReworkReworkedBuyMenu`: leave in place, `Enabled = false`, for one release (decision 1). Its five
  vault `.md` files stay until it is deleted; add a one-line "superseded by Shop" note at the top of
  each, no wikilinks.
- New vault files: `LocalBounty/StarterGui/Shop/ShopController.md` (+ any modules you split out —
  the 2000-line prototype is at Luau's top-level-local ceiling risk just like the old one; a
  `Shop/Modules/` folder of ModuleScripts is the sane shape). `Requires:` wikilinks for
  `StoreConfig`, `TitlesConfig`, `EmoteConfig`, `LimitedStockConfig`, `WeaponDisplayConfig`,
  `TitleRenderer`, `AnimationLoader`, `WaitForRequired`; RemoteEvent rows per §5; BindableEvent rows
  for `MenuNavigateRequested`, `BlackBarMenuCovered`, `CurrencyVaultRequested`. Then
  `python update_bounty_graph.py` and grep the graph for `"_src": "shopcontroller"`.
- `UI_STYLE_GUIDE.md`: fix `MainMenuGui` DisplayOrder (1 → 8), add `Shop` / `CurrencyShop` to the
  Bounty registry line, and add the new purchase-button hover recipe (`PurchaseableGradient` ↔
  `UnHoverGradient`, `TopBarFrame` off, `UIShadow` on, text → black) under §5.4 — it is now the
  shop's standard button.
- Changelog: one entry in `changelog/UNRELEASED.md` via `/changelog` — not data-affecting (no Wallet
  reasons, no profile shape change). Rollback = re-point MenuHandlerScript at
  `ReworkReworkedBuyMenu` and disable `Shop`.
- Memories to update after the build: `project_currency_hud` (chips no longer on the Trading Post
  page), `project_menu_tab_gate`, `project_limited_stock` (new card location).

---

## 11. Traps found while surveying (so nobody pays for them twice)

1. **`CanvasLeftLimited` is invisible to the controller.** It is authored `Visible = true`, sits at
   x `0.275`, y `0.380` (left-middle, beside `CanvasLeft`), and nothing hides, shows, fades or moves
   it. In the scratch place it just floats there at load. Wire it before judging the Featured
   layout.
2. **`bindPurchaseHover` is one-shot** (`active = false` after the first `Activated`). Correct for a
   purchase, wrong for redeem / BUY / anything re-pressable. The returned reset function re-arms it.
3. **Ownership is mocked in locals** (`skinOwnership`, `weaponSkinOwnership`, `hunterPurchased`,
   `isOwned`). Every one of them must become state-event-driven, and the "owned" repaint must run
   from the push, not the click (§5.7).
4. **`defaultWeapon()` matches `^default`** — Bram's `Grudgekeeper` breaks it (§3.3).
5. **Runtime-created remotes**: `PurchaseHunterEvent`, `PurchaseSkinWithTokensEvent`,
   `EquipWeaponSkinEvent`, `PurchaseWeaponSkinWithTokensEvent`, `ShopPurchaseSuccessEvent`,
   `RequestSkinData`, and all title / emote remotes do not exist in edit mode. `WaitForChild`.
6. **`PurchaseSkinEvent` vs `PurchaseSkinWithTokensEvent`** are two different remotes with two
   currencies; the vault `.md` calls the authored one by the wrong name.
7. **`ShopPurchaseSuccessEvent` has two signatures** (§5.7).
8. **Hover rate limit** exists for a reason — card ripples fire `MouseEnter` in bursts.
9. **`TitleRenderer.apply` needs a real `TextSize`** — `TextScaled` labels render the style at the
   wrong size (4.6, 5.4).
10. **The scratch place's sounds are ungrouped** (§3.1, §8).
11. **`Shop.Canvas` has no aspect lock** (§9).
12. `StarterGui.Shop.TextButton` is the prototype's toggle — remove it, or the first player to find
    a 200×50 white "Button" at the bottom-left will.

---

## 12. As built — deviations and additions (2026-08-23)

Recorded by the session that executed this spec. Each is a place where the result differs from, or
adds to, the sections above; the sections themselves were left as written.

1. **Module split.** `ShopController` was not kept as one 1973-line script. It is `Shop.ShopController`
   (open/close, tabs, content fit, chips, nav hand-offs, attribute consumption) plus seven
   `Shop.Modules.*` ModuleScripts — `ShopCore` (helpers), `ShopState` (remotes + ownership mirror),
   `ShopFeaturedTab`, `ShopHuntersTab`, `ShopWeaponsTab`, `ShopExtrasTab`, `ShopVaultController` — and
   `ReplicatedStorage.Config.SkinCatalog` (hunter / skin / gun-skin copy + token prices, consolidated
   from the old `HuntersBuyController` tables; Bounty-only, not mirrored). **The tab modules carry the
   `Shop` prefix** because the Collection already owns a `HuntersTab` ModuleScript and the vault graph
   keys nodes on the bare script name — the two merged into one node until the rename.
2. **Layout (§9): `Shop.Canvas.Content`.** Instead of an aspect lock on `Canvas`, a new `Content` Frame
   (AnchorPoint .5,.5) now holds `TopFrame` + the four tab canvases; `Canvas` keeps only the
   full-screen gradient backdrop. `ShopController.updateContentFit` sizes `Content` to
   `h = min(vh, vw / (16/9))`, then shrinks / pins so the STORE bar top (`0.0785·h`) clears
   `GuiService:GetGuiInset().Y` and the draw bottom (`0.761·h`) clears `0.80·vh − 2 px` (the bottom
   nav). Measured: first-draft phone put the bar 30 px under a 58 px topbar; 4:3 wrapped the headline.
3. **Old scripts disabled, not merely hidden (§10).** `ReworkReworkedBuyMenu` stays `Enabled = false`
   for one release, but its four LocalScripts were set `Disabled = true`: left running under a hidden
   GUI they played `UIPurchaseSucces` and the vault coin sprinkle on every `ShopPurchaseSuccessEvent`
   and duplicated the `Request*` pulls.
4. **CurrencyHudController was rewritten, not just gated.** The Row layout, the mirror of the old shop
   canvas and the `VaultLayout` stand-down were removed; it is Bounty-Pass-stack-only and also hides
   while `Shop.Enabled`.
5. **Copy written for the build — owner to eyeball.** Skin-card rarity words (`DEFAULT` / `GROUP PERK` /
   `BOUNTY PASS` / `BUNDLE` / `LIMITED`, then `RARE` / `EPIC` / `LEGENDARY` by token price) and the
   EXTRAS purchase-panel descriptions. Bundle-exclusive skins read `BUNDLE ONLY` (disabled) since
   the BUNDLES tab is inert; the inline error red is `(220,140,140)` (`ShopCore.FEEDBACK_ERR`).
6. **CurrencyShop additions (§7):** `Canvas.BottomFrame.BuyButton` is a clone of the prototype's teal
   `BuyButtonRobux` (position 0.5,1.42 / size 0.5,0.62 under the offer row); `Canvas.SideFrame.ReturnFrame`
   is a GO BACK clone of `ReturnToHuntersFrame` under the chips. Reveal order side → row → BUY.
7. **Emote rig for the Bounty Pass** now comes from `Shop.Templates.EmoteCard` (BattlePassClient), not
   from a built card — the new shop builds its cards at runtime, so there is no authored card to walk.
8. **Deep links (§6):** the Collection's Shop module writes every request attribute
   (`TradingPostRequestedTab`, `AccessoryModeRequest`, `Requested*`) on the `Shop` ScreenGui itself;
   the old tab names are kept and mapped in `ShopController.onEnabled`.
9. **`ReworkedUIPlay`** blocks PLAY on `Shop` and `CurrencyShop` (replacing the old GUI in its list).
10. **Live playtest:** done by the owner 2026-08-23 (three rounds, PC) and confirmed — open/close,
    stand + camera, vault, purchases, deep links, the EXTRAS surfaces (§14). Mobile hitboxes on a
    real phone remain unexercised.

## 13. Playtest round 1 — fixed the same day (2026-08-23)
The owner's first live pass (PC, windowed ~1663×681) raised six items; all are in, verified
statically + by edit-mode harness, and **confirmed live in the owner's later rounds the same day**.
1. **Titles / emotes grids showed 8 cards.** The authored `ScrollingFrame`s are `CanvasSize {0,0},{2,0}`
   with `UIGridLayout` cells `{0.5,0},{0.25,0}` and `AutomaticCanvasSize = None`; CanvasSize scale is
   relative to the frame's **parent** and the cells' scale to the **canvas**, so the canvas held
   4 rows = 8 cards and the rest laid out past the scroll extent. `ShopCore.fitGridCanvas(scroll, n)`
   stretches the canvas to the rows built and keeps the card's pixel size (verified 17 → 4.5×, cell
   px identical). Applied to Titles, Emotes, hunter skins, gun skins.
2. **Stray card top-left on every screen** = the seven `Shop.Templates` Frames (GuiObjects in a Folder
   under the ScreenGui render). Authored `Visible = false`, re-hidden at load, `Core.cloneTemplate`
   un-hides clones.
3. **Extras header 66 px left of its grid.** `Core.tween` keyed by instance only; every panel reveal
   is "slide Position, then fade the same frame's BackgroundTransparency", so the fade cancelled the
   slide and the panel froze at the −0.05/−0.025 start offset (Hunters/Weapons detail + buy panels
   too). Tweens are now keyed per (instance, property set). The six card grids were also narrowed
   `0.38 → 0.3705` to the column width so the grid edges meet the header/panel edges.
4. **Selected skin / gun previewed in the centre** (old HuntersBuyController behaviour) — new
   `Shop.Modules.ShopStandDisplay`: hunter skin / gun on `workspace.FeaturedItems.Stand` (idle, bob,
   drag-to-spin, the old HUNTERS offsets + `WeaponDisplayConfig`), camera `CameraPartHunterCloseup`
   on HUNTERS / WEAPONS and Fortuna + `CameraPartFeaturedCloseup` elsewhere; the lists show the
   equipped hunter / gun. Hooked from `ShopController.applyStandForTab`, `ShopHuntersTab.selectSkinCard`,
   `ShopWeaponsTab.selectWeaponSkinCard`.
5. **Bram's shotgun overflowed its card.** `putWeapon` sized the camera from `GetBoundingBox()`, whose
   size is in the model's own axes (Bram: 0.75 × 0.28 × 3.30 for on-screen 3.30 × 0.75 × 0.28). Now
   world-axis extents, 45 % height budget on cards (the viewport runs behind name / rarity / price
   pill — Fortuna's cards and Dust's revolver were touching the pill) and 77 % on the selected header,
   refit on `AbsoluteSize`.
6. **Vault BUY price off-centre.** The  glyph's fallback font has different advance / bearings in the
   live client than in Studio (digits 28 % wider live), so glyph-in-text can never be centred
   reliably. `Core.attachRobuxPrice` draws `rbxasset://textures/ui/common/robux.png` + an
   `AutomaticSize.X` number in a centred `UIListLayout` row mirroring the label's colour /
   transparency / Visible / UIStroke; `controller.setRobuxPrice` on purchase buttons. Applied to the
   vault BUY, the limited BUY, and the hunter / bundle / limited price labels.

## 14. Playtest round 2 — panel alignment (2026-08-23, later the same day)
7. **Side panels did not meet the top bar's edges.** The four tab canvases are `0.8` of `Content`
   wide while `TopFrame` is `0.8738`, so the bar's edges sit at canvas fractions `−0.0461` / `1.0461`
   and every left panel started 67 px inside the bar, every right panel ended 62 px inside it.
   Authored `Position.X.Scale` only (no code): FEATURED `CanvasLeft` / `CanvasRight` onto the bar
   edges, `CanvasLeftLimited` shifted with the left card to keep its gap; HUNTERS / WEAPONS / EXTRAS
   left-column frames `0.1898 → 0.1391`, right purchase panels `0.8663 → 0.9129`; the root Hunters
   and Weapons grids a further `0.0046` left so the visible card chrome (the `0.95` centred `Canvas`
   child of each cell) meets the bar, not the transparent cell. Skin grids stay on the header's edge
   (their cards inset 2.5 % inside the header's width, like the EXTRAS tiles inside `BackgroundStart`),
   and `ShopHuntersTab` / `ShopWeaponsTab` re-align the skin grid to the selected header's X at load
   anyway. Exact at every resolution because `updateContentFit` only changes `Content`'s height.
   Verified in edit mode: every edge within 0.0 px of the bar on HUNTERS and FEATURED.
8. **EMOTES previews on your own hunter.** Opening the EMOTES category puts the equipped hunter in the
   equipped skin on the lobby stand (`ShopStandDisplay.showHunter`, Dust/Default fallback, same rule
   as the HUNTERS list) under the featured close-up the tab already has — the whole body is visible
   there (edit-mode check: Dust head to boots); the hunter close-up would crop an emote. Selecting an
   emote card plays it on the stand rig as well as in the header viewport: `Stand.playEmote` — a
   looped Action-priority clip over the idle, loaded on its own thread with a token + model check
   (`stopEmote` / `clear` cancel it). The EXTRAS back button restores Fortuna (`showHome` →
   `Stand.showFeatured()` only when the stand reads `"hunter"`); leaving the tab was already
   `ShopController.applyStandForTab`'s job. `ShopExtrasTab` now requires `ShopStandDisplay`.
9. **Title style on the purchase panel heading.** `CosmeticPurchaseFrame.CharacterName` renders the
   selected title through `TitleRenderer.apply` at 0.8 of the slot height, like the selected-item
   heading. That label stays in the panel's fade map (the heading was removed from its map instead),
   so the style is applied only after the fade-in lands: TitleRenderer's static presets size their
   effects from the host's transparency when they (re)fit and do not self-correct while a tween moves
   it; animated presets re-derive every frame. `schedulePurchaseNameStyle` waits out
   `purchaseFadeEndsAt` (0.32 s after `showPurchasePanel`), every pending apply carries a token that
   `clearPurchaseNameStyle` bumps (hide, back, category change, emote selection), and a refresh for
   the same title keeps the effect. Edit-mode harness: DEADEYE (tint, static) and HIGH NOON (fire,
   animated) both render in the slot. Also noted in code: `fitStyledLabel`'s width loop is a no-op on
   the shop's custom FontFace (`GetTextSize` rejects `Enum.Font.Unknown`); the condensed font means
   no catalog title overflows, but a long title would need a `GetTextBoundsAsync` measure.
10. **EXTRAS stand, tile, cards, header (same evening).** (a) The equipped hunter is on the stand from
    the moment EXTRAS opens and for the whole tab: `ExtrasTab.show` places it (`Stand.showHunter`)
    before `showHome`, `ShopController.applyStandForTab` skips tab 4, the back button from EMOTES only
    `Stand.stopEmote()`s, and `openExtraCategory` / `showHome` re-place it if the stand does not read
    `"hunter"` (vault return, `forget`). (b) The EMOTES tile's authored rig cycles random emotes while
    the home is up — `startEmoteTileLoop` / `stopEmoteTileLoop` beside the TITLES tile loop:
    `AnimationLoader.load` per clip (Action, not looped), played once, held for min(length, 6 s),
    the next blended in 0.25 s before the end, never the same emote twice running; the loop checks
    `Core.isOpen` + home visibility each turn and stops on category open / tab leave / shop close.
    (c) The emote cards preview on the equipped hunter: `buildEmoteCards` swaps the template rig for
    `Stand.makePreviewRig(hunter, skin)` at the template rig's pivot and records the pair;
    `ensureEmoteCardsForEquipped` rebuilds on the way into EMOTES when it changed (lazy on purpose:
    the pair arrives with SkinDataEvent, and rebuilding on that push would tear a visible grid down
    mid-ripple). `frameRig` was re-derived: the template rig was small enough to sit under the old
    7-stud minimum distance, a full-size hunter (≈6 studs) filled the card and lost its head under
    the name label — it now fits the head-to-feet span (not the bounding box: an unwelded accessory
    Handle skews it) into the card's clear band at 0.42 of the viewport height, centre at 0.55.
    (d) The EMOTES header's emote preview viewport is removed — authored
    `ExtrasSelectedFrame.ViewportFrame` deleted and `showSelectedEmote` / the selected-track playback
    path with it; the stand is the preview. **Rig note:** the hunter templates under
    `ReplicatedStorage.Characters` carry AnimationConstraints + disabled ragdoll BallSockets and no
    Motor6Ds; an unanchored clone collapses in edit mode (no animation stepping) — harness them
    anchored, and expect them to hold at runtime exactly as the HUNTERS cards do.
