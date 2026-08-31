# 17 — Vesper grapple overshoots the platform

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner decision: no recurrence in the ~2 weeks since the 2026-08-01 launch. Closed on elapsed time, **not** on a playtest — the status below was still `FIXED (unverified)`.

---

**Status:** FIXED (unverified) · **Sev:** P2 · **Area:** Redwater — Vesper · **Shipped:** [Hotfix 5](../../2026-08-03-hotfix-5.md)

**Reported:** Vesper can sometimes get hurled way past a platform when hooking. Cause unknown — needs diagnosis before a fix.

**Diagnosed 2026-08-03. The bug was in the RELEASE, not the pull** — and the bot path already
documents it. `SunspikeClient.stopGrapplePull` released the player at `velocity * 0.25`, where the
pull speed is `distance / TravelTime`, so the residual was **`0.714 x distance` studs/s with no
ceiling**: 89 studs/s off a max-range hook. `HopVelocity` is then a **floor** (`math.max(v.Y, 60)`),
not an addition, so a *flat* hook — which has almost no natural upward velocity — was handed 60
anyway, buying 0.61s of hang time for that horizontal speed to run.

**The correlation asked for above is hook distance x how FLAT the hook is.** Not ping: the pull is
entirely client-owned, and the client recomputes distance from its own position, so latency shifts
*when* the pull starts and never the trajectory. Studs travelled past the pull target, measured:

| hook dist | flat | 30 deg | 60 deg |
|---|---|---|---|
| 40 | 17.5 | 15.1 | 8.7 |
| 100 | 43.7 | 37.8 | 22.5 |
| 125 | **54.6** | 47.3 | 35.2 |

That is why it is *sometimes*: the common case (standing on the ground, hooking a ledge above you)
is steep, so the residual is mostly vertical and you pop up and land fine. A long flat hook dumps
the same energy horizontally. All **33** authored perches are narrower than 54.6 studs — mean
narrow-axis footprint **20.1** — so a 60-stud flat hook already overshoots the average perch.

**Secondary, real but minor — do not re-derive it as the main cause.** `ArrivalRadius` 4 is an
8-stud band point-sampled once per Heartbeat, and the per-frame step is `distance / (0.35 x fps)`,
which exceeds 8 studs whenever `distance > 2.8 x fps` (any hook past 84 studs at 30fps). It looks
decisive and is not: the pull *homes*, so a missed sample gets more chances, and simulating it with
frame jitter puts the real miss rate at ~1% at 30fps and ~18% at 20fps. When it does miss, the pull
runs its full `TravelTime * 2` deadline and then takes the same hop.

**The bot path solved all of this and the player path never got it.** `BotController` separates
`finish(true)` from `finish(false)`, zeroes horizontal velocity on success, clamps Y to **12** (not
60) on failure, and carries a dot-product overshoot check. Its comment reads: *"The authored player
arrival damps to 0.25 and adds a hop... 0.25 of the pull speed is still fast enough to carry it off
the far edge."* Related measurement in `BotCombat`: the player's `+4` pull offset clears geometry
only **~62%** of the time.

**Fix (2026-08-03, shipped in [Hotfix 5](../../2026-08-03-hotfix-5.md)):** new
`VesperConfig.GrappleHook.MaxLandingSpeed = 40`, applied in `SunspikeClient.stopGrapplePull` as a
clamp on the **horizontal magnitude only**, direction preserved. Max flight past the target drops
54.6 → 24.5 studs.

**Deliberately NOT done, because the brief was that the hook must not change feel:**
- *Copying the bot's success path* (zeroing horizontal outright) — the bot's own comment says that
  suits something which cannot course-correct on landing. On a player it reads as the hook stopping
  dead.
- *Splitting the timeout branch to drop the hop* — the hop is doing real work there, getting the
  player over a lip the pull failed to clear. The clamp covers that path anyway, since every exit
  routes through `stopGrapplePull`.
- *The dot-product overshoot check* — with the clamp in, it barely moves the symptom and it does
  change when the pull ends. Worth doing on its own terms, not smuggled in here.

**Why this is safe on feel, and how to re-check it:** the clamp is XZ-only, so `HopVelocity`, the
vertical carry, and therefore **time-to-landing are arithmetically unchanged** — 0.61s before and
after at every distance. Any hook whose residual is already under 40 (roughly **56 studs and
shorter**) runs identical arithmetic to before, so the risk surface is only hooks long enough to be
broken today. Both scripts compile.

**Still to verify (human, MCP playtesting unavailable):** a long flat cross-canyon hook lands on the
perch instead of sailing off it; a short ground-to-ledge hook feels exactly as it did; a hook whose
pull is blocked by a rock face still pops up over the lip rather than sliding back.
