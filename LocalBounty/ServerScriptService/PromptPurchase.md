---
tags: [server, script]
path: game.ServerScriptService.PromptPurchase
type: Script
lines: 4
---

# PromptPurchase

Bootstrap script that starts StoreService on the server.

## What it does
1. Requires `StoreService` from `PlayerServices`
2. Calls `StoreService.Start()` to initialize the purchase handler

## Dependencies
- **Requires:** [[StoreService]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None — delegates entirely to [[StoreService]].

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[StoreService]] | `StoreService.Start()` | Boots the Robux purchase flow |
