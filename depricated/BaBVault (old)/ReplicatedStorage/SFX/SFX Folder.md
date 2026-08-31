# SFX Folder

Sound effect templates stored in ReplicatedStorage. Scripts clone these and parent them to the appropriate location for positional audio.

**Path:** `game.ReplicatedStorage.SFX`
**Type:** Folder

## Sounds

| Name | Used By | Purpose |
|------|---------|---------|
| RoundStart | [[RoundController]] | Plays when a new round begins |
| WoodImpactSound | [[GunServer]] | Bullet hits wood material |
| BrickImpact | [[GunServer]] | Bullet hits brick material |
| GlassImpact | [[GunServer]] | Bullet hits glass/window |
| SandImpact | [[GunServer]] | Bullet hits sand material |
| StoneImpact | [[GunServer]] | Bullet hits stone/concrete |
| CardFlip | [[CardController]] | Card flip animation sound |
| CardPick | [[CardController]] | Card dealt from deck sound |
| PreviewCard | [[CardController]] | Card moves to preview position |
| LegendarySound | [[CardController]], [[CardFactory]] | Looping legendary card hover sound |
| SatchelSound | [[CardController]] | Card collected into satchel |
| Cactus and Dust | — | Ambient western music track |
| Cinematic slow western blues | — | Music track |
| High Noon | — | Music track |

### Cosmetic (Subfolder)

| Name | Purpose |
|------|---------|
| RoundKill | Kill confirmation sound |
| Canyon Song - Sting 1 | Short musical sting |
| Release | Cosmetic release sound |

## Referenced By

- [[GunServer]] — clones impact sounds for material-based hit SFX
- [[CardController]] — references CardFlip, CardPick, PreviewCard, LegendarySound, SatchelSound
- [[CardEffects]] — `playSoundFromTemplate()` clones and plays any sound template
