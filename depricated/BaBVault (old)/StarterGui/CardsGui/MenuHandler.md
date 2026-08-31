# MenuHandler

Controls CardsGui visibility — shows open/close buttons when not in a round, hides everything when opted in.

**Path:** `game.StarterGui.CardsGui.MenuHandler`
**Type:** LocalScript (32 lines)
**Runs on:** Client

## How It Works

1. When `OptedIn` attribute is true: hides Canvas, OpenButton, and CloseButton
2. When `OptedIn` is false: shows OpenButton and CloseButton (Canvas stays hidden until explicitly opened)
3. OpenButton click: shows Canvas
4. CloseButton click: hides Canvas

## Visibility Logic

| OptedIn | OpenButton | CloseButton | Canvas |
|---------|------------|-------------|--------|
| false | Visible | Visible | User-toggled |
| true | Hidden | Hidden | Hidden |

## Dependencies

- Player `OptedIn` attribute — set by [[LobbyService]]

## Used By

- [[CardsGui]] — runs alongside [[OpenStoreScript]] and [[BuyButtonScript]]
