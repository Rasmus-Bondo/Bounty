# 5 — Bram's charge cooldown started on the keypress instead of on the charge end

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#5 — Bram's charge cooldown started on the keypress instead of on the charge end.**
*(Fixed 2026-08-04, **VERIFIED by the owner the same day**. In Studio, **not yet published** — it
ships in the next release.)* `BreachCharge.Cooldown` is **still 6** and `Time` still 3, exactly as
the narrowed scope required. Effective gap after a full charge went 3s → 6s; a charge cut short on
a wall at ~1s went 5s → 6s, so the early-slam case changed least.

**The cooldown could not simply be moved, and this is the part worth not re-deriving.**
`RevolverDashService:DoDash` writes `Cooldowns[player]` at activation, and that write is what
refuses a second Q mid-charge. It is also a **shared** module — Dust's Quick Draw and Fortuna's
Ability1 dash construct their own instances — so editing `DoDash` would have moved three hunters'
cooldowns, not one. The stamp therefore stays put and `BreachChargeService:_endCharge` **restarts**
it, which is Bram-only and leaves the shared primitive untouched.

**Three implementations, each with one exit funnel**, which is what kept the change small:
`_endCharge` on the server (both `_releaseCharge` and `_resolveSlam` route through it);
`finishBreachCharge` on the player client, the single exit for all six reasons, which needs its own
copy because it owns the input gate and the HUD fill; and `BotCombat._tryBreachCharge`, restamped
where its loop exits. **The bot line is the one to revert first if bot aggression reads as too
passive** — bots gate on the same `config.Cooldown` via `_ready`, their charges are distance-scaled
(0.45s–3s) so the shift is smaller, and nobody reported them.

**Two traps, both hit while writing it:**
1. *Restamping unconditionally undoes Last Call.* The ultimate refreshes this cooldown on
   activation (`ResetCooldown` → nil) and every landed blast shaves it (`ReduceCooldown`), and both
   can land **while a charge is in flight** — a blind restamp silently cancels the refresh the ult
   just paid for. The server only restamps while `Cooldowns[player]` is still the value
   `TryStartCharge` recorded in `charge.CooldownStamp`; the client mirrors that with a
   `BreachCooldownEpoch` counter bumped by the Last Call handler and by each
   `AbilityCooldownsReduced` push.
2. *Moving the client's `CooldownStarted` fire outright leaves the Q icon reading READY
   mid-charge.* The press-time fire is what keeps the HUD occupied during the charge; moving it
   wholesale would light the icon for up to 3s while a press **cancels** rather than recasts. The
   press now fires a placeholder of `BreachCharge.Time`, superseded on release — the fill is
   token-guarded, so the restart supersedes cleanly.

The `humanoid.Died` handler was also routed through `finishBreachCharge("Invalid")`: it inlined the
same three lines without starting a cooldown and **races** the charge loop's own `Invalid` exit, so
dying mid-charge could leave the client off cooldown seconds before the server — which restamps
from `_endCharge` either way — and the next Q would charge locally against a server refusing it.
