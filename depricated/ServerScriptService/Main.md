---
tags: [server, script, boot]
path: game.ServerScriptService.Main
type: Script
lines: 22
---

# Main

The boot script for all server-side modules. It requires and initializes every module in a defined order.

## What it does

1. Requires [[HealthBarModule]] and [[DashDustVFXModule]], calling `.start()` on each
2. Requires [[HighNoonModule]] and [[RevolverModule]], calling `.init()` on each

That's the entire script — 22 lines, no game logic.

## Dependencies

- **Requires:** [[HealthBarModule]], [[DashDustVFXModule]], [[HighNoonModule]], [[RevolverModule]]
- **Required by:** Nobody (it's a top-level Script that auto-runs)

## Notes

- The two-phase pattern (`start` vs `init`) separates passive setup modules (health bars, VFX) from active combat modules
- Order matters: HighNoonModule is initialized before RevolverModule, since RevolverModule `require()`s HighNoonModule at load time
