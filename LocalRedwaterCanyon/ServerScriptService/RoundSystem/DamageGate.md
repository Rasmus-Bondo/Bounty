---
tags:
  - server
  - modulescript
  - gamemode
  - combat
path: game.ServerScriptService.RoundSystem.DamageGate
type: ModuleScript
lines: 24
---

# DamageGate

The one server-side friendly-fire gate every damage site calls.

## What it does
1. `allows(attackerCharacter, victimCharacter)` delegates to the resolved gamemode's `CanDamage`
   hook via `State.gamemodeRules`, so damage policy stays a rules decision — a future team mode
   could turn friendly fire back on by answering differently — while the `TakeDamage` sites share
   one implementation.
2. Unresolved rules (the boot window) gate nothing, which is FFA behaviour.

Takes character Models, so players and bot rigs go through the same call. A refused hit must be
refused **before** any `TakeDamage`, hit marker, hit sound, damage direction, health-bar reveal or
ultimate charge — dealing zero damage instead still fires all of those through the hit pipeline.

## Dependencies
- **Requires:** [[State]]
- **Required by:** HighNoonDamage, RevolverModule, SunspikeModule, StarfallSightModule,
  GrudgekeeperModule, BotCombat

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[State]] | `State.gamemodeRules` | The resolved rules module whose `CanDamage` hook decides the answer |
