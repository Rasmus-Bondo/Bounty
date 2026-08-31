# 78 — `BotCombat._slamPin` settles only *bot* victims

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

~~**`BotCombat._slamPin` settles only *bot* victims**; a player gets a bare `"Unpin"` with no safe
seat.~~ **FIXED 2026-08-05 (unverified, unpublished)**, in the Breach Carry shared-geometry
migration — see `UNRELEASED.md`. The settle was gated off for players at `BotCombat:1787` and
`_releasePin:1757` then fired an argument-less `"Unpin"` that `BramWorldFXClient:229` skips because
it type-checks for a Vector3. `_slamPin` now seats **both** victim types, written directly
server-side while the bot still holds network ownership (before `_releasePin` hands it back) rather
than routed through the victim's client — legitimate here because a bot's root is authoritative,
whereas a player Bram must ask the client since his own server HRP lags. Guarded by
`BreachCarryGeometry.isPastPlane`, so a slam granted at long range can never *pull* a victim onto a
wall they were clear of. The **second divergence** found in the same pass is fixed too: the
hardcoded `3` became the config's `SlamWallClearance` (2) — the value the config comment warns
reads as a rebound, which Hotfix 3's 3→2 change never reached — and the back-off is now measured
along the **charge direction** rather than the wall normal, matching the player path (1.53 studs
apart on a 45° hit). A third, unlogged defect went with them: the seat wrote a bare `CFrame.new()`,
i.e. identity rotation, snapping slammed victims to face world +Z; it now preserves their own yaw.
**Still needs a human playtest** — get slammed by a bot Bram and confirm you end flush against the
wall rather than floating short of it, and that a slammed bot is flush at 2 studs rather than 3.
*(raised: #9, fixed 2026-08-05)*
