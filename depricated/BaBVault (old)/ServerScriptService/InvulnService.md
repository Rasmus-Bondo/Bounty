# InvulnService

Spawn protection system. Makes players invulnerable for a configurable duration after spawning, with a visible flicker effect that accelerates as a warning before expiry.

**Path:** `game.ServerScriptService.RoundSystem.InvulnService`
**Type:** ModuleScript (144 lines)
**Runs on:** Server

## How It Works

### Applying Invulnerability (`applyInvulnerability`)

1. **Generation counter**: bumps `invulnGeneration[player]` so any previous flicker loop stops
2. Sets `Invulnerable` attribute to `true` on the player
3. **Health protection**: connects to `HealthChanged` — any damage is instantly reverted to MaxHealth
4. **Records original transparency** of all visible BaseParts (skips parts already at Transparency=1)

### Flicker Loop (server-side, replicated via Transparency)

Runs in a `task.spawn`:

| Phase | Duration | Flicker Interval |
|-------|----------|-----------------|
| Normal | 0 → 7s | INVULN_FLICKER_BASE (0.3s) |
| Warning | 7s → 10s | Lerps from 0.3s → INVULN_FLICKER_FAST (0.1s) |

Each flicker cycle:
1. Sets all visible parts to Transparency 0.5
2. Waits `interval`
3. Restores to original transparency
4. Waits `interval`

### Auto-Expiry

After `INVULN_DURATION` (10s), the loop breaks and calls `removeInvulnerability()` — but only if:
- The character is still parented (alive)
- The generation counter hasn't changed (no newer invuln applied)

### Removing Invulnerability (`removeInvulnerability`)

1. Clears `activeInvulns[player]`
2. Sets `Invulnerable` attribute to `false`
3. Disconnects health protection connection
4. Restores all visible parts to Transparency 0

### Generation Counter

Prevents race conditions when invuln is re-applied before the previous one expires (e.g., quick respawn). The old flicker loop sees a mismatched generation and stops.

### Player Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| Invulnerable | boolean | Read by [[GunServer]] to skip damage |

## Dependencies

- [[Config]] — INVULN_DURATION (10), INVULN_FLICKER_BASE (0.3), INVULN_FLICKER_FAST (0.1), INVULN_WARNING_TIME (3)

## Used By

- [[MainServer]] — Initialize() called at boot
- [[RoundController]] — applies invuln during Setup phase and on mid-round respawn
- [[LobbyService]] — applies invuln on mid-match join
- [[GunServer]] — checks Invulnerable attribute before applying damage
