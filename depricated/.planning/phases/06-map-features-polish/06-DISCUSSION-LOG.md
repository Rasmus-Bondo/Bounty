# Phase 6: Map Features & Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-05
**Phase:** 06-map-features-polish
**Areas discussed:** Destructible objects, Zone shrinking system, Ragdoll consistency, Map reset integration, Zone boundary shape

---

## Destructible Objects

### What types of destructible objects?

| Option | Description | Selected |
|--------|-------------|----------|
| Barrels only | Start with the 4 barrels already in Workspace | |
| Barrels + crates | Two object types with different break behaviors | |
| Barrels + crates + windows | Three types covering different materials | |
| You decide | Claude picks appropriate types | |

**User's choice:** Windows (custom input)
**Notes:** User specifically wants windows as the destructible type.

### How should destructible objects break?

| Option | Description | Selected |
|--------|-------------|----------|
| Instant shatter | One shot destroys immediately with particle burst | ✓ |
| Health-based | Objects have HP, partial damage shows cracks | |
| One-shot with physics debris | Shatters into physics parts that fly and settle | |

**User's choice:** Instant shatter

### Should destroyed objects provide gameplay effect?

| Option | Description | Selected |
|--------|-------------|----------|
| Visual/audio only | Purely cosmetic breaking | |
| Cover removal | Destroyed objects lose collision | |
| Damage splash | Barrels explode dealing area damage | |

**User's choice:** Custom — "The window should break and the bullet should continue through like it had not been there"
**Notes:** Bullet passthrough is the key mechanic. Window shatters and bullet continues as if unobstructed.

### Should barrels also be destructible?

| Option | Description | Selected |
|--------|-------------|----------|
| Windows only | Focus on windows as single destructible type | ✓ |
| Windows + barrels | Both break with different behaviors | |

**User's choice:** Windows only

---

## Zone Shrinking System

### Zone boundary visual?

| Option | Description | Selected |
|--------|-------------|----------|
| Damage fog wall | Semi-transparent colored fog at boundary edge | |
| Sandstorm | Western-themed dust storm that closes in | |
| Invisible boundary | No visual wall, just damage when outside | |

**User's choice:** Sandstorm, with note: "Fire on the ground"
**Notes:** User wants fire on the ground as the zone boundary visual, not a sandstorm in the air.

### Zone damage rate?

| Option | Description | Selected |
|--------|-------------|----------|
| Gradual pressure | Low damage early, increasing per phase | |
| Consistent sting | Same damage rate throughout all phases | ✓ |
| Instant kill boundary | Touching fire = instant death | |

**User's choice:** Consistent sting

### Zone phase timing?

| Option | Description | Selected |
|--------|-------------|----------|
| Even split | 25 seconds per phase | |
| Front-loaded exploration | 40s/25s/20s/15s | |
| You decide | Claude picks pacing | |

**User's choice:** Custom — "2.5 min each phase 10 min for a round"
**Notes:** Round time should be 10 minutes (600 seconds), 150 seconds per zone phase. Config.ROUND_TIME needs update from 100 to 600.

### Event phase feel?

| Option | Description | Selected |
|--------|-------------|----------|
| Just smaller zone | No special mechanics, just tighter area | ✓ |
| Faster shrink speed | Zone shrinks faster during event phase | |
| Visual escalation only | Same rate but more intense fire visuals | |

**User's choice:** Just smaller zone

---

## Ragdoll Consistency

### Known ragdoll issues?

| Option | Description | Selected |
|--------|-------------|----------|
| Not sure yet | May work fine, needs testing | ✓ |
| Bodies glitch out | Spaz, clip through floor, fly unpredictably | |
| Inconsistent across clients | Different ragdoll views per client | |
| You decide | Claude audits and fixes | |

**User's choice:** Not sure yet
**Notes:** No specific known issues. Low priority per PROJECT.md. Researcher should audit.

---

## Map Reset Integration

### How should destroyed windows reset?

| Option | Description | Selected |
|--------|-------------|----------|
| Clone from template | Store originals in ServerStorage, clone fresh on reset | |
| Property restore | Save original properties, restore without re-creating | |
| You decide | Claude picks most reliable approach | ✓ |

**User's choice:** You decide

---

## Zone Boundary Shape

### Zone shape?

| Option | Description | Selected |
|--------|-------------|----------|
| Circular | Classic battle royale circle | |
| Rectangular | Matches canyon geometry, shrinks from edges | |
| Canyon-following | Fire closes from both ends toward middle | ✓ |

**User's choice:** Canyon-following
**Notes:** Fire closes from both ends of the canyon squeezing players toward the middle. Most thematic.

### Zone center point?

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed center | Always converges to canyon middle | |
| Random center | Final zone shifts randomly each round | ✓ |

**User's choice:** Random center
**Notes:** Prevents camping the same spot every round.

---

## Claude's Discretion

- Window placement count and locations
- Fire visual implementation details
- Zone damage exact value
- Window shatter effects
- Ragdoll constraint tuning
- Destructible reset strategy
- Zone boundary detection method
- Zone HUD indicators

## Deferred Ideas

None — discussion stayed within phase scope
