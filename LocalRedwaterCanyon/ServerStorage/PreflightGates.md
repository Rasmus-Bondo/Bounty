---
tags: [server, modulescript, tooling, preflight, mirror]
path: game.ServerStorage.PreflightGates
type: ModuleScript
lines: 626
---

# PreflightGates

Tooling-only ModuleScript holding the Studio half of `/preflight` and `/mirror`, installed identically in all three places. Never required by game code and never runs in a live server. Loaded with `loadstring(game.ServerStorage.PreflightGates.Source)()`; canonical source is `.claude/skills/preflight/PreflightGates.luau` in the docs repo, installed from `PreflightGates.rbxm`.

## What it does
1. `run()` — every per-place gate in one call, printing a `VERDICT` (PASS / JUDGE / FAIL) and a `COMPARE universe= clips= gates=` line that must agree across places
2. `walk(tier, prefix)` / `mirror(tier, prefix)` — the mirror walker: FNV-1a folds over the `match` roots (Redwater ↔ Frostbite) or the 21 `universe` modules, with a scripts-only fold (`s=`) beside the full one and a separate `resolved N of N` count
3. `syntax()` — `loadstring`-compiles every script in the place's script-bearing services
4. `botConfig()` / `roundConfig()` — assert `ServerScriptService.Bots.BotConfig` and `RoundSystem.Config` against the expected values declared at the top of the module (match places only)
5. `contract()` / `clips(group)` — run `ReplicatedStorage.Hunters.Shared.HunterViewmodelContract`'s `Report()` and `ClipManifest()` through `loadstring`, filtering the accepted `STANDING` lines so only new WARN/NOTE lines surface
6. `version()` — reads the `GameEnvironment.version = "..."` line out of the source text (no execution) for the release bump
7. Prints its own source hash (`gates=`), so a place holding a stale copy shows up in the cross-place compare

## Dependencies
- **Requires:** Nothing (loads HunterViewmodelContract, BotConfig, RoundSystem.Config via `loadstring` of their source, never `require`)
- **Required by:** Nobody (run from `execute_luau` by the /preflight and /mirror skills)

## Connections
### RemoteEvents
None.

### BindableEvents
None.

### Direct require()
None.
