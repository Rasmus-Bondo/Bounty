---
tags: [server, modulescript, lobby, spawn, analytics]
path: game.ServerScriptService.Lobby.LobbyService
type: ModuleScript
lines: 50
---

# LobbyService

Locks player characters at the JailSpawn position so they cannot move in the lobby.

## What it does
1. Finds `workspace.JailSpawn` as the anchor point
2. On CharacterAdded, sets WalkSpeed/JumpPower to 0 and disables AutoRotate
3. Teleports the character to JailSpawn position, then anchors the HumanoidRootPart
4. Zeroes out linear and angular velocity to prevent drift
5. Logs step 1 "Joined Lobby" of the cross-place onboarding funnel through [[DataService]] `tryLogFunnelStep(player, 1, ...)`, which fires `AnalyticsService:LogOnboardingFunnelStepEvent` **at most once per player, ever** — de-duped via the persisted `OnboardingFunnel` set so respawns/lobby re-entries don't re-fire it (this is what stopped the AnalyticsService "sent too many events" throttling). Steps 4-7 continue in Redwater Canyon (see RoundController and RoundStatsService there — plain text, since a cross-place name has no node in this graph)

## Dependencies
- **Requires:** [[DataService]]
- **Required by:** Main

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `tryLogFunnelStep()` | Log onboarding funnel step 1 "Joined Lobby" once per player (persisted de-dup) |
