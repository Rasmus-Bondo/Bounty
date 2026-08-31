---
tags: [client, localscript, world-model, bram]
path: game.StarterPlayer.StarterPlayerScripts.Bram.HideLocalWorldGrudgekeeper
type: LocalScript
lines: 67
---

# HideLocalWorldGrudgekeeper

Hides the local player's own replicated Grudgekeeper world model in first person, so a Bram player doesn't see their third-person shotgun clipping through the camera. Mirrors Vesper's HideLocalWorldSniper.

## What it does
1. Watches the local character for a child named `GrudgekeeperWorldCosmetic` (the cosmetic GrudgekeeperWorldVisualServer attaches) and hides it locally: `LocalTransparencyModifier = 1` on every BasePart, `Transparency = 1` on Decals/Textures, `Enabled = false` on emitters/beams/trails/lights. `LocalTransparencyModifier` is client-only, so other players still see the shotgun.
2. Re-hides on `CharacterAdded` and via `ChildAdded`/`DescendantAdded` so a late-attached or streamed-in cosmetic is caught.
3. Runs for everyone but only acts when the local character actually carries the cosmetic (i.e. the local player is Bram). Registers a [[HunterClientState]] cleanup so the mid-match hunter-switch disable/re-enable cycle doesn't stack duplicate hiders.

## Dependencies
- **Requires:** [[HunterClientState]] (from `ReplicatedStorage.Hunters.Shared`)
- **Required by:** Nobody (self-running LocalScript)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientState]] | `.registerCleanup()` | Drop CharacterAdded listeners on a mid-match hunter switch so hiders don't stack |
