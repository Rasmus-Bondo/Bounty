---
tags: [shared, modulescript, client, ui, ability, ultimate]
path: game.ReplicatedStorage.Hunters.Shared.HunterHudBump
type: ModuleScript
lines: 126
---

# HunterHudBump

Shared OOP class that pops an ability tile when it becomes usable: the whole tile scales up and settles back. Driven on cooldown expiry for the two ability slots and on the rising edge to full charge for the ultimate.

**Status: VERIFIED by the owner in a live playtest, 2026-08-06.**

## What it does
1. `.new(mainFrame)` — resolves the authored `BumpScale` UIScale under the tile's `MainFrame` and captures its resting scale. Returns `nil` (with a warn) if that child is missing or is not a UIScale, so every call site can guard with a plain `if bump then`
2. `:Play()` — cancels anything in flight, resets to the captured rest scale, then plays a fast rise followed by a settle
3. `:Destroy()` — cancels and writes the captured rest scale back

## Why it exists
Neither pre-existing readiness cue **moves**. The cooldown bar stops draining and the ready glow fades in behind the tile; both are easy to miss in peripheral vision at the moment readiness matters. Motion is the only cue that reads without being looked at directly.

## The motion
- **Rise** 0.09s `Quad`/`Out` to `rest × 1.18`
- **Settle** 0.24s `Back`/`Out` back to rest

`Back`/`Out` overshoots its target, so on the way *down* it dips slightly **under** rest before landing. That undershoot is what makes the motion read as a bump rather than a zoom, and it is the reason the settle is not a plain ease.

`PEAK_SCALE` is a **multiplier on the captured rest value**, never an absolute. A tile whose `BumpScale` is ever authored off 1 still returns to where it was authored.

A retrigger mid-bump restarts from rest rather than stacking. Two abilities can come up on the same frame, and a half-finished settle left running would fight the new rise and land the tile off its baseline.

## It scales the tile, not the glyph
`BumpScale` sits on `MainFrame`, not on the `Ability` ImageLabel, so the background, strokes, cooldown bar, keybind badge and the ready glow all travel with the artwork. Scaling only the glyph was the considered alternative and was rejected as too quiet to read mid-fight.

**Nothing reflows.** The `UIGridLayout` in `AbilityFrame` lays out the `1Ability` / `2Ability` **holders**; `MainFrame` is a child of a holder and is only 0.64–0.78 of it, so a scaled tile cannot move its neighbour. Measured at the shipped peak on desktop: 86px → 101px inside a 122px holder cell, leaving 28px of clearance. **Raising `PEAK_SCALE` past roughly 1.28 is where that stops being true.**

## The UIScale is authored, not created here
Six `BumpScale` instances exist in the data model — under `1Ability`, `2Ability` and `UltimateFrame`'s `MainFrame`, in **both** `ReworkedHunterGui.ScreenGui` and `HunterGuiMobile`. Per the project's UI rule, a code-built instance cannot be screenshot-verified in an edit-only session; this module drives structure that already exists rather than constructing it. The same reasoning put `ReadyGlow`'s layers in the data model.

**One shape, not two.** Every hunter's HUD is a clone of `StarterGui.ReworkedHunterGui`, so the tile path resolves identically regardless of hunter. The `StarterGui.HunterGui.*` trees carry an older shape and have no `BumpScale`, but nothing clones them any more.

## Triggering is the caller's job, and it is easy to get wrong
The module has no idea what "ready" means; it only plays. Two rules live at the call sites, and since 2026-08-06 only one of them is still the HUD clients' problem:

- **Cooldowns fire only on natural expiry.** This is now owned by HunterHudCooldown, which requires this module and plays it from exactly one place. The `bump` argument the four HUD clients used to thread around is gone; a restore path can no longer pass it by mistake.
- **The ultimate is rising-edge only, and stays hero-side.** `setUltimateCharge` runs on every charge tick, so a level-triggered call would restart the tween continuously for as long as the ultimate sat charged. Each client tracks a `ultimateWasReady` flag and re-arms it everywhere the ready glow is cleared — Bram's `isLastCallActive` early return and `startLastCallCountdown`, Vesper's `ultimateActive` early return and activation handler — so a recharge after the window still pops.

Dust is wired through `HighNoonChargeUI` rather than its HUD client, because that is where its charge state lives; the edge is captured there before `IsReady` is overwritten, and the instance survives HUD rebuilds so a respawn with a charged High Noon does not re-pop. Dust's HUD client no longer touches this module at all — its skill pops go through HunterHudCooldown and its ultimate pop is `HighNoonChargeUI`'s.

## The skill trigger point used to be duplicated four times
Fortuna's and Vesper's cooldown blocks were character-identical, Bram's was the same plus one branch, and Dust's was an older variant with a different signature. Wiring this module surfaced a latent bug in all four at once — a countdown thread that survived `setSkillReady` — and fixing it took four identical edits. HunterHudCooldown retired that duplication; the defect is now structurally unreachable rather than fixed per copy.

## Dependencies
- **Requires:** Nothing
- **Required by:** HunterHudCooldown (the skill pop), CardsHunterGuiClient, VesperHunterGuiClient, BramHunterGuiClient (each for the **ultimate** pop only), HighNoonChargeUI (Dust's charge meter)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
