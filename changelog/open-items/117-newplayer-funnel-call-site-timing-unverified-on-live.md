# 117 — NewPlayer funnel call-site timing unverified on live

**Area:** Analytics / onboarding · **Sev:** P3 · **Status:** BUILT (unverified)
**Raised:** 2026-08-15, built this session

## Symptom

Nothing is known to be wrong. The `NewPlayer` funnel ships without ever having run against a real
player, and its failure mode is **silent and indistinguishable from a real result**: if a call site
fires at the wrong moment — before the profile loads, after a teleport has already taken the player,
or on a server that resolved `tutorialMode` late — the affected step simply never fires, every later
step is refused by the gate, and the chart shows a clean cliff. A cliff caused by a bug and a cliff
caused by players quitting look exactly the same on the dashboard.

The ordering gate itself is not the risk; it was tested (see the release entry). The risk is the
seven places that call into it.

## Repro

Not applicable — this is a first-run verification, not a defect. Studio cannot exercise it: the
Studio gate holds `ENABLED` false, so no playtest emits a funnel event, and MCP playtesting is
unavailable in this project regardless.

Note the cohort is **not** retroactive and cannot be backfilled: only accounts whose grandfather
screen runs after the publish are ever minted an id. A first read therefore needs a day or two of
genuinely new players, not an hour.

## The test that closes it

Read the funnel on the Creator Hub once new accounts have accumulated, and check four things in
order — each one isolates a different call site:

1. **Step 1 vs step 2.** A near-total drop here means step 1 is firing for players who then never
   reach the lesson — i.e. the cohort is too wide — or step 2 is not firing at all. A drop that
   merely looks large is plausible on its own (dispatch failures, instant quits), so compare it
   against the `Tutorial` funnel's step-1 count, which measures the same arrival independently.
2. **Step 3 vs the `Tutorial` funnel's step 11.** These two fire on the same signal in `runOutro`
   and should track each other closely. A gap means the journey step is being lost where the
   tutorial step is not.
3. **Step 4.** Fires off `TeleportData.tutorialComplete` on arrival in Bounty. Materially below
   step 3 means either the return leg is failing more than believed, or `noteTutorialReturn` is
   racing the profile load.
4. **Steps 5 → 6 → 7.** Should broadly mirror the retired `MatchLoop`'s 3 → 4 → 5 shape for the
   new-player slice. Step 6 missing while 5 and 7 are present would point at the 4s deferral in
   `logJoinedMatch`.

Also confirm **CustomField01 is populated** on step 1 rather than "Unknown" — the platform split is
the main reason the funnel exists, and the 10s wait for `TelemetryClient` is the thing that buys it.

## Release entry

`NewPlayer` funnel, in [Hotfix 1.1](../2026-08-15-hotfix-1-1.md).
