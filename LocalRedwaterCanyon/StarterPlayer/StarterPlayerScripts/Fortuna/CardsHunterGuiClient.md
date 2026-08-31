---
tags:
  - client
  - localscript
  - ui
  - fortuna
  - cards
path: game.StarterPlayer.StarterPlayerScripts.Fortuna.CardsHunterGuiClient
type: LocalScript
lines: 599
---

# CardsHunterGuiClient

Fortuna's HUD: ammo pips, Recall/Ability1 cooldown fills, and ultimate charge display. Input/combat logic lives separately in [[CardsClient]]; this script is GUI-only. Phase 3 ported to consume [[HunterClientRuntime]] driven by the [[Manifest|Fortuna Manifest]].

## What it does
1. Requires [[HunterClientRuntime]] + the [[Manifest|Fortuna Manifest]] and calls `HunterClientRuntime.Start(fortunaManifest)`; if not on Fortuna, the runtime returns nil and the script silently exits. The local `events` variable now aliases `runtime.ClientEvents` so the 10+ `events.Foo:Fire()` / `events.Foo.Event:Connect(...)` call sites further down resolve to the same instances the runtime ensured
2. Clones `StarterGui.ReworkedHunterGui` into the player's GUI *named* `FortunaGameGui` — `HunterGuiMobile` on touch, `ScreenGui` otherwise — destroying any other hero's GUI clone (Template/Bram/Iris) first, then overwrites the ability icons with Fortuna's art. The name is the only thing left of the old per-hunter art: `StarterGui.HunterGui.Fortuna.FortunaGameGui` still exists with the pre-rework `Ultimate > FrameBorder` shape but is no longer cloned. The runtime shape is `UltimateFrame > MainFrame > {Background, CooldownBar, Ability, Cooldown, CooldownFrame}`
3. Listens to `AmmoChanged`/`Reloaded` BindableEvents to animate the 3 bullet-pip icons (hide/show with a back-ease scale tween) and pulse the ammo count text
4. Listens to `RecallCooldownStarted`/`Ability1CooldownStarted` and forwards the seconds into [[HunterHudCooldown]], which owns the cooldown-fill tween, the countdown label, the countdown thread and the expiry pop for both skill tiles; intentionally ignores `UltimateCooldownStarted` since the ultimate UI only shows charge percent, not a cooldown timer
5. Listens to `UltimateChargeChanged` to fill the ultimate frame, show "READY" at 100%, light the [[UltimateReadyFX]] ember halo, and pop the tile via [[HunterHudBump]] on the rising edge to full charge. Unlike Vesper and Bram this is the *only* place the halo is driven — Fortuna's HUD has no ult-active guard, so spending the ultimate clears it via the charge reset the server pushes rather than through an explicit handler. That single drive point is the one under suspicion for the stuck-halo issue in `changelog/OPEN-ITEMS.md`: a live Fortuna client was seen with the halo lit while this handler was writing an 88% label, i.e. calling `SetReady(false)` every tick
6. Creates three [[HunterMobileAbilityButton]] instances (one per skill frame, mirroring the `FrameBorder`/`FrameBorderCooldown` child) that fire the corresponding `*Requested` BindableEvent (consumed by [[CardsClient]]); replaces former inline `createMobileButton` helper
7. Creates the visible mobile FIRE button via [[HunterMobileFireButton]] in **hold** style — press fires `FireRequested:Fire(true)`, release fires `FireRequested:Fire(false)` — so mobile mirrors Fortuna's PC click-and-hold auto-repeat throw. [[CardsClient]] consumes it (replacing the old delayed `UserInputService.TouchTap` mobile shoot path)

## CharacterAdded re-renders the cached ultimate charge, it does not zero it
`resetUltimateChargeDisplay` is called at initial wiring **only**. The respawn path re-renders `currentUltimateCharge`, matching Vesper and Bram.

Zeroing there was wrong: `UltimateChargeService` resets on `RoundActive` and never on death, so a Fortuna who died holding a charged ultimate still had it, and the HUD misreported `0.0%` until the next `UltimateChargeChanged` push corrected it. Once the tile could pop, that false `0% → READY` jump also fired a phantom bump. Dust never had the defect — `HighNoonChargeUI` feeds its cached charge back through `Update`.

## The skill cooldown machinery moved out on 2026-08-06
`setSkillReady`, `startSkillCooldown`, `cooldownVisuals`, `activeSkillTweens`, `skillCooldownTokens` and the two skill-tile `HunterHudBump.new` calls are gone; this script now holds a single `cooldowns` controller and calls `:Start` / `:SetReady` / `:Destroy` on it. The removed block was **character-identical** to Vesper's, and the phantom-countdown bug they both carried (a countdown thread that survived a cancelled tween and popped a tile that was never on cooldown) is now structurally unreachable rather than fixed in four places. See [[HunterHudCooldown]].

`getChargeSize` and `setFrameSize` stayed — the **ultimate** still uses them, and only the skill half of their call sites went away. The `HunterHudBump` require stayed for the same reason: the ult tile's rising-edge pop is still driven here.

## Dependencies
- **Requires:** [[HunterClientRuntime]], [[HunterMobileAbilityButton]], [[HunterMobileFireButton]], [[UltimateReadyFX]], [[HunterHudCooldown]], and [[HunterHudBump]] (from `ReplicatedStorage.Hunters.Shared`); [[Manifest|Fortuna Manifest]] (from `ReplicatedStorage.Hunters.Fortuna.Config`). [[HunterClientState]]. No longer requires [[HunterRemoteSetup]] directly — runtime owns bindable ensuring.
- **Required by:** Nobody

## Connections
### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `AmmoChanged` | ← | Fired by [[CardsClient]] |
| `Reloaded` | ← | Fired by [[CardsClient]] |
| `RecallCooldownStarted` | ← | Fired by [[CardsClient]] |
| `Ability1CooldownStarted` | ← | Fired by [[CardsClient]] |
| `UltimateCooldownStarted` | ← | Fired by [[CardsClient]] (ignored) |
| `UltimateChargeChanged` | ← | Fired by [[CardsClient]] |
| `RecallRequested` | → | Mobile button → consumed by [[CardsClient]] |
| `Ability1Requested` | → | Mobile button → consumed by [[CardsClient]] |
| `UltimateRequested` | → | Mobile button → consumed by [[CardsClient]] |
| `FireRequested` | → | Mobile FIRE button (hold: `true`=press / `false`=release) → consumed by [[CardsClient]] |

### RemoteEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientRuntime]] | `.Start(manifest)` | Hero gate + ClientEvents resolution (replaces former direct [[HunterRemoteSetup]] usage) |
| [[Manifest|Fortuna Manifest]] | (table return) | Declarative description of Fortuna |
| [[HunterMobileAbilityButton]] | `.new()`, `:Start()` | Mobile touch buttons for recall/ability1/ultimate skill frames |
| [[HunterMobileFireButton]] | `.new()`, `:Start()` | Visible mobile FIRE button (hold style) → fires FireRequested |
| [[UltimateReadyFX]] | `.new()`, `:SetReady()`, `:Destroy()` | Ember border on the ult icon at full charge |
| [[HunterHudCooldown]] | `.new(canvas, names)`, `:Start()`, `:SetReady()`, `:Destroy()` | The Recall/Ability1 cooldown bars, labels, countdown threads and expiry pops |
| [[HunterHudBump]] | `.new()`, `:Play()`, `:Destroy()` | Tile pop on the **ultimate's** rising edge to full charge (the skill pops are internal to [[HunterHudCooldown]]) |
