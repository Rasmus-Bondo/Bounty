---
name: project_boost_potions
description: "XP/Cash boost consumables — design decisions, data model; BUILT both places incl. the BOOSTS-tab UI with real art. Only the trading post is deferred"
metadata: 
  node_type: memory
  type: project
  originSessionId: 6c4508ec-8db7-4c93-9aaa-9e66a5553807
  modified: 2026-07-26T20:16:18.375Z
---

XP & Cash **boost potions**: consumables earned from the battle pass (and later a trading post — NOT wired yet, user deferred). Completes the "Boosts recorded, not applied" follow-up in [[project_battle_pass]].

**Catalog:** new shared `ReplicatedStorage.BoostConfig` (mirrored verbatim both places, like BattlePassConfig). 6 ids = kind × duration: `xp_25_15/30/60`, `cash_25_15/30/60`. All `percent = 25`. `xp` multiplies account/level XP earning; `cash` multiplies Cash earning. Exposes `get(id)`, `list()`.

**User's design decisions (2026-07-04):**
- **Timer = match-time only.** Duration is a budget of LIVE-ROUND seconds (`Active[kind].remaining`), ticks down ONLY during an active Redwater round; pauses in intermission, in the Bounty lobby, and offline. NOT a wall-clock expiry.
- **Effect = account XP + Cash only.** Battle-pass season XP is intentionally NOT boosted.
- **Same-kind reactivation = blocked** while one of that kind is running (button disabled until it expires). XP + Cash boosts run concurrently (one Active slot per kind).
- **Multiplier = 1.25**, applied as `math.floor(base*mult + 0.5)` at each ProgressionService gameplay earn (kill/assist/round/bounty/time-alive); code-redemption grants stay unmultiplied.
- **Trading post currency = Cash** (chosen despite circularity for cash boosts) — but trading post itself is OUT OF SCOPE for now.
- **Build scope = systems only, no UI.** Contract for the UI person: `ActivateBoost:FireServer(boostId)`; `RequestBoostState`/`BoostStateEvent` for inventory+active; player attributes `XPBoostRemaining`/`CashBoostRemaining` (seconds) for a smooth countdown.
- **Activation location = BOUNTY LOBBY, not Redwater** (user, 2026-07-04, after initial build). Fits match-time: pop a potion in the lobby, it sits paused at full duration, burns only once in a live Redwater round. So `ActivateBoost` is handled in Bounty; Redwater's `BoostService` had its client `ActivateBoost` handler REMOVED (kept `BoostService.activate` as a server/testing API only). Redwater is spend + display only.

**Data model** (`Boosts` in the profile template, restructured from the old `{percent,games}` list):
`Boosts = { Inventory = {[boostId]=count}, Active = { xp = {percent,remaining}, cash = {...} } }`. `ensureData` normalizes any pre-migration shape (old `{}` or old list) to this — old games-based boosts are discarded (were never usable).

**BUILT — Bounty (verified compiling + logic-tested via execute_luau):** `BoostConfig` created; `DataService` template Boosts→new shape; `BattlePassService` `ensureData` guard (migration) + `grantReward` `kind=="boost"` → `Inventory[boostId]+=1`; `BattlePassConfig` reward rows L15→`xp_25_30`, L25→`cash_25_30`, L35→`xp_25_60` (kind `xpBoost`→`boost`, `boost={percent,games}`→`boostId`). Client doesn't reference the old `xpBoost`/`boost` — safe. Vault + BountyGraph synced.

**BUILT — Redwater (verified compiling + behavioral sim via execute_luau):** `BoostConfig` mirrored verbatim (both copies newSourceLength 2070); `DataService` template + `BattlePassService.ensureData` Boosts→new shape; **new `BoostService`** (`ServerScriptService.PlayerServices`, ~222 lines): `activate` (inventory>0 + block-if-active → `Active[kind]={percent,remaining=minutes*60}`), round-gated 1s tick loop (`while State.roundActive`, decrement by real dt, expire at ≤0 → clear slot + fire `BoostExpired`), writes `XPBoostRemaining`/`CashBoostRemaining` player attrs each tick, `getMultiplier`, `grantBoost`, `RequestBoostState`/`BoostStateEvent`. Started in `Main` right after `BattlePassService.Start()`.
`ProgressionService`: the single primitive **`addRewards(player,xp,cash,reason,noBoost)`** now multiplies by `BoostService.getMultiplier` (`floor(base*mult+0.5)`) and RETURNS the boosted amounts; `awardKill/awardAssist/awardBountyKill/awardBountySurvival` pass those to `fireCombatReward` so popups show real numbers; `awardCodeRedemption` passes `noBoost=true`. Redwater vault + RedwaterCanyonGraph synced.

Sim confirmed: 15-min→900s @×1.25, same-kind reactivation blocked, xp+cash concurrent, expiry reverts to ×1.00 while other kind keeps ticking, reactivate after expiry, rounding 100→125 / 37→46.

**BUILT — Bounty activation service (verified compiling + sim):** new Bounty `BoostService` (ServerScriptService.PlayerServices, 163 lines) owns activation + state streaming: `ensureBoosts`, `activate(player,boostId)` (block-if-active; sets `Active[kind]={percent,remaining=minutes*60}` — stays PAUSED in lobby, no tick loop), `grantBoost`, `sendState` (sets `XPBoostRemaining`/`CashBoostRemaining` attrs + fires `BoostStateEvent`), `Start()` creates `ActivateBoost`/`RequestBoostState`/`BoostStateEvent` (ensureRemote at RS root) + PlayerAdded hook. No getMultiplier/tick/State (lobby earns no gameplay XP/Cash). Wired into Bounty `Main` after `BattlePassService.Start()`. Bounty vault + graph synced. Sim: grant→activate gives remaining=3600s paused (no lobby decrement), block/none reasons correct.

Note: battle-pass boost claim writes `Boosts.Inventory` directly in Bounty BattlePassService.grantReward (does NOT call BoostService.sendState) — the boost UI should `RequestBoostState` on open / after a claim to refresh. Left decoupled on purpose.

**UI — BUILT since (BOOSTS tab of the Bounty Collection menu, see [[project_collection_panel]]):** left grid of 6 tiles + right description panel + USE button, driven by exactly the contract below. **Real artwork landed 2026-07-26** — a `BOOST_ICONS` map in CollectionGuiController holds one asset per id (small/medium/big × XP/Cash; XP art is potion bottles, Cash art is coins/bags, so the tile caption carries "XP · 15 MIN" / "CASH · 15 MIN" to name the kind). Same art repeats as a hero medallion in the right panel over a kind-tinted disc. Unowned = `LOCKED_TINT` grey. Gotcha hit while building it: [[project_uistroke_thickness_scale]].

**Remaining follow-ups (NOT built):**
- Optional in-match Redwater countdown pill (read-only). Contract: `ActivateBoost:FireServer(boostId)` (Bounty), `RequestBoostState`→`BoostStateEvent`, `BoostExpired(kind)` (Redwater), attrs `XPBoostRemaining`/`CashBoostRemaining`.
- **Trading post:** user explicitly deferred — do NOT add boosts to it yet. `BoostService.grantBoost(player,id,count)` is the ready hook; chosen currency = Cash.
- Runtime round-trip not observed (edit-session only; can't drive live players/rounds via plugin) — verified by compile + logic sim.

Related: [[project_battle_pass]], [[feedback_never_partial_overwrite]], [[feedback_verify_code]].
