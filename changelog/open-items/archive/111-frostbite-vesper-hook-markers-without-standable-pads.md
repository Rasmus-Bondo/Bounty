# 111 — Frostbite Vesper hook markers without standable pads

**Area:** Bots / Frostbite Claim · **Sev:** P3 · **Status:** CLOSED 2026-08-15 (never verified)
**Raised:** 2026-08-13, first Frostbite playtest · **Fixed:** 2026-08-14

**Closed 2026-08-15 — owner decision. Never playtested.** Live only since 2026-08-14 (Update 1), so
this is closed on the owner's call rather than on elapsed time; there is no live evidence either
way. If the warn reappears, raise a **new id**.

## Symptom

A server warn during a Frostbite match:

```
[BotCombat] Vesper hook marker at (192, 61, 75) has no standable pad within 6 studs;
excluded from perch selection.        -- BotCombat:1067
```

The marker was dropped from perch selection for the life of the server. Nothing else broke — the
Vesper bot simply never perched there.

## Repro

Solo playtest in Frostbite Claim with a Vesper bot in the match. Observed once, 2026-08-13.

## What was done

The count question this item existed to answer is settled: **exactly one** of the 40 markers failed
the pad test, the one in the warn. It was moved to `(192, 67, 96)`. Diagnosis and the elevation
finding that came out of the same audit are in the 2026-08-14 release entry; the four markers left
in flat ground are item [113](113-frostbite-vesper-perches-below-the-elevation-floor.md).

## The test that closes it

Run a full Frostbite match with a Vesper bot alive across several rounds and confirm **zero**
`has no standable pad` warns, and that she actually reaches and holds the perch near
`(192, 66, 94)`.

Static verification is already done (40/40 markers resolve a pad, replicated in edit mode) and
cannot close this: `resolveGrappleAim`'s spherecast depends on where the bot is standing when it
fires, so reachability only proves out in a match.

## Release entry

2026-08-14 — *Frostbite Vesper bots no longer perch at floor level*.
