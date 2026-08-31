---
tags:
  - client
  - localscript
  - ui
  - disabled
path: game.StarterGui.PostGameGui.PostGameScript
type: LocalScript
lines: 162
---

# PostGameScript

Disabled leaderboard popup that used to show a top-5 + "you" post-round scoreboard; superseded by the victory showcase flow.

## What it does
1. Listens for `ReplicatedStorage.Events.PostGameStats` `OnClientEvent` and builds a ranked leaderboard (top 5, plus the local player's row with a separator if they're outside the top 5)
2. Each row shows rank, name, kills, deaths, and a K/D ratio (`formatKD`), highlighting the local player's own row
3. Reads `ReplicatedStorage.RoundStatus` for the title text (falls back to "ROUND OVER")
4. Auto-hides the overlay after 5 seconds via `task.delay`
5. **Currently disabled and effectively dead:** [[RoundController]] still builds the equivalent stats table (`buildPostGameStats()`) but passes it straight into `startVictoryShowcase(stats)` instead of firing a `PostGameStats` remote — nothing in the live game fires that remote anymore. The post-round flow is now handled by VictoryShowcaseClient and StatMenuGui's StatMenuScript (plain text on purpose — naming the script that replaced this one is not a code-level connection)

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PostGameStats` | ← Server (dead) | No script currently fires this; [[RoundController]] replaced it with `startVictoryShowcase()` |

### BindableEvents
None

### Direct require()
None
