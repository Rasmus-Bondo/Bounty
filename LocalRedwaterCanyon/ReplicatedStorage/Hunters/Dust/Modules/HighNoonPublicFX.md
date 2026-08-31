---
tags: [client, modulescript, vfx, audio, ultimate]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonPublicFX
type: ModuleScript
lines: 366
---

# HighNoonPublicFX

OOP world-visible effects for the HighNoon ultimate, seen by all players (not just the caster).

## What it does
1. Shows a red Highlight on the caster's character (occluded depth mode) so other players see who is ulting
2. Plays positional world sounds on the caster's root part: the `Start` warning cue on the cast frame, the eagle cry at 0.55s, and the looping mid-atmosphere fading in from 0.1s
3. The `Start` cue is the gameplay warning that a High Noon is winding up — it gets its own `ConfigureWarningSound` rolloff (min 60 / max 220 / emitter 60) so anyone the ultimate can reach hears it in time to break line of sight. The caster's client passes `SkipStartSound` because it already plays the same asset non-positionally through HighNoonLocalSFX
4. Ambient layers use `ConfigureWorldSound` (min 12 / max 180) — the max matches `HighNoonServerConfig.Targeting.Range`, so a caster can't execute someone standing outside the ultimate's own audio footprint
5. One-shot cues outlive the cast: `RemoveWorldUltimateSounds` fades only looped sounds unless `stopOneShots` is passed (a restart does), and one-shots self-destruct on `Ended`. Without this a short cast window — a bot's is exactly `LockInTime` — clipped the eagle and start cues mid-cry
6. Spawns continuous dust particle effects in a ring around the caster (10-25 stud radius)
7. Dust particles emit every 0.12s at random angles with configurable height offset
8. `StartCasterPublicUltimateFX` activates all three effects and forwards an options table; `StopCasterPublicUltimateFX` cleans them all up
9. Per-caster token system allows multiple players to use HighNoon simultaneously
10. `GetCasterCharacter` accepts either a `Player` (resolves `.Character`) or a bare `Model`. The Model branch is what lets bots reuse this module — BotVisualClient requires it and passes a bot's local visual model, so bot High Noon looks and sounds identical to a player's

## Dependencies
- **Requires:** Nothing
- **Required by:** HighNoonPublicFXClient (ungated, runs for every player) and BotVisualClient (Dust bot ultimates). Previously required by `HighNoonClient` — moved out so non-Dust players also see the caster highlight, eagle/mid world sounds, and dust ring (that require no longer exists in code; plain text so the graph doesn't carry a dead edge).

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
