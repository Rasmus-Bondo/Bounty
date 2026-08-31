---
tags: [shared, modulescript, client]
path: game.ReplicatedStorage.Modules.FeaturedSequence
type: ModuleScript
lines: 1486
---

# FeaturedSequence

Client-side module that plays the Fortuna featured-hunter cinematic reveal sequence.

## What it does
1. `FeaturedSequence.Preload(shouldYield)` — preloads all assets (Fortuna model, cards, SFX, animations) via `ContentProvider:PreloadAsync`; safe to call multiple times (guards with flags)
2. `FeaturedSequence.Play(sequenceId)` — runs the full reveal: blink-open eyelid wipe → positions camera to `CameraPartFeatured` → spawns Fortuna model at stand → plays intro animation → shoots small flying cards → impact card throw → camera shake → closeup tween to `CameraPartFeaturedCheckPointCloseup` then `CameraPartFeaturedCloseup`
3. `FeaturedSequence.Cleanup()` — cancels any in-progress sequence, destroys all tracked instances and connections, stops audio tracks
4. Uses `sequenceId` guard so a new call immediately cancels mid-flight tweens from a previous call
5. Reads camera parts from `workspace.CameraFolder`, props from `workspace.FeaturedItems`, templates from `ReplicatedStorage.FeaturedItems`

6. **The three workspace props it reads must stay `ModelStreamingMode = Persistent`.** `Stand`, `Card` and `Rocks` sit under `workspace.FeaturedItems`, which is a **Folder** and therefore carries no streaming mode of its own — the mode lives on each child Model. All three were `Default` until 2026-08-03 while sitting ~480-490 studs from the lobby slots, which made `getStandTopPosition` warn `Stand model needs a PrimaryPart set.` on live clients **even though the PrimaryPart is authored** (it is `Union`, a UnionOperation). `Model.PrimaryPart` is a *reference to a descendant BasePart*, so it reads nil while the Model is replicated as an empty container — the property is not unset, there is simply nothing for it to point at. The `WaitForChild` chain that resolves them offers no protection whatsoever: `FeaturedItems` → `Stand` returns instantly on the container. A loose BasePart would have thrown an infinite-yield warning; a Model hides it. That asymmetry still holds now the top-level `FeaturedItems` lookup goes through [[WaitForRequired]] — the helper only changes *when* an unresolved wait reports (30s, not the engine's 5s), and a Model that resolves instantly as an empty container was never reporting in the first place. The consequence was a bail at line 802 and a visibly empty pedestal. `Rocks` has no authored PrimaryPart, which is fine because nothing reads it — but a streamed-out `rocksTemplate:Clone()` yields an invisible crater with no warning at all

## Dependencies
- **Requires:** [[WaitForRequired]] (everything else is read as workspace/RS instances directly)
- **Required by:** HuntersBuyController — deliberately **plain text, not a wikilink**. A `Required by:` wikilink points dependency → dependent, which is backwards; the caller's own file declares the `require()` and supplies the correct edge. Writing it on both sides only creates a reciprocal pair whose direction is decided by whichever the parser reached first

## Connections
### RemoteEvents
None.

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[WaitForRequired]] | `waitForRequired(parent, name)` | `Terrain`, `CameraFolder` and `FeaturedItems` off `workspace`, plus `Stand` / `Card` / `Rocks` off `FeaturedItems` (2026-08-15), without the engine's 5s "Infinite yield possible" warning. The three children needed it as much as the container did: `FeaturedItems` is a plain **Folder**, so it replicates empty and the Persistent Models inside arrive afterwards and independently. Required lazily inside `initialize()`, which is guarded by `initialized` and so resolves once |
