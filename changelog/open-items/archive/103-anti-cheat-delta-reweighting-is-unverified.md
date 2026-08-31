# 103 — Anti-cheat delta reweighting is unverified

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-13 (Hotfix 16) with no false-positive kick reported. Closed on elapsed time, not on
evidence. If it resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P1 · **Area:** Redwater — AntiCheat
*(raised: Hotfix 16)*

---

**Symptom.** `MovementChecker`'s position-delta flag was a flat weight 3 against a threshold of 5, so
two of them in one life silently kicked the player. A large delta at `hSpeed` ~0 is equally the
signature of a CFrame teleport and of a stalled client snapping back in, so a player on a bad
connection could be kicked for their connection. The flag is now weight 3 when the horizontal-speed
check corroborates it and weight 1 when it does not, with `(uncorroborated)` appended to the reason and
a `ping` field added to the kick context.

**Repro.** Not reproducible on demand — it needs a genuinely stalled client, and inducing one reliably
is the problem. Both new format paths and the weight selection were exercised in an edit session; the
kick decision itself was not.

**The test that closes it.** Not a playtest — the shape of the next kick batch on the Creator Hub.
Read the reasons and the new `ping` field:

- An `(uncorroborated)` flag on a high-ping player that **did not** reach the threshold is the fix
  working.
- A repeating cheat still reaching the threshold a few seconds later is also the fix working.
- An `(uncorroborated)` kick on a low-ping player would mean the corroboration rule is wrong.

**Anti-cheat — never appears in the public note.** Prompted by review of three live kicks on
2026-08-13 (two accounts); all three were judged genuine exploits and **none** would have been
prevented by this change.

**Shipped in:** [Hotfix 16](../2026-08-13-hotfix-16.md) — under `## Changed`.
