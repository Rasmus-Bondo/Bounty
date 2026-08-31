---
tags:
  - shared
  - modulescript
  - gamemode
  - ui
path: game.ReplicatedStorage.Modules.TeamView
type: ModuleScript
lines: 118
---

# TeamView

What colour a side should LOOK from here — the client's team palette, and the only place a team
colour pair is allowed to live.

## What it does
1. Holds the four colour pairs: `WORLD` (rig outlines, bounty marks), `TEXT` (kill feed and
   scoreboard names), `PLATE` (HUD plates and banners) and `DOOR` (the spawn houses' force-field
   doors). Four scattered copies of these pairs existed before this module, three of them on the
   server. `DOOR` is its own pair because the doors are lit ForceField, which washes the `WORLD`
   pair out — and because a door reads as a **rule** rather than decoration: blue is the one you can
   walk and shoot through, red is the one that stops you.
2. `localTeam()` returns the viewer's own side or nil — nil in FFA and for anyone not yet stamped.
3. `displayTeam(team)` maps a real team id to the one it should be **drawn** as: the viewer's own
   side is always `"blue"`, every other side always `"red"`. Everyone therefore fights red enemies,
   which is the whole point — a shooter reads "red = shoot" faster than they read a team name.
4. Identity when the viewer is unstamped (a spectator, or the window before assignment replicates):
   red still draws red. Absolute is a worse read than relative but it is never a **lie**, and the
   opposite fallback would tell a player their own team is shootable.
5. `color(palette, team)` is the one-call form; nil out means "leave the authored colour alone",
   which is how every caller's FFA path works.
6. `onChanged(callback)` fires when the viewer's own `Team` attribute changes. Every surface that
   paints a team colour subscribes: the stamp lands after the HUD and the rigs have already drawn
   once, so without a repaint a joiner's whole first round renders in absolute colours.

**Client only** — it reads `Players.LocalPlayer`. That is also why no server module holds a team
colour any more: a `Highlight`'s colour is one value replicated to everybody, which is exactly what
this scheme cannot have.

The real ids never move. TeamAffinity, friendly fire, scoring, spawns and the `TeamScoreRed` /
`TeamScoreBlue` attributes all still speak red/blue; this module is the last step before a team id
becomes a pixel.

## Dependencies
- **Requires:** Nothing
- **Required by:** DominationClient, CapturePointVisualClient, TeamVisualClient, BotVisualClient, KillFeedClient, StatMenuScript,
  RoundStatusClient, VictoryShowcaseClient, BountyListClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
