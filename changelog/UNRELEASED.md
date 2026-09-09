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
- **Mirrored gamemode code** (Redwater ↔ Frostbite, not part of the 21): `TutorialDirector`,
  `TutorialClient`, `BotVisualClient`, and `StarterGui.TutorialGui`'s `CountdownLabel`. Verified ✅
  — 87294 / 113735 / 60316 bytes, checksums 485986420 / 1651700463 / 32834051, identical in both.
- **Data-affecting:** no. The tutorial's payout totals are unchanged (250 Cash / 50 Tokens); only
  the per-step instalment moves, 25/5 over 10 steps to 31/6 over 8 with the 2/2 remainder settled
  in `payOut`. Nothing on the profile changes shape.

---

## Added

- **The two first-takedown bots wear the red enemy outline.** The ordinary TDM/Domination
  `TeamOutline` treatment — outline only, `Occluded`, `OutlineTransparency = 0.45` — in a fixed
  `TeamView.WORLD.red`, because the lesson has no teams for TeamView to resolve and those two are
  simply "the enemy" for one step. Deliberately **not** the bounty style, which is `AlwaysOnTop`
  and reads through rock: the lesson teaches that signal two steps later and the two must not look
  alike. `TutorialDirector` stamps a `TutorialOutline` attribute on the server rig and
  `BotVisualClient` draws it on the client clone, because a Highlight parented to a bot's server
  rig never renders — the rig is hidden part by part and the player sees the clone. Read off the
  source rig and watched with `GetAttributeChangedSignal`, so a stamp landing a frame after the
  spawn still takes.
  **Rollback risk:** low, and the halves are independent — without the director the attribute is
  never set and `BotVisualClient` draws nothing; without `BotVisualClient` the attribute is inert.
  **Verified:** syntax + mirror checksums across both match places. **Not seen rendered** — a
  bot-visual clone only exists at runtime, so this one needs the playtest.

## Changed

- **The onboarding tutorial is 8 steps, down from 10.** `FreeMouse` (open the settings panel) and
  `Stats` (open the scoreboard) are gone from `TutorialDirector.STEPS`, along with everything
  hanging off them in `TutorialClient` — copy, key icons, the settings-gear glow, the mobile STATS
  cue, both client-observed gates and the step-to-step panel closes. **The lesson also stops at
  two pads instead of three:** `LiveFire` briefly inherited `FreeMouse`'s `stop = 4` and lost it
  the same day, so the closing fight is staged where the bounty step leaves the player and stop 4
  (`CheckPointTutorial3`) is never visited at all — a 122-stud walk to a third pad being exactly
  the elapsed time the cut exists to remove. The funnel arithmetic that decided it is in the
  `STEPS` comment. `CLIENT_GATED` is empty
  and `report`/`TutorialProgress` are left standing for a future step.
  **Rollback risk:** low — reverting restores both steps and nothing stored changes. Revert
  `Telemetry` with them or the funnel logs steps 8-11 with no name.
  **Verified:** syntax + three-way mirror checksums. **NOT playtested.**

- **Live Fire is 20 seconds, down from 30, and shows a countdown.** The banner's dormant
  `ProgressLabel` — the "6 / 10" counter retired on 2026-08-10 — was renamed `CountdownLabel` and
  repurposed rather than a new label being authored. The client owns the clock and starts it when
  the line pops, which is the instant the server's own deadline is set from.
  **The countdown sits under EXIT TRAINING**, reparented out of the banner onto the gui root.
  `layoutCountdown` owns its rect *and* the banner's touch position together, both derived from
  the button's live height — the number goes between the two, so they cannot drift apart. On
  touch the banner is otherwise pinned 16px under the button, which is not room for a number, so
  it takes a reservation for the life of the countdown rather than that drop being retuned for
  all eight steps; `applyTouchLayout` reads the same flag, so a viewport change mid-countdown
  re-applies the shift instead of quietly undoing it.
  **The walk-in problem went with the move to area 2.** The five bots now spawn on the area-2
  ultimate line, 44-78 studs out and 3-5s in, rather than the area-3 free-roam ring at 100-125
  studs and 6-9s — so 20s is ~15-17s of real fighting instead of ~11-14. `FreeRoamBotSpawn` is
  unused by the lesson now: from area 2, five of its eight markers are 21-73 studs away on every
  bearing (21 being the ambush spawn the distance rule exists to prevent) and the other three sit
  behind the area-3 wall. If area-2 free-roam markers are ever authored, revisit the choice.
  **Rollback risk:** low. `TutorialClient` falls back to no countdown if the label is missing, so a
  place reverted past the rename degrades quietly instead of erroring.
  **Verified:** device matrix at 1080p, 640×480 windowed and a Galaxy A06 after the move — the
  number sits under the button and clears the banner at all three, by 16px on the phone, which is
  the tightest of them. Tablet is the same arithmetic with more room. **NOT playtested.**

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
