# 116 — Vesper's world hold pose doesn't grip the sniper

**Area:** Hunters / Vesper · **Sev:** P2 · **Status:** CLOSED 2026-08-15 — not a real defect
**Raised:** 2026-08-14, owner report · **Closed:** 2026-08-15

**Closed 2026-08-15 on an owner playtest — two clients plus server.** Vesper reads correctly in
third person across deaths, the ultimate and the rest of a round. There is no grip defect and
there never was one: the whole symptom was the hold **not playing** on other players' screens,
which was the missing `VesperWorldIdleClient`, fixed the same day. This item and that one were
always the same bug seen from different distances.

The clip observation below is left as a record, not a defect: `rbxassetid://90093651135788` keys
`LeftUpperArm` and not `LeftLowerArm`, so the forearm resolves from the core locomotion clip. That
is measurably true and visually **fine** — the playtest is the evidence that outranks it. Do not
re-raise it from a static read of the keyframes; if the hold ever looks wrong again, the thing to
check is whether the twin is running, not the clip.

## Symptom

In third person, a Vesper player's hands are not on the world sniper. The gun itself looks seated —
it rides the right hand where it should — but the arms don't hold it: the off hand isn't on the
forestock and the pose reads as if the character were carrying nothing.

Owner-facing only in the sense that **you never see your own** — `HideLocalWorldSniper` hides the
cosmetic in first person, so this is entirely what other players see of you.

## Repro

Superseded. What was reported here was the world hold not playing at all on other players'
screens, which reads from a distance as "she isn't holding it properly". A Vesper **bot** always
looked correct — bots are server-owned rigs, so the server's track holds on them — and that
asymmetry is what made this look like a pose problem rather than a playback one.

## The test that closed it

Owner playtest 2026-08-15, two clients plus a server: Vesper watched in third person across
deaths, the ultimate and general play, on the fixed build. Correct throughout.

## Release entry

The `VesperWorldIdleClient` fix, 2026-08-15 — see [Hotfix 1.1](../../2026-08-15-hotfix-1-1.md). Same bug, one entry.
