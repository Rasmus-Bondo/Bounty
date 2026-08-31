---
tags:
  - server
  - modulescript
path: game.ServerScriptService.RoundSystem.SpawnService
type: ModuleScript
lines: 469
---

# SpawnService

Handles teleporting players to round spawn points and managing corpses.

## What it does

1. Reads spawn parts from `workspace.SpawnPoints` folder
2. Teleports individual players to random round spawns, filtered by safe zone when active. `teleportPlayerToSpawn` / `sendPlayerToRoundSpawn` now return a **success boolean** — `false` when the character isn't ready yet (missing root/humanoid, or health still 0 mid-spawn) so the caller can retry instead of silently skipping a slow loader. **The boolean only reports that the write was ISSUED,** not that it survived: a player owns their character's physics, so a client asserting its own position can beat the server's `root.CFrame` write with no error and no failed return. `verifyTeleport` settles that asynchronously — 0.35 s later (a couple of round trips, and still inside the 8 s `ACImmuneUntil` the same call granted, so a repair can never flag the anti-cheat) it re-measures the root against the target and repairs only if it is more than 30 studs off. The tolerance is loose on purpose: the spawn point drops the player 4 studs up, so they are in free fall for the whole window (~12 studs) and can sprint another 8, while the real failure measured **119 studs**. The repair branches on `Anchored` because `SetNetworkOwner` *throws* on an anchored part — an anchored root is already server-driven and takes the plain write (this is the round-end case, since `freezePlayerForVictory` anchors 0.15 s after the jail teleport), while an unanchored one gets `SetNetworkOwner(nil)`, the write, zeroed velocity, and an explicit `SetNetworkOwner(player)` restore that retries for up to 10 s if the root is anchored when it comes due — abandoning that restore would leave the player server-simulated and indistinguishable from permanent lag. Added 2026-08-04: this failure was silent, and at round start it costs the whole match (the player stays at the jail spawn, 59 studs under the map), which `teleportAllToRoundSpawns`' `unplaced` retry cannot catch because that list only collects the guard failures above. **Every teleport carries a per-player ticket since 2026-08-13, and a verify whose ticket has been superseded does nothing.** Two teleports closer together than the 0.35 s window otherwise each dragged the player back to their own stale target and warned about it: the first verify woke to find them standing on the *second* target, read that as a refused write, and repaired backwards — undoing the unique-spawn assignment `teleportAllToRoundSpawns` had just made and taking network ownership for `TELEPORT_OWNERSHIP_HOLD` twice. Not hypothetical spacing — RoundController's round start issues one teleport through `hookCharacter` and the next 0.25 s later (`TELEPORT_BLACKSCREEN_HOLD`), 0.1 s inside the window, and a late joiner during `"Starting"` hits the same overlap. The warning also logs the root's actual position now, because the offset alone cannot separate a discarded write (character left at the world origin — Redwater has no SpawnLocation) from a superseded one. `teleportPlayerToSpawn` returns the target CFrame as a **second** return value so RoundController's post-settle check can ask "is the player where I put them" rather than the weaker "is the player somewhere safe"; every existing caller reads only the boolean, and both guard failures return a bare `false`
3. Teleports all players to unique shuffled round spawns at round start, filtered by safe zone. Returns the **list of players it could not place** (characters not yet loaded during the pass); RoundController keeps retrying these so a slow-loading client isn't stranded in the jail cage for the whole round
3a. `getSafeSpawnPool` is the single spawn-eligibility rule, shared with BotService. A spawn point must sit `SPAWN_ZONE_MARGIN` (27 studs) inside the fire to be eligible, measured by [[ZoneService]] `getSafeClearance` — one number that works for a canyon's two walls or a bowl's ring, so this filter carries no zone-shape knowledge of its own. Clearance is measured from the wall's inner **face**, so the old zero-margin `isPositionInSafeZone` check accepted a spawn standing *on* the flames: the wall's `CrawlerFlameColumn` emitters sit up to 3 studs past that face, their particles spill ~10 further, and the wall keeps closing at 1.875 studs/s while the 3s spawn-protection bubble runs. The margin is **derived** (`FIRE_WALL_FX_OVERHANG` 12 + 8s of boundary travel) so retuning `ZONE_PHASE_DURATION` / `ZONE_FIRE_MOVE_FRACTION` / the zone geometry cannot silently invalidate it. Bots had always pathed with `BotConfig.FirewallAvoidanceMargin` (26); only the spawn filter was passing nothing
3a-i. `FIRE_WALL_SPEED` is derived as the **widest single step** in the shared fraction walk (1.00 → 0.75 → 0.50 → 0.25 of the map's original playable area) over `ZONE_PHASE_DURATION * ZONE_FIRE_MOVE_FRACTION`. Taking the max is free on a linear map — a span shrinks linearly, so all three steps are 112.5 studs and the result is still exactly 1.875 — and load-bearing on a radial one, where a radius does not, so the ring closes faster every phase (1.02 then 1.33 studs/s on Frostbite) and only the last step is worth sizing a margin against
3b. When no spawn clears the margin, the fallback is the **single deepest-inside spawn** — not the old `or spawnParts`, which picked uniformly from every spawn point and could drop a player hundreds of studs behind the wall. (Simulated across the whole round at every centre offset against the current 44-point layout: the eligible pool never drops below 12 — 12–16 once the Final phase is fully closed — and the fallback is never reached. Before the final-zone spawns were added in 2026-07 it bottomed out at 3.)
4. Clears corpses from `workspace.CorpseFolder`
5. Ensures all players have alive characters via `SkinService.loadCharacter`. The dead test is **state-based, not health-based** (2026-08-13): a corpse whose health regenerated above 0 — Roblox's default Health script does exactly that, see HunterCharacterUtil `IsAlive` — reads as alive on health alone and is never rebuilt, so the round would start with a player still lying dead
5a. **`respawnAllPlayers` is the round-START version of that, and is not the same thing** (2026-08-06). `ensureAllPlayersAlive` only rebuilds characters that are missing or dead; `respawnAllPlayers` rebuilds **every** character, survivors included. Once the server started looping rounds, a player who lived to the buzzer carried their remaining health into the next round holding a half-empty cylinder, because health, ammo and the client-side ability state are all rebuilt on `CharacterAdded` — and a survivor never fires one. A fresh character is the single chokepoint that resets all of it: RoundController `hookCharacter` restamps `MaxHealth`/`Health`, each hunter client's respawn path refills its magazine and clears its cooldown sweeps, and `ServerWeaponGuard` rebuilds its per-character magazine and burst window (its state carries the character it was built for, so a new one invalidates it by construction). Only safe because `State.roundPhase` is no longer `"Summary"` by the time it runs — `hookCharacter` freezes anything it sees load during `"Summary"` that is not flagged a late arrival, and the loop's single unfreeze has already gone. RoundController skips it on the server's first round, where there is nothing to reset and everyone present has just arrived
6. Sets `ACImmuneUntil = tick() + 8` attribute on the player before any CFrame teleport — prevents MovementChecker from false-flagging the position delta. (Plain text, not a wikilink: this is an attribute MovementChecker happens to read, not a `require()`, remote or bindable, so it is not a code-level connection. It was linked until 2026-08-04, which put an edge in the graph that does not exist in code.) Timestamp instead of the old boolean-plus-`task.delay(1)` clear: overlapping teleports were wiping each other's immunity early, and a still-loading client can replay a teleport as ~190 studs/s of smooth movement several seconds late (false kick); spawn-protection force-fields cover the same window, so cheat exposure is minimal
7. Calls [[SpawnProtectionService]].grant(player) after every teleport — grants a `Config.SPAWN_PROTECTION_DURATION`-second ForceField bubble. Covers round-start spawns, in-round respawns, mid-round joins, and the jail-spawn path (harmless there since combat isn't allowed post-round).
8. Calls [[ZoneService]] `resetPlayerFireTime(player)` on every validated placement. The burn ramp survives death — it is only cleared by a live zone tick that finds the player back inside the safe area — so a player who died in the fire used to carry the ramp into the next life and re-enter the burn at the `ZONE_DAMAGE_MAX` cap instead of the 5 DPS base.

## Team modes

`ResolveSpawn` asks the resolved gamemode first: a rules module may return a CFrame, and only a nil
answer falls through to the normal shuffled safe pool. That is the whole hook -- FFA returns nil and
behaves exactly as before, while a team mode returns its pad slot for every spawn and respawn.

The CFrame-placing half of the old teleport path was split out so both callers share it, rather than
the team path re-implementing the lift and the physics settle.

## Dependencies

- **Requires:** [[Config]], [[MapConfig]], [[ZoneService]] (lazy require, via the `zoneService()` accessor), [[SkinService]], [[SpawnProtectionService]]
- **Required by:** RoundController, BotService, TutorialDirector (the ult-step plant and the arrival gate's backstop teleport)

## Connections

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | `ZONE_PHASE_DURATION` / `ZONE_FIRE_MOVE_FRACTION` | The closing schedule half of the `SPAWN_ZONE_MARGIN` derivation |
| [[MapConfig]] | `Zone.Shape` / `Start` / `End` / `StartRadius`, `Instances.SpawnPoints`, `Instances.JailSpawn` | The map-geometry half of the same derivation, plus the two workspace folder names this module resolves |
| [[ZoneService]] | `ZoneService.getSafeClearance()`, `resetPlayerFireTime()` | Studs a spawn point sits inside the fire; clear the burn ramp on placement |
| [[SkinService]] | `SkinService.loadCharacter()` | Spawn player with their selected skin model |
| [[SpawnProtectionService]] | `SpawnProtectionService.grant()` | Grant a temporary ForceField bubble after every teleport |
