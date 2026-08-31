# 122 — Domination deferrals: Captures on the stat card, the XP-per-minute soak (pads-in-every-mode: done)

**Status:** DEFERRED · **Sev:** P3 · **Raised:** Domination build (2026-08-22)

## Symptom

Three things the Domination spec deliberately left for after the first playtest (the third was closed the
same day; the file slug predates that and is kept because ids and links never change):

1. **The stat card has no Captures column.** Captures / neutralises are paid and shown in the combat
   feed, but not counted anywhere a player can see afterwards. The podium still ranks by kills by
   decision (DOMINATION_SPEC 12.2); the column is the minimum that makes objective play visible.
2. **XP per minute is untested against the other modes.** At 80 / 40 / 15 the objective rewards are
   projected at ~1.4× the XP/min of TDM (spec 12.3) — an owner call, recorded so nobody "fixes" it
   blind. The mode ballot electing Domination every time because it pays more is the failure.
3. ~~**The capture pads and their beams are visible in Deathmatch and TDM.**~~ **Done 2026-08-22** —
   `RoundSystem.CapturePointService` parks them in `ServerStorage.ParkedMapGeometry` for every mode that
   does not declare `UsesCapturePoints`, the way `TeamBaseService` parks the houses. See the Domination
   entry in [UNRELEASED](../UNRELEASED.md). Still owes the playtest look (item 121 checklist).

## Repro

Play any Domination match (1, 2); play any non-Domination match and look for the pads (3).

## The test that closes it

1. A `Captures` column on the post-game stat card, populated from a per-player capture count
   (session stat, not profile shape — it does not need to persist).
2. DEV soak: total XP per player per match in Domination vs TDM, normalised per minute. Above ~1.15×,
   `Config.DOMINATION_CAPTURE_XP` 80 → 60 is the dial; never the kill reward.
3. ~~Either an owner decision that the pads are part of every map's dressing, or a mode-swap of the
   pads / beams through the `TeamBaseService` park-and-restore path keyed on `Gamemode == domination`.~~
   Done — verify in play: no pads or beams in a Deathmatch or TDM round; all three back (with their
   colours working) after a mode ballot into Domination.

## Notes

Raised by the build entry in [UNRELEASED](../UNRELEASED.md). None of these blocks the playtest in
item 121.
