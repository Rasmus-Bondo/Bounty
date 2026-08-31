---
tags:
  - server
  - modulescript
  - gamemode
  - teams
path: game.ServerScriptService.RoundSystem.TeamService
type: ModuleScript
lines: 308
---

# TeamService

Team membership, assignment and score for team gamemodes. Inert in FFA — nothing calls it when the
resolved mode's `TeamCount` is 0.

## What it does
1. Declares `TEAMS = { "red", "blue" }` and keeps `playerTeams`, per-player `CharacterAdded` hooks
   and the two scores as module state.
2. `setPlayerTeam(player, team)` stamps the `Team` attribute on the Player **and** the character,
   and registers a `CharacterAdded` hook that restamps every future rig. SkinService builds a
   brand-new character on every respawn, so a stamp that does not ride `CharacterAdded` is gone the
   first time its owner dies.
3. **No team colour lives here.** The rig outline was `applyTeamOutline` in this module until
   2026-08-19 and is now TeamVisualClient's, because every player sees their own side as blue and
   a server-set Highlight is one `OutlineColor` replicated to the whole server. This module owns the
   stamp, the assignment and the score; the colour belongs to TeamView.
4. `AddScore(team, amount)` / `ZeroScores()` / `GetScores()` keep the pair and publish them as the
   workspace attributes `TeamScoreRed` / `TeamScoreBlue`, which is what the client score HUD watches.
5. `CountHumans()` counts assigned players per side. Bots are deliberately excluded — they yield
   seats by retiring on their next death rather than holding them.
6. `AssignAll(players, groupIdOf, friendTargetOf, maxGroupSize)` is round-start assignment: groups
   first and **whole**, largest group first onto the side with more room, then solos shuffled onto
   whichever side is smaller. No skill or level balancing. A **group** is a party (`groupIdOf`)
   unioned with whoever joined a friend inside it (`friendTargetOf`), by union-find over the two
   keys — that union is what makes a friend join survive a round boundary instead of being
   reshuffled apart at the next buzzer. `maxGroupSize` caps it: friend links chain (A joins B, C
   joins A) and a group is always seated whole, so with no ceiling one side could grow until the
   other is empty. A merge that would breach the cap does not happen and the two groups seat apart.
7. `AssignArrival(player, preferredTeam)` handles a mid-round joiner: a preferred team — a
   party-mate's, or the friend they pressed Join on — wins whatever the balance; otherwise the
   smaller side. What counts as preferred, and whether that side still has room for it, is the
   mode's call (TeamDeathmatch's `preferredTeamFor`); by the time it arrives here it is final. It
   then defers a `BotService:Reconcile()` nudge, because the join-time reconcile ran before this
   player had a team and its per-team targets missed them.
8. `ResetRound()` disconnects every character hook, clears the `Team` attribute from players and
   their characters, and zeroes the scores. Clearing the stamp is what drops the outlines — the
   client watches the attribute. Teams persist for a whole round and reset at the top of the next.
9. `Players.PlayerRemoving` disconnects the leaver's hook and forgets their team.

## Dependencies
- **Requires:** [[BotService]] (lazy, inside `AssignArrival` — a deferred `pcall(require, ...)` so
  there is no load-order edge and no require cycle)
- **Required by:** Domination, RoundController (for the TDM-to-FFA teardown), TeamDeathmatch

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BotService]] | `botService:Reconcile()` | Re-run bot fill after a mid-round joiner takes a team, so the retiring bot lands on the joiner's own side |
