---
tags: [server, modulescript, economy, dev-only]
path: game.ServerScriptService.PlayerServices.TesterGrantService
type: ModuleScript
lines: 251
---

# TesterGrantService

Holds the external playtester accounts at 999,999 Cash and 999,999 Tokens on every join, and unlocks the cosmetics no balance can buy, in the DEV universe only.

## What it does
1. `Start()` returns immediately unless `GameEnvironment.env == "Dev"`. The gate is the env string, not `not isLive` and not an `IsStudio` check — `"Unknown"` is what an unpublished place resolves to, and paying out there would write into whatever universe that file actually belongs to
2. `FORCE_IN_STUDIO` (default `false`) is ANDed with `RunService:IsStudio()`, so a `true` left in by accident is inert on every published server, DEV and live alike. In a Studio playtest of a **live** place file it does write the real live profile of whoever is signed in, because Studio has no separate DataStore
3. Matches testers by **UserId**, held in the `TESTERS` table with their username and display name as trailing comments. Usernames are changeable and a display name is not an identifier at all, so neither is ever compared
4. On join (and for anyone already present when `Start()` runs), polls `DataService.getPlayerData` for up to 10 s — DataService loads profiles from its own `PlayerAdded` and this one can win that race
5. **Tops up rather than granting**: awards only the shortfall to `TARGET_BALANCE` in each of Cash and Tokens. A tester who spent everything is rich again on their next join with no manual action; one who somehow has more keeps it; one already at target triggers no Wallet call and no analytics event at all
5a. **Unlocks the cosmetics currency cannot buy** (2026-09-19). Three explicit allowlists — `TESTER_HUNTERS`, `TESTER_HUNTER_SKINS`, `TESTER_WEAPON_SKINS` — granted on every join: 1 hunter, 3 hunter skins and 5 weapon skins, nine unlocks on a fresh tester profile. Currency alone stopped being enough once the pass had exclusive skins: a Bounty Pass skin carries no price and every purchase handler refuses it, so 999,999 Tokens still could not reach one without grinding the pass to its level. Deliberately an allowlist and not "everything in the folder" — a tester buying a shop skin with the balance above exercises the purchase path, and a blanket grant would hide it. Fortuna is listed because she is the only hunter not owned from day one and `InfernoHand` cannot be equipped, rendered or seen in Collection without her
5b. **Two grant paths, because the places do not agree on the API.** Bounty's DataService owns `GrantCharacter` / `GrantHunterSkin` / `GrantWeaponSkin`, and routing through them is what re-sends `SkinDataEvent` so a Collection tile unlocks without a rejoin. The match places run a slimmer DataService with **no `Grant*` functions at all**, so there the profile fields are written directly — the same thing the live grant sites do, since cosmetics are not chokepointed the way [[Wallet]] chokepoints currency, and a match place has no shop UI to refresh. Ownership is tested before granting rather than relying on the grants being idempotent, so the log line lists what actually changed
6. Pays through `Wallet.award` with the reason `dev_tester_grant`, never by writing `data.Cash` / `data.Tokens`, then calls `DataService.updateLeaderstats` so the Cash/Token chips update without a rejoin
7. Mirrored VERBATIM across Bounty, Redwater Canyon and Frostbite Claim — a tester can land in any of the three first (the lobby normally, a match place directly when they follow a friend in), so whichever one they hit has to be the one that pays

## Dependencies
- **Requires:** [[GameEnvironment]], [[DataService]], [[Wallet]]
- **Required by:** Main

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `GameEnvironment.env`, `.place` | The DEV-only gate, and the place name in the boot log line |
| [[DataService]] | `DataService.getPlayerData()`, `DataService.updateLeaderstats()`, `GrantCharacter()`, `GrantHunterSkin()`, `GrantWeaponSkin()` | Reach the joining player's profile table, push the new balances to the leaderstats the currency chips read, and unlock the tester cosmetics. The three `Grant*` calls are guarded by a `type(...) == "function"` check: only Bounty's DataService defines them |
| [[Wallet]] | `Wallet.award()` | The sole currency mutator — awards the shortfall and logs the economy Source event |
