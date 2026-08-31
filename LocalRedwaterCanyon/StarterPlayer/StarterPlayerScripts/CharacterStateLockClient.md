---
tags:
  - client
  - localscript
  - movement
  - anti-jank
path: game.StarterPlayer.StarterPlayerScripts.CharacterStateLockClient
type: LocalScript
lines: 142
---

# CharacterStateLockClient

Client-side counterpart to CharacterStateLockServer: disables physics-breaking humanoid states and clamps angular velocity for the local character every frame.

## What it does
1. Disables Swimming, Ragdoll, FallingDown, Physics, and GettingUp humanoid states via `SetStateEnabled` on character spawn, and forces `PlatformStand = false`
2. On `Humanoid.StateChanged` into one of those disabled states, defers a correction that changes state to Freefall (airborne) or Running (grounded)
3. Every `RunService.RenderStepped`, re-applies the state locks, re-checks for a bad state, and clamps the HumanoidRootPart's `AssemblyAngularVelocity` (soft cap 14, hard reset to zero at 28) to stop spinning/jitter
4. Re-enables all the disabled states on death so ragdoll-on-death VFX (if any) isn't blocked, and disconnects all connections
5. Note: there is no direct code connection to the existing server-side CharacterStateLockServer — both independently lock down the same set of states on their own side (client predicts/stabilizes locally, server enforces authoritatively)

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
