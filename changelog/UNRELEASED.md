# Unreleased

Work that has shipped to no one yet. `/changelog` writes here; `/preflight` renames this file to
`YYYY-MM-DD-<release>.md` when the release rolls and drops a fresh empty one in its place.

**Concurrency:** several agents work this project at once. **Never `Write` this file whole** — append
with an `Edit` anchored inside a `## Added` / `## Changed` / `## Fixed` heading, and re-read
immediately before editing, because another agent may have written since. A whole-file write is the
one operation that destroys a concurrent entry without complaining; a stale anchor merely errors,
which is the point.

[Index](../CHANGELOG.md) · [Conventions](CONVENTIONS.md) · Previous release: [Hotfix 3.1](2026-09-09-hotfix-3-1.md)

---

- **Shared modules:** none yet.
- **Data-affecting:** no.

---

## Added

- **NEWGUI port — jump stretch and landing squash on the HUD panels (both match places).**
  `HunterHudShake.Jump` stretches the weapon panel, the ability / ultimate containers and the
  portrait to 1.04 on the `Jumping` edge; `Play` (landing) now also squashes them to 0.94, on the
  authored `ImpactScale` UIScales the restyle added. `LandingImpactClient` reports the jump edge.
  Amplitudes are first drafts for the owner's live playtest; `TOUCH_TILE_IMPULSE` in
  `HunterHudShake` is the flip if the tiles make the mobile ability row step. Revert: delete the
  four `ImpactScale`s per template and the module degrades to the old bob. Harness-verified
  (compiles, template shape asserted), not playtested.
- **Kill-cam card is authored** — `StarterGui.KillCamGuiTemplate.KillCamGui` (a Folder wrapper so
  the round sweep never force-shows it); `KillCamClient.createGui` clones it instead of building
  three labels in code. White SemiBold / Medium type from the design place; the `KillerTitle`
  slot and the feed-clearance placement are unchanged. Not playtested.
- **Objective line** — `EyeCandy.Canvas.ObjectiveAnnouncement` (the design's `AnnouncerGui` text)
  shown through a new `OBJECTIVE` action on `AnnouncementEvent`, in the notice lane so it queues
  behind a kill card. `DominationAudioClient` fires it beside its claimed / lost cues with relative
  wording: "YOUR TEAM IS NOW CONTROLLING A POINT" / "ENEMY TEAM IS NOW CONTROLLING A POINT" /
  "YOUR TEAM LOST A POINT" (the last is a first draft for the owner). Not playtested.

## Changed

- **NEWGUI port — the "Bounty - UI Update" HUD restyle in Redwater and Frostbite** (spec
  `NEWGUI_PORT_SPEC.md`, built by `NEWGUI_PORT_RESTYLE.luau`; the twelve owner decisions D1–D12
  of 2026-09-13). Both `ReworkedHunterGui` templates: slate cards and slabs, pink / yellow
  cooldown fills drawn **above** the card (D3), no gold rope on the tiles or portrait (D4), a
  `ModernReadyAccent` underline toggled by `HunterHudCooldown` / `UltimateReadyFX` (D2), Bold
  Italic ammo / name / badges, white–red–slate health segments (`SegmentedHealthManager`
  constants in both templates changed to match). Desktop geometry follows the design (canvas
  0.22 at y 0.874; ability grid `CellSize 0.485` + `CellPadding 0.015` — 0.5 wrapped tile E under
  tile Q). **Touch geometry is byte-identical to before**: the script's snapshot diff reported 0
  frozen violations on `HunterGuiMobile`, and absolute rects were equal before / after at
  `samsung_galaxy_a06`, `iphone_XR`, `ipad_6th_generation`, `vga`, `hd_1080`. Mobile has ONE slab
  (`ModernPlayerPanel`, sized in scale of the frozen PlayerFrame) because its WeaponFrame overlaps
  the PlayerFrame; `WeaponFrame.ZIndex` 1→2. The HUD paint floor moved: desktop ~0.777→~0.806,
  touch 0.830→~0.819 (3.4px higher on a phone, still 13px clear of the announcement stack);
  `DominationClient` / `AnnouncementController` comments updated, constants unchanged. Revert:
  the two templates are only recoverable from the previous place version — no flag. **Awaiting
  the owner's visual sign-off; vault / graph updates held until then.**
- **Quick wins, both places (D6, D7, D11, D12).** `RoundStatusGui` team chips opaque with
  `UICorner (0.15, 0)` and black strokes; `DominationGui` flat black (shadows off, team bars and
  pad circles `#000000`; the 2026-08-29 gradients stay); `BountyListGui` full restyle — 0.242 ×
  0.168 canvas, square portraits with a black ring + drop shadow, raised name, darker reward
  stroke (scaled ×2.5, never assigned), `BountyListClient.HEADROOM_SCALE` re-derived
  (`0.0569 × 0.1684`); the five touch buttons opaque `#131415` (FIRE keeps its red) in the
  authored instances AND the fallback constants of `HunterMobileFireButton` / `JumpButton` /
  `ReloadButton` / `SprintButton` / `VesperScopeController`; SCOPE gained the Border ring the
  other four carry. The BountyList canvas is the one touch-geometry change in the port —
  edit-mode matrix only, needs the phone look.
- **Cross-place check:** every touched script is byte-identical in Redwater and Frostbite;
  the two HUD templates and the quick-win GUIs hash equal. `DominationGui` differs only in
  pre-existing runtime leftovers (capture-bar text, sweep gate colours), not in the port's edits.
  `execute_luau` edits are not captured by the changelog hook — this entry is hand-written from
  the spec.

- **NEWGUI first look, round 1 (owner, 2026-09-13, both places).** Skill tiles fill **white**
  with a **black** (`SLATE_900`) ready underline; pink is gone from the tiles: `CooldownBar` is now bottom-anchored with a positive
  height (`HunterHudCooldown.READY_SIZE` +1 — a negative-height frame did not render mid-fill),
  clips a dark icon copy (`ModernFillContent.ModernAbilityOver`, mirrored off `Ability.Image` by
  `HunterHudCooldown`) so the glyph reads on both halves, and the countdown label gets a dark
  text stroke. Ultimate tile untouched. Vesper's rifle / Bram's shotgun Fit boxes moved inside
  the desktop slab (`VesperHunterGuiClient` / `BramHunterGuiClient`). `BountyListClient` in
  Domination measures `DominationGui.CapturePointClaimed` and hangs the strip 2px under it
  (names ran through the dials on every screen). Mobile `ModernPlayerPanel` flush with the
  portrait (0.76 tall at y 0.5). Recorded as the `firstlook` part of `NEWGUI_PORT_RESTYLE.luau`.
  Revert: the four scripts to their 2026-09-13 morning versions and re-run the port's `hud` part
  (the instances are only recoverable from the place version). Edit-mode captures at six
  viewports; not playtested. Still awaiting the owner's second look.

## Fixed
