---
tags: [client, localscript, world-model, animation, bram]
path: game.StarterPlayer.StarterPlayerScripts.BramWorldIdleClient
type: LocalScript
lines: 231
---

# BramWorldIdleClient

Plays Bram's looping third-person Grudgekeeper hold on every Bram player's character, as seen by every client. Bram's counterpart to FortunaCardsWorldIdleClient and WorldRevolverAimIdleClient.

## What it does
1. For every player in the server, watches for a character carrying the `GrudgekeeperWorldCosmetic` prop (attached server-side by GrudgekeeperWorldVisualServer) and plays Bram's world `Idle` clip — resolved once at boot from the Bram manifest via `HunterAnimations.id("Bram", "World", "Idle")` — looped on that character's Humanoid Animator at Action priority.
2. Gated on the owning player's `SelectedHunter == "Bram"` attribute, so a mid-match hunter switch starts or drops the hold.
3. Runs a 0.35s watchdog per character instead of a fire-once retry: the hold is what a character loses to a streamed-in rig, a late cosmetic, or a client-side re-Animate, so it has to re-arm itself. Playback returns early once the track is playing, so the steady state is two field reads per interval.
4. Stops the track on death, character removal, hunter switch, and player leaving, so a corpse or a swapped hunter is never left cradling the shotgun.

**Why this exists:** GrudgekeeperWorldVisualServer plays the same clip server-side, but a *player* character's Animator is owned by that player's own client, so the server's looped hold does not reliably hold on other people's screens — every hunter with a long gun needs this client-side twin. Bots are server-owned rigs, so BotController's server-side world idle track is enough for them; that asymmetry is why bot Brams held the gun forward while real Brams did not.

It lives at the top level of `StarterPlayerScripts`, **not** in the `Bram` folder, because it must run on every client including players who are not Bram — HunterClientLoader would otherwise disable it. The clip id comes from the manifest (the one home of clip identity); the WorldAnimations folder is an unread leftover until Phase 2 deletes it.

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
| [[AnimationLoader]] | `AnimationLoader.load()` | Load the Grudgekeeper hold only once the clip is confirmed fetched. An honest false return is what turns the existing watchdog into a real retry loop — it used to treat the empty-handed pose as the settled state |
| [[AnimationLoader]] | `AnimationLoader.prewarm()` | Warm the clip at script start so the first Bram spawn does not pay the fetch inside a watchdog tick |
| [[HunterAnimations]] | `HunterAnimations.id()` | Resolve the world Idle clip id from the Bram manifest |
