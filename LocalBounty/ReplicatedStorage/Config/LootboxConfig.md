---
tags: [shared, modulescript, config, lootbox, economy]
path: game.ReplicatedStorage.Config.LootboxConfig
type: ModuleScript
lines: 176
---

# LootboxConfig

Tuning data for the lootbox chests: price, tier odds, pity thresholds, the per-stage drop table, the item pools, the super-chest pool and the duplicate refund rate. **Bounty-only** — not on the mirrored-module list; Redwater never opens a chest.

## What it does
1. `PRICE_TOKENS` (100) — one standard chest. A purchase **banks** a chest (`Lootboxes.Unopened += 1`); nothing opens on purchase
2. `BASE_ODDS` — the tier roll before pity (52 / 30 / 14 / 3.2 / 0.8), and the pity rules that lift it: `PITY_EPIC_THRESHOLD` 20 chests without Epic+ forces the next Epic+ (`PITY_EPIC_LEGENDARY_SHARE` 0.2 of those Legendary); `PITY_LEGENDARY_THRESHOLD` 100 without a Legendary forces one. Every standard chest counts, free or bought; super chests sit outside the system
3. `DISPLAYED_ODDS` — what the odds panel paints: the **effective** rates once pity is folded in (50 / 29 / 14 / 5 / 2), measured by a 1e6-open simulation on 2026-09-03. Deliberately not equal to `BASE_ODDS`; re-run the simulation and update this table whenever the base odds or a threshold changes
4. `DROPS` — one row per stage; the stage reached IS the tier and drags lower-tier filler with it, so stage 1 is exactly one Common (the guaranteed-item rule). `tierCount` / `fillerCount` are `{ min, max }`
5. `POOLS` — per-tier allowlist of categories (`cash`, `tokens`, `potion`, `emote`, `title`, `heroSkin`, `weaponSkin`), each with a `weight`. The service picks a category by weight then uniformly within it. Emotes are listed by predicate (`EmoteConfig.isPurchasable`) and live in Rare only; titles are the 17 purchasable ids split Uncommon / Rare / Epic by judgement rather than price; the 10 skins are tiered by judgement too (`Frostpiercer` Legendary beside `Icefang` / `FrozenHand` Epic). `HellFire`, `BetaRevolver`, `PrestigeCard` and `Wraith` are excluded by rule and the service's asserts refuse them even if listed
6. `SUPER_WEAPON_SKINS` — the tutorial super chest's guaranteed skin pool: `Icefang`, `Frostpiercer`, `FrostbiteGrudgekeeper` (three, not four: `HellFire` is a pass reward). `SUPER_FILLER_COUNT` 3 items from `SUPER_FILLER_TIERS` with every skin category stripped
7. `DUPLICATE_REFUND_RATE` 0.35 of shop price, floored in the service before Wallet (which rounds half-up). `REMOTE_COOLDOWN` 0.5s per-player debounce on the open / purchase remotes

## Dependencies
- **Requires:** Nothing
- **Required by:** LootboxService, ChestController

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
