---
tags:
  - client
  - localscript
  - gamemode
  - audio
  - teams
path: game.StarterPlayer.StarterPlayerScripts.DominationAudioClient
type: LocalScript
lines: 125
---

# DominationAudioClient

The two Domination objective cues — a pad claimed, a pad lost. Built 2026-08-23.

## What it does
1. Reads the same workspace attributes the HUD does and fires nothing of its own, so there is no
   remote and no server work: `DomOwner_<Letter>` flipping **is** the capture event, and every
   client already has it.
2. Client-side and relative, for the same reason the pad paint is: "claimed" and "lost" are the SAME
   attribute change seen from the two sides, so the sound cannot be chosen on the server without
   picking one team's word for it. A viewer with no team stamp (a spectator, or the sliver before
   assignment replicates) hears nothing rather than being told a side won something.
3. Owner transitions, from where the viewer stands. Landing on **yours** is always
   `ObjectiveClaimed`; anything else is `ObjectiveLost` only if you HELD the pad going in, so
   `before == own` is the whole test. Neutral to theirs is silent — nobody lost anything, and every
   pad on the map is neutral at the buzzer, so it otherwise fired three times in the opening seconds
   of a match (owner, 2026-08-23). Theirs to neutral is silent for a different reason: that is your
   own team half way through a steal, and the claim cue lands a few seconds later.
4. Distinguishes `nil` from `""`. `EndRound` **removes** the `Dom*` attributes, and reading that
   teardown as "every pad went neutral" would play a lost cue for each pad you held as the match
   ends, so a nil forgets the pad instead of firing.
5. Cues are **2D**, cloned from `ReplicatedStorage.SFX.Domination` into `SoundService` to play: a pad
   flipping is worth hearing from the far end of the map, which is exactly where a positional emitter
   on the pad would be silent. The clone carries the template's `SFX` SoundGroup, so it obeys the
   settings sliders. Each clone is destroyed on `Ended` and swept by `Debris` after `SOUND_LIFETIME`
   (10s) regardless — `TimeLength` is 0 until the asset loads, so it cannot size that.
6. Seeds `owners` from whatever is already published at startup, so a mid-round joiner adopts the
   current owners silently and only hears what happens after they arrive.
7. `play()` no-ops on a missing template or an empty `SoundId`, so an unfilled cue is silent rather
   than an error.

## No contested cue
There deliberately is not one (owner, 2026-08-23). A third cue was built alongside these two and cut
before a sound was ever chosen for it. Contested is the one pad state that flips repeatedly on its
own — every time the last defender steps off a pad and back on — so it needed a per-pad cooldown and
an "is this pad even mine" test just to stop it chattering through fights the viewer is not in, and
the capture dial already shows a stalled meter. `DomContested_<Letter>` is still published and still
drives the HUD's CONTESTED readout; nothing here reads it.

## Dependencies
- **Requires:** [[TeamView]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TeamView]] | `localTeam()` | Whether a flip reads as claimed or lost for this viewer |

Reads (no edges): the `DomOwner_<Letter>` and `Gamemode` workspace attributes published by
Gamemodes.Domination, the `ReplicatedStorage.RoundActive` BoolValue, and the two Sound templates in
`ReplicatedStorage.SFX.Domination` — both `Volume = 2.5`. They had been at
Roblox's default 0.5; 2.0 (the level `OnboardingSFX.ObjectiveComplete` uses) was still hard to hear
over gunfire, so these sit above it deliberately.
