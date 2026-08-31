# 110 — Parked dead assets are unverified in a running game

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-13 (Hotfix 17) with nothing reported missing. Closed on elapsed time, not on evidence. If a
parked asset turns out to have been live, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P3 · **Area:** both places — `ServerStorage.Unused`
*(raised: Hotfix 17)*

---

**Symptom.** Nothing is known to be wrong. Three nodes were moved out of the client download path
on the strength of a name-and-id grep: Redwater's `SFX."Recall complete"` and `"purchase complete"`,
and Bounty's `Workspace.WorkingChest`. If any of them is reached by a construction the grep cannot
see — a name assembled at runtime, or a path walked by index — the reference now resolves to nil in
a live server and not in an edit session.

**Repro.** None. The risk is specifically that `grep_scripts` matches literals, so a name built by
concatenation would not have appeared in the sweep that cleared these.

**The test that closes it.** Join both places after publishing and watch the server and client logs
for `Recall complete`, `purchase complete` or `WorkingChest` in a nil-index or `WaitForChild` timeout
— **expect none**. Restoring one is a reparent: each parked node carries an `OriginalPath` attribute.

**The `HTTP 429` on the `Recall complete` asset id will probably persist** and is not the test. The
same second carries fetch failures from three unrelated subsystems, so it is join-time request volume
being throttled, not that asset. This reduces volume; it does not target the row.

**Shipped in:** [Hotfix 17](../2026-08-13-hotfix-17.md) — under `## Changed`.
