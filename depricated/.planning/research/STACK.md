# Stack Research: Bullets and Bounty

## Recommended Stack

| Component | Recommendation | Confidence |
|-----------|---------------|------------|
| Networking | RemoteEvents + UnreliableRemoteEvents | High |
| Persistence | ProfileService (wrapper over DataStore) | High |
| UI | Traditional ScreenGui/Frame hierarchy | High |
| Input | UserInputService + ContextActionService | High |
| Raycasting | workspace:Raycast with RaycastParams | High |
| Audio | Positional Sound on Attachments | High |
| Physics | Roblox default + custom movement via Humanoid | High |

## Networking

**RemoteEvents** for reliable communication (damage, round state, kills, DataStore saves):
- `RemoteEvent:FireServer()` for client-to-server (shoot, reload, sprint)
- `RemoteEvent:FireClient()` / `FireAllClients()` for server-to-client (round updates, kill feed)

**UnreliableRemoteEvents** for frequent, loss-tolerant data (introduced 2023):
- Player position updates if doing custom replication
- Cosmetic effects (bullet tracers, particle hints)
- NOT for damage or state changes

**Pattern:** Centralize all remotes in a single ReplicatedStorage folder. Use a RemoteManager module to create/access them by name rather than scattering RemoteEvent instances.

**Anti-cheat:** Server must be authoritative for all damage, kills, currency, and XP. Client sends intent (shot direction), server validates.

## Persistence

**ProfileService** (community module, widely adopted):
- Handles session locking (prevents data duplication across servers)
- Automatic retry on DataStore failures
- Clean API for loading/saving player profiles
- Prevents data loss from concurrent writes

**Alternative: Raw DataStoreService** — viable but requires manual session locking, retry logic, and rate limit management. Not recommended for new projects.

**Data structure:**
```lua
{
    Cash = 0,
    Level = 1,
    XP = 0,
    Stats = {
        TotalKills = 0,
        TotalDeaths = 0,
        TimeAlive = 0,
        TimeDead = 0,
        GamesPlayed = 0,
    },
    Settings = {
        -- player preferences
    }
}
```

**Rate limits:** 60 + numPlayers * 10 requests/minute per DataStore. ProfileService handles this automatically.

## UI Framework

**Traditional ScreenGui approach** (recommended for this project):
- ScreenGui > Frame > child elements
- LocalScripts driving UI state
- Simple, debuggable, no external dependencies
- Well-documented by Roblox

**NOT recommended:** Roact/React-lua — adds complexity and a learning curve without enough benefit for this scope. Better suited for large studio teams with complex UI state.

**Mobile UI considerations:**
- Use `UISizeConstraint`, `UIAspectRatioConstraint` for responsive scaling
- `ScreenGui.IgnoreGuiInset = true` for full-screen elements
- Minimum touch target size: 44x44 pixels (accounting for `GuiService:GetScreenResolution()`)
- Test at multiple aspect ratios (16:9, 19.5:9, 4:3)

## Input Handling

**ContextActionService** for game actions (shoot, reload, sprint, crouch):
- Automatically supports keyboard + gamepad + touch
- `BindAction` with touch button support built in
- Priority system prevents input conflicts

**UserInputService** for raw input detection:
- Camera control, mouse position for aiming
- `UserInputService.TouchEnabled` to detect mobile
- Platform-specific UI adjustments

**Mobile-specific:**
- Virtual joystick (Roblox provides default, or custom via ThumbstickController)
- Dedicated touch buttons for shoot, reload, sprint, crouch
- Aim assist: slight auto-aim / bullet magnetism for touch input
- Larger UI elements, simplified HUD

## Combat Systems

**workspace:Raycast()** with RaycastParams:
- Set FilterDescendantsInstances to exclude shooter's character
- FilterType = Enum.RaycastFilterType.Exclude
- Use Attachments on gun for muzzle position
- Server validates ray origin (must be near player's actual position)

**Hit detection pattern (server-authoritative):**
1. Client fires RemoteEvent with ray origin + direction
2. Server validates origin is near player's head/gun
3. Server performs its own raycast
4. Server applies damage if valid hit
5. Server fires kill/damage events to relevant clients

**Lag compensation (optional, advanced):**
- Store recent player positions server-side
- Rewind time based on shooter's ping
- Cast ray against historical positions

## Audio

**Positional audio via Sound on Attachments:**
- Parent Sound instances to gun's MuzzleAttachment
- `Sound.RollOffMode = Enum.RollOffMode.InverseTapered`
- `Sound.RollOffMinDistance = 10` (full volume within 10 studs)
- `Sound.RollOffMaxDistance = 200` (silent beyond 200 studs)

**Pattern:**
- Gun sounds: Play on the gun Part/Attachment (positional)
- UI sounds: Play via SoundService (non-positional)
- Ambient/music: SoundService or dedicated Part
- Impact sounds: Create temporary Sound at hit position, play, then Destroy

**Current issue in codebase:** Sounds playing server-wide because they're fired via server Script. Fix: fire sounds via client LocalScript using RemoteEvent notification.

## What NOT to Use

| Avoid | Why |
|-------|-----|
| Roact/React-lua | Overkill for this project scope, adds dependency complexity |
| Raw DataStoreService | No session locking, manual retry needed — use ProfileService |
| BodyVelocity/BodyForce | Deprecated — use VectorForce, LinearVelocity if needed |
| Mouse object | Deprecated — use UserInputService instead |
| RemoteFunction for combat | Yields the calling thread — use RemoteEvent (fire-and-forget) |
| Client-side hit detection | Exploitable — server must validate all damage |
| Filtering disabled | Security nightmare — always use FilteringEnabled (default since 2019) |

## Recommendations

1. **Adopt ProfileService** for DataStore — handles the hard parts of persistence
2. **Centralize RemoteEvents** in a shared folder with a manager module
3. **Server-authoritative combat** — client sends intent, server validates and applies
4. **ContextActionService** for cross-platform input binding
5. **Positional audio** on gun attachments to fix the current server-wide sound issue
6. **Responsive UI** with constraint objects for mobile scaling
7. **Keep UI simple** — traditional ScreenGui hierarchy, no framework overhead
