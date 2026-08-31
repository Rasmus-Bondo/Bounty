---
tags: [client, localscript, ui, combat]
path: game.StarterPlayer.StarterPlayerScripts.HitMarkScript
type: LocalScript
lines: 526
---

# HitMarkScript

Client-side hitmarker and crosshair system. Displays hit confirmation feedback with animated triangles, screen shake, kill skulls, and sounds.

## What it does

### Crosshair
- Persistent dot at screen center, hides mouse cursor
- Pulses on hit (grows then shrinks), turns red on headshot

### Hitmarker
- Three triangles in a triangular pattern that expand outward on hit
- Headshots: red color, glow flash, screen shake, longer hold time
- Hit stacking: rapid hits increase triangle spread and stretch (up to 6 stacks, decays after 0.55s)

### Kill Skull
- On kill: skull icon expands with Back easing, holds, then splits into upper/lower halves that fly apart and fade
- Different colors for body kill vs headshot kill

### Sound
- Layered hit sounds: primary + body/headshot layer with randomized pitch
- Different sounds for headshot vs body hit

### Flash
- Semi-transparent flash frame pulses behind crosshair on hit

## Dependencies

- **Requires:** Nothing
- **Reads from:** `ReplicatedStorage.GuiTemplates.GunGui` or `StarterGui.GunGui`

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|-------------|
| `HitConfirm` | ← Server | Fired by [[RevolverModule]] on revolver hits and [[HighNoonModule]] on ultimate hits |
