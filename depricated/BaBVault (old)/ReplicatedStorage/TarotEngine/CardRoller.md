# CardRoller

Weighted random rarity selection and template lookup for the card gacha system.

**Path:** `game.ReplicatedStorage.TarotEngine.CardRoller`
**Type:** ModuleScript
**Runs on:** Client

## Rarity Weights

| Rarity | Weight | Drop Rate |
|--------|--------|-----------|
| Common | 60 | ~60.6% |
| Uncommon | 20 | ~20.2% |
| Rare | 10 | ~10.1% |
| Epic | 4 | ~4.0% |
| Legendary | 5 | ~5.1% |

**Total weight:** 99

## Functions

| Function | Description |
|----------|-------------|
| `RollRarity()` | Weighted random selection from RarityWeights table. Returns rarity string. |
| `GetTemplateForRarity(rarity)` | Looks up the matching MeshPart in [[CardTemplates Folder]] by name |
| `RollTemplate()` | Combines both — rolls rarity, gets template. Returns `(template, rarity)` |

## Dependencies

- `ReplicatedStorage.CardTemplates` — folder containing rarity-named MeshPart templates

## Used By

- [[CardController]]`:SpawnLocalCards()` — calls `RollTemplate()` for each of 3 cards per pack
