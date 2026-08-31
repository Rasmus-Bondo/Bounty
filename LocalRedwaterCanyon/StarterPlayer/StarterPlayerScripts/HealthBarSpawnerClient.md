---
tags:
  - client
  - localscript
  - ui
  - combat-feedback
path: game.StarterPlayer.StarterPlayerScripts.HealthBarSpawnerClient
type: LocalScript
lines: 35
---

# HealthBarSpawnerClient

Client-side health bar spawner that shows an overhead health bar on a hit target, visible only to the attacker who dealt the hit.

## What it does
1. Listens for the `HealthBarReveal` RemoteEvent, fired server-side only to the player who just landed a hit
2. Calls `HealthBarController:RevealDamage()` synchronously (no `task.defer`) every single time the remote fires — not just the first time — so the bar only ever reacts to hits *this* client's player actually dealt, never another attacker's hits on the same target (see [[HealthBarController]])
3. On the first hit against a given target, `RevealDamage` internally calls `SetupCharacter`, which clones the `HealthBarGui` template and parents it onto that character's `Head` — since this clone is created by the local client, it never replicates to the server or to other clients, so only the attacker sees it
4. Each attacker who hits the same target ends up with their own independent local copy of the bar and its own 3-second visibility timer

## Dependencies
- **Requires:** [[HealthBarController]] (from `ReplicatedStorage.Modules`)
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `HealthBarReveal` | ← Server | Listened from `Hunters.Shared.Remotes` (cross-hero — created by [[HunterSharedRemoteSetup]]); fired by [[RevolverModule]], [[HighNoonDamage]], and [[CardsServer]] to the attacker only, on every landed hit |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HealthBarController]] | `.new()`, `:RevealDamage()` | Creates (on first hit) and re-triggers the locally-owned overhead health bar BillboardGui on every hit |
