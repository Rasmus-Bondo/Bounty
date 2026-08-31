---
tags: [client, localscript, vesper, cosmetic]
path: game.StarterPlayer.StarterPlayerScripts.Vesper.HideLocalWorldSniper
type: LocalScript
lines: 65
---

# HideLocalWorldSniper

Hides the local player's own third-person world sniper cosmetic (`VesperWorldSniper`) so a Vesper player never sees their own world model clipping through the first-person view. Deliberately hunter-agnostic and always-on (no `SelectedHunter` gate) — it only ever touches a cosmetic named `VesperWorldSniper`, which only Vesper characters carry, so it self-gates by cosmetic name and keeps working through mid-match hunter selection changes.

## What it does
1. On the local player's character (now and on every `CharacterAdded`), looks for a `VesperWorldSniper` child and hides it: `LocalTransparencyModifier = 1` on parts, `Transparency = 1` on decals/textures, and disabled particles/beams/trails/lights
2. Watches the character's `ChildAdded` and the cosmetic's `DescendantAdded` (deferred) so streamed-in / late-replicated pieces are hidden too
3. Registers a [[HunterClientState]] teardown cleanup that disconnects its `CharacterAdded` listener — it sits in the cycled `Vesper` folder, so without this the loader's disable/re-enable on a swap would stack duplicate hiders

## Dependencies
- **Requires:** [[HunterClientState]] (teardown registry — cleanup only)
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientState]] | `.registerCleanup()` | Drop the CharacterAdded listener on a mid-match hunter swap |
