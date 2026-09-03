---
tags: [client, localscript, ui, menu, currency]
path: game.StarterGui.CurrencyHudGui.CurrencyHudController
type: LocalScript
lines: 398
---

# CurrencyHudController

The lobby's Bounty Pass and LOOT-tab cash / token chips — their balances, their `+` buttons and the two layouts: stacked beside the pass panel, a row over the chest purchase panel.

## What it does
1. Owns `CurrencyHudGui` (`DisplayOrder = 5`, `IgnoreGuiInset = true`, `ResetOnSpawn = false`). The chips are authored under `Canvas.TopFrame.CurrencyMenuFrame` and re-parented at runtime into the second ScreenGui `CurrencyHudStackGui.StackHolder`; `Canvas` itself is set `Visible = false` at load and is only their authored home
2. **The chips are the Trading Post's pill, cloned.** Since 2026-08-24 `CurrenyFrame` holds `CurrencyCashFrame` / `CurrencyTokenFrame` — copies of the chips in `Shop.Canvas.Content.TopFrame`, the same template the currency vault's `SideFrame` uses. They replaced the old bare-number chips (`CashFrame` / `TokenFrame`: a coloured `Header` number, a `CurrencyLabel` coin and a small round `BuyCurrencyFrame`), which are in `backups/2026-08-24_pre-passchip-restyle-bounty.rbxm`
3. **Since 2026-08-23 this GUI shows nothing on the Trading Post.** `StarterGui.Shop` draws its own chips in its `TopFrame` and the currency vault (`StarterGui.CurrencyShop`) its own in its `SideFrame`. The old "Row" layout, the mirror of the old shop canvas and the `VaultLayout` stand-down were removed with the old `ReworkReworkedBuyMenu` (rollback = restore this script from `backups/2026-08-23_pre-shop-migration-bounty.rbxm` together with that GUI)
4. **PassStack layout** — Bounty Pass. Cash above tokens at screen x `0.829 .. 0.971`, y `0.206 .. 0.363` on 16:9: right of the pass panel (ends `0.800`), below its close ✕ (ends y `0.160`), above the OPEN PARTY handle (starts y `0.420`). The grid wraps to one chip per row via full-width cells, and cash stays on top by `LayoutOrder`
4b. **LootRow layout** — the LOOT tab (since 2026-09-03: Tokens are spent and Cash / Tokens won there). The same two chips side by side in `CurrencyHudGui.LootHolder` (this GUI — `ChestMenu` is `ScreenInsets.None` too, so no second host is needed), laid out in **pixels** from the live neighbours: each chip 0.485 of `ChestMenu.Canvas.ChestPurchaseFrame`'s width at the pill's 273:75 aspect (clamped between 28 px and the pass chip's 75/1080 of the height), the row right-aligned to the panel in the band between `ReworkedSettingsGui.SettingsButton` and the panel's top. When that band cannot hold the row — a phone: the gear's row ends at y 54, the panel starts at 66 — the pair moves up into the gear's row as a two-high **stack** left of `VersionTagGui.Build`, as tall as the gear plus its margins (28-px chips on a 360-px phone), clear of the XP bar at the top centre that a row there lay across. Re-laid on this GUI's `AbsoluteSize`, and again 50 ms later, because this GUI's size changes before the neighbours it measures have re-laid. The chip-height clamp guards its own bounds: the pass-chip cap drops under the 28-px floor on a phone, and a crossed `math.clamp` throw there meant no chips on any phone until the device matrix caught it. Those are instance reads with fallbacks, not code links
5. **The two hosts exist because of `ScreenInsets`.** A ScreenGui has one inset mode; the stack must match `BattlepassGui`'s `DeviceSafeInsets` while this GUI is `ScreenInsets.None`. Hosting the stack here drifted it relative to the pass panel by the notch width on a phone — **and this is invisible to a clone-based preview harness**, which gives every clone the harness's own inset mode. Verify inset-sensitive geometry by comparing the ScreenGui properties, not by measuring clones
6. **The stack waits for the camera.** It shows only once `MenuCameraArrived` has fired for `4BattlePassFrame`, so it lands together with the pass panel instead of hanging in empty space for the length of the bird-flight — BattlePassClient fades that panel in off the same signal. The latch is cleared the moment `SelectedMenuFrame` moves elsewhere
7. **`StackHolder` is `0.1425 x 0.156750` with a `1.6174` aspect lock**, a uniform 75% of the box the old chips used. The pill fills its whole grid cell where the old chip only used the middle 60% of it, so at the old box the pair outweighed the pass panel it sits beside. At 75% each chip is 273 x 75 px at 1080p — the vault chip's proportions — and its `+` comes out 60 px, 25% larger than the old chip's 48 px
8. **Mobile scaling:** the box is `RelativeXY` with `AspectType = FitWithinMaxSize`, so whichever axis is tighter binds. `RelativeYY` is **wrong** here and was tried first: it collapses the stack to 205 px on a 2400x1080 phone. Portrait is not a case — nothing sets `ScreenOrientation`
9. **Visibility** requires `SelectedMenuFrame` to be `4BattlePassFrame` (Stack) or `2LootFrame` (LootRow), `BountyIntroComplete`, `MainMenuGui.Enabled`, **and `Shop.Enabled == false`** (the shop enables before the menu attribute moves when a `+` opens the vault from the Bounty Pass, and it has its own chips). Home is deliberately excluded — nothing to spend on there; so are Collection and the Trading Post
10. The **party panel hides the stack** (not the LOOT row, which sits above its top edge). Opened, it slides to x `0.824 .. 1.0`, y `0.201 .. 0.675`, straight over it. Detected by watching `PartyFrame.Position`, which covers the tween as well as the endpoints
11. `refresh()` is guarded by a memo of the last applied state — the party tween alone fires it ~20 times on the way open; it listens to `SelectedMenuFrame`, `MenuCameraArrived`, `MainMenuGui.Enabled`, `Shop.Enabled`, `BountyIntroComplete` and `PartyFrame.Position`; the LOOT row alone re-lays on the GUI's `AbsoluteSize`
12. Binds `leaderstats.Cash` / `.Tokens` to the two `CurrencyAmount` labels with comma grouping plus a small scale pop on change. Bound here rather than through `ShopCore.bindLeaderstat` so a balance still draws if the shop GUI is slow to replicate
13. **The pill `+` is bound by `ShopCore.bindCurrencyPurchaseHover`**, resolved in a spawned thread so only the `+` waits on `StarterGui.Shop`. That helper owns the rest/hover swap (stroke and gradient pair on the button, gradient and shadow on the symbol), the overlaid hitbox and the `UIHover` / `UIClick` cues, and it normalises a chip authored with two gradients enabled
14. **The `+` buttons fire `CurrencyVaultRequested`.** ShopController answers when the shop is already open; MenuHandlerScript answers when it is not, opening the shop straight into the vault. Their guards are mutually exclusive, so exactly one side responds. **MenuHandlerScript must resolve this GUI with an unbounded `WaitForChild` in a spawned thread** — it lives in StarterGui itself and routinely runs before `CurrencyHudGui` is copied into PlayerGui

## Dependencies
- **Requires:** [[ShopCore]]
- **Required by:** Nobody (top-level LocalScript)

## Connections
### RemoteEvents
None

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `CurrencyVaultRequested` | → | [[ShopController]] opens the vault when the shop is already up |
| `CurrencyVaultRequested` | → | [[MenuHandlerScript]] opens the shop straight into the vault when it is not |
| `MenuCameraArrived` | ← | [[MenuHandlerScript]] gates the Bounty Pass stack and the LOOT row until the camera lands |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ShopCore]] | `Core.bindCurrencyPurchaseHover()` | Rest/hover state, hitbox and sound cues for the cloned pill's `+` |
