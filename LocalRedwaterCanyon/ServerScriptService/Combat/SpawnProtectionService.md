---
tags:
  - server
  - modulescript
  - combat
path: game.ServerScriptService.Combat.SpawnProtectionService
type: ModuleScript
lines: 79
---

# SpawnProtectionService

Grants a temporary invincibility bubble to players right after they spawn, using Roblox's native `ForceField` for both the visible blue bubble VFX and automatic `Humanoid:TakeDamage` immunity (covers every damage path — revolver shots, HighNoon ultimate, Fortuna cards, zone damage).

## What it does

1. `grant(player)` — attaches a visible `ForceField` named `SpawnProtectionField` to the character, sets the `SpawnProtected = true` attribute on the character, and schedules a `task.delay` to clear it after `Config.SPAWN_PROTECTION_DURATION` seconds (3s). Re-granting stacks safely by first clearing any existing field on that player.
   - **The `SpawnProtected` attribute is load-bearing, not just bookkeeping.** High Noon's target acquisition reads it to skip protected players outright — HighNoonTargeting's cone scan for a Dust player, and `BotCombat._ultimateCandidates` under its `skipUntargetable` flag for a Dust bot. Both read the attribute by name rather than requiring this module (the targeting module lives in `ReplicatedStorage` and cannot reach `ServerScriptService`), so **renaming it silently un-fixes launch issue #12** — nothing errors, the ult just starts locking shielded players again. Grep for the string, not for requires.
2. `onAttack(player)` — drops the shield early the first time the player fires or activates an ability. Called from every hunter's server-side fire/attack remote handler.
3. On `PlayerRemoving`, clears any active field for that player.
4. Since the ForceField is parented to the character, it auto-destroys when the character is removed on death — no explicit cleanup needed for the death path.

## Dependencies

- **Requires:** [[Config]]
- **Required by:** SpawnService (calls `grant` after every teleport), RevolverModule (calls `onAttack` on fire), HighNoonModule (calls `onAttack` on ultimate activation and each shot), CardsServer (calls `onAttack` on throw and ultimate), SunspikeModule (calls `onAttack` on fire; also passed to StarfallSightModule for ultimate activation and empowered shots), GrudgekeeperModule (calls `onAttack` on fire and both abilities; also passed to LastCallModule for ultimate activation)

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | `Config.SPAWN_PROTECTION_DURATION` | Duration of the spawn shield in seconds |
