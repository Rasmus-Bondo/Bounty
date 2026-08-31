# Features Research: Bullets and Bounty

Reference games: Arsenal, Phantom Forces, Bad Business, The Wild West, Frontlines

## Table Stakes

Features players expect in any Roblox FPS. Missing these = players leave immediately.

| Feature | Complexity | Notes |
|---------|-----------|-------|
| Responsive shooting | Medium | Instant feedback on fire, visible tracers/effects |
| Hit markers / kill confirmation | Low | Visual + audio cue when shots land |
| Crosshair | Low | Static or dynamic, must exist |
| Kill feed | Low | Shows who killed whom |
| Scoreboard | Low | Tab to see all players, kills, deaths |
| Respawning | Low | Quick respawn, no long waits |
| Mobile controls | Medium | Touch joystick, shoot button, aim assist |
| Sound effects | Low | Gun fire, reload, footsteps, impacts |
| Round timer / game flow | Low | Players need to know time remaining |
| Basic HUD | Low | Health, ammo, timer visible at all times |
| Smooth movement | Medium | No jitter, responsive WASD + mobile joystick |
| Death screen | Low | Show who killed you, respawn countdown |

## Differentiators

Features that could set Bullets and Bounty apart from other Roblox FPS games.

| Feature | Complexity | Dependencies | Notes |
|---------|-----------|-------------|-------|
| Western theme / atmosphere | Low-Med | Map, audio | Unique setting vs military/modern shooters |
| Match pacing (shrinking zones) | High | Round system | Battle-royale-like pressure, rare in Roblox FPS |
| Bridge collapse event | High | Map, physics | Scripted map event mid-match — memorable moment |
| Revolver-only combat | Low | Gun system | Skill-based, high-damage-per-shot gameplay |
| Bounty system | Medium | Progression | Cash bounties on high-kill players |
| Destructible environment | High | Physics, networking | Breakable barrels, crates, windows |
| Spawn invulnerability (ghost) | Medium | Spawn system | Flickering transparent — visual and mechanical |
| Opt-in lobby system | Medium | Round system | Join/leave freely, no forced waiting |
| Stat tracking / progression | Medium | DataStore | Level, XP, cash persist across sessions |
| Sprint + stamina | Medium | Character controller | Adds tactical depth (manage stamina) |

## Anti-Features

Things to deliberately NOT build in v1. These add complexity without core value.

| Feature | Why Not |
|---------|---------|
| Weapon skins / cosmetics | Requires shop UI, inventory, DataStore complexity — defer |
| Multiple weapon types | Revolver-only is the identity; adding variety dilutes and needs balancing |
| Vehicles | Map is too small, adds physics complexity |
| Building / fortification | Wrong genre — this is fast FPS, not Fortnite |
| Chat commands / admin system | Not needed for playtest phase |
| Clans / teams | Deathmatch is FFA, team features unnecessary |
| Custom character models | R15 default with western clothing is fine |
| Leaderboard (global) | OrderedDataStore adds complexity; do local scoreboard first |
| Voice chat | Roblox handles this natively if enabled, don't build custom |
| Achievement system | Nice-to-have, not core — defer to post-v1 |

## Feature Dependencies

```
Crosshair ← (standalone)
Hit markers ← Gun system
Kill feed ← Kill tracking ← Gun system
Scoreboard ← Kill/death tracking
Respawning ← Round system
Mobile controls ← Input system refactor
Sprint/Crouch ← Character controller ← Input system
Stamina ← Sprint
Weapon recoil ← Gun system + Camera control
Sound fix ← Positional audio refactor
Bullet impacts ← Raycasting + material detection
Stat tracking ← DataStore/ProfileService
Progression (XP/Level) ← Stat tracking
Cash system ← Stat tracking + Round rewards
Stat menu UI ← Stat tracking
Post-game stat board ← Round system + Stat tracking
Spawn invulnerability ← Spawn system
Mid-match join ← Lobby + Round system
Map reset ← Round system
Destructible objects ← Physics + Map reset
Match pacing zones ← Round system (advanced)
Bridge event ← Match pacing + Map scripting
```

## Recommendations

**Build order priority (based on dependencies and impact):**

1. **Code refactor + module cleanup** — foundation for everything else
2. **Sound fix + crosshair + hit markers** — immediate feel improvement
3. **Input system (mobile support)** — unlocks largest player base
4. **Sprint/crouch/stamina + recoil** — combat depth
5. **DataStore + progression** — retention loop
6. **Lobby + opt-in + mid-match join** — player flow
7. **Map reset + destructibles** — round polish
8. **Match pacing + bridge event** — signature feature, build last

The western theme and revolver-only combat are the strongest differentiators. Double down on gun feel (recoil, sound, impact effects) rather than adding feature breadth.
