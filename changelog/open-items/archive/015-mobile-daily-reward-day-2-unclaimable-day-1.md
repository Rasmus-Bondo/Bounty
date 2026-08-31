# 15 — Mobile daily reward Day 2 unclaimable, Day 1 difficult

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#15 — Mobile daily reward Day 2 unclaimable, Day 1 difficult.**
*(VERIFIED by the owner 2026-08-03, shipped in [Hotfix 3](../../2026-08-03-hotfix-3.md).)*
**The suspected cause was wrong, so do not re-derive it.** The mobile Play button and the
thumbstick were both ruled out before any fix: `ReworkedUIPlay` already watches `DailyLoginGui`
and disables itself whenever the panel is open, and `StarterPlayer.DevTouchMovementMode =
Scriptable` means Roblox never builds touch controls in the lobby at all. The actual cause was
the mascot **ViewportFrame's transparent bounding rectangle** acting as a tap sink over 88% of
the Day 1 and Day 2 CLAIM buttons.
**The reusable lesson:** a ViewportFrame (or any decorative image) eats taps across its whole
rectangle, not just its visible art — so any art layer that overlaps a button needs its
interactivity killed, and a tap target has to be measured against the *rectangles* above it, not
against what the screenshot looks like. Checked at the time on Galaxy A06 / iPad A16 / 1366×768:
all 7 hit targets ≥ 44×44, no hitbox overlapping a neighbouring tile.
