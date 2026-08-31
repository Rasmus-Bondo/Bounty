# Research Summary: Bullets and Bounty

## Key Findings

### Stack
- **Server-authoritative architecture** — client sends intent, server validates and applies all damage/state
- **ProfileService** for DataStore persistence — handles session locking, retries, rate limits automatically
- **Traditional ScreenGui** for UI — no framework overhead, use constraint objects for mobile scaling
- **ContextActionService** for cross-platform input — built-in touch button support
- **Positional audio** on gun Attachments — fixes current server-wide sound bug
- **workspace:Raycast()** for hit detection — server validates all hits

### Table Stakes (must have)
- Crosshair, hit markers, kill feed, scoreboard
- Responsive shooting with visual/audio feedback
- Quick respawning, death screen
- Mobile controls (touch joystick, shoot button, aim assist)
- Basic HUD (health, ammo, timer)
- Smooth movement on both PC and mobile

### Differentiators (competitive advantage)
- Western theme + revolver-only combat (unique in Roblox FPS space)
- Match pacing with shrinking zones + bridge collapse event
- Bounty system on high-kill players
- Spawn invulnerability with ghost/flicker visual
- Opt-in lobby (join/leave freely)

### Watch Out For
1. **Client-trusted combat** — #1 exploit vector, must fix during combat refactor
2. **DataStore data loss** — use ProfileService, implement BindToClose, auto-save periodically
3. **Server-wide sounds** — current bug, fix by moving to client-side positional audio
4. **Mobile performance** — test on phones throughout development, not at the end
5. **Mobile input design** — needs aim assist, large touch targets, not just virtual buttons
6. **RemoteEvent flooding** — rate-limit all remotes server-side
7. **Round edge cases** — use explicit state machine, handle join/leave in every state

### Architecture Direction
- Consolidate RemoteEvents into shared folder with manager
- Convert standalone scripts to ModuleScripts under a service-oriented structure
- Thin Tool scripts that delegate to shared modules
- Clear separation: Server services (GameManager, RoundController, CombatManager, PlayerDataService) / Client controllers (InputController, WeaponClient, CameraController, UIController)

### Recommended Build Order
1. Code refactor + remote consolidation (foundation)
2. Sound fix + crosshair + hit markers (immediate feel)
3. Combat validation + server authority (security)
4. Input system + mobile controls (largest audience)
5. Sprint/crouch/stamina + recoil (combat depth)
6. DataStore + progression (retention)
7. Lobby + opt-in + mid-match join (player flow)
8. Spawn invulnerability + map reset (round polish)
9. Destructibles + match pacing (signature features)

## Files

- `STACK.md` — Roblox services, APIs, and patterns
- `FEATURES.md` — Feature categorization and dependencies
- `ARCHITECTURE.md` — Module structure, data flow, refactoring plan
- `PITFALLS.md` — Common mistakes and prevention strategies
