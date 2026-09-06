---
tags: [client, localscript, audio, bounty, music]
path: game.StarterPlayer.StarterPlayerScripts.BountyMusicClient
type: LocalScript
lines: 365
---

# BountyMusicClient

Local adaptive music and stingers for bounty ownership, bounty claims, and the final authored section of the round.

## What it does
1. **Bounty music** — starts a looped clone of `SFX.BountySFX.BountyPlaced` (2.8s fade in) when `BountyPlaced` names the **local** player, and fades it out over 1.2s on `BountyRemoved`. Every handler filters on `targetUserId ~= player.UserId` first, so only the hunted player hears their own theme.
2. **Bounty-ended stinger** — `playTailStinger` plays only the **last 5 seconds** of `BountyEnded` by seeking to `clipLength - tailDuration`, so the cue resolves rather than restarting a long piece that would be cut off.
3. **Claim stinger, alternating — RETIRED 2026-09-06, held behind `BOUNTY_STINGER_ENABLED = false`.** EyeCandy's `BOUNTY CLAIMED` header now plays `SFX.Reward.Bounty` on the same event for the same one player, and two stingers over one kill is noise — the new asset is 12.33s, long enough to still be sounding over the next two kills. Kept as a flag rather than deleted so the choice is one word to reverse; everything below still describes what runs if it is flipped back, and AnnouncementController's `playBountyStinger` call has to be dropped in the same pass. Original behaviour: `BountyClaimed` and `BountyClaimed2` alternate via `claimVariantIndex`, with `PlaybackSpeed` jittered ±2% so back-to-back claims never sound identical. Fired only when the killer is the local player, and **silent while the `workspace.TutorialMode` attribute is true** (2026-08-09): the onboarding lesson claims a bounty seconds after the ultimate's own stinger and the two stacked into noise over the kill the lesson most wants watched. Only this stinger is gated — the bounty track and the placed/ended cues still play, so the tutorial step still sounds like a real one.
4. **Round-ending music, synchronised to the clock, not to an event.** `tryStartRoundEndingMusic` runs off `RoundTime` value changes and seeks into `RoundEndingSoon` by `effectiveDuration - remaining` — so a **mid-round joiner drops into the correct point of the track** instead of starting it from the top. It takes over from the bounty music, fading that out over 2s.
5. **`ROUND_ENDING_AUDIBLE_TRIM` (6s) exists because the asset lies about its length.** `RoundEndingSoon` carries roughly six seconds of inaudible tail metadata, so `TimeLength` overshoots the musical ending. The effective duration is `TimeLength - 6`, which is what lands the audible finish at 0:00 rather than six seconds early.
6. **Preloads its five templates at boot and names what never arrived** (2026-08-13). A `task.spawn` runs `ContentProvider:PreloadAsync` over `BountyPlaced` / `RoundEndingSoon` / `BountyEnded` / `BountyClaimed` / `BountyClaimed2`, retries the failures once after 10s, then warns with the names and ids of anything still missing. Without it a failed CDN fetch is invisible — the clone plays a Sound with no data and the `TimeLength <= 0` guard below simply returns.
7. **`RoundActive` false is the master reset** — clears `hasLocalBounty`, fades both tracks out and clears `roundEndingStarted`, so the next round starts clean. On `RoundActive` true it re-evaluates both, which covers a joiner arriving mid-round. It ends with an `updateAmbientDuck()` that both branches fall through to, which is the only thing that lifts the duck once `roundEndingStarted` is cleared.
8. **Ducks the map's ambient music bed under every cue it starts** (2026-08-14). The map's own background track is an authored looping `Sound` under `Workspace` that this script neither starts nor stops; `updateAmbientDuck` fades it to 0 over 1.5s whenever `bountyMusic`, `roundEndingMusic` or `roundEndingStarted` is live and back to its authored volume over 3s when none is. The sound is found by the **`AmbientMusic` CollectionService tag**, not by name, because this file is mirrored verbatim into every match place and each map names its own track — an untagged map simply never ducks. Redwater's own `Wagon Trail Blues` is untagged and never plays; Frostbite Claim's `Hunt Beneath the Northern Sky` carries the tag.

## Audio routing
Every sound is a `:Clone()` of an authored template under `ReplicatedStorage.SFX.BountySFX`, so it **inherits that template's `SoundGroup`** and obeys the player's Music/SFX and Master sliders. Clones are parented to `SoundService` (non-positional, deliberately — this is the local player's own score, not a world sound) and destroyed by the fade tween's `Completed:Once`, so nothing accumulates across rounds.

The ambient bed is the one sound this script touches that it did **not** clone. It stays where the map authored it and only its `Volume` is written — the Sound keeps playing silently through a duck, so it needs no restart and stays in sync with every other client, and a client-side write to a replicated instance is local, so each player ducks their own mix only.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `BountyPlaced` | ← Server | [[BountyService]] starts the bounty track when the id is the local player |
| `BountyRemoved` | ← Server | [[BountyService]] stops the bounty track and plays the ended stinger |
| `BountyClaimed` | ← Server | [[BountyService]]; the claim stinger it drove is now flag-disabled, so this listener is inert until `BOUNTY_STINGER_ENABLED` is flipped back |

### BindableEvents
None

### Direct require()
None
