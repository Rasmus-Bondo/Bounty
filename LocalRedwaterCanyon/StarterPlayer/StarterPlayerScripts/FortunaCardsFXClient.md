---
tags:
  - client
  - localscript
  - vfx
  - audio
  - fortuna
  - cards
path: game.StarterPlayer.StarterPlayerScripts.FortunaCardsFXClient
type: LocalScript
lines: 737
---

# FortunaCardsFXClient

Plays the visible flying-card VFX and 3D throw/recall/ultimate sounds for every Fortuna player's cards, for all clients (not gated to Fortuna players — it just reacts to remotes that only fire for Fortuna casts).

## What it does
1. Listens to `CardFlyFX` (basic/Ability1/Ultimate throws), `CardRecallFX` (cards returning to a player), and `CardThrowVFX` (`"UltimateVanish"`) remotes
2. Spawns a cloned, trail-attached visual card and animates it along a quadratic Bezier curve from origin to target (curve amount, vertical lift, and spin speed all vary by visual style: Basic/Ability1/Ultimate/Recall), fading it out near the end of the flight and destroying it
3. Plays throttled, pitch-varied 3D positional sounds per style (fling/whoosh/multi-throw for basic, ability sound for recall, ultimate sound for vanish) so rapid-fire throws don't sound like a stutter
4. On Ultimate vanish: emits a ring of 10 particle bursts around the caster's position (skipped for the local caster, who sees their own first-person vanish FX separately) plus the ultimate sound
5. Assigns every cloned card SFX (fling/whoosh/multi-throw/ability/ultimate) to the `SoundService.SFX` `SoundGroup` in `play3DSound` so SettingsController's SFX Volume slider attenuates card sounds alongside gunshots and footsteps

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `CardFlyFX` | ← Server | Fired by [[CardsServer]] on every card throw |
| `CardRecallFX` | ← Server | Fired by [[CardsServer]] on card recall |
| `CardThrowVFX` | ← Server | Fired by [[CardsServer]] on ultimate vanish |

### BindableEvents
None

### Direct require()
None
