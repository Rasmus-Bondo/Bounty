---
tags: [client, localscript, gui, bram]
path: game.StarterPlayer.StarterPlayerScripts.Bram.BramHunterGuiClient
type: LocalScript
lines: 713
---

# BramHunterGuiClient

Bram's HUD. GUI-only; input/combat logic lives in [[GrudgekeeperClient]]. Mirrors VesperHunterGuiClient, cloning `StarterGui.ReworkedHunterGui` as `BramGameGui` (`HunterGuiMobile` on touch, `ScreenGui` otherwise) and destroying other heroes' GUIs. Not the older `StarterGui.HunterGui.Template.TemplateGameGui`, which still exists on the pre-rework `Ultimate > FrameBorder` shape but is no longer cloned by anything. Exits early via [[HunterClientRuntime]] when the local player isn't Bram.

## What it does
1. Ammo: 2 of the template's 6 bullet pips (spares hidden) + the pulsing RichText counter
2. Skill1 = Q/Breach Charge, Skill2 = E/Shrapnel Shell: `BreachChargeCooldownStarted`/`ShrapnelShellCooldownStarted` forward their seconds into [[HunterHudCooldown]], which owns the fill tween, the countdown label, the countdown thread and the expiry pop. It is token-guarded, so a restart (Last Call refresh, per-hit refunds re-firing CooldownStarted with new remaining values) cleanly supersedes the old fill, and a 0-duration CooldownStarted snaps straight to ready **and pops**, so a Last Call refresh is visible rather than silent. The pop is guarded on the tile having actually been cooling, because `AbilityCooldownsReduced` re-fires a clamped `0` on every landed blast during the window and would otherwise strobe both tiles. Bram was the only hunter with a zero-length branch before the extraction; the shared module now applies it to all four, though only Bram ever fires a zero
3. Ultimate frame: charge percent / READY from `UltimateChargeChanged`; while Last Call is active (`UltimateState` remote) the label counts down the 10s window instead. The [[UltimateReadyFX]] ember halo rides the same state and is cleared in three places, because the label alone is not enough to infer it: the charge branch drives it every tick, `setUltimateCharge`'s early return drops it while Last Call is up, and `startLastCallCountdown` drops it before the countdown takes over the label. The [[HunterHudBump]] pop rides the **same three points** — it is rising-edge gated on `ultimateWasReady`, which is re-armed wherever the halo is cleared, so a recharge during or after the window still pops
4. Mobile: [[HunterMobileAbilityButton]] overlays on Skill1/Skill2/Ultimate + a visible FIRE button via [[HunterMobileFireButton]] (tap style — was an inline `createMobileFireButton` helper before the shared extraction) — all route through the request bindables into [[GrudgekeeperClient]]
5. CharacterAdded: re-clones/re-enables the GUI, resets pips, fills, and the ult display

## The skill cooldown machinery moved out on 2026-08-06
`setSkillReady`, `startSkillCooldown`, `cooldownVisuals`, `activeSkillTweens`, `skillCooldownTokens`, the zero-length branch and the two skill-tile `HunterHudBump.new` calls are gone; this script now holds a single `cooldowns` controller and calls `:Start` / `:SetReady` / `:Destroy` on it. The phantom-countdown bug all four HUDs carried (a countdown thread that survived a cancelled tween and popped a tile that was never on cooldown) is now structurally unreachable rather than fixed per copy. See [[HunterHudCooldown]].

`getChargeSize` and `setFrameSize` stayed — the **ultimate** still uses them, including the Last Call window, and only the skill half of their call sites went away. The `HunterHudBump` require stayed for the same reason: the ult tile's rising-edge pop is still driven here, off the same three clear points as the halo.

## Dependencies
- **Requires:** [[HunterClientRuntime]], [[HunterMobileAbilityButton]], [[HunterMobileFireButton]], [[UltimateReadyFX]], [[HunterHudCooldown]], [[HunterHudBump]] (from `ReplicatedStorage.Hunters.Shared`); [[Manifest|Bram Manifest]] + [[GrudgekeeperConfig]] (from `ReplicatedStorage.Hunters.Bram.Config`), [[HunterClientState]]
- **Required by:** Nobody (self-running LocalScript)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `UltimateState` | ← Server | [[LastCallModule]] Start/End — drives the active-window countdown label |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `AmmoChanged` / `Reloaded` | ← | [[GrudgekeeperClient]] ammo state |
| `BreachChargeCooldownStarted` / `ShrapnelShellCooldownStarted` | ← | [[GrudgekeeperClient]] cooldown fills |
| `UltimateChargeChanged` | ← | [[GrudgekeeperClient]] charge display |
| `FireRequested` / `BreachChargeRequested` / `ShrapnelShellRequested` / `UltimateRequested` | → | Mobile buttons → [[GrudgekeeperClient]] |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientRuntime]] | `.Start(manifest)` | Hero gate, client events, remotes |
| [[Manifest|Bram Manifest]] | (table return) | Declarative description of Bram |
| [[GrudgekeeperConfig]] | `Basic.MagazineSize`, `Ultimate.Duration` | Pip count + countdown fallback |
| [[HunterMobileAbilityButton]] | `.new()`, `:Start()` | Mobile ability buttons |
| [[HunterMobileFireButton]] | `.new()`, `:Start()` | Visible mobile FIRE button → fires FireRequested |
| [[UltimateReadyFX]] | `.new()`, `:SetReady()`, `:Destroy()` | Ember border on the ult icon at full charge |
| [[HunterHudCooldown]] | `.new(canvas, names)`, `:Start()`, `:SetReady()`, `:Destroy()` | The Breach/Shrapnel cooldown bars, labels, countdown threads and expiry pops |
| [[HunterHudBump]] | `.new()`, `:Play()`, `:Destroy()` | Tile pop on the **ultimate's** rising edge to full charge (F); the skill pops are internal to [[HunterHudCooldown]] |
