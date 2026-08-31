---
tags: [shared, modulescript, server, client, status-effects, combat]
path: game.ReplicatedStorage.Hunters.Shared.HunterActionLock
type: ModuleScript
lines: 165
---

# HunterActionLock

Dependency-free shared module answering "is this character allowed to act right now?" — firing, abilities and reload alike. Combines two server-written character attributes with the round's own phase, and owns the **refcounted** write side of the pin attribute.

## What it does
1. `.IsStunned(character)` — `character:GetAttribute("StatusStunned") == true`. The hard stun set by HunterStatusEffects `ApplyStun`, i.e. Bram's wall slam
2. `.IsPinned(character)` — true while `StatusPinnedUntil` (a `Workspace:GetServerTimeNow()` deadline) is still in the future. `GetServerTimeNow` is the synchronised clock, so one written deadline reads identically on the server and on every client; `os.clock()` is per-machine and `tick()` is wall time, and neither survives the server→client hop this attribute makes
2a. `.IsRoundActive()` — reads the authored `ReplicatedStorage.RoundActive` BoolValue, resolved lazily and cached. **The one state that is not per-character:** while it is false nobody acts at all, which covers the match summary (RoundActive is cleared at the buzzer, ~1s before the showcase opens), the intermission and the countdown. A **missing** value reads as *live*, deliberately — every server ability module fails closed on its own RoundActive check, whereas a client stuck closed could not fire for the rest of its session with nothing left to recover it
3. `.IsLocked(character)` — `not IsRoundActive() or IsStunned or IsPinned`. The gate every caller actually wants. Nil-safe: a nil character is unlocked for the stun and pin halves, and a non-numeric deadline is ignored rather than throwing — but the round check still applies, since outside a live round there is nothing to allow
4. `.AcquirePin(character, holderKey, deadline)` — records `holderKey` against the character in a weak-keyed registry and **raises** the attribute toward `deadline`. Raise-only: a second charger grabbing a victim can never shorten the lock the first is relying on
5. `.ReleasePin(character, holderKey)` — drops that holder's claim and rewrites the attribute to the longest deadline still held, clearing it only when the last holder lets go. Nil `holderKey`, an unknown holder and a parentless character are all no-ops rather than throws
6. `.STUN_ATTRIBUTE` / `.PIN_ATTRIBUTE` — the attribute names, so writers and readers cannot drift on a string literal
7. **The pin is refcounted because more than one charger can hold the same victim while the lock is only one attribute** — and because Bram's charge has *two* independent implementations, BreachChargeService for players and BotCombat for bots, neither of which can see the other's book-keeping. Holder keys are whatever is unique per charger: `"BramPin<UserId>"` on the player side, the bot's own model on the bot side (`BOT_PIN_KEY` is one shared string and would have made two bot Brams release each other). The registry has weak keys so a character leaving the game drops out without a `CharacterRemoving` hook, which would have cost this module its no-dependencies property
8. **The pin is a deadline, not a flag, on purpose.** A stranded flag is a player who cannot fire for the rest of the round. The pin is written from a shared per-charge Heartbeat loop, and one throw inside a shared `pairs()` loop permanently freezes every later entry. A deadline expires on its own whichever cleanup path got skipped — the same reasoning behind the `Duration` on the pin's HunterMovement override and the client carry-follow's `PIN_MAX_DURATION`
9. **Deliberately requires nothing.** Both attributes live on the character model, so this is safe to require from a LocalScript, a server module or a bot brain. HunterStatusEffects is specifically not required: it pulls in HunterMovement, which owns `Humanoid.WalkSpeed` and runs a Heartbeat loop, and nothing here needs either. HunterGate is the model for this shape

## Why it exists
Before this module the only gate was a raw `StatusStunned` read duplicated across the four hunter clients and BotCombat. `ApplyStun` is only called on Bram's wall **slam**, so the entire **ram** phase of Breach Charge was ungated — a carried victim had no status attribute at all. That let the roster's three displacement abilities (Dust's Quick Draw, Fortuna's Surge, Vesper's Grapple Hook) break the carry, after which the charge's own `ReleaseDistance` desync check dropped the pin and completed the escape. Holding both states in one predicate is what stops the next hunter's mobility ability from reopening the same hole.

The write side moved here later, and for the same reason. The original fix only taught the **player** charge to set the attribute, so a player carried by a **bot** Bram was still completely ungated — the exact hole the module was built to close, reopened by the half of the feature that was overlooked. Being rammed is identical from the victim's side; they cannot tell whether the Bram hauling them has a client, and every one of the 12 gates below is already indifferent to who did the pinning. Mirroring the raw set/clear into BotCombat would not have been enough on its own either: with two systems writing one attribute and neither aware of the other, whichever charger let go first would have lifted the other's lock. Refcounting is what makes a second holder safe, and it retro-fixed the player-vs-player case that `_isPinnedByAnyCharge` used to cover by scanning only player charges.

The round check joined it for the third time in the same shape (launch issue #8 — abilities usable during the match summary). Five of the seven server ability modules had each grown their own `isRoundCombatAllowed()` helper reading `RoundActive`; Fortuna's CardsServer and Dust's HighNoonModule never did, so her throw, recall, ultimate and Surge — and High Noon's activate and shoot — were gated on the stun/pin state alone and still fired while the summary was up. CardsClient never read `RoundActive` anywhere either, so Fortuna additionally played the entire local cast (animation, card FX, cooldown burn) against a server that was dropping the request in silence. The movement half of that issue was already handled elsewhere — RoundController anchors the root and holds a zero-speed `VictoryFreeze` override for the whole showcase — so only the ability half was outstanding. Putting the round in the shared predicate rather than writing the helper a sixth and seventh time is what stops the next hunter being the third to forget it.

**Known asymmetry, accepted:** the root-level jump handler (ManuelJumpClient) is not round-gated, so Dust/Vesper/Bram can still jump in the pre-round cage while Fortuna — the only hunter with its own `doJump` behind this predicate — cannot. Irrelevant during the summary itself, where `LockJump` disables the jump state for everyone.

## Dependencies
- **Requires:** Nothing
- **Required by:** BreachChargeService and BotCombat (the two Bram charges — both `AcquirePin`/`ReleasePin` around a carry, and BotCombat also gates its own bot's fire + ThinkAbility), GrudgekeeperModule, LastCallModule, RevolverModule, HighNoonModule, CardsServer, SunspikeModule, StarfallSightModule (server ability/fire entry points), FPSRevolverClient, CardsClient, SunspikeClient, GrudgekeeperClient (each hunter's client `isCombatAllowed`)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
