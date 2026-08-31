# 6 — Bram's charge could be cancelled on frame one

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#6 — Bram's charge could be cancelled on frame one.** *(Fixed 2026-08-04, **VERIFIED by the
owner the same day**. In Studio, **not yet published** — it ships in the next release alongside
#5.)* New `GrudgekeeperConfig.BreachCharge.ChargeCancelLockoutTime = 1`, read in
`GrudgekeeperClient.tryBreachCharge`: while `S.IsBreachCharging`, a Q press inside the charge's
first second returns instead of calling `finishBreachCharge("Input")`. The press is **dropped, not
queued** — a queued cancel would end the charge up to a second after a panicked double-tap the
player had already forgotten making.

**One gate covered every input,** which is what kept it to two files. Q-again is the *only*
deliberate cancel left — firing commits the charge Reinhardt-style (#9-era change) and jumping is
locked for its whole duration — and the mobile Q button reaches the same `tryBreachCharge` through
the `BreachChargeRequested` bindable. `BotCombat:_tryBreachCharge` needs no mirror: it is a
server-driven gap-closer with no input to cancel.

**Client-only on purpose — do not "harden" it server-side.** The Q cancel and the automatic
airborne exit both send a bare `"End"` on `BreachChargeRequest`, so the server cannot tell them
apart, and the airborne one legitimately fires at `ChargeUngroundedGraceTime` (**0.55s**, inside
the lockout) when Bram charges off a ledge. A server refusing an early `"End"` would keep carrying
pinned victims after the client had stopped driving, until `BreachChargeService`'s own
`Time + 0.75` timeout — a desync worse than the bug. Nothing is exposed by leaving it on the
client: ending your own charge early drops victims for the minor `ReleaseDamage` and, since #5,
still pays the full 6s cooldown, so it is a self-nerf, not an exploit.

**The stranding risk the original note warned about is structurally closed,** not merely
untriggered. The gate sits inside the `S.IsBreachCharging` branch, and every early end — WallHit,
Airborne, Invalid, the server's `ChargeEnd` — clears that flag before the check is reached; from
there the next Q is governed by `S.BreachReadyAt` like any other. The only charge it can suppress
input on is one still genuinely running, which `Timeout` ends at `BreachConfig.Time`.
`breachChargeStartedAt` is 0 once the movement loop is cleared, and the check falls *through* to
the cancel in that case rather than blocking on a stale zero.

**Two bounds if the value is ever retuned:** keep it below `Time` (3, or the charge becomes
uncancellable) and above `ChargeUngroundedGraceTime` (0.55, or a ledge-hop out-runs the
commitment window).
