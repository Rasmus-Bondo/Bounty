---
tags: [shared, modulescript, config, cosmetics, group]
path: game.ReplicatedStorage.Config.GroupPerkConfig
type: ModuleScript
lines: 57
---

# GroupPerkConfig

The one client-readable source of truth for skins granted free to Outlaw Syndicate members.

## What it does
1. Declares `GroupId` (`647193849`, the Outlaw Syndicate) — passed to `Player:IsInGroup` on the server and to `GroupService:PromptJoinAsync` by the JOIN GROUP button on the client. Carries **no URL**: the join happens in-experience.
2. Declares `Skins`, a `[hunterName] = { [skinName] = true }` map. Currently `Dust = { Wraith = true }`.
3. Exposes `isGroupSkin(hunterName, skinName)` — true when a skin is granted by group membership rather than sold. Nil-safe on both arguments: callers pass values straight off a selection that may be nil before the first grid build, and reading a table with a nil key is legal in Lua (only writing one throws).

## Why it exists
Created 2026-08-12. "Wraith is a group perk, not a purchase" was previously written **three independent times** — DataService's `GROUP_UNLOCK_SKINS` (server-only), HuntersBuyController's `SKINS` table entry (`GroupUnlock = true`, a private local of one ScreenGui) and CollectionClient's inline `name == "Dust" and skin == "Wraith"` comparison. The Collection menu could reach **none** of them, so its shared EQUIP button fell through to **`PURCHASE`** on a skin that cannot be bought at any price in any currency. Adding the next group skin is now one edit here.

⚠ **Bounty-only, deliberately.** Redwater Canyon has no group code at all — the grant runs once at profile load in the lobby and the profile carries it from there. This is **not** one of the mirrored shared modules and must not be copied into Redwater; doing so would add a mirror nothing reads and that `/preflight` would then have to keep in sync forever.

⚠ **The grant is one-way and permanent.** `grantGroupSkins` only ever writes `true` and nothing anywhere clears it, so a player who joins the group and later leaves **keeps** the skin. That is intended. If revocation is ever added it must clear the equipped pointers itself — `sanitizeEquippedSelection` validates the equipped skin with `skinExists()`, which only checks the model is present under `ReplicatedStorage.Characters.<Hunter>.Skin.<Skin>` and **never consults ownership**, so a revoked skin would keep being worn with nothing to repair it.

## Dependencies
- **Requires:** Nothing
- **Required by:** DataService, HuntersBuyController, Shop, CollectionClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
