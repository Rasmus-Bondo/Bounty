---
tags:
  - client
  - localscript
  - ui
  - ranked
  - leaderboard
path: game.StarterGui.RankLeaderboardGui.RankLeaderboardClient
type: LocalScript
lines: 632
---

# RankLeaderboardClient

Populates the far-left lobby leaderboard panel (`RankLeaderboardGui`) from RankLeaderboardService; the panel is opened/closed from the reworked main menu's CanvasLeft `4Leaderboard` button.

## What it does
1. Lives inside the `RankLeaderboardGui` ScreenGui — a narrow vertical panel anchored to the far-left edge of the screen, positioned to sit clear of the 3D PLAY / CHANGE MODE buttons (which occupy the left third of the lobby)
2. Fires the `RankLeaderboardRequest` RemoteEvent on load and every 60s to ask the server for fresh data
3. On the server's reply `{ top, ownRP, ownRank }`, clears the list and clones the hidden `RowTemplate` once per top entry (up to 100) into the `List` **ScrollingFrame** (vertical, `AutomaticCanvasSize`, 8-9 visible + scroll), filling rank / name / RP (comma-formatted); highlights 1st place and the local player's own row in gold. The list stays the **complete** #1-#100 standings even though the podium repeats the top three above it
4. Updates the pinned bottom "YOU" row with the local player's own RP total and rank (`#n` when in the top 100, otherwise `—`)
5. `Panel` is closed by default (`Visible = false`) and is toggled open/closed by the reworked main menu's `CanvasLeft.Frame.3Leaderboard.Button` (fetched via WaitForChild in a `task.spawn`). The old in-GUI `LeaderboardButton` is now hidden (`Visible = false`)
6. Click-outside-to-close: a full-screen invisible `CloseOverlay` TextButton is created behind the panel (`ZIndex = 0`, `BackgroundTransparency = 1`) and closes the board when clicked; `Panel.Active = true` so clicks landing on the panel itself don't fall through to the overlay. A `setBoardOpen(open)` helper keeps panel + overlay visibility in sync
7. Opening animation: the whole canvas slides in from the left with a Back-ease + `UIScale` pop, then the rows "fan" in one by one (`ROW_STAGGER` 0.028s each, rotation + scale + fade), with the pinned YOU row landing last. **The board must never appear to load twice**, which takes three things working together:
   - `setBoardOpen(true)` sets the podium's `TopFrame.Frame`, `List.Visible` and `YouRow.Visible` to `false` *before* the panel is drawn. The rows still hold the last fetch's results in their finished state, so without this the board slides in already populated and then blanks itself to fly the rows in. `playRowFan` re-shows them in the same frame that `prepareFade` blanks them, so they are never drawn un-faded
   - The fan is held on `fanPending` until `populate()` swaps in the rows this open's request asked for, so stale rows and fresh rows can't each animate. `OPEN_FAN_DELAY` (0.08s) is measured from the panel slide so a fast reply keeps the lead-in; `OPEN_FAN_FALLBACK` (0.35s) is a safety net
   - `playRowFan` hard-guards on `fannedOpenToken == openToken` — at most one fan per open regardless of caller. `openToken` only changes on an open/close transition
   - The podium leads the cascade (orders 0-2) and the numbered rows start after it, so the eye lands on
     first place rather than starting at row #1 and jumping back up
   The 60s background refresh swaps rows in silently instead of replaying the fly-in
8. Usable from every main-menu section (Home, Loot, Collection, BattlePass, TradingPost) — the GUI is never force-disabled based on the selected bottom tab, and stays open across tab switches until closed. `RankLeaderboardGui.DisplayOrder = 40` so the panel renders above other full-screen menu overlays (e.g. `BattlePassMenu` at 30, `QuestClient`'s gui at 20)

9. **Podium** (`FrameBackground.TopFrame`) — the gold-bordered block above the list showing 1st / 2nd / 3rd. The three places are AUTHORED labels (`1First`, `2Second`, `3Third`), not clones of a row template, because each carries its own gold / silver / bronze colour, so they are looked up by name into a `PODIUM_SLOTS` table. Each label's own text is the finishing player's NAME, taken from `data.top[1..3]`; a place nobody holds yet shows an em dash rather than the authored placeholder. Its `RPLabel` is the **Token payout** for that place, not RP — stamped once at load from [[RankRewardsConfig]]'s `bracketFor()`, the same brackets RankSeasonRewardService pays from, so the podium cannot advertise a number the payout will not honour
10. **Responsive tiering.** `ScreenInsets = None`, matching every other lobby ScreenGui — on `CoreUISafeInsets` the board sat ~62px right of the left menu it belongs beside, and lost the same off the top. Three tiers, all keyed off the ScreenGui's own `AbsoluteSize` (NOT `Camera.ViewportSize`: the two disagree under Studio's device simulator, where a 1024x768 tablet reads as an 899x746 camera):
   - **Phone / desktop** keep the authored `0.2 x 0.76 @ 0.193, 0.53`
   - **Tablet** (`TouchEnabled` AND short edge >= 600 — the `TouchEnabled` qualifier matters, a 1920x1080 desktop passes the short-edge test on its own) re-derives width from height to hold the desktop 0.47 aspect, which stops a 4:3 screen rendering the board a third narrower than it was drawn. Widening also has to SHORTEN: a wider board reaches across the HOME/COLLECTION bar, so the tablet tier stops at 0.735 rather than 0.89
   - **Desktop** (not `TouchEnabled`) grows the row label heights (rank 0.58, name 0.76, RP 0.64 of the row, against 0.48 / 0.62 / 0.52 on touch). Every row label is *height*-bound, so its fraction of the row is what caps the text; touch keeps the smaller set because its rows are deliberately small so the podium stays the bigger element
   `FrameBackground` is 0.9 of Canvas and centred, so pinning `Position.X - 0.45 * width` keeps the gap to the left menu identical at every width. All of it re-runs on the ScreenGui's `AbsoluteSize` signal — resolving the tier once at load would latch the (0, 0) first-frame reading as a phone for the whole session

11. **Season rewards flyout** (`Canvas.RewardsPanel`) — a second panel attached to the right edge of the Canvas, listing what each finishing bracket wins. Authored as a **clone of `FrameBackground`** so it inherits that panel's exact surface, stroke, gradient and shadow rather than re-typing values, and parented to `Canvas` rather than to the board panel, so it inherits the open slide and `LeaderboardOpenScale` for free — only its rows have to join the fan, which they do after the YOU row on the same `ROW_STAGGER`. Rows are built ONCE at load from [[RankRewardsConfig]] (the ladder cannot change within a season) and only the countdown is refreshed, on the same 60s tick as the board. The panel carries **two columns, not three**: a per-row "+ TITLE" column could not coexist with a right-aligned number at 4:3 — the board's `NameLabel` (0.17–0.73) and `RPLabel` (0.71–0.97) overlap, which a short left-aligned name hides and centred text does not — so the podium is marked by a gold bracket label and explained once in `FootnoteLabel`, which also buys `#31-100` the width it needs to survive `TextScaled`. Each row's number carries a **token icon**, cloned from the podium's rather than authored a second time so the two cannot drift; it lives on `RewardRowTemplate`, which `buildRewardRows()` clones, so every bracket gets one

## Dependencies
- **Requires:** [[GameEnvironment]], [[RankRewardsConfig]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RankLeaderboardRequest` | → Server / ← Server | Requests the board from [[RankLeaderboardService]] and receives the top list + own RP/rank |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `getRankSeason()`, `getRankSeasonEnd()`, `getRankSeasonDisplay()` | Season number, the countdown in `SeasonLabel`, and the PLAYER-FACING season number shown there |
| [[RankRewardsConfig]] | `displayRows()` | The ladder rows the flyout draws |
