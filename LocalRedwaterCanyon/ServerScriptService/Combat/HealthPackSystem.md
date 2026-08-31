---
tags:
  - server
  - script
  - combat
path: game.ServerScriptService.Combat.HealthPackSystem
type: Script
lines: 137
---

# HealthPackSystem

Server-authoritative pickup system for health packs. Auto-wires any model tagged `HealthPack` (via CollectionService) that has a `TouchHitbox` child BasePart.

## What it does

1. Discovers all `HealthPack`-tagged models on startup and subscribes to `GetInstanceAddedSignal` / `GetInstanceRemovedSignal` so copy-pasted stands wire up automatically
2. Connects each pack's `TouchHitbox.Touched` to resolve the player from the touching part, validate the pack's `Active` attribute and that the humanoid is alive
3. On valid touch: heals +35 instantly (clamped to MaxHealth), starts/refreshes a per-player regen task, sets the model's `Active` attribute to false, and schedules reactivation in 30 seconds
4. Per-player regen runs 5 ticks at 1s intervals, healing 6% of MaxHealth per tick (totals 30% over 5s). A second pickup cancels the prior task and starts a fresh one (refresh semantics)
5. Cleans up regen state on `Players.PlayerRemoving`
6. Visibility of the Pickup part is driven entirely off the `Active` attribute by [[HealthPackVisuals]] on the client; this script never touches the part's Transparency or CFrame

## Dependencies

- **Requires:** Nothing
- **Required by:** Nobody

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|-------------|
| `HealthPackPickedUp` | → Client | Fired to the healing player alone. [[HealthPackPickupFeedbackClient]] plays the layered heal sounds and the green screen-edge vignette; [[SegmentedHealthManager]] (both HUD templates) also listens to animate the health bar |
| `HealthPackWorldFX` | → Client | Fired to everyone with the healed character, so nearby players see the heal. [[HealthPackPickupFeedbackClient]] draws the particles and the expanding ForceField sphere |

### BindableEvents

None

### Direct require()

None

### CollectionService Tags

| Tag | Usage | Other scripts |
|-----|-------|---------------|
| `HealthPack` | Owns the tag — applies to stand models, wires `Touched` on `TouchHitbox`, drives `Active` attribute, and reactivates after 30s (firing immediate pickup on overlap via `GetPartsInPart`) | [[HealthPackVisuals]] (spin + visibility); combat raycasts exclude only each pack's green `Pickup` + invisible `TouchHitbox` (the solid `Base` stand still blocks shots/LOS): [[RevolverShooting]] / [[RevolverModule]] / [[RevolverLagCompensation]] / [[HighNoonTargeting]] / [[SunspikeModule]] / [[GrappleHookService]] / [[PinningRoundService]] / [[GrudgekeeperModule]] / [[ShrapnelShellService]] / [[CardsServer]] / [[AimAssistController]] |
