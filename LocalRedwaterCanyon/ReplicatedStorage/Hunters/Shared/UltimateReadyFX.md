---
tags: [shared, modulescript, client, ui, ultimate]
path: game.ReplicatedStorage.Hunters.Shared.UltimateReadyFX
type: ModuleScript
lines: 524
---

# UltimateReadyFX

Shared OOP class that lights the "charged" state on a hunter's ultimate icon: at full charge a soft gold light breathes out from behind the whole ult tile, and the `ModernReadyAccent` underline shows. The look is selected by a named preset.

**Status: VERIFIED by the owner in a live playtest, 2026-08-06; the mobile mask verified the same way 2026-08-07.** The look is signed off. Two things those playtests do *not* cover are called out where they belong below — the stuck-glow defect (root cause still unknown) and phone performance of the 24-layer stack (never measured on a handset).

## What it does
1. `.new(ultimateMainFrame)` — reads the active preset, then resolves `Background.UIStroke` (and `InnerStroke` only if the preset asks for it) plus every `UIShadow` under `ReadyGlow`, capturing each one's authored values. Also resolves the `ModernReadyAccent` underline (nil-tolerant, added by the NEWGUI port D2, 2026-09-13). Returns `nil` (with a warn) if the `Background` is missing, the preset name is unknown, or there is nothing to light — so every call site can guard with a plain `if fx then`
2. Also captures `ReadyGlow` itself as the **glow mask**, along with the colour of `CooldownBar` to tint it with. Only when there are layers to mask
3. `:SetReady(isReady)` — idempotent, and deliberately so: callers drive it from their charge handler, which fires several times a second while the bar fills
4. `_ignite` — shows the `ModernReadyAccent` underline, solves the per-layer falloff, sets the rest keyframe, then plays a `RepeatCount = -1, Reverses = true` Sine tween to the peak. Costs no per-frame Lua, which matters far more on phones than the extra tween objects do. Then makes the mask opaque, which clips the glow to a rim
5. `_extinguish` — hides the `ModernReadyAccent`, cancels the tweens and writes every captured authored value back, mask included. Restoring from the capture rather than from hardcoded values is load-bearing: the mobile HUD authors its strokes at transparency 0.25 / 0.40 where the desktop one authors 0
6. `:Destroy()` — extinguishes and drops the captured references

## The glow is a stack of UIShadows, and that is not incidental
**A single `UIShadow` cannot glow.** Its `Spread` dilates a hard silhouette with essentially no falloff, so behind the tile it renders as a solid gold band hugging the edge — rejected twice as "a fat line", at spread 0.22 and again at 0.16. Changing the spread only changes the band's width.

**Stacking many shadows at graded spread and alpha rebuilds the falloff the primitive lacks.** Each layer is a *filled* dilation, so overlapping them accumulates into a smooth gradient. This is the opposite of `UIStroke`, which is an *outline* — stacking those gives concentric rings, and conflating the two is why stacking was wrongly written off here early on. (The TitleStyles `bloom.layers` trick works on glyphs for the same filled-vs-outline reason.)

24 layers are authored as `ReadyGlow.Layer01` … `Layer24`, innermost first, zero-padded so a plain name sort is also the render order.

### Layers composite, they do not add
Stacked transparencies **multiply**, so what you see at the tile edge is the *product* of every layer's transparency. The obvious way to stop "more layers" meaning "brighter" — dividing each layer's alpha by the layer count — caps achievable opacity at roughly `1/count` and makes the glow impossible to brighten. That bug shipped once and made the effect untunable.

Each layer is instead given `total ^ share`, where the shares sum to 1. The product telescopes back to exactly `total`, so:

- `GlowTransparency` means **accumulated transparency at the tile edge** — a true brightness knob
- the authored layer count changes **smoothness only**, with no re-tuning

Verified numerically: 24 layers composite to 0.1000 against a 0.10 target, and 0.0101 against 0.01.

## Presets
`ACTIVE_PRESET` at the top of the module selects one of five; nothing else needs touching, and every hunter picks it up because there is one module and one HUD shape.

| Preset | Stroke (× authored) | Glow radius | Glow transparency (accumulated) | Half-period |
|---|---|---|---|---|
| `Hairline` | 1.0 → 1.3 | — | — | 1.1s |
| `HairlineSoft` | 1.0 → 1.15 | 0.16 → 0.22 | 0.55 → 0.40 | 1.1s |
| `HairlineMedium` | 1.2 → 1.4 | 0.20 → 0.26 | 0.40 → 0.26 | 1.1s |
| `GlowOnly` **(active)** | untouched | 0.32 → 0.40 | 0.10 → 0.01 | 1.35s |
| `Heavy` | 2.4 → 3.4 (+`InnerStroke`) | — | — | 1.1s |

`GlowOnly` leaves the border authored and does everything with light. The spread swing is small and the transparency swing large, on purpose: spread moves the outer edge, and a soft edge sweeping in and out drags the eye to the far radius, whereas transparency breathes brightness in place. The layers also run hotter toward the crest (`EMBER` → `EMBER_HOT`) — once transparency is near its ceiling, colour is the only brightness left, and a whiter gold separates from Redwater's orange rock where more of the *same* gold just matches the background.

`Heavy` is the original shipped look, retained only so the change is one word to reverse — it reads as a fat gold slab.

## Where it sits — an explicit design decision, not an accident
The glow is hosted on `MainFrame.ReadyGlow`, an authored transparent Frame at **`ZIndex 0`**, present in both `ReworkedHunterGui.ScreenGui` and `HunterGuiMobile`. Since the NEWGUI port (2026-09-13, D3) `MainFrame` orders its children `ReadyGlow 0 → Background 5 → CooldownBar 6 → ModernReadyAccent 7 → Ability 8 → Cooldown 9 → CooldownFrame 10` (before the port the order was `ReadyGlow 0 → CooldownBar 1 → Background 2 → Ability 3`), and the ScreenGui is `ZIndexBehavior = Sibling`, which orders whole **subtrees** by their root's ZIndex. At 0 the glow sits beneath the card and the charge fill, so it renders behind the **entire** tile: the interior keeps its authored dark, the ability glyph is untouched, and light escapes only around the outside. The card has no strokes since that port (D4), so the stroke half of every preset finds nothing and only the layers light. On mobile that last part needs a mask to be true — see "Behind the tile only works if the tile is opaque" below.

The alternative — hosting it inside `Background` (ZIndex 2), above the fill and below the glyph, so the tile *face* lights amber — is **measurably more visible** on Redwater's terrain and was still rejected: the brief is that the light must sit behind the ability icon, not tint the tile. Both were rendered over the live map and compared before the call was made. The consequence to respect is that this layer has less area to work with and is therefore an inherently quieter effect.

Nothing in the chain (`MainFrame` → `UltimateFrame` → `Canvas` → ScreenGui) sets `ClipsDescendants`, which is what lets the glow reach past the tile at all.

## Behind the tile only works if the tile is opaque — on mobile it is not
**Fixed 2026-08-07.** On phones the glow appeared to sit *in front of* the ability glyph. The layering was never wrong: the two trees are byte-identical on ZIndex, and the glow was behind everything the whole time. What differs is the surface in front of it.

`HunterGuiMobile` authors **every** tile fill at `CooldownBar.BackgroundTransparency = 0.45` so the map reads through the HUD; `ScreenGui` authors the same fills at `0`. A `UIShadow` is a *filled* dilation, so the stack covers the tile's own footprint as well as the halo around it. Desktop's opaque fill swallows that interior; mobile's let 55% of the glow through. The tile face lit gold, the gold pooled in the glyph's negative space, and the light read as being on top of the icon.

The fix is a **mask**: the layers render behind their own parent (their `UIShadow.ZIndex` is `-1`), so `_ignite` gives `ReadyGlow` an opaque body while lit and `_extinguish` restores the authored `BackgroundTransparency = 1`. The lit colour is read from `CooldownBar` so the masked interior is the tile's own dark rather than a second grey introduced by the module.

Two reasons the mask lives on `ReadyGlow` and not on the charge bar:
- **HunterHudCooldown owns that bar's properties.** Writing to it from here would be two modules driving one instance.
- **The bar is only full-height at full charge.** Masking on `ReadyGlow` is correct no matter what the fill is doing.

It applies on every device — on desktop the opaque fill already hides it, so it is a provable no-op there. Consequence to accept: the mobile ready tile goes solid dark while its translucent ability neighbours do not. That is exactly the desktop look, and it is the *charged* tile.

## Tune it against the map, never against a dark card
Redwater's `Ambient` is `(0.60, 0.43, 0.23)` over sand at `(202, 113, 58)` at `Brightness 3.5`. A warm translucent glow on warm bright rock has very little contrast, so anything tuned on a dark preview background will be far dimmer in a match than it looked. An earlier trough of `0.72` was invisible in play and read as "the glow did not load" — the effect was working and simply could not be seen. Preview harnesses for this should use a **transparent** ScreenGui over the live viewport.

## What else was tried, so it is not retried
- **`UIStroke` widened to 3.4× authored thickness** — a hard-edged line only gets thicker, never softer. Rejected as a fat gold slab.
- **A radial glow image behind the tile** (`rbxassetid://75202463`) — structurally wrong here: the texture's bright centre is occluded by the tile itself, so only its dim outer tail is ever visible. Sized to stay contained it showed nothing; sized to show, it reached far across the screen. Could be contained or visible, never both.
- **Lighting the border**, and **darkening `ShadowStroke` into a dark rim** — both read as restyling the button rather than lighting it.

**Thickness is an authored fraction, not a pixel count** (0.03 and 0.015 on these strokes). Stroke multipliers scale whatever was authored; an absolute number would render identically at every viewport size and blow the border out on a phone. The hunter cards in HunterSwitchClient follow the same rule. `GlowSpread` is likewise a fraction of the icon's own side, so the glow scales with the tile on every device.

## `SetReady(false)` does not fully trust its early return
The idempotent guard has one exception: if the FX believes it is already extinguished but `_tweens` is non-empty, it re-runs `_extinguish` instead of returning. `_extinguish` clears that list, so a live tween in the "dark" state is always a bug state.

This is not hypothetical. A live client was observed lit at full breathe while the ultimate label read 88% — `SetReady(false)` running every tick and doing nothing. The root cause was never reproduced (the playtest ended first), so the invariant is enforced rather than the cause fixed. Tracked in `changelog/OPEN-ITEMS.md`.

**One shape, not two.** Every hunter's HUD is a clone of `StarterGui.ReworkedHunterGui` (`ScreenGui` on desktop, `HunterGuiMobile` on touch), so `UltimateFrame > MainFrame > {Background, ReadyGlow}` resolves the same regardless of hunter. The `StarterGui.HunterGui.*` trees still carry an older `Ultimate > FrameBorder` shape, but nothing clones them any more.

## Performance note
24 shadow layers is 24 draws and 24 tweens per lit HUD. Only one HUD is on screen at a time and the tweens run engine-side, but this has **not** been measured on a phone. If it ever needs to come down, the layer count is a pure smoothness dial — dropping to 12 costs gradient quality and nothing else, because brightness is solved against the count.

## Dependencies
- **Requires:** Nothing
- **Required by:** VesperHunterGuiClient, BramHunterGuiClient, CardsHunterGuiClient, HighNoonChargeUI (Dust's charge meter) — plain text on purpose: each caller declares its own `require()`, and repeating them as wikilinks here would race those edges into the wrong direction

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
