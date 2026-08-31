---
tags: [server, client, modulescript, utility, combat, shared]
path: game.ReplicatedStorage.Hunters.Shared.HunterCharacterUtil
type: ModuleScript
lines: 303
---

# HunterCharacterUtil

Shared utility module for hunter character validation, hit detection, accessory filtering, and team checks. Used by every hunter (Dust, Fortuna, future) to avoid duplicating these helpers.

Overwhelmingly server-side, but **not server-only since 2026-08-08**: AimAssistController requires it on the client for `IsStealthed` alone. That is safe because the one expensive thing this module does at require time — the workspace walk and the `DescendantAdded`/`DescendantRemoving` listeners in behavior 1 — sits behind a `RunService:IsServer()` gate, so a client require costs nothing. (Verified the hard way: `loadstring`-ing this module in an edit-mode session runs that branch against the whole Redwater workspace and hangs the plugin connection.)

## What it does
1. On require (server only), maintains a `cachedModels` set of every alive humanoid model in workspace by listening to `workspace.DescendantAdded`/`DescendantRemoving` for Humanoids and to each Humanoid's `Died` signal — so `GetHumanoidModels` is O(1) lookup, load-bearing for lag compensation
1a. **The same `Died` handler pins the corpse at zero health** (added 2026-08-13). A `HealthChanged` connection re-zeroes any write that lifts a dead body above 0, for as long as the character lasts. The reviver it was written for — Roblox's own Health script, which has no dead check — has since been replaced by Redwater's own `StarterCharacterScripts.Health`, so this now fires only if something *else* heals a corpse. It stays as the standing guarantee, not as the fix. `IsAlive` (#10) covers every path that asks this module; the pin covers the ones that never will — bot target selection, aim assist, and SpawnService's round-start respawn sweep. Server-only by construction, since every caller sits inside the `IsServer` branch
2. `GetCharacterHumanoidRootHead(player)` validates a player has an alive character with HumanoidRootPart and Head, returns `character, humanoid, rootPart, head`
3. `GetHitCharacterAndHumanoid(hitPart)` walks up the ancestry from a hit part to find the owning Model and Humanoid (no filtering)
4. `GetHumanoidFromHit(instance)` like `GetHitCharacterAndHumanoid` but also filters out accessory parts and folder-nested parts via `ShouldIgnoreCombatPart`, and rejects dead humanoids — used by Fortuna's projectile resolution
5. `GetHumanoidModels()` returns all alive humanoid models in workspace (from the cache populated in #1)
6. `ShouldIgnoreCombatPart(instance)` returns true if the instance is inside an Accessory or inside a Folder nested under the character model (e.g. cosmetic/holstered weapon folders)
7. `IsHeadshotPart(hitPart)` checks if a hit part is named "Head" or has `HitboxType = "Head"` attribute (canonical headshot signal across all hunters; the legacy `IsHead` boolean attribute is no longer recognized)
8. `IsEnemy(attackerPlayer, targetCharacter)` returns true when attacker and target are on different teams; same-character returns false; character-less humanoids count as enemies
9. `IsStealthed(character)` (added 2026-08-06) — is this character currently hidden from sight? Fortuna's ultimate hides her by dropping every part to `Transparency = 1`, which is a fact about *pixels*: server-side AI reads positions, so an invisible Fortuna is a perfectly ordinary target to anything that does not ask this explicitly. Checks **two** attributes because there are two casters and checking one holds the rule for half the game — `UltimateInvisible` (set by CardsServer on a player Fortuna, written inside `setCharacterInvisible` in lockstep with the transparency change so it cannot drift from the real window) and `BotFortunaInvisible` (set by BotCombat on a bot one). HealthBarController reads the same pair for the same reason. Deliberately **not** `UltimateUntargetable`: that answers a different question — "may High Noon lock this character" — and the two are kept apart on purpose, since Bram's Last Call publishes `UltimateActive` for movement headroom and overloading these once handed him a High Noon immunity. They coincide for Fortuna today; they are not the same rule

10. `IsAlive(humanoid)` (added 2026-08-13) — the canonical "is this thing alive" test, and the reason every other check in this file stopped asking about health alone. `Health > 0` **and** `GetState() ~= Dead`. Health on its own accepts corpses: Roblox's default Health script regenerates a body that has already died (see 1a), and a Humanoid never leaves the Dead state whatever its health reads afterwards — so the state is the fact and the health is the symptom. This is what launch issue #10's duplicate kill-feed row turned out to be: the follow-up shot found a corpse back above 0 and killed it a second time. Used internally by #1, #2 and #4, and called directly by RevolverModule and BotCombat; the four damage services and SpawnService test the same rule inline because they require nothing

## Team modes

`IsEnemy` answers false for an ally, which is the single gate behind Fortuna's cards, Vesper's
pinning round and Bram's shrapnel.

## Dependencies
- **Requires:** [[TeamAffinity]]
- **Required by:** Domination (IsAlive for pad occupancy), RevolverModule, CardsServer, SunspikeModule (also injected into Vesper's Grapple/Pinning services and StarfallSightModule), GrudgekeeperModule (also injected into Bram's Breach/Shrapnel services), BotCombat, BotBrain, AimAssistController (the one client-side caller — `IsStealthed` only)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
