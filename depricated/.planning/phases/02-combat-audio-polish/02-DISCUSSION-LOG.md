# Phase 2: Combat & Audio Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-29
**Phase:** 02-combat-audio-polish
**Areas discussed:** Crosshair, Recoil, Impact materials, Audio approach

---

## Crosshair Design

| Option | Description | Selected |
|--------|-------------|----------|
| Simple dot | Clean center dot, properly aligned to where bullets land. Matches western theme. | (partial) |
| Cross/plus shape | Traditional FPS crosshair with 4 lines forming a + shape | |
| Dynamic spread | Crosshair lines expand when moving/firing to show accuracy cone | |

**User's choice:** Simple dot selected, but then clarified: do NOT change crosshair style — Aetria handles visual design. Phase 2 should only fix the alignment bug (crosshair is off from where bullets land).

| Option | Description | Selected |
|--------|-------------|----------|
| White with black outline | High contrast on all backgrounds | |
| Red dot | Classic FPS red dot sight feel | |
| You decide | Claude picks | |

**User's choice:** "Dont change the style of crosshair aetria does this"
**Notes:** Crosshair visual design is Aetria's responsibility. Phase 2 scope is alignment fix only.

---

## Recoil Feel

| Option | Description | Selected |
|--------|-------------|----------|
| Heavy & deliberate | Strong upward camera kick with slow recovery. Rewards pacing shots. | ✓ |
| Moderate & snappy | Noticeable kick but quick recovery. Faster follow-ups. | |
| Light & fast | Minimal camera disruption. More arcade-feel, easier on mobile. | |

**User's choice:** Heavy & deliberate
**Notes:** Fits the big revolver feel.

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — spread on rapid fire | Consecutive shots increasingly inaccurate. Resets when pausing. | ✓ |
| No — visual only | Camera kicks but bullets always go exactly where crosshair points. | |

**User's choice:** Yes — spread on rapid fire
**Notes:** Rewards trigger discipline over spam clicking.

---

## Impact Materials

| Option | Description | Selected |
|--------|-------------|----------|
| Stone + Metal + Sand | Covers main canyon surfaces | |
| Just stone and metal | Minimal additions | |
| All common materials | Add glass, brick, grass, concrete too | |

**User's choice:** Custom list: wood, bricks, glass, sand/ground, and rocks
**Notes:** Five specific materials requested. Wood already implemented. No metal requested — replaced with bricks and glass.

---

## Audio Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Client-predicted | Shooter hears gun immediately. Others hear when server processes. | ✓ |
| Server-only | All sounds from server. Simpler but ~50-100ms perceived delay. | |

**User's choice:** Client-predicted
**Notes:** Prioritizes responsive feel.

| Option | Description | Selected |
|--------|-------------|----------|
| Medium range | Full volume ~10 studs, fades by ~200 studs | ✓ |
| Long range | Audible up to ~400 studs | |
| You decide | Claude picks based on map size | |

**User's choice:** Medium range
**Notes:** Can hear nearby fights but not across entire map.

---

## Claude's Discretion

- Arm positioning IK parameter tuning (VIEW-01, VIEW-02)
- Exact recoil values (kick angle, spread, recovery time)
- Exact audio rolloff distances within ~10/~200 guidance

## Deferred Ideas

None — discussion stayed within phase scope
