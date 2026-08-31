---
name: project_ui_style_guide
description: "UI_STYLE_GUIDE.md in the project root is the authored design spec (colors, fonts, corners, motion, DisplayOrder registry) — read it before creating any GUI instance"
metadata: 
  node_type: memory
  type: project
  originSessionId: 83e042ff-fda0-418b-9f10-36cbf1716294
  modified: 2026-08-05T11:05:50.099Z
---

`C:\Users\2000b\Documents\bulletsandbounty\UI_STYLE_GUIDE.md` — created 2026-08-05 by scanning every
`ScreenGui` in both places (8,730 descendants in Bounty, 2,736 in Redwater) and writing down what the
UI actually **is**, not what someone intended. `CLAUDE.md` points at it under a **UI Style Guide**
heading. It is a **living document — agents may read and edit it**, and `.claude/settings.json`
allows `Read(...)` + `Edit(...)` on it (no `Write` rule — see [[feedback_no_write_permission_rule]]).

**What it settles** so it never has to be re-derived: the color tokens with exact RGB; the three
legitimate fonts (primary is `rbxassetid://12187376174`) and the banned ones; the sharp-panels /
rounded-buttons corner rule; component recipes for panel, setting row, slider, button, toast; the
`TweenInfo` table; and the full `DisplayOrder` registry for Redwater.

**Why it exists:** the design language was only encoded in the instance tree, so each agent
re-guessed it and produced grey `GothamSSm` boxes that did not belong — `StatMenuGui`,
`TeleportOverlay` and the old leave-confirm dialog all drifted that way. Section 10 lists that debt
explicitly so it gets fixed rather than copied.

**Two sections are about speed rather than style, and are the reason the file is worth opening even
for a small tweak.** §1.1 — *a property read-back is not verification*, and a value read off an
existing instance is not necessarily reproducible by assigning it, so **clone UI that already looks
right instead of re-typing its property values**. §9 — the **build-and-verify order**, whose headline
is *run `capture_device_matrix` on the FIRST draft, not the last*, plus a copy-paste geometry
assertion snippet (overlap / 44px touch target / off-screen / mismatched label sizes).

Both exist because rebuilding the leave-confirm dialog took nine build-screenshot-fix cycles and
about six were avoidable: three defects were present in the very first build and got found one at a
time because each round checked a single viewport, and the worst single cost was hand-authoring a
`UIStroke` from a number read off the settings panel (see [[project_uistroke_thickness_scale]]).

**How to apply:** read it before authoring GUI instances; when you establish a new pattern or find a
rule that is wrong, edit the file in the same pass instead of working around it. It is subordinate to
`CLAUDE.md` → UI Rules (author UI as instances, never build it in code) — that file is the *how you
are allowed to build it*, this one is the *what it must look like*.

Related: [[feedback_ui_screenshot_verify]], [[project_uistroke_thickness_scale]],
[[feedback_responsive_breakpoints]], [[project_lobby_screen_insets]].
