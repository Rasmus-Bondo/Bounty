---
tags:
  - server
  - modulescript
  - combat
  - stats
  - analytics
path: game.ServerScriptService.PlayerServices.RoundStatsService
type: ModuleScript
lines: 334
---

# RoundStatsService

Tracks per-player combat stats for the round (kills, deaths, assists, damage, headshots, accuracy) shared by every weapon/hero system.

## What it does
1. Keeps a per-player (by UserId) stats table: kills, assists, deaths, currentKillStreak, bestKillStreak, damageDealt, headshots, shotsFired, shotsHit, bountiesHeld, bountyKills
2. `RegisterShotFired(player)` increments shotsFired for accuracy tracking, then logs step 5 "Shot the Gun" of the onboarding funnel via [[DataService]] `tryLogFunnelStep(player, 5, ...)` — the analytics event now fires **at most once per player, ever** (persisted de-dup) instead of on every shot as it used to, which is what tripped AnalyticsService's "sent too many events" cap. Shared chokepoint for both RevolverModule and CardsServer
3. `RegisterDamage(attacker, victimCharacter, damage, isHeadshot)` rounds and accumulates damage/headshot counts on the attacker, logs a short-lived (`ASSIST_WINDOW` = 10s) damage entry against the victim for later assist credit, and logs step 6 "Hit a Player" via [[DataService]] `tryLogFunnelStep(attacker, 6, ...)` (once per player, ever)
4. `RegisterDeath(player)` increments deaths and resets currentKillStreak
5. `ResolveDeath(victimCharacter, killerPlayer, killerBotId)` is the **single per-death crediting point**, called once from each authoritative death handler (RoundController for player victims, BotService for bot victims) no matter what landed the final blow. It credits the killer's kills/currentKillStreak/bestKillStreak (players only — `killerPlayer` resolved from the victim's `LastDamager` attribute), then grants an assist to every *other* player who damaged the victim within `ASSIST_WINDOW` (the killer is excluded, whether a player or a bot via `killerBotId`), returns the assister UserIds so the caller awards XP/Cash via ProgressionService, and clears the victim's damage log. Logs step 7 "Killed or Assisted" for the killer and every resolved assister via [[DataService]] `tryLogFunnelStep(_, 7, ...)` — once per player, ever. **Replaces the old `RegisterKill`/`RegisterBotKill`, which ran inside the per-hit damage pipelines and so silently dropped assists (and stat kills) for any finisher that bypassed them — zone/firewall, fall damage, DoT, a bot's killing blow on a player.**
6. `GetPlayerStats(player)` returns a snapshot including computed accuracy (`shotsHit / shotsFired`, clamped 0-100)
7. `Reset()` clears all stats and re-seeds an empty entry for every current player (called at round start)
8. `EnsurePlayer(player)` lazily creates a stats entry without changing existing values
9. `ClearPlayer(playerOrUserId)` wipes one participant's stats outright, called from RoundController's `PlayerRemoving` handler. **Leaving forfeits the round** — because this table is keyed by UserId (unlike `State.playerKills`/`playerDeaths`, which are keyed by the Player *instance* and so read zero for the new instance a rejoin creates), a player who left and rejoined the same live round used to resume their old kills/assists/deaths/streaks/damage/accuracy, and `EnsurePlayer` on rejoin was a no-op while the entry still existed. It also drops the damage log in **both** directions: entries recorded against them (so their first death back can't credit assists to whoever shot them in their previous life) and entries they recorded against others (so a kill landing just after they rejoin can't hand them a pre-leave assist)
10. `resolveUserId` is the shared Player-or-UserId coercion behind `getOrCreateStats` and `ClearPlayer`
11. **Tracks which hunters each player actually played this round** (`hunters` set + `hunterCount`), via a `noteHunter` helper called from every stat-mutating entry point. The hunter is read off the `SelectedHunter` player attribute rather than plumbed through every call site, because HunterSwitchService flips that same attribute when it applies a queued swap — so it is already the live answer everywhere. Swaps are death-gated and applied on respawn, so a life belongs entirely to one hunter and there is no mid-life ambiguity
12. `GetPlayerStats` therefore also returns `hunterLabel` — the single hunter they played all round, or **`"Mixed"`** if they swapped at any point. This is what keeps the per-hunter analytics cells clean: without it, a whole match of Dust hipfire would be credited to whatever hunter the player happened to end as, and "Vesper accuracy on phones" would be measuring the wrong hunter. It also makes the size of the swapped cohort visible instead of smearing it across the roster
13. `firstKillAt` records the clock time of a player's first KILL of the round (not assist), exposed as `timeToFirstKill` in seconds relative to the round start that `Reset()` establishes. Consumed by RoundController's `FirstKillTime` analytics event — the "did I ever feel good" moment. Known imprecision accepted on purpose: the 10s `ASSIST_WINDOW` means an assist can occasionally cross a respawn boundary and be noted against the newly swapped-in hunter

14. `RegisterBountyPlaced(player)` / `RegisterBountyKill(player)` count the two bounty events per round, called from BountyService beside the existing `notifyBountyPlaced` and `bountyClaim` sites. They are counters only — nothing is logged where they happen, because Telemetry's standing rule is one aggregate per player per match and a per-event emit from a combat path is what tripped the analytics cap once already. `GetPlayerStats` returns both as `bountiesHeld` / `bountyKills`, which RoundController drains at round end into the `MatchBounties` / `MatchBountyKills` events. These exist to measure the battle pass's two unmeasured `XP_SOURCES` inputs: `becomeBounty` is worth 20 BP XP a time and `killBounty` 10, together the biggest slice of per-match XP no chart previously showed

## Dependencies
- **Requires:** [[DataService]], [[QuestEvents]]
- **Required by:** BountyService (lazy, in Start — increments the two bounty counters), HunterServerRuntime (resolves it once per hunter, passes to HunterHitPipeline and exposes as `runtime.RoundStats`; degrades gracefully to nil if missing — the pipelines now use it only for `RegisterDamage`), RoundController and BotService (both call `ResolveDeath` on the `Humanoid.Died` event; RoundController also calls `EnsurePlayer` on join and `ClearPlayer` on leave). (RevolverModule and CardsServer previously required this directly.)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `tryLogFunnelStep()` | Log onboarding funnel steps 5-7 (shot/hit/kill) once per player, persisted de-dup |
