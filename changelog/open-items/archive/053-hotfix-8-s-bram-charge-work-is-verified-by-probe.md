# 53 — Hotfix 8's Bram charge work is verified by probe and simulation, never played

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Hotfix 8's Bram charge work is verified by probe and simulation, never played** (raised:
Hotfix 8). MCP playtesting is unavailable, so every entry in that release closed on a harness rather
than a match. The evidence is unusually strong for the refactor itself — an A/B harness ran the old
and new wall test over **10,944 comparisons** (76 origins across real map geometry x 72 headings x
both cast distances) with **zero** mismatches, the clamp matched over 4,800 cases, and
`settlePoint` / `carryPoint` / `isPastPlane` matched their old inline forms to within 1.4e-4 studs.
**That proves the geometry is unchanged, which is exactly what a refactor needs and is not the same
as proving the charge feels right.**

Four checks in this release are **not** covered by a numbered launch issue and will otherwise go
unverified — #22, #26, #27 and #28 each track their own above:
1. **Vesper's Pinning Round on a bot** — E marks bots visibly for the zone's life and clears on exit
   or at 6s, and a bounty bot still shows a single gold glow with no jittering copy at the raw server
   position. A marked bot that is then shot **will** flicker; that is the Highlight-channel defect
   under #27 and is expected here.
2. **`MatchStart` analytics rows** — play a match and confirm new rows carry real values rather than
   `Unknown|Unknown`. This one is checkable from the dashboard rather than in-game, so it is the
   cheapest of the four.
3. **A player slammed into a wall ends flush against it**, not a gap short of it.
4. **A player slammed by a *bot* Bram is seated against the wall** the same way. Separate from (3):
   the bot charge is a different implementation and only the geometry is now shared.

The refactor also **deliberately did not unify** input, target selection, wall-detection authority
(client reports at 5, server re-verifies at 18) or each caller's exclude list — a bot additionally
excludes `VesperHookSpotsBot` and `WallMap`, so a bot Bram cannot slam a victim into its own
navigation scaffolding where a player Bram can. **If a slam behaves differently between a player and
a bot Bram, that asymmetry is intended and is the first place to look**, not a regression in the
shared module.
