# InputController

Central input binding script — maps keyboard and mobile touch buttons to gameplay actions (sprint, crouch, shoot, reload, stats).

**Path:** `game.StarterPlayer.StarterPlayerScripts.InputController`
**Type:** LocalScript (117 lines)
**Runs on:** Client

## How It Works

### Keyboard Bindings (all platforms)
- **LeftShift** (hold): Sprint — fires `SprintEvent:FireServer(true/false)`
- **LeftControl** (toggle): Crouch — fires `CrouchEvent:FireServer(isCrouching)`

### Mobile Touch Buttons
- Detects mobile via `UserInputService.TouchEnabled`
- Enables `MobileControlsGui` and wires up ActionFrame buttons:

| Button | Action |
|--------|--------|
| ShootButton | `Tool:Activate()` on equipped tool |
| ReloadButton | `GunRemote:FireServer("Reload")` |
| SprintButton | Hold: SprintEvent true/false |
| CrouchButton | Toggle: CrouchEvent |
| StatsButton | `_G.ToggleStatMenu()` (from [[StatMenuScript]]) |

### PC Mode
- Hides MobileControlsGui
- Still wires StatsButton for Device Emulator testing

## Dependencies

- ReplicatedStorage.Events.MovementEvents.SprintEvent — consumed by [[MovementService]]
- ReplicatedStorage.Events.MovementEvents.CrouchEvent — consumed by [[MovementService]]
- ReplicatedStorage.Events.[[GunRemote]] — consumed by [[BanditGun GunServer]]
- PlayerGui.[[MobileControlsGui]] — touch button UI
- `_G.ToggleStatMenu` — global set by [[StatMenuScript]]

## Used By

- Runs automatically for all players in StarterPlayerScripts
