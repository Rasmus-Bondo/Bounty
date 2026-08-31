---
tags: [server, modulescript, skins, character, teleport]
path: game.ServerScriptService.PlayerServices.SkinService
type: ModuleScript
lines: 341
---

# SkinService

Reads the skin selection from teleport data on join and spawns the correct character model on every spawn (initial and respawn).

## What it does
1. `Start()` sets `Players.CharacterAutoLoads = false` so Roblox's auto-respawn never fires independently, then calls `loadCharacter` for each player on PlayerAdded (handling initial spawn)
2. On PlayerAdded, reads `player:GetJoinData().TeleportData.characterSelections[userId]` and stores the `{category, subfolder, modelName}` selection
3. `getSelection(player)` returns the stored selection, defaulting to Dust/Default/DustDefault
4. `loadCharacter(player)` clones the skin model from `ReplicatedStorage.Hunters.<category>.Character.<subfolder>.<modelName>`, runs `normalizeRig` on it to align the rig with the DustDefault baseline, disables the Animate LocalScript, destroys the old character, sets `player.Character = clone`, yields one server frame via `task.wait()`, then re-enables Animate — this two-batch replication forces the client to start Animate fresh inside the character context; falls back to `player:LoadCharacter()` if the model is missing
5. `normalizeRig(clone)` enforces parity with DustDefault by: (a) converting any AnimationConstraint joints to Motor6D (using DustDefault as the C0/C1 reference), (b) stripping rig artifacts that diverge from DustDefault: `NoCollisionConstraint`s (cause ragdolled corpses to stay rigid), `JointRotation` Attachments parented under `*RigAttachment` (reorient Motor6D animation axes), and `BallSocketConstraint`s (legacy AC-rig artifact), and (c) copying DustDefault's Humanoid configuration onto the clone — `BreakJointsOnDeath` (without this Wraith dies as a rigid plank instead of ragdolling), `DisplayDistanceType`, `HealthDisplayType`, plus movement/scale properties — so any future imported skin spawns with the same death/animation behavior as DustDefault
6. Cleans up per-player selection on PlayerRemoving
7. `onBeforeLoadCharacter(fn)` registers a pre-load hook; `loadCharacter` runs all registered hooks (pcall-guarded) at its very start, before `getSelection`, so a hook can change the selection just in time for the imminent respawn. HunterSwitchService registers one to apply a death-gated hunter swap on the player's next respawn — this is the single choke-point that makes the swap land on death respawn, round-start respawn, and initial spawn without SkinService needing to know about hunter switching (no require cycle)
7a. Immediately after `WaitForSelection` and **before** the pre-load hooks, `loadCharacter` calls [[HunterSelectionService]]`.RefreshWeaponSkinsFromProfile(player)`, which re-publishes every hunter's equipped gun skin from the shared profile. Called directly rather than registered as a hook so the ordering is not left to registration order: it has to run before HunterSwitchService's `applyPending`, which selects the swapped-to hunter. It refreshes *all* hunters, so whichever one the hooks land on already has the right `EquippedWeaponSkin_<Hunter>` attribute. This is what makes a mid-match swap spawn holding the gun skin equipped for that hunter, and what covers friends-list joiners, who arrive with no teleport payload to snapshot
8. `loadCharacter` opens with [[HunterSelectionService]]`.WaitForSelection(player)`, before the pre-load hooks. A player who joined this server directly from the Roblox friends list has no teleport data, so their hunter is resolved asynchronously from their profile; blocking here — the one choke point every spawn path funnels through (this module's `Start`, RoundController's initial-spawn fallback and its respawns, HunterSwitchService) — means whichever caller wins the race still builds the character as the resolved hunter rather than the placeholder default. A no-op for every player who arrived from the lobby. The gate doubles as the attribute-publish barrier: [[HunterSelectionService]] withholds a direct joiner's `SelectedHunter` / `EquippedWeaponSkin_<Hunter>` attributes until the resolve settles and publishes them *before* releasing `resolving`, so by the time this returns the character is built and every client boots off final values

## Dependencies
- **Requires:** [[HunterSelectionService]] (reads the player's hunter selection to pick the right character model), [[TeamAffinity]] (resolves the rig collision group, so a team mode puts each fighter in TeamRed/TeamBlue)
- **Required by:** Main, SpawnService, RoundController, HunterSwitchService (registers a pre-load hook + calls `.loadCharacter`)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterSelectionService]] | `.InitPlayer()`, `.WaitForSelection()`, `.RefreshWeaponSkinsFromProfile()`, `.GetSelection()` | Resolve the loadout on join, hold a direct joiner's first spawn until their hunter resolves, re-publish every hunter's gun skin from the profile on every spawn, and read the selection that picks the character model |
