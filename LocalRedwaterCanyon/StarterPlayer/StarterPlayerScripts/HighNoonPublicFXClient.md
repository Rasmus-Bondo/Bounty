---
tags:
  - client
  - localscript
  - vfx
  - audio
  - ultimate
  - dust
path: game.StarterPlayer.StarterPlayerScripts.HighNoonPublicFXClient
type: LocalScript
lines: 59
---

# HighNoonPublicFXClient

Ungated client listener that renders the world-visible High Noon FX (red caster highlight, eagle/mid world sounds, dust ring) for every player in the round — not just Dust players.

## What it does

1. Runs for every player; has no hero gate. The Dust-specific `HighNoonClient` is gated to Dust players only, so the public FX listener has to live in its own script — otherwise Fortuna/other-hunter players never see who is ulting
2. Constructs a single [[HighNoonPublicFX]] instance configured with `DustParticle` (from `ReplicatedStorage.Hunters.Dust.Objects`) plus `Eagle`, `Mid`, and `Start` sounds (from `ReplicatedStorage.Hunters.Dust.SFX.DustUltimate`). `Start` is the public warning cue, played at `StartWorldVolume = 0.8`
3. Listens on `HighNoonVisual.OnClientEvent` and dispatches:
   - `CasterStart` → `publicFX:StartCasterPublicUltimateFX(hunterPlayer, { SkipStartSound = hunterPlayer == localPlayer })` — spawns the red occluded `Highlight`, plays the start warning + eagle + looping mid world sounds, starts the dust ring. `CasterStart` is `FireAllClients`, so it reaches the caster too; they skip the world copy of the warning because HighNoonClient already plays that asset non-positionally for them
   - `CasterEnd` → `publicFX:StopCasterPublicUltimateFX(hunterPlayer)` — fades sounds, removes highlight, stops the dust ring
4. Ignores all other states (`Start`, `Locked`, `End`) — those are handled by `HighNoonClient` for the local Dust caster

## Dependencies

- **Requires:** [[HighNoonPublicFX]] (from `ReplicatedStorage.Hunters.Dust.Modules`)
- **Required by:** Nobody

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|--------------|
| `HighNoonVisual` | ← Server | [[HighNoonModule]] broadcasts `CasterStart`/`CasterEnd` via `FireAllClients` |

### BindableEvents
None

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[HighNoonPublicFX]] | `.new()`, `:StartCasterPublicUltimateFX()`, `:StopCasterPublicUltimateFX()` | World-visible FX rendering (red highlight, eagle/mid sounds, dust ring) |
