# ReplicatedStorage

Shared container replicated to both server and all clients. Holds modules, events, assets, and templates that both sides of the game need access to.

**Path:** `game.ReplicatedStorage`

## Scripts & Modules

| Name | Type | Description |
|------|------|-------------|
| [[Shime]] | ModuleScript | UI shimmer/shine effect library for GuiObjects |
| [[CombatEvents]] | ModuleScript | Cached references to combat-related RemoteEvents |
| [[laserBeamEffect]] | ModuleScript | Bullet tracer beam visual effect |

## Folders

| Name | Contents |
|------|----------|
| [[Events Folder\|Events]] | RemoteEvents and BindableEvents for client-server communication |
| [[TarotEngine Folder\|TarotEngine]] | 7-module card gacha system (rolling, spawning, animating, interacting) |
| [[Revolver Folder\|Revolver]] | Bullet tracer module, LaserBeam template, ReplicateShot remote |
| [[SFX Folder\|SFX]] | Sound effect templates (impacts, round, cards, cosmetic) |
| [[VFX Folder\|VFX]] | ParticleEmitter templates for material-based bullet impacts |
| [[CardTemplates Folder\|CardTemplates]] | MeshPart card models by rarity (Common through Legendary) |

## Standalone Assets

| Name | Class | Description |
|------|-------|-------------|
| RoundStatus | StringValue | Current round status text, created by [[References]] |
| RoundTime | IntValue | Remaining round time in seconds, created by [[References]] |
| BuyCardsEvent | RemoteEvent | Triggers card pack opening, used by [[BuyCardsServer]] and [[CardController]] |
| SparkleLegendary | ParticleEmitter | Sparkle effect template cloned onto legendary cards |
| WoodSplinterParticle | ParticleEmitter | Wood impact particle (standalone, outside VFX folder) |
| [[BotRig]] | Model | R15 character template used by [[BotSpawner]] for AI bots |
| Footstep | Part | Template with SandStep sound + footprint Decal, cloned by [[FootstepService]] |
| Model | Model | (Unused/placeholder model) |
| 100966990927922 Hat ID | Folder | Hat asset reference |
