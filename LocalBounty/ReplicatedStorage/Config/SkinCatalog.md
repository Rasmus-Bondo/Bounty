---
tags: [shared, modulescript, config, shop, skins, hunters]
path: game.ReplicatedStorage.Config.SkinCatalog
type: ModuleScript
lines: 297
---

# SkinCatalog

Bounty-only presentation catalog for the Trading Post: hunter copy, skin copy and token prices, and the gun-skin list per hunter. **Not mirrored** — it describes lobby shop copy, not gameplay.

## What it does
1. `HunterOrder` and `Hunters[name]` (`Title / Class / Description / Weapon / Free`; Fortuna carries `ProductKey = "FortunaHunter"` and `CashPriceKey = "Fortuna"` into StoreConfig)
2. `Skins[hunter]` — `{ Name, Title, Header, Description, TokenPrice }` per skin, in shop order
3. `WeaponSkins[hunter]` — index 1 is the default gun skin. An entry with **no** `TokenPrice` is not sold here; `CodeOnly = true` says a redemption code is the only supply (Dust's `BetaRevolver` since 2026-08-27) and is declared in this table rather than deferred to a config module the way group / pass / bundle / limited skins are, because the code table is server-only and the client cannot read it. The flag picks the shop LABEL and grants nothing
4. `getHunter / getSkin / getWeaponSkin / defaultWeaponSkinName / hunterFromLabel`
5. Consolidated from the per-hunter tables the old HuntersBuyController carried inline (migration 2026-08-23)

## Dependencies
- **Requires:** Nothing
- **Required by:** ShopState, ShopHuntersTab, ShopWeaponsTab

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
