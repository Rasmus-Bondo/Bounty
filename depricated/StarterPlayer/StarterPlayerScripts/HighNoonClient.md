---
tags: [client, localscript, combat, ultimate]
path: game.StarterPlayer.StarterPlayerScripts.HighNoonClient
type: LocalScript
lines: 1529
---

# HighNoonClient

Client-side ultimate ability handler. Manages the full High Noon experience: activation, FOV cinematics, target UI, SFX, VFX dust, and shot visuals.

## What it does

### Activation
- F key or mobile button activates when charge is full (100)
- Sends `HighNoonRequest:FireServer()` with aim direction
- Sends aim updates to server every 80ms during active ultimate

### FOV Cinematics
- Zoom out to 78 FOV over 0.6s (cubic bezier easing)
- Then zoom in to 44 FOV over 2.1s
- Returns to default FOV over 0.85s on end

### Target UI
- Clones `ReplicatedStorage.DustUltimateTarget` billboard onto each target
- Lock-in phase: shrinking frame around target
- Locked phase: skull mark replaces frame
- Highlights targets with orange outline (AlwaysOnTop depth mode)

### Sound Design
- Local caster sounds: Start, Whistle, looping Mid atmosphere
- World/positional sounds for other players: Eagle cry, Mid atmosphere on caster's character
- Pooled fire sounds (8 instances) for rapid shot playback

### VFX
- Dust particles spawned around caster at random angles (10-25 stud radius)
- Red highlight on caster visible to other players
- Muzzle flash and laser beam on each shot

### Charge UI
- Listens to `HighNoonChargeUpdate` from server
- Updates `TemplateGameGui > Canvas > UltimateFrame > Ultimate > FrameBorderCooldown` fill
- Shows percentage text until full

### Mobile Support
- Creates invisible `MobileUltimateButton` over the ultimate UI frame
- Touch tap fires shot during active High Noon
- Retries button creation until TemplateGameGui exists

## Dependencies

- **Requires:** [[laserBeamEffect]] module from `ReplicatedStorage.Revolver`
- **Fires remotes:** `HighNoonRequest`, `HighNoonShootRequest`, `HighNoonAimUpdate`
- **Listens to remotes:** `HighNoonVisual`, `HighNoonShot`, `HighNoonChargeUpdate`
- **Fires bindable:** `HighNoonAimNudge` (consumed by [[HighNoonViewModelOrbit]])
- **Reads UI from:** `PlayerGui.TemplateGameGui` (created by HunterGuiClient)
