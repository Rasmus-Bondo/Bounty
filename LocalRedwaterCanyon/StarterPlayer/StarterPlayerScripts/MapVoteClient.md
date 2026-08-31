---
tags: [client, localscript, ui, round]
path: game.StarterPlayer.StarterPlayerScripts.MapVoteClient
type: LocalScript
lines: 419
---

# MapVoteClient

Drives the authored `StarterGui.MapVoteGui` for the end-of-match **mode** ballot — tiles in, ballots out.

## What it does
1. Listens on the `MapVote` RemoteEvent for the server's four messages: `Start` (options, incumbent id, `kind`, duration), `Tally` (running counts), `Result` (winner + final counts) and `Clear`. `kind` is what picks the header prompt and the result prefix; since 2026-08-27 the server only ever sends `"mode"`, but every path here stays kind-driven — see the mode-ballot note below
2. **Builds tiles from the server-sent options, never from `MapCatalog`** — the module replicates and the client could read it, but then the tiles a player sees and the ids the server accepts would come from two different reads of two different builds the moment a publish lands mid-round. One authored `TileTemplate` is cloned per option (the one legitimate clone-a-template pattern; structure stays authored)
3. **The panel SHARES the match-summary screen (2026-08-16), it no longer owns a beat of its own.** RoundController fires `Start` the moment the summary's step 2 lands, so the stats card, the podium and the ballot are one screen. `payload.duration` **is** rendered, in this panel's own header (see item 9): it was ignored for two days in 2026-08-16..18, when one ballot meant the summary's `NEXT MATCH IN` counter *was* the ballot window and a second timer was noise. The map ballot broke that identity and the header froze; the map ballot is gone again as of 2026-08-27 and the two windows are equal once more, but the header countdown is deliberately **kept** rather than reverted, because it is what stops the header freezing if they ever diverge again. The panel stays its **own** ScreenGui rather than moving under `VictoryShowcase`, whose fade machinery collects a state over its whole subtree and would tween tiles it did not build; `DisplayOrder` 1000000 puts it above the showcase's 0, and `ScreenInsets` was changed to `DeviceSafeInsets` to match the showcase so the tile band is measured against the same screen rectangle the stats card and RETURN TO BOUNTY sit in
4. Sizes the grid at runtime from the option count: `CellSize` X-scale is `(1 - padding * (count - 1)) / count`, and the canvas `UIAspectRatioConstraint.AspectRatio` is `TILE_ASPECT * count / (1 - padding * (count - 1))` — the exact solution of "cell width / cell height = `TILE_ASPECT`" for the canvas, replacing the old `count + padding * (count - 1)`, which was a near-enough approximation of the square case (it landed cells on 0.99) and does not generalise to a wide cell. The aspect lives on the **canvas**, not the tile, so `MapName` and `VoteText` keep the boxes they were authored against
5. **Tiles are landscape (`TILE_ASPECT` 1.6), not square.** Square was what a panel owning the whole screen could afford; sharing it, the tiles get a shallow band between the podium's feet and the counter, where a square tile is a small tile. It also suits the art better — the thumbnails are map photographs and the `ImageButton` is authored `ScaleType = Crop`, so a wide tile crops top and bottom off a landscape photo instead of its sides
6. Tapping a tile fires the option id back over `MapVote`; the server takes the last ballot, so changing your mind is just tapping again. The selected tile shows its `SelectStroke`. The template's `ImageButton` is authored `Modal = true` (2026-08-14): a visible Modal GuiButton is what frees the PC cursor from the first-person lock while the panel is up — the project's standard answer, never a `MouseBehavior` write — and the lock resumes on its own when `Clear` disables the gui
7. **The gold `UIShadow` behind a tile is a VOTE indicator, not decoration** (2026-08-16) — it fades in when that map has at least one vote and out when it has none, so a glance at the band says where the room is leaning without reading two numbers. It stays authored `Enabled = true` and is switched off per clone at build time; authoring it off would leave a dead-looking glow in the Explorer. `Enabled` is set before the fade in (a disabled `UIShadow` does not render, so tweening transparency first shows nothing then pops) and cleared only on a completed fade out, re-checked because a vote can land mid-fade
8. **Hover and press bounce the tile.** Hover scales the inner `Frame` to 1.05 on a 0.14s Quad; press punches to 1.13 on a 0.26s `Back`/`Out`, whose overshoot is the bounce, then settles back to hover-or-rest. The bounce plays on **every** press including a re-press of your own pick — the vote is the idempotent half, the feedback must not be, or a deliberate second tap reads as one the game missed. The inner `Frame` is the handle because the cell itself is owned by the `UIGridLayout`; `MapName` was reparented under that frame so photo, name and count bounce as one object rather than the art sliding under a pinned caption
9. **Renders this ballot's own seconds in the header**, from the server-sent `payload.duration` — `"VOTE FOR NEXT MODE  •  7"`, ticking down on a token-guarded `task.spawn` loop so a straggling countdown from a previous ballot cannot write over the current header. A `Result` bumps the token and the result caption owns the header from then on. A payload with no usable duration falls back to the bare prompt rather than a frozen `0`. This replaced a `RenderStepped`-driven countdown that was removed on 2026-08-16 and reinstated in this cheaper form on 2026-08-18
10. The GUI is authored `Enabled = false` **and `ResetOnSpawn = false`** (2026-08-14 — the property must be authored, not set by this script: joining loads the character twice, and the second load destroyed the clone this script's WaitForChild chain had already grabbed, leaving it parked on a dead instance and deaf to `Start` for the whole session). Only `Start`/`Clear` toggle Enabled. RoundClientController's round sweep exempts `MapVoteGui` by name — the sweep force-shows any ScreenGui it has no stored state for, which would otherwise put a live vote panel over gameplay on respawn
11. `Result` highlights the winning tile and updates the header; `Clear` hides the panel and destroys the built tiles so the next vote starts clean. Teardown cancels each tile's size and shadow tweens **before** destroying it — a playing Tween holds a reference to its instance, and these are built and torn down every round

## The mode ballot

Since 2026-08-27 (SERVER_CONSOLIDATION_SPEC §2) this is the **only** ballot. The map vote that used to run ahead of it is gone: the map is a routing
consequence now, decided after the ballot closes by which server the roster is packed into or rotated to, so this panel simply never receives
`kind = "map"` again.

**Nothing here was torn out for that.** The GUI and the `MapVote` remote keep their names — renaming is a three-place cutover for zero behaviour change —
and every path stays `kind`-driven, with the `map` rows still present in `HEADER_PROMPTS` and `RESULT_PREFIXES`. They cost two strings and are what would
make a returning map ballot a server-side change with nothing to do here. What did change is the defaults: `currentKind` initialises to `"mode"` and
`Clear` resets to it, so the panel can never open or reset showing map copy.

The grid maths at item 4 is derived from the option count and needed nothing — the ballot now carries **three** tiles on both live maps, since each
declares all three modes.

**Each tile's photograph is that mode's DESTINATION MAP** (2026-08-28), not this map and not decoration. GamemodeConfig rows carry no art, so the
server resolves per mode where that mode would send the roster — the server it would merge into, or the map it rolled for a fresh one — and sends that
`MapCatalog` row's thumbnail on the option. So the three tiles can legitimately show three different maps, the mode name stays the caption (it is what
the vote decides), and the map is read off the art alone. Nothing in this script changed to do it: `buildTiles` already assigned `option.thumbnail`.
The panel-brown plate survives as the fallback for an option that arrives with no thumbnail at all — without it the tile would be a name floating in a
stroke. **The tile is a promise, not a preview:** the winning tile's map is pinned into the end-of-round decision, so what the art showed is where the
roster goes. See RoundController's `runBallotsDuringSummary`.

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `MapVote` | ← Server / → Server | [[RoundController]] `Start`/`Tally`/`Result`/`Clear` in; a single option id string out per ballot |

### BindableEvents
None

### Direct require()
None
