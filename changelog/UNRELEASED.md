# Unreleased

Work that has shipped to no one yet. `/changelog` writes here; `/preflight` renames this file to
`YYYY-MM-DD-<release>.md` when the release rolls and drops a fresh empty one in its place.

**Concurrency:** several agents work this project at once. **Never `Write` this file whole** — append
with an `Edit` anchored inside a `## Added` / `## Changed` / `## Fixed` heading, and re-read
immediately before editing, because another agent may have written since. A whole-file write is the
one operation that destroys a concurrent entry without complaining; a stale anchor merely errors,
which is the point.

[Index](../CHANGELOG.md) · [Conventions](CONVENTIONS.md) · Previous release: [Update 3](2026-09-07-update-3.md)

---

- **Shared modules:** `Telemetry` — the `Tutorial` funnel's step table, 11 rows to 8. Mirror
  verified ✅ (29005 bytes / checksum 1995265427, identical in all three places).
- **Data-affecting:** no. The tutorial's payout totals are unchanged (250 Cash / 50 Tokens); only
  the per-step instalment moves, 25/5 over 10 steps to 31/6 over 8 with the 2/2 remainder settled
  in `payOut`. Nothing on the profile changes shape.

---

## Added

## Changed

- **The onboarding tutorial is 8 steps, down from 10.** `FreeMouse` (open the settings panel) and
  `Stats` (open the scoreboard) are gone from `TutorialDirector.STEPS`, along with everything
  hanging off them in `TutorialClient` — copy, key icons, the settings-gear glow, the mobile STATS
  cue, both client-observed gates and the step-to-step panel closes. `LiveFire` inherited
  `FreeMouse`'s `stop = 4`, so the walk to the last pad survives and now leads straight into the
  fight. The funnel arithmetic that decided it is in the `STEPS` comment. `CLIENT_GATED` is empty
  and `report`/`TutorialProgress` are left standing for a future step.
  **Rollback risk:** low — reverting restores both steps and nothing stored changes. Revert
  `Telemetry` with them or the funnel logs steps 8-11 with no name.
  **Verified:** syntax + three-way mirror checksums. **NOT playtested.**

- **Live Fire is 20 seconds, down from 30, and shows a countdown.** The banner's dormant
  `ProgressLabel` — the "6 / 10" counter retired on 2026-08-10 — was renamed `CountdownLabel` and
  repurposed rather than a new label being authored. The client owns the clock and starts it when
  the line pops, which is the instant the server's own deadline is set from.
  **Watch this one:** the five bots spawn 100-125 studs out and take 6-9s to walk in, so 20s is
  only ~11-14s of actual fighting and the countdown now puts a number on screen for the wait. If
  it reads badly, the lever is starting the clock at the bots' arrival — noted in the `STEPS`
  comment, not yet done.
  **Rollback risk:** low. `TutorialClient` falls back to no countdown if the label is missing, so a
  place reverted past the rename degrades quietly instead of erroring.
  **Verified:** device matrix at Galaxy A06 / iPad / 640×480 windowed / 1080p — legible and clear
  of the banner line at all four. **NOT playtested.**

- **The `Tutorial` funnel is 8 rows, down from 11** (`Telemetry.TUTORIAL_FUNNEL_STEPS`, mirrored).
  "Free The Cursor" and "Stats Panel" went with their steps; "Completed Training" was cut because
  it read 100.00% off Live Fire every day — finishing the stopwatch *is* finishing the lesson, so
  the row could never differ from the one above it. Live Fire is the terminal. **NewPlayer step 3
  is untouched** and still fires on the same signal in `runOutro`.
  **The funnel name is deliberately unchanged.** Steps 1-7 are identical, so the dashboard reads as
  a clean before/after across the cut, which is the point of making it. The cost: step 8 blends
  "Free The Cursor" before 2026-09-09 with "Live Fire" after it, and steps 9-11 stop reporting —
  **read step 8 by date.**

## Fixed
