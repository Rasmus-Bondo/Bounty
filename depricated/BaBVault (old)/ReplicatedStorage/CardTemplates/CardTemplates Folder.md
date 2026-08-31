# CardTemplates Folder

MeshPart card models organized by rarity tier. Each card is a physical 3D mesh with decals for front/back art and a PointLight for glow effects. The Legendary card also has a SurfaceGui with a shimmer frame.

**Path:** `game.ReplicatedStorage.CardTemplates`
**Type:** Folder

## Contents

| Name | Class | Children | Notes |
|------|-------|----------|-------|
| BorderPart | MeshPart | — | Border glow mesh cloned around cards by [[CardEffects]] |
| Common | MeshPart | Decal, PointLight, CardReveal | 60% drop rate |
| Uncommon | MeshPart | Decal, PointLight, CardReveal | 20% drop rate |
| Rare | MeshPart | Decal, PointLight, CardReveal | 10% drop rate |
| Epic | MeshPart | Decal, PointLight, CardReveal | 4% drop rate |
| Legendary | MeshPart | Decal, PointLight, CardReveal, SurfaceGui(Shime) | 5% drop rate, special reveal animation |

## How Cards Work

1. [[CardRoller]] rolls a rarity using weighted random (see drop rates above)
2. [[CardRoller]] finds the matching template by name in this folder
3. [[CardFactory]] clones the template, adds highlight/border/legendary effects
4. [[CardAnimator]] handles fly-in, flip, and preview animations
5. [[CardController]] manages the full interaction lifecycle

## Referenced By

- [[CardRoller]] — `GetTemplateForRarity()` looks up templates by name
- [[CardController]] — references `BorderPart` for border glow effect
- [[CardFactory]] — clones template meshes to create card instances
