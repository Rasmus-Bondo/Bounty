---
tags:
  - client
  - localscript
  - gamemode
  - combat
path: game.StarterPlayer.StarterPlayerScripts.TeamVisualClient
type: LocalScript
lines: 216
---

# TeamVisualClient

Every team-relative visual in the world, for player rigs — the outline, the bounty mark's colour and
the two spawn houses' force-field doors.

## What it does
1. Puts the `TeamOutline` Highlight on every player character: fill fully transparent so purchased
   skins stay visible, `OutlineTransparency = 0.45`, `Occluded` rather than through-wall. This was
   `TeamService.applyTeamOutline` on the server until 2026-08-19; it had to move, because a
   Highlight's `OutlineColor` is one value replicated to everyone and the colour is now per-viewer.
2. Repaints the bounty mark. BountyService builds it on its FFA gold and never touches those two
   properties again, so this local write is the only one that lands on them.
3. The bounty mark still WINS the rig while present — two Highlights on one rig do not blend — and
   `ChildAdded` / `ChildRemoved` watchers on the character hand it back when the mark clears.
4. Refreshes on the character's own `Team` attribute change as well as the player's: the server
   stamps a fresh rig inside its own `CharacterAdded` handler, which can land after this client's,
   so the first paint legitimately finds nothing.
5. Paints the spawn houses' `RedBaseDoor` / `BlueBaseDoor` parts from `TeamView.DOOR`, so your own
   base's door is always the blue one and the enemy's the crimson one. Here a door is read as a
   **rule** rather than decoration — blue is the one you can walk and shoot through, red is the one
   that stops you. Painted from the palette rather than a cached authored pair, which is what lets
   your own door render correctly while the enemy base, 400 studs away, has never streamed in. The
   doors sit inside their base model, so a `workspace.ChildAdded` watcher catches the mode swap
   parking or restoring the whole house, and a per-base `DescendantAdded` catches streaming.
6. Repaints everything on the viewer's own team stamp landing, via `TeamView.onChanged`.

Bots are the same job on the client visual clone and belong to BotVisualClient; the HUD surfaces
each own theirs. Every path is nil-safe, so FFA runs it as a no-op.

## Dependencies
- **Requires:** [[TeamAffinity]], [[TeamView]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TeamAffinity]] | `TeamAffinity.teamOf()` | The rig's real side, character stamp first and player stamp as backup |
| [[TeamView]] | `TeamView.color()`, `.displayTeam()`, `.onChanged()` | Turn that side into the colour this viewer should see, and repaint when the viewer's own side changes |
