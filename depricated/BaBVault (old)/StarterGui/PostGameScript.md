# PostGameScript

Post-round leaderboard overlay showing top 5 players ranked by kills, with the local player highlighted. Auto-hides after 10 seconds.

**Path:** `game.StarterGui.PostGameGui.PostGameScript`
**Type:** LocalScript (151 lines)
**Runs on:** Client

## How It Works

1. Listens for `PostGameStats` RemoteEvent from server
2. Receives sorted array of `{name, kills, deaths}` for all round participants
3. Shows the round winner/status in the title (read from `RoundStatus` StringValue)
4. Creates rows for top 5 players
5. If local player not in top 5, adds a separator and their row at the bottom
6. Auto-hides overlay after 10 seconds

## Row Layout

| Column | Width | Content |
|--------|-------|---------|
| Rank | 10% | "#1", "#2", etc. |
| Name | 35% | Player display name |
| Kills | 18% | Kill count |
| Deaths | 18% | Death count |
| K/D | 19% | Kill/death ratio (2 decimal places) |

## Visual Styling

| Property | Local Player | Other Players |
|----------|-------------|---------------|
| Background | (60, 50, 30) @ 0.3 | Black @ 0.8 |
| Text Color | Gold (255, 230, 128) | Light gray (220, 220, 220) |
| Font | GothamBold | Gotham |

## GUI Structure

| Element | Type | Description |
|---------|------|-------------|
| Overlay | Frame | Full-screen semi-transparent background |
| LeaderboardFrame | Frame | Centered leaderboard container |
| TitleLabel | TextLabel | Winner announcement or "ROUND OVER" |
| PlayerList | ScrollingFrame | Contains player rows + UIListLayout |

## Dependencies

- [[PostGameStats]] RemoteEvent — fired by [[RoundController]] at round end
- `RoundStatus` (StringValue) — in ReplicatedStorage, set by server before firing stats

## Used By

- Runs automatically in PlayerGui when the player joins
