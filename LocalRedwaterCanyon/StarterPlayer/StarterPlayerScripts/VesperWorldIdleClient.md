---
tags: [client, localscript, world-model, animation, vesper]
path: game.StarterPlayer.StarterPlayerScripts.VesperWorldIdleClient
type: LocalScript
lines: 242
---

# VesperWorldIdleClient

Plays Vesper's looping third-person sniper hold on every Vesper player's character, as seen by every client. Vesper's counterpart to BramWorldIdleClient, FortunaCardsWorldIdleClient and WorldRevolverAimIdleClient.

## What it does
1. For every player in the server, watches for a character carrying the `VesperWorldSniper` prop (attached server-side by VesperWorldVisualServer) and plays Vesper's world `Idle` clip — resolved once at boot from the Vesper manifest via `HunterAnimations.id("Vesper", "World", "Idle")` — looped on that character's Humanoid Animator at Action priority.
2. Gated on the owning player's `SelectedHunter == "Vesper"` attribute, so a mid-match hunter switch starts or drops the hold.
3. Runs a 0.35s watchdog per character instead of a fire-once retry: the hold is what a character loses to a streamed-in rig, a late cosmetic, or a client-side re-Animate, so it has to re-arm itself. Playback returns early once the track is playing, so the steady state is two field reads per interval.
4. Stops the track on death, character removal, hunter switch, and player leaving, so a corpse or a swapped hunter is never left cradling the sniper.
5. Does **not** stand down while the player is scoped. The server's scope pose is Action3 and its shoot beat Action4, so both already outrank this Action-priority hold; suppressing on the `VesperWorldScoped` attribute would only matter when the server's scope track *also* failed to hold on this client, and would drop her to the stock R15 pose instead.

**Why this exists:** VesperWorldVisualServer plays the same clip server-side, but a *player* character's Animator is owned by that player's own client, so the server's looped hold does not reliably hold on other people's screens — every hunter with a long gun needs this client-side twin, and Vesper was the only one that never got one. Other players saw her arms hanging at her sides with the sniper dangling from one hand. Bots are server-owned rigs, so BotController's server-side world idle track is enough for them; that asymmetry is why a Vesper bot cradled the sniper while a Vesper player did not.

It lives at the top level of `StarterPlayerScripts`, **not** in the `Vesper` folder, because it must run on every client including players who are not Vesper — HunterClientLoader collects only the per-hunter folders, so a root script is never disabled by a swap. The clip id comes from the manifest (the one home of clip identity); the WorldAnimations folder is an unread leftover until Phase 2 deletes it. Gun skins reuse the `VesperWorldSniper` cosmetic name, so the Frostpiercer needs no separate case.

Mirrored byte-identical into Frostbite Claim, which has no vault of its own.

## Dependencies
- **Requires:** [[AnimationLoader]], [[HunterAnimations]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[AnimationLoader]] | `AnimationLoader.load()` | Load the sniper hold only once the clip is confirmed fetched. A bare `LoadAnimation` hands back a valid track while the clip is still downloading, so a failed fetch would read as success and the watchdog would settle on the empty-handed pose |
| [[AnimationLoader]] | `AnimationLoader.prewarm()` | Warm the clip at script start so the first Vesper spawn does not pay the fetch inside a watchdog tick |
| [[HunterAnimations]] | `HunterAnimations.id()` | Resolve the world Idle clip id from the Vesper manifest |
