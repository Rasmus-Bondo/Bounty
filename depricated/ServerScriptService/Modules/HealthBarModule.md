---
tags: [server, module, ui, health]
path: game.ServerScriptService.Modules.HealthBarModule
type: ModuleScript
lines: 313
---

# HealthBarModule

Server-side module that creates and manages BillboardGui health bars above every character's head.

## What it does

1. On player join (and for existing players), hooks `CharacterAdded`
2. For each character, clones `ReplicatedStorage.HealthBarGui` template onto the head
3. Strips any scripts from the cloned GUI
4. Manages health bar animations:
   - **Damage:** bar shrinks with a Quad tween, trail bar follows after 180ms delay
   - **Heal:** both bars move together
   - **Show/hide:** bar appears on damage, auto-hides after 3 seconds with a fade-out
5. Disables default Roblox health display (`DisplayDistanceType = None`)

## Dependencies

- **Requires:** Nothing
- **Required by:** [[Main]] (`.start()` at boot)
- **Reads from:** `ReplicatedStorage.HealthBarGui` (template)

## Connections

No RemoteEvents or BindableEvents. The `HealthBarGui` BillboardGuis it creates are removed on the local player by LocalHealthBarHide (client-side).

## Notes

- Runs on the server but creates BillboardGuis that replicate to all clients
- Builds a transparency cache of all GUI elements to enable smooth batch fade in/out
- Uses a token-based system to cancel outdated fade timers
