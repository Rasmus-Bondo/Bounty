# 80 — The three items the mobile touch UI rebuild raised, and why two of them were not real

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Closed 2026-08-08 — the three items the mobile touch UI rebuild raised, and why two of them
were not real.** Recorded here rather than deleted, because both false leads look like genuine
defects on paper and will be re-raised by anyone reading the layout code cold.
1. **`HunterMobileFireButton._applyEdgeInset` — real, and deleted.** It was reported as fighting
   `HunterMobileClusterLayout.apply` for FIRE's X. It was worse and better than that: the cluster
   rebuild had already stopped `:Start()` calling `_watchEdgeInset`, so the whole path was
   *unreachable* — it hooked nothing and wrote nothing, and the "undefined order on rotation"
   risk could not actually occur. Deleted along with `_abilityRightEdge`, `_watchEdgeInset`, the
   three `EDGE_INSET`/`HUD_CLEARANCE` constants and the module's only `require`
   (`HunterIntroTags`): 436 → 322 lines. Its per-aspect measurement table is kept as a source
   comment, since it is the record of why a static right-edge offset is impossible.
2. **`HunterIntroTags.WRAP_LINES` — not recoverable screen space. Do not chase this again.** The
   three-line reserve does look like ~35pt of waste sitting exactly where the touch cluster now
   lives, but **nothing measures the box.** Both consumers — `HunterMobileSprintButton`'s
   ability-row clamp and `HunterMobileReloadButton`'s authored slot — measure `TextBounds`, so
   the empty air is already free to them. Nor would dropping to 2 shrink what they *do* measure:
   the longest copy (`GRAPPLE TO SURFACES`) wraps to two lines **at the ceiling text size**, so a
   two-line box renders identically and the band is the same height either way. All the change
   would remove is the headroom protecting a longer future phrase, or a handset with wider
   metrics than Studio's, from being squeezed toward `MIN_TEXT` or clipped — which is exactly
   how `CHARGE AND PIN` and `LIFESTEAL FRENZY` failed on a real device before this box existed.
   Now stated in the source at the constant, and in the two consumers' comments.
3. **The PC HUD portrait overhang — a measurement error, not a defect.** The claim was
   `ScreenGui.Canvas.PlayerFrame.PlayerHunterFrame` at X `0.1741` against a half-width of
   `0.1770`. That `0.1770` is the **mobile** frame's half-width: both HUDs author the frame at
   `0.76` inside a `PlayerFrame`, but the mobile canvas is aspect 7.4 with a `0.29`-wide
   PlayerFrame and the PC canvas is aspect **10.0** with a `0.364`-wide one, which puts PC's half
   width at `0.10440`. Measured by rendering both in CoreGui: the PC frame sits **21px inside**
   the canvas (0.0254 of canvas width) while the mobile one is flush at 0.00. Since the canvas is
   aspect-locked, that margin is the same fraction on every screen. **No PC change was made** —
   the touch-only scope of this release held.
*(raised and closed: mobile touch UI rebuild, 2026-08-08)*
