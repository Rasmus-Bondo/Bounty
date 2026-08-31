---
tags: [shared, modulescript, client, ui, ability]
path: game.ReplicatedStorage.Hunters.Shared.HunterHudCooldown
type: ModuleScript
lines: 276
---

# HunterHudCooldown

Shared OOP controller for a hunter HUD's two **skill** cooldown tiles: the draining bar, the tenths countdown label, the countdown thread and the readiness pop. One instance per HUD, created once. Extracted from the four HUD clients on 2026-08-06 per `HUNTER_HUD_COOLDOWN_REFACTOR.md`, which is now closed.

## What it does
1. `.new(canvas, names)` — resolves both tiles off the canvas (`AbilityFrame → 1Ability/2Ability → MainFrame → {CooldownBar, Cooldown}`) and builds a [[HunterHudBump]] per tile. `names` is in **HUD order**, so `names[1]` is the Q slot and `names[2]` the E slot. Returns `nil` (with a warn naming the missing slot) if the authored shape is not there, so every call site guards with a plain `if cooldowns then`
2. `:Start(name, seconds)` — retires whatever was running for that name, snaps the bar to empty, then Linear-tweens it to full over `seconds` while a `task.wait(0.05)` loop writes `%.1f` into the label. Pops the tile at natural expiry
3. `:SetReady(name)` — retires the countdown and forces the resting state (bar full, label blank). **Does not pop**
4. `:Destroy()` — retires every countdown and calls `Destroy` on each tile's bump, which writes the authored `BumpScale` value back. Idempotent, and `Start` / `SetReady` no-op afterwards

## Destroy isolates the two slots on purpose
The tile loop takes **one `pcall` per tile**, and `self._tiles` is dropped *before* it runs rather than after. Both matter because `Destroy` is called from inside each HUD client's own `pcall` during a live hunter swap: a throw on slot 1 would otherwise abandon slot 2 — leaving its countdown thread running and its `BumpScale` off its authored value — with the error swallowed upstream and nothing on screen to show for it. Clearing `_tiles` first means a partial teardown still leaves the controller reading as dead instead of answering calls.

Verified by fault injection: with **both** tiles' bumps throwing on `Destroy`, both countdowns still retire and `_tiles` is still cleared. Under a single shared `pcall` whichever slot came second in `pairs()` kept counting. The three HUD clients that own an ultimate bump were split the same way for the same reason (`CardsHunterGuiClient:563`, and its twins in Vesper and Bram); Dust's was already a standalone `pcall`.

## Why it exists
The four hunters already shared the *authored* HUD — all of them clone one `StarterGui.ReworkedHunterGui` and rename the clone. What they did not share was the code driving it. Measured on 2026-08-06, Fortuna's and Vesper's `setSkillReady` + `startSkillCooldown` blocks were **character-identical** once the skill names were normalised away, Bram's was the same plus one branch, and Dust's was an older variant with an explicit-args signature.

Two costs landed on the same day. Wiring the [[HunterHudBump]] pop meant threading a trigger point through four scripts by hand even though the animation itself was already one module. And a real bug — a countdown **thread** that outlived the bar tween cancelled alongside it — had to be fixed four times with four identical edits.

## The token bug is now structurally unreachable
`SetReady` and `Start` both retire the previous countdown through the same private `retire`, which bumps a per-tile token *and* cancels the tween. Cancelling the tween alone never stopped the spawned loop: it kept overwriting the restored blank label with a phantom remaining time, then called back at expiry and popped a tile that was never on cooldown. Reachable by respawning mid-cooldown, and latent for as long as the code existed because on its own it was only a label flicker.

The fix used to live in four places and depend on nobody forgetting it. There is now one code path into a countdown's retirement and no caller can skip it.

## The pop is internal, and that is the point
`HunterHudBump` fires from exactly one place in this module: the natural expiry of a countdown. It is deliberately **not** a parameter. Every other path — initial wiring, respawn, and a cooldown cleared to zero — restores a *resting* tile, and popping there fires on every spawn. The old per-hunter `bump` argument existed only to suppress that, so deleting the argument deletes the standing chance of a caller passing it from a restore path.

## Zero-length cooldowns rest immediately, and pop if something was cooling
`seconds <= 0` goes straight to the resting state with no tween — a zero-duration tween would otherwise only flip on the next 0.05s tick. This branch existed in Bram alone before the extraction; adopting it for all four is one of the two intentional behaviour changes of the refactor, and it is unreachable for the other three (only `GrudgekeeperClient` ever fires a zero).

**It pops, but only if the tile was actually mid-cooldown.** An ability going from cooling to usable is exactly what the pop advertises, and Last Call refreshing both charges is the moment Bram most needs to see it. The guard is not optional, because Bram fires zeros down **two** paths:

- `GrudgekeeperClient:1250-1251` — Last Call activation, one `Fire(0)` into each slot. The refresh. Pops.
- `GrudgekeeperClient:1265-1273` — `AbilityCooldownsReduced`, fired on **every landed blast** during the window, with both remaining times clamped by `math.max(..., 0)`. Once an ability is fully shaved it re-fires `0` on every subsequent hit.

A blanket pop on zero would therefore strobe both tiles on every blast for the rest of the ultimate. `wasCooling` is captured before `retire` clears the tween, so the second path fires exactly one pop — at the blast that actually finishes the cooldown — and nothing after. Same rule as the natural-expiry pop: fire on the transition, never on the resting state.

Ulting with an ability already off cooldown correctly does **not** pop it; nothing was refreshed.

## Scope: skills only, never the ultimate
`UltimateFrame` is deliberately absent from the slot table. The ultimate's charge display is genuinely different per hunter — three different early-return guards across Fortuna, Vesper and Bram, and Dust has no such function at all because its ultimate lives in `HighNoonChargeUI`. The ultimate's readiness edge, its ember-halo clears and its own bump stay hero-owned alongside those guards. Widening this module to cover the ult tile turns a refactor into a gameplay change.

The `getChargeSize` / `setFrameSize` helpers stayed behind in Fortuna, Vesper and Bram for the same reason: only the *skill* half of their call sites moved here.

## What the call sites look like
Each HUD client keeps its own event wiring — the cooldown bindables are manifest-declared under per-hunter names (`BreachChargeCooldownStarted`, `GrappleCooldownStarted`, `RecallCooldownStarted`, `DashCooldownStarted`) and this module never subscribes to anything. It receives seconds.

| Hunter | Slot 1 (Q) | Slot 2 (E) |
|---|---|---|
| Dust | `Skill1` | `Skill2` |
| Fortuna | `Recall` | `Ability1` |
| Vesper | `Grapple` | `Pinning` |
| Bram | `Breach` | `Shrapnel` |

The names are opaque keys. The module never knows that slot 1 is a dash for Dust and a grapple for Vesper.

## Verified 2026-08-06 (edit-mode harness, no playtest)
Against a clone of the authored `ReworkedHunterGui`: respawn mid-cooldown leaves the label blank with zero pops; a normal completion pops exactly once; a retrigger mid-cooldown pops exactly once; `Destroy` mid-cooldown stops the label and leaves `BumpScale.Scale` at its authored 1. Zero-length: a refresh while cooling pops once, a refresh on an already-ready tile does not pop, and six consecutive zeros after one cooling tile produce exactly one pop (the strobe case). Sampled side by side against the pre-refactor implementation over a 3s cooldown, the bar `Size` and label `Text` matched exactly — max delta 0.00000 across 21 samples.

**Harness gotcha:** `require()` in `execute_luau` returns the plugin's **cached pre-edit** copy, which silently reported the zero-length pop as absent. Compile the live source instead — `loadstring(src.Source:gsub("script%.Parent", "<absolute path>"))`, since `script` does not exist in a `loadstring` chunk.

**Status: DONE and VERIFIED by the owner in a live playtest, 2026-08-06 — desktop and mobile.** All six checklist items pass: natural expiry, respawn mid-cooldown, instant retrigger, hunter switch mid-cooldown, Bram's Last Call refresh, and the mobile ability buttons.

One nuance: the Last Call **pop** was added after the desktop pass (owner request), so on desktop that item is harness-verified rather than eyes-verified. Covered by the mobile pass.

## Dependencies
- **Requires:** [[HunterHudBump]]
- **Required by:** HunterGuiClient, CardsHunterGuiClient, VesperHunterGuiClient, BramHunterGuiClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterHudBump]] | `.new()`, `:Play()`, `:Destroy()` | The readiness pop, fired only at a countdown's natural expiry |
