# 115 — Hunter switch across a map move is unplayed

- **Raised:** Update 1 (2nd publish), 2026-08-14
- **Severity:** P1
- **Status:** CLOSED 2026-08-15 (never verified)
- **Closed:** 2026-08-15 — **owner decision. Never playtested.** Live only since the 2026-08-14 2nd
  publish, so this is closed on the owner's call rather than on elapsed time; neither the party nor
  the solo path below was ever run. If a player arrives at the destination as the wrong hunter,
  raise a **new id**.
- **Release entry:** [Update 1](../2026-08-14-update-1.md) — *A mid-match hunter switch now survives a map change*

## Symptom

Winning a map vote after switching hunters mid-match respawned the player at the destination as the
hunter they left the **lobby** with, not the one they were playing. Both the party path and the solo
path were affected, for different reasons.

## Repro

Never reproduced in Studio, and cannot be — **TeleportService does not run in a Studio session**, so
the entire `moveToMap` payload path is unreachable from an edit-mode or solo playtest. The fix was
derived by reading the two payloads, not by observing the failure.

## The test that closes it

Needs a real live map vote, run **twice** — the party and solo payloads were wrong in different ways
and one passing does not imply the other:

1. **Solo.** Join a match, switch hunter mid-match (kill-cam card row), win a vote to the other map.
   Expect to spawn at the destination as the **switched** hunter. This path previously carried no
   selection at all and resolved the *profile* hunter, so a player who had never switched would not
   have noticed it was broken.
2. **In a party.** Same, with at least two players, at least one of whom switched. Expect every
   member to arrive as their own live selection. This path carried a `characterSelections` snapshot
   frozen at arrival.
3. Run one of the two **Redwater → Frostbite** and the other **Frostbite → Redwater**. Both places
   carry the same file byte-identical, so a one-direction test proves both only if they published
   together — confirm the version tag reads the same release in both.

**Check you are on the right build first.** The fix shipped in Update 1's **2nd publish**
(`Bounty r2440 · Redwater r2616 · Frostbite r341`). The in-game tag reads `Update 1` for both
publishes and cannot tell them apart, so match the **r-number** — testing on `r2613`/`r332` would
reproduce the original bug and look like the fix failed.

Closes as VERIFIED when a switched hunter survives the move in both party and solo.

## Notes

Publishing the two match places apart breaks this in one direction only, which is the failure mode
that looks like a flaky bug rather than a deploy mistake. See the release entry for why the two
payloads diverged.
