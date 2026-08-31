---
tags: [server, modulescript, codes, economy]
path: game.ServerScriptService.PlayerServices.CodeRedemptionService
type: ModuleScript
lines: 166
---

# CodeRedemptionService

Validates and grants rewards for player-entered redemption codes from the settings panel (Bounty lobby copy).

## What it does
1. Holds a hardcoded `CODES` table mapping an uppercased code string to a reward, supporting `cash`, `tokens` and/or `weaponSkin` per code
2. `weaponSkin = { hunter, name, title }` unlocks a gun skin; `hunter` and `name` are the instance names the profile stores, `title` is only the confirmation copy. Since 2026-08-27 this is the entire supply of a code-only skin — SkinCatalog's `CodeOnly` flag is the shop label and grants nothing. A code with no currency at all is valid
3. Gates each entry on an optional `active` flag and an optional `startsAt`/`expiresAt` window in UTC epoch seconds (`os.time()` is UTC on every server, so the intended local time is spelled out in a comment beside each value)
4. Reports a switched-off or not-yet-open code as "That code isn't valid.", so an unreleased code leaks nothing to players guessing at it; a code at or past `expiresAt` reports as expired instead. A code with no `startsAt` opens the moment the place is published, so a publish that slips past its `expiresAt` ships it already dead
5. On `RedeemCodeRequest`, normalizes the code and validates that it resolves and is not already in `data.RedeemedCodes`
6. On success, marks the code redeemed, then grants `reward.weaponSkin` via [[DataService]] `GrantWeaponSkin` (which resends `SkinDataEvent`, so the Trading Post card flips CODE ONLY → OWNED without a rejoin) and awards `reward.cash` and/or `reward.tokens` via [[Wallet]] `award` (economy Source, reason `code`), calling `updateLeaderstats` only when currency actually moved
7. Replies over `RedeemCodeResponse` with a success/failure message naming each currency granted and each skin unlocked

The `CODES` table and its gate are kept identical with the Redwater Canyon and Frostbite Claim copies of this module. `RedeemedCodes` is shared profile state and the settings panel is reachable in all three places, so a code listed in only one reads as invalid in the others. The award plumbing below the table is place-specific and deliberately differs: this copy has a shop to keep in sync, so it routes the skin grant through DataService rather than writing the profile directly.

## Dependencies
- **Requires:** [[DataService]], [[Wallet]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RedeemCodeRequest` | ← Client | [[SettingsController]] requests a code redemption |
| `RedeemCodeResponse` | → Client | Result message back to [[SettingsController]] |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()`, `GrantWeaponSkin()`, `updateLeaderstats()` | Read/write profile, unlock a `weaponSkin` reward, sync leaderstats |
| [[Wallet]] | `award()` | Award the code's Cash/Tokens as an economy Source (reason `code`) |
