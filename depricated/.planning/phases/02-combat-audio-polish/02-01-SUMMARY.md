---
phase: 02-combat-audio-polish
plan: 01
status: complete
started: "2026-03-29T00:00:00Z"
completed: "2026-03-29T00:15:00Z"
---

# Summary: Fix Positional Audio System

## What Was Built

Converted the gun audio system from non-positional (tool-level) playback to fully positional 3D audio using MuzzleAttachment and InverseTapered rolloff. Added client-predicted fire sound for instant shooter feedback and material-specific impact sounds at hit locations.

## Tasks Completed

1. **Server-side positional gunfire** — Rewrote `playSound()` to clone sounds onto MuzzleAttachment with RollOffMode=InverseTapered, MinDistance=10, MaxDistance=200. Cleanup via Debris.
2. **Client-predicted fire sound** — Added immediate fire sound clone in Tool.Activated before RemoteEvent, giving the shooter zero-latency audio feedback.
3. **Material-specific impact sounds** — Created `MATERIAL_SOUND_MAP` covering 18 material types mapped to 5 sound categories (Wood, Brick, Glass, Sand, Stone). Added `playImpactSound()` that creates temporary positioned attachments at hit locations.

## Key Files

- `game.ServerStorage.BanditGun.GunServer` — Positional playSound, material detection, impact sound system
- `game.ServerStorage.BanditGun.GunClient` — Client-predicted fire sound in Tool.Activated
- `game.ReplicatedStorage.SFX.BrickImpact` — New sound object
- `game.ReplicatedStorage.SFX.GlassImpact` — New sound object
- `game.ReplicatedStorage.SFX.SandImpact` — New sound object
- `game.ReplicatedStorage.SFX.StoneImpact` — New sound object

## Deviations

- Impact sounds use placeholder Roblox audio asset IDs. User should test and swap with preferred audio assets if needed.
- Kept `emitWoodImpactEffects` for wood particles (Plan 02-03 will generalize particles to all materials).

## Self-Check: PASSED

- [x] RollOffMode.InverseTapered in GunServer playSound
- [x] RollOffMinDistance = 10 in GunServer
- [x] RollOffMaxDistance = 200 in GunServer
- [x] MuzzleAttachment used for sound parenting
- [x] Debris:AddItem for cleanup
- [x] Client-predicted fire sound in GunClient Tool.Activated
- [x] Material detection via MATERIAL_SOUND_MAP
- [x] playImpactSound creates temporary Attachment at hitPosition
- [x] 4 new Sound objects in ReplicatedStorage.SFX
