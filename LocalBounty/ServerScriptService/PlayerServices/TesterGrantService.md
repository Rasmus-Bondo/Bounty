---
tags: [server, modulescript, economy, dev-only]
path: game.ServerScriptService.PlayerServices.TesterGrantService
type: ModuleScript
lines: 132
---

# TesterGrantService

Holds the external playtester accounts at 999,999 Cash and 999,999 Tokens on every join, in the DEV universe only.

## What it does
1. `Start()` returns immediately unless `GameEnvironment.env == "Dev"`. The gate is the env string, not `not isLive` and not an `IsStudio` check — `"Unknown"` is what an unpublished place resolves to, and paying out there would write into whatever universe that file actually belongs to
2. `FORCE_IN_STUDIO` (default `false`) is ANDed with `RunService:IsStudio()`, so a `true` left in by accident is inert on every published server, DEV and live alike. In a Studio playtest of a **live** place file it does write the real live profile of whoever is signed in, because Studio has no separate DataStore
3. Matches testers by **UserId**, held in the `TESTERS` table with their username and display name as trailing comments. Usernames are changeable and a display name is not an identifier at all, so neither is ever compared
4. On join (and for anyone already present when `Start()` runs), polls `DataService.getPlayerData` for up to 10 s — DataService loads profiles from its own `PlayerAdded` and this one can win that race
5. **Tops up rather than granting**: awards only the shortfall to `TARGET_BALANCE` in each of Cash and Tokens. A tester who spent everything is rich again on their next join with no manual action; one who somehow has more keeps it; one already at target triggers no Wallet call and no analytics event at all
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
| [[DataService]] | `DataService.getPlayerData()`, `DataService.updateLeaderstats()` | Reach the joining player's profile table, and push the new balances to the leaderstats the currency chips read |
| [[Wallet]] | `Wallet.award()` | The sole currency mutator — awards the shortfall and logs the economy Source event |
