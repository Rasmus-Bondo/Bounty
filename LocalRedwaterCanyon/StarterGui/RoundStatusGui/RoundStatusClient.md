---
tags:
  - client
  - localscript
path: game.StarterGui.RoundStatusGui.RoundStatusClient
type: LocalScript
lines: 362
---

# RoundStatusClient

Client-side HUD that displays the match timer and zone phase timer at top center of screen.

## What it does

1. Renders two stacked timers at top-center, flush with the top edge of the screen: the match timer (`TimerSlot.TimerLabel`, amber, 45px) and the zone/phase timer directly under it (`ZoneLabel`, pale cream, 22px). `Container` is 58px tall at `y = 0` offset and its UIListLayout sorts by **Name**, which is what puts TimerSlot above ZoneLabel
1b. **The list padding is -9px, deliberately negative.** Both labels are `TextScaled`, so each box carries a few px of unused font padding at its ends and a zero gap still rendered as roughly 10px of air between the glyphs. Pulling the rows together by 9px seats the phase timer directly under the match timer; the container height is `45 + 22 - 9` and follows it. This is why nothing here should assume `Container` height equals the sum of its children
1a. **There is no status line.** A `StatusLabel` used to sit above both timers showing the round phase text ("Waiting for players...", "Intermission - round starting in N...", "Not enough players!", the winner line, "Returning to lobby..."). It was deleted along with this script's `RoundStatus` wiring, which is what lets the timers reach the top edge — the label's 30px row was the gap. RoundController still writes the `RoundStatus` StringValue and nothing renders it. Consequence: in the Waiting and Not-enough-players states the timer is 0 and therefore hidden too, so top-center is **empty**; the intermission countdown still reads as the timer's own M:SS, and the winner is announced by the VictoryShowcase podium instead
2. Reads `RoundTime` IntValue and formats it as M:SS countdown timer in orange
3. Reads workspace attributes `ZonePhaseName`, `ZonePhaseTimeLeft`, `ZonePhase` for zone info
4. Hides timer when value is 0, hides zone label when phase <= 1 or empty
5. Updates reactively via `.Changed` and `GetAttributeChangedSignal` connections
5a. **Mobile fade:** on touch devices both timer labels and their UIStrokes drop to `TextTransparency = 0.3` (`MOBILE_TEXT_TRANSPARENCY`, the one constant to tune). The HUD is far denser on a small screen and this stack now sits flush with the top edge sharing that band with the Roblox topbar, so full-opacity text competes with the fight for attention. Desktop keeps them solid. The stroke is faded alongside the text on purpose — an opaque outline around dimmed glyphs reads as a *heavier* label, not a lighter one. Applied once and never re-asserted, which is safe because nothing else writes transparency on these labels
5b. `TouchEnabled` is resolved with a **bounded poll** (0.2s interval, 12s deadline), not a single read at load. Studio's device emulator flips `TouchEnabled` a beat *after* client scripts start, so a one-shot check leaves every emulated phone on the desktop path — the same trap the mobile Scope button and VesperScopeController work around. A real non-touch PC never flips it, so the loop simply expires and the timers stay solid
6. **Phase-begin announcer:** a sibling `PhaseAnnounce` TextLabel (direct child of the ScreenGui, so it stays out of the timer stack's UIListLayout) shows a brief `PHASE N • NAME` banner whenever the zone advances to a new phase.
6a. **It sits at `{0.5, 0}, {0.175, 68}`, not just below `Container`.** It was authored at y 66 — immediately under the timers — until 2026-08-05, when the bounty list was reworked into a portrait row that takes the band directly under the timer stack. The banner is transient (~4s) and that row is permanent, so the banner yielded the slot and moved below it.

  **The `0.175` is `BountyListGui.Canvas`'s own height scale, duplicated here on purpose.** That row is 17.5% of viewport height with no clamp, starting at y 60, so `0.175 × H + 60 + 8` sits exactly 8px under it on every device. A fixed offset was tried first and had to clear the row's worst case, which left 8px of gap at 1080p and 66px on a phone. Nothing here reads the bounty panel's geometry and nothing should — the kill feed used to track that panel and was carried across the screen when it moved — so this is a **number kept in step by hand**: change the bounty row's `0.175` or its y offset and this moves in the same pass. Position is authored; this script only tweens transparency and the `AnnounceScale` UIScale, never position. Driven off the `ZonePhaseName` attribute change (ZoneService sets `ZonePhase` first and `ZonePhaseName` last, so both read current here). Pops in + fades in (~0.25s), holds ~3.25s, then fades out over 0.5s; a token guard makes overlapping/interrupted triggers cancel cleanly. Seeds a baseline on its first call so a mid-round joiner is not announced the phase already in progress, and only fires on forward transitions into phase 2+ (Exploration/phase 1 stays silent). Resets for the next round when the phase returns to 0

## Team modes

Two team-only elements ride this GUI, and both are drawn from the viewer's own side outward
([[TeamView]]): every player sees themselves as blue and the other side as red.

The score chips either side of the timer are shown only while the mode has teams and the round is
live. **They are not named after the score they carry** -- the BLUE plate always shows the viewer's
own side and the red plate the other, so a red-team player reads the `TeamScoreRed` attribute out of
the blue chip. The plates keep their authored colours; only the numbers move, and they move again
when the viewer's own stamp lands.

The banner used to announce which side you were on. That question now answers itself, so it teaches
the **rule** once per round instead -- two fixed lines, always on the blue plate. It is still driven
off the local player's `Team` attribute changing, plus a join-time snapshot, so a mid-round joiner
sees it as well as everyone at round start. A nil team hides it, which is what happens on a switch
back to a free-for-all mode. The plate was grown 40px -> 58px to hold the second line, which still
clears `PhaseAnnounce` below it.

## Domination (2026-08-22)

`updateTeamScores` hides both score chips while the workspace `Gamemode` attribute is `domination`
— `isTeamMode()` is true for it, so the exclusion is explicit. DominationGui carries the score there.
The team assignment banner still shows.

## Dependencies

- **Requires:** [[TeamAffinity]], [[TeamView]]
- **Required by:** Nobody

## Connections

### RemoteEvents

None - reads Value objects and workspace attributes only.

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TeamAffinity]] | `TeamAffinity.isTeamMode()` | Show the chips only in a team mode |
| [[TeamView]] | `TeamView.localTeam()`, `TeamView.PLATE` | Decide which chip is the viewer's own, and paint the banner |
