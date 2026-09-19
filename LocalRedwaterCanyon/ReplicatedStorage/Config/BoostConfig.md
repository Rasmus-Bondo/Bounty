---
tags: [shared, modulescript, boosts, config, events]
path: game.ReplicatedStorage.Config.BoostConfig
type: ModuleScript
lines: 140
---

# BoostConfig

Shared catalog of the XP / Cash boost consumables, plus the limited-time server-wide bonus events. Identical copy must exist in all three places — edit together (same rule as BattlePassConfig).

## What it does
1. Exports `BOOSTS` — a map of 6 boost ids to `{ kind, percent, minutes, label, icon }`. Two kinds (`xp`, `cash`) × three durations (15/30/60 min), all `percent = 25`. `xp` multiplies account/level XP earning; `cash` multiplies Cash earning. `minutes` is a budget of **live-round** time spent only during active Redwater rounds (see Redwater's BoostService)
2. `icon` is the potion art for that boost — one asset per duration so 15/30/60 are tellable apart. It lives here rather than in either UI because **two** readers paint it: BoostsTab and BattlePassClient's reward cards. Adding a boost gives both its art automatically
3. `get(id)` — returns the catalog entry for an id, or nil
4. `list()` — stable id list for UI, sorted by kind then ascending duration
5. Exports `EVENTS` — limited-time server-wide bonuses, each `{ id, kind, percent, label, startsAt, endsAt }`. A separate table from `BOOSTS` because the duration model is the opposite: a potion spends a budget of live-round seconds per player, an event runs on **wall clock** and starts and ends for everyone at once, with no inventory, no activation and nothing on the profile. `startsAt` / `endsAt` are UTC epoch seconds (`os.time()` on a Roblox server is UTC), half-open so the end instant is already off
6. `activeEvent(kind, now)` — the event running at `now`, or nil. `kind` filters to `"xp"` / `"cash"`; nil matches any kind, which is what the lobby banner uses to announce whichever is running. First match wins, so two overlapping windows of one kind do **not** stack
7. `eventPercent(kind, now)` — additive bonus percent, 0 when nothing is running. Percent rather than a fraction, to match the potion / friend / BOUNTY+ terms it is added beside
8. `DEV_FORCE_EVENT_ID` — testing switch: that event id runs immediately regardless of the clock. Gated on [[GameEnvironment]] `isLive` being false **or** `RunService:IsStudio()`, the second because a Studio session opened from a live place file resolves `game.PlaceId` to the live id and so reports live. Neither can be true on a live server, so a forgotten value cannot start or extend a real event
9. A past window is inert rather than stale — `activeEvent` simply never matches it again — so rows stay as the record of what ran. Scheduling the next event is one new row and no code change anywhere

## Dependencies
- **Requires:** [[GameEnvironment]] (environment gate for `DEV_FORCE_EVENT_ID`)
- **Required by:** BoostService (validates ids on activate; adds `eventPercent` to the earn multiplier in both match places), FriendBonusService (adds the same term to the lobby multiplier preview and supplies the banner's label + end time), BoostsTab (grid order, labels + icons), BattlePassClient (reward-card icon for `kind == "boost"`), BattlePassService (`get()` validates a `boost` reward's `boostId` before granting — an unknown id now refuses the claim rather than writing an unspendable inventory entry). A future trading-post UI will require it client-side.

## Connections
### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `isLive` | Keep `DEV_FORCE_EVENT_ID` inert on a live server |
