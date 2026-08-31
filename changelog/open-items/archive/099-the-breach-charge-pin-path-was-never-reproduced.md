# 99 — The Breach Charge pin path was never reproduced

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-12 (Hotfix 15) with no recurrence reported. Closed on elapsed time, not on evidence. If it
resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P1 · **Area:** Redwater — combat after a Bram slam
*(raised: Hotfix 15)*

---

**Symptom.** Two fixes in Hotfix 15 both address being stuck after a Bram Breach Charge, and neither
was tested against an actual slam:

1. **Dust could be left permanently unable to shoot** with rounds still in the cylinder — only a
   reload, dash, High Noon or death recovered it. Reported from the tutorial as "couldn't shoot for
   5-6 seconds"; roughly 3.5s of that was the carry plus `SlamStunDuration` working as designed, the
   rest was unbounded.
2. **A reload lost to the pin was lost for good**, all four hunters — `HunterAutoReload` fired on the
   ammo N→0 edge and dropped the trigger outright if the action lock was up at that instant. Worst for
   Fortuna, who has no click-an-empty-gun fallback.

**Repro.** Never reproduced. Staging a bot slam on demand is impractical, so both fixes rest on the
reasoning plus an owner playtest of *ordinary* firing and reloading, which was clean. Fix 2 was also
harness-tested against a synthetic 3.5s block (reload fired 0.17s after the lock lifted, no
double-reload, no leaked loop) — that exercises the retry, not the slam.

**The test that closes it.** Get slammed by a Bram — a real player is easiest — as Dust with rounds
left, and confirm you can fire the moment the stun ends. Then empty a magazine into the slam window on
Fortuna and confirm the reload lands once the lock lifts instead of leaving her empty.

**`RetryInterval = 0` restores the old auto-reload behaviour** if the retry misbehaves.

**Shipped in:** [Hotfix 15](../2026-08-12-hotfix-15.md) — two entries under `## Fixed`.
