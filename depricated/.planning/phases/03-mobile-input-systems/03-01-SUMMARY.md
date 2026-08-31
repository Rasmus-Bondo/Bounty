---
phase: 03-mobile-input-systems
plan: 01
status: complete
started: "2026-03-30T14:32:37Z"
completed: "2026-03-30T14:36:37Z"
---

# Summary: Server-Authoritative Sprint/Crouch/Stamina with MovementService and Stamina Bar UI

Server-authoritative MovementService handling sprint (WalkSpeed 24), crouch (WalkSpeed 8, CameraOffset -1.5), and stamina (drains in ~6s, regens after 2s delay over ~3.5s) with RemoteEvents for client intent and a gold stamina bar with smooth client-side interpolation.

## Tasks Completed

1. **Create MovementService with sprint/crouch/stamina and RemoteEvents** -- Created MovementEvents folder under ReplicatedStorage.Events with SprintEvent and CrouchEvent RemoteEvents. Created MovementService ModuleScript with WALK_SPEED=16, SPRINT_SPEED=24, CROUCH_SPEED=8, MAX_STAMINA=100, DRAIN_RATE=100/6, REGEN_RATE=100/3.5, REGEN_DELAY=2. Server enforces mutual exclusivity between sprint and crouch. Heartbeat tick handles stamina drain/regen. Updated MainServer to require and Initialize MovementService.

2. **Create stamina bar UI with smooth client interpolation** -- Created StaminaBar Frame inside HealthDisplayGui.Canvas positioned below XP bar, matching existing bar sizing pattern (0.567 width, 0.026 height). Dark background with gold/yellow Fill frame. Added UICorner (4px radius) to both for rounded edges. Created StaminaBarClient LocalScript with RenderStepped interpolation (LERP_SPEED=10) reading player Stamina attribute for smooth visual updates.

## Key Files

- `game.ServerScriptService.RoundSystem.Modules.MovementService` -- Server-authoritative sprint/crouch/stamina logic
- `game.ServerScriptService.RoundSystem.MainServer` -- Updated to require and initialize MovementService
- `game.ReplicatedStorage.Events.MovementEvents` -- Folder containing SprintEvent and CrouchEvent
- `game.ReplicatedStorage.Events.MovementEvents.SprintEvent` -- Client-to-server sprint intent
- `game.ReplicatedStorage.Events.MovementEvents.CrouchEvent` -- Client-to-server crouch intent
- `game.StarterGui.HealthDisplayGui.Canvas.StaminaBar` -- Stamina bar frame (dark background)
- `game.StarterGui.HealthDisplayGui.Canvas.StaminaBar.Fill` -- Gold fill frame
- `game.StarterPlayer.StarterPlayerScripts.StaminaBarClient` -- Smooth stamina bar interpolation

## Deviations from Plan

### Minor Adjustments

**1. [Rule 2] Initialize function naming** -- Plan used `Init()` but existing codebase services use `Initialize()` (BanditService has no init, but RagdollService, CollisionService, etc. all use `Initialize()`). Used `Initialize()` to match established convention.

**2. [Positioning] StaminaBar placement** -- Plan suggested generic "below or adjacent" positioning. Inspected existing Canvas layout (HealthBar at Y=0.5, XpBarDisplay at Y=0.663) and placed StaminaBar at Y=0.72 to sit cleanly below XP bar with matching width and horizontal alignment.

## Known Stubs

None -- all data sources are wired (MovementService sets Stamina attribute, StaminaBarClient reads it). Sprint/crouch RemoteEvents are created and connected. No placeholder data or TODO items.

## Verification Notes

- MovementService source confirmed: SPRINT_SPEED=24, CROUCH_SPEED=8, WALK_SPEED=16, DRAIN_RATE, REGEN_DELAY=2
- MovementEvents folder confirmed with SprintEvent and CrouchEvent children
- MainServer confirmed: requires MovementService (line 7), calls Initialize() (line 15)
- StaminaBar confirmed with Fill child and UICorner on both
- StaminaBarClient confirmed: RenderStepped:Connect, GetAttribute("Stamina"), math.clamp, lerp interpolation

## Playtest Checklist

- [ ] Hold Shift to sprint -- verify player moves faster (WalkSpeed 24 vs 16)
- [ ] Sprint until stamina bar empties (~6 seconds) -- verify sprint auto-stops
- [ ] Stop sprinting, wait 2 seconds -- verify stamina starts regenerating (~3.5 seconds to full)
- [ ] Press Ctrl to crouch -- verify slower movement and lowered camera view
- [ ] Verify sprint and crouch are mutually exclusive (starting one cancels the other)
- [ ] Verify stamina bar displays near health/XP bars and fills/drains smoothly

## Self-Check: PASSED

- [x] MovementService ModuleScript exists at game.ServerScriptService.RoundSystem.Modules.MovementService
- [x] SprintEvent RemoteEvent exists at game.ReplicatedStorage.Events.MovementEvents.SprintEvent
- [x] CrouchEvent RemoteEvent exists at game.ReplicatedStorage.Events.MovementEvents.CrouchEvent
- [x] StaminaBar Frame exists at game.StarterGui.HealthDisplayGui.Canvas.StaminaBar
- [x] Fill Frame exists at game.StarterGui.HealthDisplayGui.Canvas.StaminaBar.Fill
- [x] StaminaBarClient LocalScript exists at game.StarterPlayer.StarterPlayerScripts.StaminaBarClient
- [x] MainServer updated with MovementService require and Initialize call
- [x] All verified via MCP grep_scripts and get_instance_children
