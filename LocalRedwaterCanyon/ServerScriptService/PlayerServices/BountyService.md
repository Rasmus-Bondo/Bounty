---
tags: [server, modulescript, combat, economy, bounty]
path: game.ServerScriptService.PlayerServices.BountyService
type: ModuleScript
lines: 589
---

# BountyService

Tracks kill streaks, marks players **and arena bots** who reach 3 kills without dying, applies visible highlights, and calculates scaled rewards.

## What it does
1. Tracks per-target kill streaks, resetting on death. A **target** is either a Player or a BotService record, and every function below is written against a small accessor pair (`isPlayerTarget` / `targetUserId` / `targetDisplayName` / `getBountyStart` / `getStreak`) so there is one bounty implementation rather than a bot copy that drifts.
2. When a target reaches `BOUNTY_KILL_THRESHOLD` kills without dying, places a bounty with a start timestamp. For a player it also calls `ProgressionService.notifyBountyPlaced(killer)` (the "BOUNTY ON YOU!" announcement, shown by CombatTextClient off ProgressionService's own CombatReward remote) and `RoundStatsService.RegisterBountyPlaced`; both are keyed by Player and are skipped for bots, which have no client to notify and no stats row to write.
3. Applies a Highlight (AlwaysOnTop) to the marked character, visible through walls, always built on the gold/orange. In a team mode it ends up wearing the holder's **team colour** instead — an enemy with a bounty reads as an enemy first, and the fuller AlwaysOnTop style is what still says "bounty" — but that colour is per-viewer since 2026-08-19, so TeamVisualClient repaints the Highlight when it replicates and this module never sets one. **For a bot this is only half the story** — see *The bot glow lives on the client* below.
4. Reapplies the highlight on respawn via CharacterAdded — **players only**. A player keeps their bounty across lives; a bot's bounty ends with the life that earned it, and BotService clones a fresh rig per life regardless.
5. When a bounty target is killed, calculates a scaled reward (base + duration × scale), awards it via `ProgressionService.awardBountyKill(killer, ...)` (fires CombatReward kind="bounty_claim"), tracks `bountyClaim` through [[QuestEvents]] and counts it in `RoundStatsService.RegisterBountyKill`. **The victim may be a bot**; the killer is always a real player, and a non-player killer is refused rather than erroring on a wallet it does not have.
6. When a *player* bounty holder dies (`registerDeath`), pays them a duration-scaled survival bonus via `ProgressionService.awardBountySurvival` (CombatReward kind="bounty_survived" — the "SPREE BONUS" popup), and calls `BattlePassService.onBountyTakenDown(player)` to credit the Dead Man's Hand BP quest if they scored ≥2 kills that bounty life.
7. When a *bot* bounty holder dies (`registerBotDeath`), clears the streak and the bounty with **no payout half** — the survivor bonus, the `bountyTime` quest track and the Dead Man's Hand credit all write to a profile a bot does not have. A bot's bounty is worth exactly what the player who claims it is paid.
8. `clearBotBounty` handles a bot leaving the round *without* dying — retired for a joining player, or swept at round end. Kept separate from `registerBotDeath` because that one is the death path and prints a "held Ns" line; skipping this strands a list row naming a rig that no longer exists.
9. At round end, awards survivor bonuses to **players** still holding bounties. Bots are not filtered out here, they are simply not in `State.playerBounties`.
10. Fires BountyPlaced/BountyClaimed/BountyRemoved to all clients for [[CombatFeedClient]] rows and [[BountyMusicClient]] track changes, and publishes a ranked `BountyListUpdated` snapshot (top holders + duration-scaled cash) on change and on a ~1s loop to drive the [[BountyListClient]] list. Players and bots share one list and rank against each other on the same terms, so a bot on a long spree can hold the top row. **The rank key is `startedAt`, not `cash`** — see *Ranking is by age, not value* below.
10a. Each entry also carries `team`, the holder's team id, which is what the card's portrait ring is drawn from — or nil in FFA so the card keeps its authored gold. It used to be a resolved `ringColor`; the colour now depends on who is looking, and one server-computed Color3 would paint every card the same for a lobby that no longer agrees on what red means. The HUD resolves the id through the same module the rig outline goes through, so the ring and the mark cannot disagree.
11. `targetPortrait` resolves what each bounty card RENDERS — see *The portrait spec* below. Adds `hunter` and a resolved `model` `{category, subfolder, modelName}` to every snapshot entry.
12. Cleans up on PlayerRemoving and provides `resetAll()` for round start, which clears both sides.
13. **Tutorial guard (one line, design 4.1):** `registerKill` early-returns while `State.tutorialMode` — it is the player-only door to `registerTargetKill`, so the player is never marked (steps 6 and 7 credit 7 kills against a threshold of 3 and would otherwise mark them mid-ultimate). `registerBotKill`, `claimBounty` and `registerTargetKill` are untouched: step 8's marked bot works exactly as a live match's.

## The bot glow lives on the client
`applyHighlight` on a bot's `workspace.ArenaBots` rig is **not what players see**. BotVisualClient renders a smoothed clone in `ClientBotVisuals` and hides the server rig part-by-part with `LocalTransparencyModifier`, so a server-made Highlight adorns a body nobody is looking at — and, since `LocalTransparencyModifier` does not suppress a Highlight, it would render at the raw un-smoothed position beside the real one.

So the bot bounty glow is built **client-side** by BotVisualClient off the `BountyListUpdated` snapshot, exactly as bot Bram's Last Call highlight is. The two implementations must keep the same Highlight properties.

The server-side call is still correct and deliberately kept: on the `ClientVisualSmoothing = false` path no visual is built, the server rig is what renders, and its Highlight is the one that shows. `BotVisualClient.hideServerInstance` disables the server copy only when a visual actually exists, so the two can never double up.

## Ranking is by age, not value

`getBountySnapshot` sorts **oldest bounty first on `startedAt`**, and the entry carries that
timestamp alongside the cash for exactly that purpose. The two orders are identical, so nothing is
lost: `getBountyReward` is `BOUNTY_BASE_CASH + floor(duration * BOUNTY_TIME_SCALE_CASH)` with both
of those [[Config]] values constant, which makes cash a pure function of age. Ranking on cash was
ranking on start time with the resolution thrown away.

Throwing it away was launch issue #29 (fixed 2026-08-06). The floor quantises cash to one step every
2 seconds, so two bounties placed **less than 2s apart** sit exactly tied for most of every cycle
and untied for the rest of it — and the old comparator ranked those two states differently: untied
by cash (favouring the older bounty), tied by name (favouring the alphabetically first). Whenever
those answers disagreed the cards traded places about once per publish, which is once per second.
Simulated over 120 publishes, the old comparator swapped on 119 of them and the current one on none.

Two properties follow, and both are worth not undoing:

- **A live bounty's start time never changes.** `setBountyStart`'s only caller is `placeBounty`,
  guarded by `not getBountyStart(target)`, and every other write to either table is a clear. So the
  relative order of surviving entries is **fixed for the life of the list** — cards move only when
  one leaves it. That is why no separate "sticky slot" mechanism was needed on the client: the
  ordering is already sticky by construction.
- **This holds only while `BOUNTY_BASE_CASH` is a constant.** If base cash ever becomes per-target —
  streak-scaled, say — then age and value stop agreeing, and the intended order has to be decided
  outright rather than derived from either one.

The tiebreak is `userId` rather than `name` because it is the only genuinely unique key: Roblox
display names are not unique, and two players sharing one would land back on an unresolvable
comparison and an unstable sort. It fires only on an exact float tie between two `tick()` reads.

## The portrait spec
Since 2026-08-05 the bounty list is a row of portrait cards rather than a name-and-cash list, so every snapshot entry carries `hunter` plus a **resolved** `model` `{category, subfolder, modelName}` — never a skin name. The name-to-model rule stays in [[HunterSelectionService]]; re-implementing it on the client is the drift this arrangement exists to prevent.

For a **player** it is `HunterSelectionService.GetSelection` — the live selection SkinService spawned them from, so the card cannot disagree with the body the shooter is hunting for. It is resolved **per publish, not captured when the bounty is placed**: a player keeps their bounty across lives and can swap hunter from the kill cam, and a captured spec would keep showing the hunter they stopped being for the rest of the spree. That is also why the publish signature includes the model — a snapshot suppressed as "cash unchanged" would strand the portrait.

For a **bot** it is [[BotConfig]]'s `HunterBehavior[<hunter>].DefaultCharacter`, read rather than rebuilt from the hunter name, so a BotConfig change moves the portrait with the rig. Bots have no skins — BotService clones that one path and nothing else — so a bot card always shows the default look.

Either field may be `nil` and the client falls back a step at a time (resolved model, then the hunter's authored `ViewportFrame`, then no portrait). A bounty card losing its picture must never cost the row its name and cash.

## Where bot state lives
Bot streaks and bounties are **not** in `State.playerBounties` / `State.playerStreaks`. Those two tables are indexed by Player from outside this module — by [[BattlePassService]] (Dead Man's Hand) and RoundController (the claim guard on the player death path) — and `RoundStatsService.RegisterBountyPlaced` keys its telemetry row by Player as well, so a bot record in either table would break all three. Bots get module-local tables keyed by the BotService record instead.

Those tables are weak-keyed, but that is a backstop only: every exit clears explicitly, because GC timing is not prompt enough to stop a dropped record leaving a ghost row on everyone's bounty list. `resetAll` uses `table.clear` rather than a fresh literal so the weak-key metatable survives.

Bot record ids are **negative** (`BotService.NextId` starts at -100001) and were already published as `userId` by `BotService.GetPostGameStats`, so bot bounties ride the existing remotes with no client change at all: every consumer either uses `userId` as a table key ([[BountyListClient]]) or compares it against `LocalPlayer.UserId` ([[BountyMusicClient]], [[CombatFeedClient]]), and a negative id can never collide with a real one.

## Dependencies
- **Requires:** [[Config]], [[State]], [[QuestEvents]], [[ProgressionService]], [[BattlePassService]], [[RoundStatsService]], [[HunterSelectionService]], [[BotConfig]] (the last five lazy, in Start). The last two are read-only portrait sources for the bounty cards — see *The portrait spec*. `RoundStatsService` is counters only — `RegisterBountyPlaced` beside `notifyBountyPlaced`, `RegisterBountyKill` beside the `bountyClaim` track — so the round-end telemetry can report bounty rates without this module emitting an analytics event from a combat path. It does not require QuestService directly — quest reporting goes through [[QuestEvents]], which reaches both quest engines
- **Required by:** RoundController, Main, BotService, BotController

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `BountyPlaced` | -> Client | [[CombatFeedClient]] "IS ON A SPREE" row · [[BountyMusicClient]] starts the bounty track when the id is the local player |
| `BountyListUpdated` | -> Client | [[BountyListClient]] refreshes the live bounty cards (top holders + scaled cash + resolved hunter/skin portrait spec, players and bots together) |
| `BountyClaimed` | -> Client | [[BountyListClient]] flashes CLAIMED on the row · [[CombatFeedClient]] "TOOK DOWN" row |
| `BountyRemoved` | -> Client | [[BountyListClient]] fades the row out · [[BountyMusicClient]] stops the bounty track |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | Constants | BOUNTY_KILL_THRESHOLD, reward values |
| [[State]] | `State.playerStreaks`, `State.playerBounties` | Read/write the player half of bounty state (the bot half is module-local) |
| [[ProgressionService]] | `awardBountyKill()`, `awardBountySurvival()`, `notifyBountyPlaced()` | Award scaled XP/Cash for bounty claims and spree-holder survival bonuses; fire announcement-only popup when a bounty is placed |
| [[QuestEvents]] | `track()` | Progress `bountyClaim` on a successful bounty kill and `bountyTime` on a player leaving a bounty life; reaches both quest engines |
| [[BattlePassService]] | `onBountyTakenDown()` | Credit the Dead Man's Hand BP quest when a player bounty holder is taken down |
| [[RoundStatsService]] | `RegisterBountyPlaced()`, `RegisterBountyKill()` | Per-round counters behind the MatchBounties / MatchBountyKills telemetry |
| [[HunterSelectionService]] | `GetSelection()` | The live hunter/skin a player bounty holder is wearing, published as the card's portrait spec |
| [[BotConfig]] | `HunterBehavior[<hunter>].DefaultCharacter` | The authored rig path a bot bounty holder spawned from, published as its portrait spec |
