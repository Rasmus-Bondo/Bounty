---
tags: [server, script, networking, setup, shared]
path: game.ServerScriptService.Hunters.HunterSharedRemoteSetup
type: Script
lines: 57
---

# HunterSharedRemoteSetup

Startup server script that creates the neutral cross-hero remotes folder used by every hunter, and fixes each remote's reliability class.

## What it does
1. Ensures `ReplicatedStorage.Hunters.Shared.Remotes` folder exists
2. Creates 7 reliable RemoteEvents in it (idempotent via [[HunterRemoteSetup]]): the 5 cross-hero combat remotes `HitConfirm`, `HealthBarReveal`, `DamageDirection`, `KillFeed`, `KillCam`, plus the 2 bot FX remotes `BotUltimateFX` and `BotFortunaCardFX`
3. Creates `BotShotFX` and `BotTransformUpdate` as **UnreliableRemoteEvents**, destroying and recreating either one if an older reliable `RemoteEvent` of that name is found. Both are transient and superseded by the next shot/tick, so resend and queue semantics only cost bandwidth when a connection falls behind
4. `BotUltimateFX` and `BotFortunaCardFX` stay reliable on purpose, and a long comment above them in the source says so. They carry paired state transitions (ultimate `Start`/`End`, card `Stick`/`Remove`/`Recall`/`Clear`), and unreliable delivery is lossy *and* unordered — a dropped or late `End` leaves the highlight, looping sound and dust ring running on every client forever, and a dropped `Clear` orphans Fortuna cards in the world. They are also low-frequency, so the bandwidth argument for the unreliable pair does not apply
5. That same reliability split is why only the unreliable pair is drained during client load by EarlyShotRemoteDrain: a reliable RemoteEvent hands its queued events to whichever handler connects first, so a no-op drain on `BotUltimateFX` would swallow a `Start` the real handler never sees
6. Runs once at server startup; consumers (server firers + client listeners) read from this single canonical path instead of each hunter's own `Hunters.<Hunter>.Remotes` folder

## Dependencies
- **Requires:** [[HunterRemoteSetup]]
- **Required by:** Nobody (Script; consumers find the resulting remotes via `WaitForChild` on `Hunters.Shared.Remotes`)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `HitConfirm` | created | Server → Client; fired by [[RevolverModule]], [[HighNoonDamage]], [[CardsServer]]; listened by [[HitMarkScript]] (Dust + Fortuna copies) |
| `HealthBarReveal` | created | Server → Client (attacker only); fired by [[RevolverModule]], [[HighNoonDamage]], [[CardsServer]]; listened by [[HealthBarSpawnerClient]] |
| `DamageDirection` | created | Server → Client (victim); fired by [[RevolverModule]], [[HighNoonDamage]], [[CardsServer]]; listened by [[DamageDirectionClient]] |
| `KillFeed` | created | Server → All Clients; fired by [[RevolverModule]], [[HighNoonDamage]], [[CardsServer]], [[BotController]] (bot kills); listened by [[KillFeedClient]] |
| `KillCam` | created | Server → Client (victim); fired by [[RevolverModule]], [[HighNoonDamage]], [[CardsServer]], [[BotController]] (bot kills — payload is the bot rig, not a Player); listened by [[KillCamClient]] |
| `BotUltimateFX` | created (reliable) | Server → All Clients; fired by [[BotCombat]] as paired `Start`/`End` phases for Dust, Fortuna and Bram ultimates; listened by [[BotVisualClient]]. Must stay reliable — see note 4 — and must never be drained |
| `BotFortunaCardFX` | created (reliable) | Server → All Clients; fired by [[BotCombat]] as `Stick`/`Remove`/`Recall`/`Clear` card lifecycle ops; listened by [[BotVisualClient]]. Must stay reliable — see note 4 — and must never be drained |
| `BotShotFX` | created (unreliable) | Server → Nearby Clients; fired by [[BotCombat]] per bot shot; listened by [[BotVisualClient]] and drained during load by [[EarlyShotRemoteDrain]] |
| `BotTransformUpdate` | created (unreliable) | Server → All Clients; fired by [[BotService]] as a batched pivot/velocity/grapple list each tick; listened by [[BotVisualClient]] and drained during load by [[EarlyShotRemoteDrain]] |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterRemoteSetup]] | `.EnsureFolder()`, `.EnsureRemoteEvents()` | Shared idempotent folder/remote creation |
