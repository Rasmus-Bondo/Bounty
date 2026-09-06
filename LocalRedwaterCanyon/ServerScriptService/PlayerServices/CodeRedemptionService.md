---
tags: [server, modulescript, economy, persistence]
path: game.ServerScriptService.PlayerServices.CodeRedemptionService
type: ModuleScript
lines: 230
---

# CodeRedemptionService

Validates and grants rewards for player-entered redemption codes from the settings panel.

## What it does
1. Holds a hardcoded `CODES` table mapping code string to a reward, supporting `cash`, `xp`, `tokens`, `chests` and/or `weaponSkin` per code
2. `weaponSkin = { hunter, name, title }` unlocks a gun skin; `hunter` and `name` are the instance names the profile stores, `title` is only the confirmation copy. The shop lives in Bounty and its `CodeOnly` flag is a label that grants nothing, so this field is the entire supply of a code-only skin. A code with no currency at all is valid
3. Gates each entry on an optional `active` flag and an optional `startsAt`/`expiresAt` window in UTC epoch seconds (`os.time()` is UTC on every server, so the intended local time is spelled out in a comment beside each value)
4. Reports a switched-off or not-yet-open code as "That code isn't valid.", so an unreleased code leaks nothing to players guessing at it; a code at or past `expiresAt` reports as expired instead. A code with no `startsAt` opens the moment the place is published, so a publish that slips past its `expiresAt` ships it already dead
5. Handles `RedeemCodeRequest` from the client: normalizes the code (strips whitespace, uppercases)
6. Rejects empty input, codes that do not resolve, and codes already in the player's `RedeemedCodes` profile table
7. On success, marks the code redeemed in `data.RedeemedCodes`, writes any `weaponSkin` straight into `OwnedWeaponSkins[hunter][skin]` via a local helper, grants any Cash/XP through `ProgressionService.awardCodeRedemption()` and any Tokens through [[Wallet]] `award` (economy Source, reason `code`) followed by `updateLeaderstats`
8. `reward.chests` adds standard lootbox chests straight to `Lootboxes.Unopened` on the shared profile via a local helper — there is no LootboxService and nothing opens a chest in a match place, so the lobby's LOOT tab reports the new count on the next profile load, exactly as it does for the tutorial super chest TutorialDirector banks. `Unopened`, never `SuperUnopened`: these are ordinary chests and go through the pity system when they are opened
9. Fires `RedeemCodeResponse` back to the requesting client with `{success, message}` in all cases

The `CODES` table and its gate are kept identical with the Bounty and Frostbite Claim copies of this module. `RedeemedCodes` is shared profile state and the settings panel is reachable in all three places, so a code listed in only one reads as invalid in the others. The award plumbing below the table is place-specific and deliberately differs: this copy keeps Cash/XP on ProgressionService because that module owns the XP curve and the LevelUp fire, and the skin grant is a plain profile write rather than a DataService call — there is no `GrantWeaponSkin` and no `ReplicatedStorage.WeaponSkins` folder in a match place, and nothing re-reads `OwnedWeaponSkins` after the character is built, so a mid-match redeem lands on the next spawn or back in the lobby off the same shared profile.

## Dependencies
- **Requires:** [[DataService]], [[ProgressionService]], [[Wallet]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RedeemCodeRequest` | ← Client | [[SettingsController]] fires with the entered code text |
| `RedeemCodeResponse` | → Client | [[SettingsController]] shows the result message |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()`, `updateLeaderstats()` | Read/write `RedeemedCodes` and `OwnedWeaponSkins`, sync leaderstats after a Token award |
| [[ProgressionService]] | `awardCodeRedemption()` | Grant XP/Cash reward for a valid code |
| [[Wallet]] | `award()` | Award the code's Tokens as an economy Source (reason `code`) |
