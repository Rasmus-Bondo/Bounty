---
phase: 02-combat-audio-polish
plan: 04
status: partial
started: "2026-03-29T01:00:00Z"
completed: "2026-03-29T01:15:00Z"
---

# Summary: Accuracy Spread (Recoil Deferred)

## What Was Built

Server-side accuracy spread system that increases bullet deviation with rapid fire. Rewards trigger discipline — paced shots stay accurate while spam-clicking causes increasing inaccuracy.

Camera recoil was attempted but deferred: Roblox's default camera controller overwrites camera.CFrame each frame, preventing direct CFrame manipulation. CameraOffset approach also failed. Will revisit with a custom camera controller or alternative approach.

## Tasks Completed

1. **Server-side accuracy spread** — Tracks `consecutiveShots[player]` that increments on each shot and resets when 1.0+ seconds pass between shots. Spread increases by 0.5 degrees per consecutive shot up to 5 degrees max. First shot always perfectly accurate (spread = 0). Applied by rotating the raycast direction vector using CFrame.Angles with random X/Y offsets before the server raycast.

## Deferred

- **Camera recoil kick** — Multiple approaches attempted (CFrame.Angles in BindToRenderStep, CameraOffset manipulation, task.spawn loop). None produced visible results due to Roblox's camera controller overwriting modifications. Needs custom camera solution.

## Key Files

- `game.ServerStorage.BanditGun.GunServer` — `consecutiveShots` tracking, `SPREAD_PER_SHOT=0.5`, `MAX_SPREAD=5`, `SPREAD_RESET_TIME=1.0`, spread applied before raycast in `fireShot()`

## Self-Check: PARTIAL

- [x] consecutiveShots tracking in GunServer
- [x] Spread resets after 1.0s pause
- [x] First shot always accurate (spread = 0)
- [x] Max spread capped at 5 degrees
- [x] PlayerRemoving cleanup for consecutiveShots
- [ ] Camera recoil kick (deferred)
- [ ] Smooth camera recovery (deferred)
