# 118 — Mobile cluster-button duplicate fix is not device-tested

**Status:** FIXED (unverified) · **Sev:** P2 · **Raised:** Hotfix 1.1 (2026-08-16)

## Symptom

On a slow mobile join, a cluster button built twice: the authored button plus a legacy runtime
fallback, leaving a stray text label showing under the real button's icon. Seen live as a jump
button reading `JMP` — a half-occluded `JUMP` — on a phone joining straight into a Frostbite match.

## Repro

Join a match **directly** from the Roblox app on a touch device, so the client is still replicating
when the cluster builds. A lobby → match teleport is a weaker repro; the authored ScreenGui has
usually arrived by then. Watch for a text label under any of the five cluster buttons: `JUMP`,
`FIRE`, `SPRINT`, `RLD` or `SCOPE`.

## The test that closes it

A real touch device joining straight into a match on **both** maps, confirming exactly one of each
cluster button with no text label. Then check the jump button still works on the first tap — the fix
also moved when Roblox's own touch jump button is suppressed (client boot rather than after our
button is built) and made the touch build detached, so a regression would show as a dead or doubled
jump rather than as a label.

Studio cannot close this: the bug is a replication race that Studio replicates far too fast to
reproduce, which is why the fix shipped unit-checked rather than playtested.

## Notes

Unit-checked before shipping against three replication timings — late button, late gui,
genuinely-absent gui — each yielding exactly one gui and one button, with the old code reproducing
as two.

Diagnosis lives in the release entry: [Hotfix 1.1](../2026-08-16-hotfix-1-1.md).
