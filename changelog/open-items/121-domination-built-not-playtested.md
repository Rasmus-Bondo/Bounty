# 121 — Domination is built end to end but nobody has played it

**Status:** BUILT (unverified) · **Sev:** P1 · **Raised:** Domination build (2026-08-22)

## Symptom

The third gamemode exists in all three places — rules module, HUD, pad colouring, bot objective
bias, lobby button, Wallet reasons — and every piece is compile-verified and mirror-verified, but
the mode has not run once. Anything from "the capture meter never moves" to "the round never ends
at 500" is still possible.

## Repro

Not a bug report; a sign-off owed. In Studio, set `ServerScriptService.RoundSystem.Config.
FORCE_GAMEMODE = "domination"` in the match place, press Play, then set it back to `nil` (it must be
`nil` in anything published, DEV included). On the dev places, pick DOMINATION in the lobby picker
and PLAY.

## The test that closes it

One full match on **each** map, watching for:

1. Round start: all three pads neutral (grey / white), HUD shows `0 / 500` both sides, score chips
   hidden, the "YOUR TEAM IS BLUE" banner still shows.
2. Stand on a neutral pad alone: `CAPTURING : 7.5` counts down, your pad indicator fills, pad turns
   blue for you and red for an enemy viewer; `OBJECTIVE CAPTURED +80 XP` row; your score starts
   climbing at ~1 point per 1.5 s (plus the trickle).
3. Stand on an enemy pad alone: 15 s total, pad goes grey at the halfway point with
   `OBJECTIVE NEUTRALISED +40 XP`, then blue with the capture row. Two allies on it: 10 s.
4. Both teams on one pad: bar freezes, readout says `CONTESTED`, nobody earns from it.
5. Walk off mid-capture: the meter drifts back (0.5× solo speed); no progress is banked.
6. Die inside a pad your team owns, killed by a human: killer's feed shows
   `OBJECTIVE DEFENDED +15 XP` on top of the kill row.
7. Bots leave the houses and walk to pads **whether or not an enemy is alive somewhere** (a team-mode
   bot always has a target — the first build only moved idle bots, and none ever left), mill about on
   them, and **fight from the pad** (turn to the nearest enemy they can see, fire, keep strafing
   inside the radius — they do not leave it to chase); on the way they break off only for an enemy
   within 20 or one they can see within ~65, then resume the walk; no pad gets more than ~3 of one side's bots. On Frostbite expect a few red bots stuck
   in the house (open item 123, pre-existing).
8. First side to 500 ends the round at once (not at the clock); the team banner reads
   `YOUR/ENEMY TEAM WINS 500 - n`; 600 s without a winner decides on score, equal is DRAW.
9. Mode ballot shows three tiles and lays out on a phone; picking Domination after a TDM or FFA round
   switches cleanly (pads neutral, HUD enabled) and switching away clears the pad colours and hides
   the HUD.
10. Frostbite specifically: the HUD, the pad colours and the beams all work (the gui was copied, the
    pads use the same prefix).

Also read the `[Domination]` warnings in the output — a beam more than 30 studs from its pad, or a
missing beam, warns at boot.

## Notes

The tuning dials and what to move first are in the source comments on
`RoundSystem.Config.DOMINATION_*`. Diagnosis of anything found here goes in the release entry.

**Owner playtest 2026-08-22 (after the bot fixes):** the bot behaviour — item 7 — "feels good for
now". The other nine items are still owed.
