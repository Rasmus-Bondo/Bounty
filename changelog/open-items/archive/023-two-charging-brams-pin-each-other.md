# 23 — Two charging Brams pin each other

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Status:** **VERIFIED by the owner 2026-08-05**, on the owner's sign-off rather than a reported
playtest run · **Sev:** P2 · **Area:** Redwater — Bram · In Studio, **not yet published**

**Found by analysis 2026-08-01** (not a field report) while working #9. **Pre-existing** — none of #9's fixes caused or affect it. Diagnosed in full on 2026-08-01 and then **deferred by decision**, since resolving it was a gameplay call rather than a correctness one. The call was made 2026-08-05 (**option 2, without the knockback**) and the fix landed the same day.

**What happened (behaviour before the 2026-08-05 fix):** `BreachChargeService:_scanForPins` excludes only self, already-pinned, dead and same-team victims. Nothing stops a Bram who is *himself mid-charge* from being pinned, so two charging Brams pin **each other**. Player victims are held by their **own client** (`BramWorldFXClient:startPin`), so A's client writes A to `CarryDistance` in front of B while B's client writes B to `CarryDistance` in front of A — each player's position is defined by the other's, one frame stale.

That is a stable two-frame oscillation, snapping ~8 studs every frame (A facing +X at 0, B facing −X at 10):

| Frame | A.x | B.x | Gap |
|---|---|---|---|
| start | 0.0 | 10.0 | 10.0 |
| 1 | 4.0 | 6.0 | **2.0** |
| 2 | 0.0 | 10.0 | **10.0** |
| 3 | 4.0 | 6.0 | **2.0** |

Consequences:
- Both cameras ride the HumanoidRootPart, so both players see the world snapping back and forth at frame rate.
- **It never self-releases.** The gap peaks at 10, under `ReleaseDistance` (16), so the desync check never fires — it runs the full `Time + PinGraceBuffer` (~3.8 s).
- Both carry `StatusPinnedUntil`, so both are locked out of fire / reload / abilities for the duration, including any means of cancelling.
- `AssemblyLinearVelocity` is zeroed on both every frame, so neither can physically escape.
- If either clips a wall during it, `_resolveSlam` pays 50 damage + a 2.5 s stun — and both can slam simultaneously for a mutual knockout.

**Needs two real players.** Bot Brams run `BotCombat`'s own charge and never enter `ActiveCharges`, so a real Bram pinning a charging *bot* Bram is one-directional and harmless.

**Options considered (the decision, 2026-08-05):**
1. **Skip victims who are themselves mid-charge** — ~5 lines in `_scanForPins` (`self.ActiveCharges[targetPlayer]`). Makes the loop impossible; two charging Brams simply collide and run past. Deterministic, invents no mechanic. *Was recommended as the correctness floor.* **Not chosen** — two Brams running through each other reads as nothing having happened.
2. **Mutual bounce (Overwatch-style)** — both charges end, both briefly stunned. **CHOSEN, minus the knockback:** the owner's call was explicitly *"no explosion/knockback effect, both brams should just get stunned"*, which removes the entire tuning-and-art half of this option (knockback magnitude, impact FX/SFX) and leaves one number to pick. The clash detection reuses option 1's `ActiveCharges` test, so the correctness floor is included rather than traded away.
3. **First-to-pin wins** — rejected: the winner is decided by `pairs(self.ActiveCharges)` iteration order, which is arbitrary and can differ frame to frame and between servers.

**Fix (2026-08-05) — `BreachChargeService` + `GrudgekeeperConfig`, no client change.** Grab-box contact
with a player who is himself mid-charge now resolves as a **clash** instead of a pin: both charges
end, both Brams take a `ClashStunDuration` stun, neither is carried.

- **The test lives inside the existing pin geometry**, not in its own sweep, so the two can never
  disagree — whatever would have been pinned is exactly what clashes. It reads `ActiveCharges`, the
  authoritative charge set, so it needs no attribute and cannot be spoofed by a client.
- **`_releaseCharge` does the teardown** rather than anything bespoke, because it is already the
  "charge ended without a slam" path: each Bram's own carried victims drop for `ReleaseDamage`,
  `IsDashing`/AutoRotate reset, each cooldown restarts from now, and `"ChargeEnd"` stops each
  client's local charge loop. **That is why there is no client change** — a server-initiated end is
  the same message the wall slam has always sent.
- **`ClashStunDuration = 1.5`** (new, in `GrudgekeeperConfig.BreachCharge.Pin`), deliberately below
  `SlamStunDuration` 2.5. A slam is a play the victim lost and pays 50 damage on top; a clash is
  symmetrical and both Brams already forfeit the charge and a full `Cooldown`. It also has to stay
  short because Redwater is FFA: **two Brams stunned together in the open are a free double-kill for
  any third player**, who did nothing to earn it. That is the consideration if it is ever retuned.

**Two guards make it safe inside the shared Heartbeat loop, and both are load-bearing:**
- `_scanForPins` now **returns true** when it resolved a clash, and `_updateCharge` stops on it —
  otherwise the tick would carry on into `_maintainPins` against a charge that no longer exists.
- `_updateCharge` bails when `self.ActiveCharges[player] ~= charge`. One tick ends **two** charges,
  and clearing a key mid-`pairs()` does not un-schedule the other Bram's entry, so without this the
  stale table runs a full tick — re-pinning victims the release just dropped and restamping through
  `_endCharge` a cooldown the clash had already restarted. It must be the **first** statement in the
  function, since every early return below it calls `_releaseCharge`.

**Follow-up 2026-08-05 — jumping was dead for the rest of the life after a clash, and it is a
SEPARATE, OLDER bug that the clash merely made easy to hit.** Reported on first test of the fix
above. `GrudgekeeperClient` disables `Enum.HumanoidStateType.Jumping` on the **client** for the
charge's duration, and `ManuelJumpClient.canJump()` gates on exactly that state.
`clearBreachChargeMovement` re-enabled it on every end path **except** when `StatusStunned` was set,
where it stood aside for `HunterStatusEffects` — and nothing on that side ever completed the
hand-off, so the state stayed disabled permanently.

**The trap, and the reason this looks fixed when it is not:** `HunterMovement.applyJumpLock` *does*
call `SetStateEnabled(Jumping, true)` when it releases (`HunterMovement:286`), which reads like the
stun already covers it. **It is on the wrong machine.** The stun is applied server-side and
`SetStateEnabled` is per-machine and does not replicate, so the server reopens only its own copy
while the client's — the only one `canJump()` reads — stays shut. What the stun *does* replicate,
`JumpPower`/`JumpHeight` 0 and the `MovementJumpLocked` attribute, never reopens the state. Do not
delete the hand-off on the strength of that call.

*Fixed by:* `restoreBreachJumpAfterStun` in `GrudgekeeperClient` — standing aside while a stun runs
is still correct (otherwise a stunned Bram could jump), so the teardown now genuinely **defers**
instead of skipping: it re-enables the state the moment `StatusStunned` clears, behind a
`BREACH_JUMP_RESTORE_TIMEOUT` (8s) deadline backstop, a one-shot `done` flag, and a token so a newer
charge supersedes a pending hand-off. Firing the backstop during a longer chained stun is harmless —
`LockJump` holds `JumpPower` at 0 and owns its own TTL — whereas a disabled state strands for the
whole life. The hunter-switch cleanup force-enables the state as well, since a swapped-away Bram
leaves nobody to finish the hand-off.

**Pre-existing, not caused by the clash.** It needs Bram stunned at the instant his *own* charge
tears down, which before today only happened when a second Bram slammed him into a wall mid-charge —
i.e. the same two-Bram situation this item is about. **Verified by simulation** against the shipped
function text, extracted from source rather than retyped: armed-while-stunned does not restore and
then restores exactly once on clear; a superseding charge cancels both the signal and the backstop;
a stun that never clears still restores at the deadline; an attribute cleared in the arming gap is
caught; and signal-then-deadline restores once, not twice. `GrudgekeeperClient` compiles (1638
lines). No other script has the same shape — `RevolverDash` re-enables unconditionally, and
`HunterMovement` owns both halves of its own lock.

**Bot Brams are deliberately not included, and this is not the "is there a bot version?" trap.** A
bot's charge is a separate implementation (`BotCombat:_tryBreachCharge`) that never enters
`ActiveCharges`, and it does not produce this bug: a bot is server-owned, so a player pinning a
charging bot is one-directional with none of the client-vs-client oscillation. There is also no
readable bot-charge marker to test — the state is local to a `task.spawn` closure, and the only
attribute exposed is the generic `IsDashing`, which every hunter's dash sets.

**Verified by simulation, since MCP playtesting is unavailable.** Both modules recompile (793 / 242
lines) and `ClashStunDuration` resolves through the config to the service. The clash was then driven
against stubs: two armed charges resolve to **0 remaining**, both Brams stunned at exactly 1.5s, both
sent `"ChargeEnd"`, `IsDashing` false and AutoRotate restored on both, both cooldowns restamped. The
stale-charge tick for the second Bram produced **0 extra stuns and 0 extra teardowns**, and
`_maintainPins` ran 0 times after a clash against 1 time on an ordinary tick.

**Regression checklist if this area is touched again — needs TWO REAL PLAYERS, bots cannot
reproduce it.** Closed on the owner's sign-off rather than a run through the list below, so treat
these as the tests that would catch a regression, not as steps that have each been performed:
1. Two Brams charge head-on. Both stop, both are stunned ~1.5s, neither is carried, and there is no
   jitter or camera snapping. Confirm both recover and can act normally afterwards.
2. Confirm both Q meters restart from the clash rather than reading ready.
3. Charge into another Bram **while already carrying someone else** — the carried victim should drop
   for the ordinary release damage, not be stranded pinned.
4. A Bram charging into a *non-charging* Bram must still pin and carry him exactly as before. This is
   the regression that matters most: the clash must not swallow an ordinary pin.
5. Charge into a **bot** Bram that is itself mid-charge — should still pin the bot, unchanged.
6. Confirm neither player is kicked by anti-cheat for the stun that lands mid-flight.
7. **Jump after the clash stun wears off.** This is the follow-up bug above and the one most likely
   to regress; confirm it on both Brams, and again after a second clash in the same life.
8. Get slammed into a wall by another Bram *while charging*, and confirm jumping returns after that
   stun too — the older path that always had this bug.
9. Charge, end it normally with no stun at all, and confirm jumping is immediate — the deferral must
   not have crept into the ordinary path.
10. Clash, then switch hunters from the kill cam, and confirm the swapped-in hunter can jump.
