# 120 — Team spawn markers need a playtest in both houses on both maps

**Status:** VERIFIED · **Sev:** P2 · **Raised:** Unreleased (2026-08-19) · **Closed:** 2026-08-19

## Symptom

Reported from a Frostbite Claim playtest: players spawned **up under the roof** instead of on the
ground floor of the spawn house.

Two generator faults, both now fixed:

1. **Wrong storey.** Frostbite's floor level was inferred from a surface histogram, which picked the
   upper deck (Y≈35) rather than the ground floor the doors open onto (Y≈7.4 red / 5.4 blue). The
   floor is now taken from a raycast beneath the doors, which is how Redwater's was resolved and is
   the only anchor that means "the floor players walk on".
2. **Markers outside the walls.** Candidates were accepted on any surface belonging to the base
   model, which included the foundation apron outside the building. Five of Redwater's twelve red-house
   markers were out there, under boulders. The sweep now requires the ceiling above a candidate to
   belong to the house too, and orders candidates by distance to that floor's doors.
3. **Markers inside the decorative crates**, reported from a second Frostbite playtest — bots spawned
   in the props and were stuck. Clearance was tested with an upward ray, and a Roblox raycast whose
   origin is *inside* a part does not report that part, so a candidate standing in a crate read as
   perfectly clear. Clearance is now a solid-part overlap test (`GetPartsInPart`) over the volume the
   rig occupies, which cannot miss the part it starts inside.

A third fault sat underneath both: the sweep sampled the floor in the model's **own bounding-box
space**, and both maps' bases have rotated pivots — Frostbite's tipped so the box's local Z axis
points straight down. That swept a vertical plane instead of a horizontal one and collapsed all
twelve markers onto a single point. The sweep is now world-axis-aligned.

The earlier version of this item claimed Frostbite's houses could only fit eight markers with ~6
studs of headroom. **That was the upper deck being measured, not the houses.** On the ground floor
both maps take twelve markers with 7.5–11.5 studs of headroom.

## Repro

Team Deathmatch on either map. Spawn and respawn several times in both houses and watch where you
land.

## The test that closes it

Spawn and respawn in all four houses (both maps, both sides) and confirm every arrival is **on the
ground floor, inside the walls, facing out** — not on the roof, not on an upper storey, not on the
apron outside, and never two fighters in the same spot. Nine or more fighters on one side exercises
the wrap, since slot assignment wraps modulo twelve markers.

## Notes

Current state, harness-verified in edit mode: twelve markers per house on both maps, every one
confirmed enclosed by the house's own floor and ceiling, **zero with any `CanCollide` geometry in the
spawn volume** — checked both for the standing rig and for the rig at the instant of the +4 lift —
spacing ≥5.1 studs, headroom 7.7–11.3 studs.

Diagnosis lives in the release entry: [Unreleased](../UNRELEASED.md).

**Closed 2026-08-19:** the owner playtested the spawn houses and confirmed spawning is correct in
both houses on both maps — on the ground floor, inside the walls, and clear of the decor.
