---
tags: [server, script, character, combat, health]
path: game.StarterPlayer.StarterCharacterScripts.Health
type: Script
lines: 106
---

# Health

Redwater's own passive health regeneration, replacing the one Roblox inserts into every character.

## What it does
1. Claims the `Health` name in `StarterCharacterScripts`, which is how the engine's default character script is replaced (the same mechanism that overrides `Animate` and `Sound`). Copied into every player character on spawn; bots are cloned rigs and never receive it, so they have no passive regen — as before.
2. Regenerates `REGEN_RATE` (1%) of MaxHealth per `REGEN_STEP` (1s), matching the engine's numbers.
3. **Holds off for `COMBAT_DELAY` (5s) after the last damage taken** — the one deliberate balance change (2026-08-13). Only a *decrease* in health arms the delay, so a health pack's instant heal and this loop's own writes do not push it out. A player burning in the fire zone is re-armed by every tick, so the zone suppresses regen for free.
4. **Stops at death and never writes to a corpse.** Breaks on `Humanoid.Died`, and re-tests `Health <= 0` / `GetState() == Dead` on every tick in case a body ends up dead without that signal.
5. Disables any default health script the engine inserted alongside it, warning **once per server** via a `DefaultHealthScriptSeen` attribute on ServerScriptService.

## Why it exists
The engine's version has no dead check. Its regen loop sleeps in one-second steps, so a loop already in flight when the killing blow lands wakes up and writes ~1% of MaxHealth onto a body that has already died — and every target test in the game that asked only `Health > 0` then read that corpse as a live target. That is what launch issue #10's duplicate kill-feed row turned out to be: the shooter's next round found a body back above 0 and killed it a second time, 0.117s after the first row posted. Bots never appeared as victims because a cloned rig never receives the engine's default scripts, which is what identified it.

Behavior 5 exists because the docs describe the replacement as a **LocalScript** while the engine's own version is a server **Script**. A server Script does claim the slot — **confirmed by playtest 2026-08-13**, where the warning never fired — so the docs describe the LocalScript case rather than a requirement. The check stays as a regression guard.

This is the one reviver we know about. HunterCharacterUtil `IsAlive` and its corpse pin remain the standing guarantee against the next one.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody — copied into the character by the engine, never required

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
