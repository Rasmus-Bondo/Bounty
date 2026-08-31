---
tags:
  - client
  - localscript
  - ui
  - mobile
  - dust
path: game.StarterPlayer.StarterPlayerScripts.Dust.HunterGuiClient
type: LocalScript
lines: 443
---

# HunterGuiClient

Client-side HUD controller for Dust: ammo counter, bullet icons, skill cooldown indicators, mobile ability buttons, player name display. Phase 3 ported to consume [[HunterClientRuntime]] driven by the [[Manifest|Dust Manifest]] — replaces 78 lines of `waitForSelectedHunter` + 7 inline `if not… then Instance.new()` BindableEvent creations with a 30-line runtime prelude.

## What it does

1. Requires [[HunterClientRuntime]] + the [[Manifest|Dust Manifest]] and calls `HunterClientRuntime.Start(dustManifest)`; if not on Dust, the runtime returns nil and the script silently exits
2. Aliases the 7 [[Manifest|manifest]]-declared ClientEvents from `runtime.ClientEvents`: AmmoChanged, Reloaded, DashCooldownStarted, Skill2CooldownStarted, DashRequested, Skill2Requested, FireRequested (the runtime owns ensure-or-create — no more inline bindable boilerplate)
3. Clones the TemplateGameGui from HunterGui template into PlayerGui (or reuses existing)
4. Manages ammo display: rich-text ammo counter with pulse animation on change, 6 bullet icons that shrink/fade on use and pop back on reload
5. Manages skill cooldown UI: `DashCooldownStarted`/`Skill2CooldownStarted` forward their seconds into [[HunterHudCooldown]], which owns the animated fill bar, the countdown timer text, the countdown thread and the expiry pop for the Skill1 (dash) and Skill2 tiles. **The ultimate tile is not driven here**: Dust's charge state lives in `HighNoonChargeUI`, which owns that tile's pop
6. Creates invisible mobile touch buttons overlaying each skill frame (only visible on `TouchEnabled` devices) that fire DashRequested / Skill2Requested
7. Creates the visible mobile Fire button via [[HunterMobileFireButton]] (tap style — fires FireRequested on each tap) — replaces the former inline `createMobileFireButton` helper, and the even older TouchTap-anywhere shoot handler in RevolverInput (`TouchTap` only fires on finger release after Roblox's tap-vs-drag heuristic, so it lagged)
8. Sets the player name label to `DisplayName`
9. Re-enables the GUI on `CharacterAdded`

## The skill cooldown machinery moved out on 2026-08-06

`setSkillReady`, `startSkillCooldown`, `activeSkillTweens`, `skillCooldownTokens`, the `skillBumps` table and the `SKILL_READY_SIZE` / `SKILL_COOLDOWN_START_SIZE` constants are gone; this script now holds a single `cooldowns` controller and calls `:Start` / `:SetReady` / `:Destroy` on it. Dust migrated **last** of the four because it was the odd one out: its two functions took the frames as explicit arguments rather than reading a `cooldownVisuals` record, its bumps lived in a separate table keyed by skill name, and its size constants were named differently (identical values). The shared module resolves the tiles itself, so the call sites shrank rather than moved. See [[HunterHudCooldown]].

This script no longer requires `HunterHudBump` at all — unlike the other three it has no ultimate pop to drive, since Dust's High Noon tile belongs to `HighNoonChargeUI`.

The phantom-countdown bug all four HUDs carried (a countdown thread that survived a cancelled tween and popped a tile that was never on cooldown) is now structurally unreachable rather than fixed per copy.

## Dependencies

- **Requires:** [[HunterClientRuntime]], [[HunterMobileFireButton]], [[HunterHudCooldown]] (from `ReplicatedStorage.Hunters.Shared`); [[Manifest|Dust Manifest]] (from `ReplicatedStorage.Hunters.Dust.Config`), [[HunterClientState]]
- **Required by:** Nobody

## Connections

### RemoteEvents

None

### BindableEvents

| Bindable | Direction | Other script |
|----------|-----------|--------------|
| `AmmoChanged` | ← | [[FPSRevolverClient]] updates ammo count on shot |
| `Reloaded` | ← | [[FPSRevolverClient]] resets ammo display on reload |
| `DashCooldownStarted` | ← | [[FPSRevolverClient]] starts Skill1 cooldown timer |
| `Skill2CooldownStarted` | ← | [[FPSRevolverClient]] starts Skill2 cooldown timer |
| `DashRequested` | → | [[FPSRevolverClient]] mobile dash button fires this |
| `Skill2Requested` | → | [[FPSRevolverClient]] mobile Skill2 button fires this |
| `FireRequested` | → | [[FPSRevolverClient]] mobile Fire button fires this (also consumed by [[HighNoonClient]] during High Noon so the ultimate shot still triggers on mobile) |

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientRuntime]] | `.Start(manifest)` | Hunter gate + ClientEvents resolution |
| [[HunterMobileFireButton]] | `.new()`, `:Start()` | Visible mobile FIRE button → fires FireRequested |
| [[HunterHudCooldown]] | `.new(canvas, names)`, `:Start()`, `:SetReady()`, `:Destroy()` | The Skill1/Skill2 cooldown bars, labels, countdown threads and expiry pops |
| [[Manifest|Dust Manifest]] | (table return) | Declarative description of Dust |
