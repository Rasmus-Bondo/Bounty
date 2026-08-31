# MovementService

Server-authoritative sprint and crouch system. Listens for client RemoteEvents, validates input, manages stamina drain/regen, and sets WalkSpeed/HipHeight on the Humanoid.

**Path:** `game.ServerScriptService.PlayerServices.MovementService`
**Type:** ModuleScript (172 lines)
**Runs on:** Server

## How It Works

### Player Attributes (set on init)

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| Stamina | number | MAX_STAMINA (100) | Current stamina level |
| IsSprinting | boolean | false | Currently sprinting |
| IsCrouching | boolean | false | Currently crouching |
| LastSprintStop | number | 0 | Server time when sprint last stopped (for regen delay) |

### Sprint

1. Client fires `SprintEvent` with `true/false`
2. Server type-checks the boolean, validates character/humanoid
3. **Start sprint**: requires stamina > 0, cancels crouch if active, sets WalkSpeed to `SPRINT_SPEED` (24)
4. **Stop sprint**: records `LastSprintStop` timestamp, restores to `CROUCH_SPEED` (8) or `WALK_SPEED` (16)

### Crouch

1. Client fires `CrouchEvent` with `true/false`
2. **Start crouch**: cancels sprint if active, sets WalkSpeed to `CROUCH_SPEED` (8), sets HipHeight to `CROUCH_HIP_HEIGHT`
3. **Stop crouch**: restores HipHeight to `NORMAL_HIP_HEIGHT`, restores speed based on sprint state

### Crouch Animation

- Placeholder `CROUCH_ANIMATION_ID` (currently empty string — not yet configured)
- When set, loads an AnimationTrack per player via Animator with `Action` priority, looped
- Tracks stored in `crouchAnimations` table, cleaned up on PlayerRemoving

### Stamina Tick (Heartbeat)

Runs every frame for all players:
- **Sprinting**: drains at `STAMINA_DRAIN_RATE` (100/6 ≈ 16.7/s → ~6s to empty). Force-stops sprint at 0
- **Not sprinting**: after `STAMINA_REGEN_DELAY` (2s) since last sprint stop, regens at `STAMINA_REGEN_RATE` (100/3.5 ≈ 28.6/s → ~3.5s to full)

### Mutual Exclusion

Sprint and crouch cancel each other — you can't be in both states simultaneously.

## Dependencies

- [[Config]] — speed values, stamina rates, hip heights
- ReplicatedStorage.Events.MovementEvents.SprintEvent — RemoteEvent
- ReplicatedStorage.Events.MovementEvents.CrouchEvent — RemoteEvent

## Used By

- [[MainServer]] — Initialize() called at boot
- [[MovementController]] (client) — fires SprintEvent/CrouchEvent
