# 124 — The DEV tester top-up cannot be tested until it ships to DEV

**Status:** BUILT (unverified) · **Sev:** P2 · **Raised:** DEV tester grant (2026-08-23)

## Symptom

`PlayerServices.TesterGrantService` holds six external playtester accounts at 999,999 Cash and
Tokens on join, and it has never run. It is gated on `GameEnvironment.env == "Dev"`, which resolves
`"Live"` in all three place files that are open in Studio — so the only way to exercise it is to
publish the DEV places and have a tester join. Everything about it is compile- and mirror-verified
and nothing about it is behaviour-verified.

The failure modes that survive that gap: the profile poll timing out on a slow DataStore day and the
top-up silently not happening; the currency chips not repainting until a rejoin; a mistyped UserId
leaving one tester poor with no error anywhere.

## Repro

Not a bug report; a sign-off owed, and one that is **unobtainable before the DEV publish**. Setting
`FORCE_IN_STUDIO = true` exercises the code path in a Studio playtest, but in a live place file it
writes the real live profile of whoever is signed in — it is a debugging aid, not this test.

## The test that closes it

After the DEV places are published, have **one** tester and **one** non-tester account join DEV
Bounty, then teleport into a DEV match:

1. Tester's Cash and Token chips both read 999,999 within a second or two of the menu appearing —
   without a rejoin.
2. Server log carries `[TesterGrantService] Active in Dev/Bounty — 6 tester account(s) …` at boot
   and `<name> topped up to 999999 Cash / 999999 Tokens` on the join.
3. Tester buys something expensive, then rejoins: they are back at 999,999, and the log shows a
   second top-up for the shortfall only.
4. Tester joins again without spending: no second top-up line — the balance is already at target.
5. Non-tester account joins the same DEV server and is **not** topped up.
6. Teleport into a DEV match place: still 999,999 there, and the match server logs its own
   `Active in Dev/Redwater` line.
7. Confirm on **live** afterwards that nothing changed: no `[TesterGrantService]` line in a live
   server log at all, since `Start()` returns before it prints.

Steps 5 and 7 are the ones that matter most — they are the gate, and the gate is the whole reason
this is safe to ship.

## Release entry

[Unreleased](../UNRELEASED.md) — "DEV playtester accounts are topped up to 999,999 Cash and Tokens
on join".
