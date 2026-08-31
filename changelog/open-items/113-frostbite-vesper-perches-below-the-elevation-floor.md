# 113 — Four Frostbite Vesper perches sit below the elevation floor

**Area:** Bots / Frostbite Claim · **Sev:** P3 · **Status:** OPEN
**Raised:** 2026-08-14, from the [111](111-frostbite-vesper-hook-markers-without-standable-pads.md) audit

## Symptom

No warn — this failure is silent by construction. `resolvePerchPad` asks only whether a Humanoid can
stand somewhere, so a marker on flat ground resolves a pad and is treated as a valid perch. Four
Frostbite markers resolve pads that are not high ground:

| Marker | Pad | Height over ground 30 studs out |
|---|---|---|
| `(-30, 28, 269)` | `(-30, 30, 274)` | 2.3 |
| `(-64, 19, 159)` | `(-65, 19, 160)` | 9.8 |
| `(-111, 40, 112)` | `(-111, 40, 109)` | 16.1 |
| `(-52, 46, 14)` | `(-49, 47, 14)` | 16.4 |

All 33 Redwater perches clear 19 studs on that measure (median 57). Eight further markers were below
the floor and were nudged onto real perches on 2026-08-14; these four have no perch within 12 studs
and were left in place by owner decision, because relocating them means moving a marker 33–54 studs
onto a different structure — a perch-layout decision, not a marker fix.

## Repro

Static. Replicate `evaluatePad` (`BotCombat:975-1011`) over `Workspace.VesperHookSpotsBot`, then
measure each resolved pad's median height above 12 ground probes at 30 studs.

In play: a Vesper bot low in one of these areas has these as her only candidates that satisfy
`heightGain >= 1`, so she grapples to what is effectively floor level and snipes from open ground.

## The test that closes it

Either relocate each of the four onto a structure that clears 19 studs, or delete them and accept
the coverage gap. Then confirm all 40 (or 36) pads clear the floor, and playtest that a Vesper bot
in each of those four areas picks a perch with real height.

Two marker pairs also resolve pads 2.5 and 7.3 studs apart — `(164,65,-62)`/`(165,65,-52)` and
`(-93,90,-22)`/`(-85,90,-29)` — so four markers buy two perches. Worth folding into the same pass.

## Release entry

None yet — not fixed.
