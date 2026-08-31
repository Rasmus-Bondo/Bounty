# 21 — Bots on a kill streak never got a bounty

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#21 — Bots on a kill streak never got a bounty.** *(Fixed 2026-08-04, **VERIFIED by the owner
the same day**. In Studio, **not yet published**.)*

**It was not a guard — there was no bot code path at all.** The original note guessed at a
`Players:GetPlayerByUserId` guard or a players-only check excluding bots; there was neither.
`BountyService` was keyed on `Player` end to end, and nothing ever registered a *bot's* streak.
`BotService:_creditPlayerKill` did call `registerKill`, but for the **player who killed the bot**.
And **bots had no streak field to check**: `Record.Stats.Kills` is cumulative across lives and
cannot express "kills since the last death", so the counter that looks like it should have driven
this could not have.

**Scope was decided before implementing: full parity**, because the bounty list shows a cash
amount beside each name and marking a bot while paying nothing would read as a bug.

*Fixed by* giving `BountyService` a **target abstraction** rather than a bot copy of itself. A
*target* is either a Player or a `BotService` record, and the module is written against
`isPlayerTarget` / `targetUserId` / `targetDisplayName` / `getBountyStart` / `getStreak`, so
placement, claiming, clearing and the list snapshot are **one implementation** serving both.
Player-only behaviour is a guard inside that path, not a fork: `notifyBountyPlaced`,
`RegisterBountyPlaced`, the `CharacterAdded` re-highlight, and the whole survivor-payout half of
`registerDeath`. New entry points `registerBotKill` / `registerBotDeath` / `clearBotBounty`;
`claimBounty` generalised to either victim. `BotController:RecordKill` advances the streak;
`BotService` claims on death and clears on the death, retire and round-end exits.

**The glow needed a second pass, and that is the part worth remembering.** The first version
shipped with no highlight, because **a server-side Highlight on a bot is invisible**:
`BotVisualClient` clones every bot into `workspace.ClientBotVisuals` and hides the server rig with
`LocalTransparencyModifier`, so `applyHighlight` was adorning a body nobody renders. The
bot-parity question ran the other way here — not "is there a bot version of this service?" but
"is there a bot version of **rendering**?" Fixed with `setBountyHighlight` /
`refreshBountyHighlights` in `BotVisualClient`. Full write-up in
[[project_bot_visual_clone_rendering]]; three details that are load-bearing:
- **Driven off the `BountyListUpdated` snapshot, not the placed/removed edges** — full state on a
  ~1s loop, so it self-heals when the client joined mid-bounty, when an event was missed, or (the
  common one) when the bot's visual was built *after* it was marked, since `createVisual` waits up
  to 3s for a complete rig and a distant client loses that race routinely.
- **The server-side call was kept, not replaced** — on `ClientVisualSmoothing = false` no clone
  exists and the server rig is what renders.
- **`hideServerInstance` now disables Highlights.** `LocalTransparencyModifier` does *not*
  suppress a Highlight, so without this the server copy renders on the hidden rig at the raw
  position, jittering beside the clone's own.

**Four choices worth not undoing:**
- **Bot state is NOT in `State.playerBounties`.** That table is indexed by Player from outside the
  module — `BattlePassService` (Dead Man's Hand) and `RoundController` (the claim guard on the
  player death path) — and `RegisterBountyPlaced` keys telemetry by Player too. A bot record in it
  breaks all three. Bots get module-local tables keyed by the record.
- **Those tables are weak-keyed, but every exit clears explicitly.** GC is not prompt enough to
  stop a dropped record leaving a ghost row. `resetAll` uses `table.clear` so the metatable
  survives.
- **The streak hangs off `RecordKill`, inside its `KillFeedGate` claim** — the same thing that
  stops a repeated call double-counting the kill *stat* (#10).
- **`registerBotDeath` is separate from `clearBotBounty`.** The first is the death path and runs
  after the claim has read the bounty; the second is the bookkeeping-only exit. Collapsing them
  would either pay twice or strand a row.

**#19's retirement path needed nothing** — a retiring bot leaves through `_onBotDied`, so its
bounty is claimed and cleared by the normal death path before `_removeRecord` runs.

**Telemetry meaning changed, and two comments asserting the opposite were corrected.**
`RoundStatsService` and `RoundController` both said "only PLAYERS are ever marked... so this rate
scales with the server's human count". `MatchBounties` is still player-only; `MatchBountyKills` is
not, and bot supply runs *inverse* to the human count. The `bucketPlayerCount` split is still
right, for the opposite reason than the one written down.

**Regression checklist if this area is touched again:** a marked bot glows through terrain, with
exactly **one** glow sitting on the bot you see rather than lagging beside it, and the glow returns
after the bot streams out and back; killing it pays the amount the list was showing and progresses
the "Kill the Bounty Target" daily; your own bounty music does not start when a *bot* is marked;
a bot killed by another bot clears with nobody paid; a bot retired mid-bounty (#19) drops its row;
and no stale row survives into the victory showcase.
