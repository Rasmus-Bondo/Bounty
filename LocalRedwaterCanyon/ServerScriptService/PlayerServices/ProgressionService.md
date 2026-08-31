---
tags: [server, modulescript, progression, economy]
path: game.ServerScriptService.PlayerServices.ProgressionService
type: ModuleScript
lines: 581
---

# ProgressionService

Awards XP, Cash, and level-ups for kills, assists, deaths, round completion, and time alive. Also fires quest tracking events and floating combat-text popups. Owns the leveling curve (uncapped quadratic): `xpToNext(L) = XP_BASE + XP_LINEAR*L + XP_QUADRATIC*L^2`.

**Round earnings are deferred:** everything earned while `State.roundActive` is true is *banked*, not credited, and only lands in the player's data when RoundController calls `flushPendingRewards` at the buzzer. Leaving mid-round forfeits the bank — you have to play to the end of the round to keep your XP and Cash.

## What it does
1. Computes `xpToNext` per level from Config knobs (XP_BASE/XP_LINEAR/XP_QUADRATIC), caching each level's value and a cumulative XP table that extends on demand (uncapped)
2. Exposes `getXPNeededForLevel(level)` and `getXPInfoFromTotalXP(totalXP)` for callers (RoundController fallbacks, stat card)
3. Awards arbitrary XP and Cash for bounty claims via `awardBountyKill` (called by BountyService when a player kills someone with a bounty); fires `CombatReward` with kind="bounty_claim" → "BOUNTY CLAIMED" popup
4. Awards arbitrary XP and Cash for spree-holder survival bonuses via `awardBountySurvival` (called by BountyService when a bounty holder dies or at round end); fires `CombatReward` with kind="bounty_survived" → "SPREE BONUS" popup
5. `notifyBountyPlaced(player)` fires an announcement-only `CombatReward` (kind="bounty_placed", xp=0, cash=0) so [[CombatFeedClient]] shows the "BOUNTY ON YOU!" warning when the player's streak hits the threshold
5a. `notifyTutorialReward(player, cash, tokens)` (2026-08-17) fires `CombatReward` with kind="tutorial_step" for the onboarding lesson's per-step award instalment. **Notify only** — TutorialDirector has already moved the money through Wallet itself, guarded by the once-per-account `Tutorial.BonusPaid` flag — so it deliberately does not go anywhere near `addRewards`, which would boost-multiply a fixed award and bank it as a pending round reward the lesson then throws away in `clearPendingRewards`
5b. **`fireCombatReward` gained a fourth `tokens` channel** in the same pass, and it is in the empty-row test as well as on the wire: without that, a tokens-only row is dropped here and never reaches the feed. Every other caller passes XP and Cash only, since no reward in a real round pays Tokens
6. Awards arbitrary XP and Cash for code redemption via awardCodeRedemption (called by CodeRedemptionService)
7. Awards XP and Cash when a player gets a kill, increments session/lifetime kill count, reports `kill` through [[QuestEvents]] (plus the two scoped keys — see 7a), and fires `CombatReward` with kind="kill"
8. Awards XP and Cash for an assist via `awardAssist`, increments session "Assists" stat, and fires `CombatReward` with kind="assist" (called by HunterHitPipeline and HighNoonDamage for each assister returned by `RoundStatsService.RegisterKill`)
9. Increments session/lifetime death count when a player dies
10. Awards XP and Cash bonus to all players at round completion and reports `roundComplete` through [[QuestEvents]], plus the mode-scoped `roundComplete:<mode>` (7a). The scoped twin is fired from *here* rather than from the round loop so it can never disagree with the bare event about which rounds count — an abandoned round pays neither
7a. **Scoped quest keys** (2026-08-27). `trackForMode(player, event)` and `trackForHunter(player)` fire an EXTRA event beside the bare one — `kill:tdm`, `roundComplete:domination`, `killAs:Vesper` — for the BattlePassConfig quests that name a gamemode or a hunter. Mode comes from the `Gamemode` workspace attribute, hunter from `SelectedHunter` (the same attribute RoundStatsService counts `hunterCount` from, so a death-gated mid-match swap moves subsequent kills onto the new hunter's quest for free). Both are nil-guarded and the failure is asymmetric on purpose: a missing attribute drops the **scoped** key and leaves the bare one alone, because a quest that stalls is recoverable and one credited to the wrong hunter is not
11. After every XP award, recomputes level from totalXP (so curve tuning can demote stale stored levels) and fires LevelUp RemoteEvent only when level ratchets up
12. Runs a time-alive reward loop (every 10s tick, awards every TIME_REWARD_INTERVAL seconds of alive time). It pays on `sessionData.TimeAlive` minus a per-player high-water mark in `timeRewardTracker`, **which is why `snapshotRoundStart` must clear that table** — see 34a
13. `sendStats(player)` builds the M / Stats menu payload: merged persistent + per-match data, with Level/CurrentLevelXP/XPNeeded/XPProgress derived from the curve rather than stored. Two callers — the `RequestStats` RemoteEvent (the player opened the menu) and `sendStatsToAll()`, fired at round start so a panel left **open** across the round boundary repaints itself instead of holding the previous round's numbers until it is closed and reopened. The menu pulls on open and never again, so without the push there is no other way for it to notice the reset
14. `getProgressionSummary(player)` returns a round-end stat card payload including `xpSegments` (a `{[tostring(level)] = xpNeeded}` map covering startLevel..currentLevel) so VictoryShowcaseClient can animate multi-level XP bar fills accurately
15. Cleans up time reward tracker on player removal
16. At each reward hook (`awardKill`, `awardAssist`, `awardRoundCompletion`, `awardBountyKill`, `notifyBountyPlaced`) also calls the matching [[BattlePassService]] `on*` hook (guarded) to award battle-pass XP and track BP weekly quests — separate from the account XP/Cash awarded here
29. The single reward primitive `addRewards` multiplies awarded XP and Cash by [[BoostService]] `getMultiplier(player, "xp"/"cash")` (active boost consumables) before crediting, rounding `floor(base*mult + 0.5)`; code redemption opts out via a `noBoost` flag. It returns the boosted amounts so `awardKill`/`awardAssist`/`awardBountyKill`/`awardBountySurvival` fire `CombatReward` with the real (boosted) numbers
30. `addRewards` also takes a canonical `analyticsReason` (kill / assist / bounty_claim / bounty_survived / round_complete / time_alive / code) and, whenever cash > 0, credits the boosted Cash through [[Wallet]] `award` (the sole currency-mutation path — mutates + logs the economy **Source** in one call); XP is still added inline
31. **Round earnings are banked, not credited.** `addRewards` splits into two tails: `bankRewards` (round live) and `creditRewards` (the old immediate path). If `State.roundActive` is true and the caller did not pass the `immediate` flag, the boosted amounts go into `pendingRewards[userId]` — `{ totalXP, totalCash, reasons = { [analyticsReason] = {xp, cash} }, order }` — and nothing touches `data.XP` / [[Wallet]] / leaderstats. `addRewards` still **returns** the boosted amounts, so the `CombatReward` popups fire during the round exactly as before and show the real numbers the player is banking. Boost multipliers are sampled at *earn* time, so a potion that expires before the buzzer still pays out in full on the kills it was live for. Deferred reasons: kill, assist, bounty_claim, bounty_survived, time_alive. Passing `immediate = true` bypasses the bank — used by `awardCodeRedemption` (a promo, not a round earn) and `awardRoundCompletion` (fires after `roundActive` is already false and must land before the stat card is built)
32. `flushPendingRewards(player)` pays the bank out: adds `totalXP` to `data.XP` in one shot, then fires **one [[Wallet]] `award` per analytics reason** (in the order the reasons were first banked) so the economy Source breakdown survives the deferral, then `checkLevelUp` + `updateLeaderstats`. Consumes the bucket, so it is idempotent. Called once per player by RoundController at round end, before `buildPostGameStats()`
33. `clearPendingRewards(player)` drops a bank without paying it; `getPendingRewards(player)` returns `(totalXP, totalCash)` for a read-only peek at what is banked
34. A player's bank is dropped on `PlayerRemoving` (leaving mid-round forfeits it — this is what makes finishing the round the condition for getting paid) and `snapshotRoundStart` clears the whole table, so a round that somehow ends without flushing can't leak earnings into the next one
34a. **`snapshotRoundStart` also clears `timeRewardTracker` (2026-08-07), and that is load-bearing rather than tidy.** The round-start reset in the round loop now zeroes each player's `TimeAlive` (per-match stats — DataService owns them). The tracker holds the alive-time value at which each player was last paid, so a mark left over from the previous round is *larger* than the freshly zeroed `TimeAlive`: the `aliveTime - mark >= TIME_REWARD_INTERVAL` test goes permanently negative and **the alive-time reward silently never pays again for the life of that server**. It is cleared here, with the round, rather than per player — `PlayerRemoving` still nils the leaver's entry, which is a different concern

## Domination objective rewards (2026-08-22)

`ProgressionService.awardObjective(player, kind, xp, cash)` — `kind` is `domination_capture`,
`domination_neutralise` or `domination_defend` and serves as both the Wallet reason and the combat-feed
row. Routes through the same `addRewards` bank as a kill (boosts apply, paid at the buzzer flush,
forfeited by leaving early) and fires `CombatReward` with that kind.

## Dependencies
- **Requires:** [[DataService]], [[Wallet]], [[QuestEvents]], [[Config]], [[State]], [[BattlePassService]], [[BoostService]] (State/BattlePassService/BoostService lazy, in Start). It no longer requires QuestService directly — quest reporting goes through [[QuestEvents]], which reaches both quest engines
- **Required by:** Domination (objective rewards), Main, RoundController, BountyService, CodeRedemptionService, TutorialDirector (drops the lesson's banked bot-kill earnings, and fires the per-step reward row), HunterServerRuntime (resolves it once per hunter for assist awards)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `LevelUp` | -> Client | Fires new level number on level-up |
| `RequestStats` | <- Client | Client requests full stats |
| `StatsResponse` | -> Client | Server responds with merged persistent + per-match data. Fired on request (the player opened the TAB / Stats menu — throttled client-side to one request per 0.35s since it became hold-to-show) **and** unprompted to every player at round start, so an open panel repaints after the per-match reset. StatMenuGui's own file declares this pair; naming it here too would make a reciprocal edge and race the direction |
| `CombatReward` | -> Client | Fires `(kind, xp, cash, tokens)` to the receiving player on kill/assist/bounty, and on each onboarding step instalment, so [[CombatFeedClient]] can show the reward row. The `tokens` channel was added 2026-08-17 and is used only by the tutorial |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()`, `getSessionData()`, `incrementSessionStat()`, `updateLeaderstats()` | Read/write player data and session stats |
| [[Wallet]] | `award()` | Credit + log every Cash economy Source (canonical reason) — from `creditRewards` for immediate earns, and once per banked reason from `flushPendingRewards` at round end |
| [[Config]] | Constants | XP_PER_KILL, CASH_PER_KILL, reward values, XP_BASE / XP_LINEAR / XP_QUADRATIC (leveling curve knobs) |
| [[State]] | `State.roundActive` | Gate time-alive rewards to active rounds only, and decide in `addRewards` whether an earn is banked (round live) or credited immediately |
| [[QuestEvents]] | `track()` | Report `kill` / `roundComplete` and their scoped twins to both quest engines. It is QuestEvents rather than QuestService because the battle-pass weeklies are a second engine reading the same events, and a site calling only one of them would advance half the quests |
| [[BattlePassService]] | `onKill()`, `onAssist()`, `onRoundComplete()`, `onBountyClaim()`, `onBecomeBounty()` | Award battle-pass XP and track BP quests at each reward hook |
| [[BoostService]] | `getMultiplier()` | Multiply awarded XP/Cash by the player's active boost consumables in `addRewards` |
