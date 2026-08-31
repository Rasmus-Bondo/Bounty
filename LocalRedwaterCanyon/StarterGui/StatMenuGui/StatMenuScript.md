---
tags: [client, localscript, ui, mobile]
path: game.StarterGui.StatMenuGui.StatMenuScript
type: LocalScript
lines: 324
---

# StatMenuScript

Client-side stats menu controller — held open with TAB on PC, tap-toggled by a mobile button on touch devices.

## What it does

1. Holds references to `MainFrame`, `Backdrop`, `Templates.ScoreRow` and the two side-by-side panels (MyStatsPanel, ScoreboardPanel)
2. Populates "My Stats" with player progression and per-match data received from `StatsResponse` RemoteEvent
2a. **The middle block is per-match, not per-server** — its header was authored `SESSION` and reads `THIS MATCH` since 2026-08-07. The five values under it (kills, deaths, K/D, time alive, time dead) and the leaderboard attributes at 3 all come from DataService's `sessionTracker`, which RoundController now zeroes at the start of every round. Until then nothing reset it, so once Redwater servers started looping rounds the panel showed every round the server had played added together — the match summary reads a different table (`State.playerKills`) and never drifted, which is what made it look like a display bug rather than a data one
2b. **The panel pulls on open and never again**, so the server pushes `StatsResponse` unprompted at round start; a player holding the menu open across the boundary would otherwise keep reading the previous round's numbers. Nothing was added to this script for it — the existing `OnClientEvent` handler already repaints from whatever arrives
3. Populates the round leaderboard by reading `SessionKills`/`SessionDeaths` attributes from all players, ranked by kills (ties broken by fewer deaths, then name). These are attributes rather than part of the `StatsResponse` payload, so the board is a **second, independent** read path — the round-start reset has to rewrite the attributes as well as the table or the board alone keeps showing last round's rows
3a. Rows are `:Clone()`d from the authored `StatMenuGui.Templates.ScoreRow`, the sanctioned "repeated rows" exception — the template is a real instance, only the repetition is code. It is authored `Visible = false` because **a GuiObject renders through a Folder**: parking it in `Templates` does not hide it. The clone sets `Visible = true`. The local player's row gets both cues, the amber `SelfStroke` ring and an amber name
3b. Row heights are a **fraction of the panel**, not a fixed 32px, and the board never scrolls: Redwater holds 10 humans (`MATCH_PLAYER_CAP` 7 + `FRIEND_SLOTS` 3) and `Players:GetPlayers()` excludes bots, so 10 rows plus a header is the whole board
4. **One panel since 2026-08-10 — there is no tab bar.** MY STATS sits in the left column and the round leaderboard in the right, both permanently visible, so the board is repopulated on every **open** rather than when a tab is picked. `TabBar` (and `MyStatsTab` / `ScoreboardTab`) was deleted outright, along with `switchTab`, `setTabState` and the `press` dip-tween that only ever served the two tab buttons
5. Opens and closes via `setOpen`, tweening the `OpenScale` UIScale (0.22 Back/Out in, 0.14 Quad/In out) and firing `RequestStats` to the server on open
6. **PC: HOLD TAB** (`UserInputService.InputBegan` opens, `InputEnded` closes) — the FPS scoreboard convention; the panel is up only while the key is down. TAB is available because the CoreGui PlayerList, its usual owner, is disabled by DisableDefaultLeaderboard (plain text: nothing connects the two scripts). The handler deliberately does **not** bail on `gameProcessedEvent`, because Roblox still marks TAB processed for GuiService selection walking and that would eat the keypress; the one case honoured is `GetFocusedTextBox()`, where TAB belongs to the chat bar being typed into
6a. **`WindowFocusReleased` closes it too, and that is not defensive padding — it is ALT+TAB.** Windows takes the window before Roblox observes the key coming up, so `InputEnded` never fires and the panel is still covering the screen when the player alt-tabs back
6b. A `heldByKey` flag gates both close paths so a key release only tears down a panel the **key** opened, never one the touch button did — a hybrid device (touchscreen PC, keyboard tablet) has both paths live at once. It is cleared unconditionally at the top of `setOpen(false)`, outside the no-op guard, so every close route drops the hold
6c. `RequestStats` is throttled to 0.35s. Hold-to-show turns one keypress into an open **and** a close, and a scoreboard key is tapped far more often than a menu was opened; a suppressed request only means the panel repaints from a payload at most that old, and the board reads player attributes locally regardless
7. **Click-outside-to-dismiss.** `Backdrop` is a full-screen `Active` frame at `ZIndex 0` behind the panel: it dims the scene, blocks clicks from falling through to RevolverInput (which would otherwise fire a shot), and clicking it outside the panel closes the menu. Non-Active panel frames let a mouse-down fall through to the backdrop underneath, so the backdrop is **never** trusted to only see outside clicks — `pointInPanel` tests the press position against the panel's absolute rect. Same contract SettingsController uses
7a. `pointInPanel` tests the union of `MainFrame` **and** `Header`, because the header plaque deliberately overhangs the top edge and is therefore outside MainFrame's rect — without it, clicking the STATS plaque dismisses the menu. `CloseFrame` is deliberately not in the union; it closes the menu either way
7b. The rect test only works because this ScreenGui is `ScreenInsets = None` + `IgnoreGuiInset = true`, which is what makes `AbsolutePosition` and `input.Position` share an origin. On an inset-respecting ScreenGui the two are off by the topbar band and every hit test silently misses
8. Mobile: `MobileStatsButton` is an **authored** instance (60×44px, top-right) that this script only reveals on `TouchEnabled` devices. It **taps to toggle** rather than mirroring the PC hold — a finger pinned to a button to keep the board up is a finger parked on top of the board. It sits to the left of SettingsGui's gear button (which owns the corner) with an 8px gap, right-anchored at X offset -62, spanning -122 to -62
8a. Those offsets are measured off the edge of the ScreenGui's inset space, which became `ScreenInsets = None` on 2026-07-30 (was `DeviceSafeInsets`). On an iPhone 16 Pro Max in landscape that moved the button from 124px to 62px from the physical right edge: Roblox reserves a 62px device-safe band on **both** short edges even though only one carries the cutout, and the whole cluster was sitting inside it. A phone with no cutout reports a 0 inset, so nothing moves there. `ReworkedSettingsGui` and `QuestCompleteNotification` moved in the same pass and the three must stay in one space — QuestToastClient and VersionTagController both clamp against this cluster in pixels off the same edge, so the 60×44 at -62 is load-bearing and must not move without updating those two
8b. It keeps `ZIndex 10`, above the backdrop, so on touch it stays tappable while the menu is open and works as a second close affordance
9. Exports `_G.ToggleStatMenu = toggleMenu` for external callers. The TAB path no longer routes through it — it is now only the touch button's handler and the external API
10. Repopulates the board on `PlayerAdded` / `PlayerRemoving` while the panel is open

## Layout notes

The GUI was rebuilt to `UI_STYLE_GUIDE.md` on 2026-08-07, replacing a grey `(20,20,20)` / GothamSSm panel — it was the guide's top listed style-debt item. It went from two stacked tab panels to **one two-column panel** on 2026-08-10. Everything is authored under `StarterGui.StatMenuGui`; this script only drives state.

- The panel is a **fit-within box**: `Size` is `{0.92, 0.80}` of the screen and `UIAspectRatioConstraint` 1.85 uses `AspectType = FitWithinMaxSize`, so the wider two-column shape clamps on **whichever axis binds first**. The old Height-dominant 1.5 could get away with deriving width from height; at 1.85 the same rule runs a 1024-wide viewport off the edge. `UISizeConstraint` caps at `(1240, 670)` — the same 1.85, so the cap is proportional and the two constraints never fight
- **The panel-height floor moved to the close button.** `MinSize (0, 300)` existed to keep the tab buttons above the 44px touch minimum; with the tabs gone the only tappable thing left inside the panel is `CloseFrame`, which now carries its own `UISizeConstraint MinSize (44, 44)`. That floors the control directly instead of flooring the whole panel, which would have fought `FitWithinMaxSize` on a small screen
- Columns are MyStats `0.43` / leaderboard `0.545` of `ContentFrame` with a `0.025` gutter, carrying a `ColumnRule` — a clone of the header `Divider` with its gradient rotated 90 and a transparency fade at both ends
- Both column stacks are sized to **fill**: MY STATS runs 0.058/0.225/0.058/0.200/0.072/0.058/0.185 on `0.022` leading (0.988 total), and the board is 0.058 heading + 0.062 header row + 10 × 0.073 rows on `0.012` leading (0.982), so a full 10-player board still fits with the heading
- **Section heading label boxes are `0.50` wide (`0.58` for ROUND LEADERBOARD) so `TextScaled` stays bound by box HEIGHT, not width.** At the old `0.30` the narrower column would have width-limited "THIS MATCH" and rendered the three headings at three different sizes. Verified by measurement, not by eye: all four headings come out at 13px on a Samsung A06
- Everything is sized in **scale**, so the type scale is identical on every device with no `UIScale` needed
- Two earlier failures found by measuring rather than eyeballing: the header plaque rendered *smaller* than the tile numbers (type hierarchy is set by box height, not weight), and the hero strip was too short for three stacked elements, bottoming the XP row out at 8px
- `PostGamePanel` was removed — it was a dead local variable that nothing referenced

## Team modes

In a team mode each row's name takes its team's colour, read off the live `Team` attribute on the
Player (safe here -- players persist, only characters get destroyed). The colour comes from
[[TeamView]] and is **relative**, so the board reads as "us and them" whichever side the server
actually put you on. The board stays **one kill-ranked list** across both teams rather than
splitting into columns -- the leaderboard is deliberately individual.

The panel repopulates on every OPEN, so a stamp landing while it is shut is picked up the next
time it is raised. Your own row keeps the amber name only in FFA; in a team mode the amber
`SelfStroke` ring alone carries "you", because the name is carrying your side.

## Dependencies

- **Requires:** [[TeamView]]
- **Required by:** Nobody (external callers use `_G.ToggleStatMenu`)

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RequestStats` | → Server | [[ProgressionService]] handles the request |
| `StatsResponse` | ← Server | [[ProgressionService]] fires back player stat data |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TeamView]] | `TeamView.displayTeam()`, `TeamView.TEXT` | Colour each leaderboard name by the side it should read as from here |
