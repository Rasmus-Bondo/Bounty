---
tags:
  - client
  - localscript
  - combat
  - animation
  - dust
path: game.StarterPlayer.StarterPlayerScripts.Dust.WorldRevolverAimIdleClient
type: LocalScript
lines: 280
---

# WorldRevolverAimIdleClient

Plays a looping aim-idle animation on every other Dust player's third-person world-model revolver. Phase 3 moved under `StarterPlayerScripts.Dust/` and migrated its gate to [[HunterGate]].

## What it does
1. Exits immediately via `HunterGate.IsHunter(player, "Dust")` if the local player isn't on Dust — only Dust players see this on others
2. For every player, first checks via `Players:GetPlayerFromCharacter` + `HunterGate.IsHunter(owningPlayer, "Dust")` that the character's own owning player is actually on Dust before doing anything else — skips silently otherwise (fixes a bug where non-Dust characters, e.g. Fortuna players, would retry for 8s and log a spurious "Aim idle failed after retries" warning since their `WorldRevolverCosmetic` never gets attached server-side)
3. For characters that pass the check, waits for their `WorldRevolverCosmetic` part (created server-side) and plays Dust's world `Idle` clip — resolved once at boot from the Dust manifest via `HunterAnimations.id("Dust", "World", "Idle")`; this was one of the FOUR files carrying the same string literal — on their Humanoid's Animator
4. Retries playback up to 80 times (0.1s apart) if the cosmetic or Animator isn't ready yet
5. Stops the track on death, character removal, or if the local player's own `SelectedHunter` attribute changes away from Dust
6. Re-evaluates all in-game characters whenever the local player's `SelectedHunter` attribute changes (uses an inline `isDustSelected` helper, not [[HunterGate]] for this recurring check — read-only attribute access, no need to yield)

## Dependencies
- **Requires:** [[HunterGate]], [[HunterClientState]], [[HunterAnimations]] (from `ReplicatedStorage.Hunters.Shared`), [[AnimationLoader]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterGate]] | `HunterGate.IsHunter(player, "Dust")` | Gate the whole stack, and skip a character whose owner is not Dust |
| [[HunterClientState]] | `HunterClientState.registerCleanup()` | Mid-match hunter-switch teardown: stop every active track and drop the player / character / attribute listeners on a swap away from Dust |
| [[AnimationLoader]] | `AnimationLoader.load()` | Load the aim idle only once the clip is confirmed fetched. This is the original failure: a bare `pcall` reported success for a clip that never downloaded, so the retry loop in `setupCharacter` exited on pass 1 and Dust held the revolver in his default pose for the rest of the life |
| [[AnimationLoader]] | `AnimationLoader.prewarm()` | Warm the clip at script start so the first spawn does not pay the fetch inside the retry loop |
| [[HunterAnimations]] | `HunterAnimations.id()` | Resolve the world Idle clip id from the Dust manifest |
