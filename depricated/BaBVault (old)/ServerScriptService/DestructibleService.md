# DestructibleService

Manages breakable windows in the map. Tracks all BaseParts named "Window", handles breaking (disable collision + increase transparency + play glass sound), and resets them between rounds.

**Path:** `game.ServerScriptService.RoundSystem.DestructibleService`
**Type:** ModuleScript (64 lines)
**Runs on:** Server

## How It Works

### Initialization

Scans all workspace descendants for BaseParts named `"Window"`. Stores each in a `windows` table (keyed by part, value = broken state) and records its original transparency.

### Breaking a Window (`breakWindow`)

1. Guards: part must be tracked and not already broken
2. Sets `CanCollide = false` and `Transparency = 0.8`
3. Creates a temporary positional Sound:
   - Asset: `rbxassetid://280667448` (glass break)
   - Volume: 0.8
   - RollOff: InverseTapered, min 10, max 200 studs
4. Sound self-destructs on `Ended`

### Checking State (`isWindowDestroyed`)

Returns whether a specific window part is broken.

### Reset (`resetDestructibles`)

Iterates all tracked windows:
- If broken: restores `CanCollide = true` and original transparency (fallback 0.3)
- Resets broken state to `false`

## Dependencies

- CollectionService (imported but not currently used — windows found by name scan)

## Used By

- [[MainServer]] — Initialize() called at boot
- [[GunServer]] — calls breakWindow when a bullet hits a Window part
- [[RoundController]] — calls resetDestructibles during round Reset phase
