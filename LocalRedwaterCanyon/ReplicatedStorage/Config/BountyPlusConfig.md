---
tags: [shared, modulescript, bountyplus, gamepass, config, economy]
path: game.ReplicatedStorage.Config.BountyPlusConfig
type: ModuleScript
lines: 103
---

# BountyPlusConfig

Shared catalog for the BOUNTY+ game pass — the id, the perk percentages, the one-time grant, and the pure helpers every reader goes through. Mirrored verbatim across all three places (this is the 21st module on that list).

## What it does
1. Exports `GamePassId = 1968529393` — a GAME PASS, not a developer product: the id resolves only as `Enum.InfoType.GamePass`, and the pass's own `ProductId` field (3711612302) is a decoy that must never be prompted with
2. Exports `Attribute = "OwnsBountyPlus"` — the player attribute the server stamps once ownership resolves; nil means "not answered yet" and must read as not-owned everywhere
3. Exports `ProfileKey = "BountyPlus"` — the profile stamp `{ Owned, Granted, GrantedAt, TokensPaid, ChestsPaid, TitlesPaid }`
4. Exports the perks: `XPBonusPercent = 25`, `CashBonusPercent = 10`, and `Grant = { Tokens = 1000, Chests = 5 }`
5. `bonusFraction(owns, kind)` — the additive term for one earn kind (`"xp"` / `"cash"`) as a fraction, 0 when not owned; nil-safe on `owns`. Only `xp` and `cash` are mapped, which is what keeps Tokens unboosted by construction rather than by each caller remembering
6. `apply(owns, kind, amount)` — the boosted amount, and the ONE place rounding happens (half-up), so the number a client draws and the number the server banks cannot disagree
7. `dataOwns(data)` — ownership as the server sees it, off the profile stamp. In this place BoostService reads it; the lobby resolves and writes the stamp, so the answer is normally already on the shared profile by the time anyone reaches a match
8. `playerOwns(player)` — ownership as the client sees it, off the attribute
9. The stack is ADDITIVE: a 25% potion plus the pass is x1.50, not x1.5625

## Dependencies
- **Requires:** Nothing
- **Required by:** BoostService (the third additive term in getMultiplier, and the join-time ownership upgrade)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
