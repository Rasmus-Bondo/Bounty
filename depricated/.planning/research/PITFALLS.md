# Pitfalls Research: Bullets and Bounty

## Critical Pitfalls

### 1. Client-Trusted Combat (Exploits)

**The mistake:** Letting the client decide if a shot hit and how much damage to deal. Exploiters can fire RemoteEvents with fake data to kill anyone instantly.

**Warning signs:** Players dying from impossible angles, instant kills, damage from across the map.

**Prevention:**
- Server performs its own raycast using client-provided direction
- Validate ray origin is within reasonable distance of player's actual position
- Rate-limit fire events (max shots per second based on weapon fire rate)
- Sanity check damage values server-side

**Phase:** Combat system refactor (early)

---

### 2. DataStore Data Loss

**The mistake:** Saving on PlayerRemoving only, not handling edge cases. Data lost when server crashes, `PlayerRemoving` doesn't fire on last player, or `game:BindToClose()` is missing.

**Warning signs:** Players reporting lost progress, inconsistent cash/XP after rejoining.

**Prevention:**
- Use ProfileService (handles session locking + retries)
- Implement `game:BindToClose()` to save all profiles on shutdown
- Auto-save every 60-120 seconds during gameplay
- Never save inside pcall without logging the error
- Test by force-closing the server during play

**Phase:** Persistence implementation

---

### 3. DataStore Rate Limits

**The mistake:** Calling `SetAsync` / `GetAsync` too frequently, hitting the 60 + 10*numPlayers requests/minute limit.

**Warning signs:** DataStore errors in output, saves silently failing, "Request was throttled" warnings.

**Prevention:**
- ProfileService handles throttling automatically
- If raw DataStore: queue saves, batch updates, use `UpdateAsync` instead of `SetAsync`
- Never save on every kill/event — accumulate changes, save periodically

**Phase:** Persistence implementation

---

### 4. Server-Wide Sound Playback

**The mistake:** Playing sounds from a server Script makes them audible everywhere at full volume. This is the current bug in the codebase.

**Warning signs:** Gunshots heard globally regardless of distance, reload sounds from across the map.

**Prevention:**
- Fire a RemoteEvent to notify clients, clients play sounds locally
- Parent Sound instances to the gun Part or an Attachment on it
- Set RollOffMode, RollOffMinDistance, RollOffMaxDistance for spatial falloff
- Server only sends "Player X fired" — client handles audio/visual

**Phase:** Sound system fix (early)

---

### 5. Mobile Performance

**The mistake:** Building for PC, testing on PC, then discovering it runs at 15 FPS on phones. Part count, scripts, and effects that are fine on PC destroy mobile performance.

**Warning signs:** Frame drops on mobile, "Client Memory" warnings, laggy touch input.

**Prevention:**
- Test on a low-end phone regularly (not just in Studio)
- Keep workspace part count under 10,000 for mobile
- Use `StreamingEnabled` for large maps
- Reduce particle emission rates on mobile (check `UserInputService.TouchEnabled`)
- Avoid excessive `RunService.Heartbeat` connections
- Profile with Roblox's MicroProfiler

**Phase:** Should be considered in EVERY phase, not a separate phase

---

### 6. Mobile Input Feel

**The mistake:** Porting PC controls to mobile with virtual buttons and calling it done. Touch FPS needs fundamentally different input design.

**Warning signs:** Players can't aim, accidental button presses, UI elements too small.

**Prevention:**
- Aim assist / bullet magnetism for touch (slight auto-correction toward nearest target)
- Large touch targets (minimum 44x44 logical pixels)
- Customizable HUD layout (let players move buttons)
- Separate sensitivity settings for touch vs mouse
- Auto-fire option or tap-to-shoot vs hold-to-aim modes
- Test with actual fingers on actual phones

**Phase:** Input system + mobile controls

---

### 7. Ragdoll Networking

**The mistake:** Applying ragdoll physics only on one client or only on server, causing desync. Different clients see the body in different positions.

**Warning signs:** Bodies snapping to weird positions, bodies standing up on death for some players, "ragdoll fix" already on the task list.

**Prevention:**
- Apply ragdoll on server (set all Motor6D joints to BallSocketConstraints)
- Let Roblox physics replication handle syncing
- Don't try to replicate ragdoll state manually
- Keep ragdoll brief (3-5 seconds), then remove character

**Phase:** Ragdoll fix (low priority per team)

---

### 8. Round Edge Cases

**The mistake:** Not handling players joining/leaving during round transitions. Round starts with 0 players, round ends but intermission never fires, player leaves during countdown.

**Warning signs:** Stuck in "waiting for players" forever, rounds that never end, ghost players in scoreboard.

**Prevention:**
- State machine for round lifecycle: `Lobby → Countdown → Active → Intermission → Lobby`
- Handle `PlayerRemoving` in every state
- Minimum player check before starting countdown
- Force-end round if all players leave during Active
- Clean up player data (scoreboard, teams) on disconnect

**Phase:** Round system refactor

---

### 9. Spawn Killing

**The mistake:** Fixed spawn points that enemies can camp. Players die immediately after respawning.

**Warning signs:** Players complaining about unfair spawns, one team/player dominating by controlling spawn area.

**Prevention:**
- Multiple spawn points spread across map
- Anti-spawn-camp: don't spawn near enemies (distance check)
- Spawn invulnerability (the ghosted/flickering system planned) — 5-10 seconds
- During invulnerability: player can't deal damage either (prevents exploit)
- Random spawn point selection weighted by distance from enemies

**Phase:** Spawn system + invulnerability

---

### 10. RemoteEvent Flooding

**The mistake:** Not rate-limiting RemoteEvents. Exploiters can spam fire events thousands of times per second, crashing the server or getting rapid-fire weapons.

**Warning signs:** Server lag spikes, players firing faster than intended, server CPU warnings.

**Prevention:**
- Server-side cooldown per player per remote (track last fire time)
- Kick or throttle players who exceed rate limits
- Use `tick()` comparisons, not just debounce booleans
- Log suspicious activity for review

**Phase:** Combat system (server validation)

---

## Medium Pitfalls

### 11. Memory Leaks from Connections

**The mistake:** Connecting to `RunService.Heartbeat`, `Touched`, or other events without disconnecting when the player dies/leaves or the object is destroyed.

**Prevention:** Store connection objects, disconnect in cleanup functions. Use `Maid`/`Janitor` pattern or manual `:Disconnect()` tracking.

### 12. Value Objects for State (StringValue, IntValue)

**The mistake:** Using ValueBase objects (like the current RoundStatus StringValue and RoundTime IntValue) for complex state. Gets messy fast, hard to debug, no type safety.

**Prevention:** Use ModuleScript state tables + RemoteEvents to sync. ValueBase objects are fine for simple cases but don't scale.

### 13. Tool Architecture Limitations

**The mistake:** Putting too much logic in Tool scripts (GunClient, GunServer inside the Tool). When the tool is cloned/destroyed, scripts restart, losing state.

**Prevention:** Keep Tool scripts thin — they call into ModuleScripts in ReplicatedStorage or ServerScriptService that hold the actual logic and state.

### 14. Not Testing with Multiple Players

**The mistake:** Only testing in Studio with 1 player. Multiplayer bugs (replication, race conditions, spawn conflicts) only appear with 2+ players.

**Prevention:** Use Studio's "Test" > "Start" with 2-3 players regularly. Test join/leave during every round state.

## Recommendations

1. **Fix sound and combat validation first** — these are the most impactful bugs and the easiest exploits
2. **Use ProfileService from day one** — don't build raw DataStore code you'll replace later
3. **Test on mobile after every major change** — don't save mobile testing for the end
4. **Rate-limit all RemoteEvents** — add server-side cooldowns during combat refactor
5. **State machine for rounds** — explicit states prevent edge case bugs
6. **Keep Tool scripts thin** — logic in modules, tools are just holders
