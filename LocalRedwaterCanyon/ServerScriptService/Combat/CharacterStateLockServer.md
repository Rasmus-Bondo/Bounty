---
tags:
  - server
  - modulescript
  - combat
path: game.ServerScriptService.Combat.CharacterStateLockServer
type: ModuleScript
lines: 163
---

# CharacterStateLockServer

Prevents characters from entering physics-breaking humanoid states (swimming, ragdoll, FallingDown, etc.) and clamps excessive angular velocity on the HumanoidRootPart every Heartbeat.

## What it does

1. Disables Swimming, Ragdoll, FallingDown, Physics, and GettingUp humanoid states via `SetStateEnabled` on character spawn
2. Monitors `humanoid.StateChanged` and defers a state correction if a bad state is entered
3. Runs a `RunService.Heartbeat` loop per character to re-apply state locks, fix bad states, and clamp `AssemblyAngularVelocity` (soft cap 18, hard reset at 35)
4. Tracks all connections per character in `characterConnections` and disconnects them on death, ancestry removal, or `PlayerRemoving`
5. Note: CharacterStateLockClient runs the same kind of state-lock/angular-velocity-clamp loop independently on the client (no direct code connection — client predicts/stabilizes locally, this script enforces authoritatively)

## Dependencies

- **Requires:** Nothing
- **Required by:** Main

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

None
