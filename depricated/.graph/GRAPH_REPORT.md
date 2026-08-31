# Graph Report - LocalRedwaterCanyon  (2026-05-20)

## Corpus Check
- 77 files · ~19,354 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 75 nodes · 108 edges · 17 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_High Noon Ultimate|High Noon Ultimate]]
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Chrono Networking|Chrono Networking]]
- [[_COMMUNITY_Testing|Testing]]
- [[_COMMUNITY_Round System|Round System]]
- [[_COMMUNITY_UI & HUD|UI & HUD]]
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Types|Types]]
- [[_COMMUNITY_Ragdoll|Ragdoll]]
- [[_COMMUNITY_HealthBarManager|HealthBarManager]]
- [[_COMMUNITY_RoundStatusClient|RoundStatusClient]]
- [[_COMMUNITY_Audio|Audio]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_LocalHealthBarHide|LocalHealthBarHide]]
- [[_COMMUNITY_ZoneAtmosphere|ZoneAtmosphere]]

## God Nodes (most connected - your core abstractions)
1. `FPSRevolverClient` - 21 edges
2. `RevolverModule` - 16 edges
3. `HighNoonModule` - 12 edges
4. `HighNoonClient` - 12 edges
5. `Main` - 10 edges
6. `Config` - 9 edges
7. `RoundController` - 8 edges
8. `RevolverDash` - 6 edges
9. `BountyService` - 6 edges
10. `ProgressionService` - 6 edges

## Surprising Connections (you probably didn't know these)
- `laserBeamEffect` --calls--> `HighNoonClient`  [EXTRACTED]
  LocalRedwaterCanyon/ReplicatedStorage/Revolver/laserBeamEffect.md → LocalRedwaterCanyon/StarterPlayer/StarterPlayerScripts/HighNoonClient.md
- `RevolverAnimations` --calls--> `FPSRevolverClient`  [EXTRACTED]
  LocalRedwaterCanyon/ReplicatedStorage/Revolver/Modules/RevolverAnimations.md → LocalRedwaterCanyon/StarterPlayer/StarterPlayerScripts/FPSRevolverClient.md
- `RevolverViewModel` --calls--> `FPSRevolverClient`  [EXTRACTED]
  LocalRedwaterCanyon/ReplicatedStorage/Revolver/Modules/RevolverViewModel.md → LocalRedwaterCanyon/StarterPlayer/StarterPlayerScripts/FPSRevolverClient.md
- `HealthBarSpawner` --calls--> `Main`  [EXTRACTED]
  LocalRedwaterCanyon/ServerScriptService/UI/HealthBarSpawner.md → LocalRedwaterCanyon/ServerScriptService/Main.md
- `FPSRevolverClient` --calls--> `JumpImpact`  [EXTRACTED]
  LocalRedwaterCanyon/StarterPlayer/StarterPlayerScripts/FPSRevolverClient.md → LocalRedwaterCanyon/StarterGui/HunterGui/Template/TemplateGameGui/JumpImpact.md

## Communities

### Community 0 - "High Noon Ultimate"
Cohesion: 0.15
Nodes (17): HighNoonCharacterUtil, HighNoonChargeService, HighNoonChargeUI, HighNoonClient, HighNoonDamage, HighNoonFOV, HighNoonGunFX, HighNoonLocalSFX (+9 more)

### Community 1 - "Combat"
Cohesion: 0.2
Nodes (11): DashDustVFX, DashDustVFXServer, RevolverDamageService, RevolverDashService, RevolverHitForgiveness, RevolverImpactFX, RevolverLagCompensation, RevolverModule (+3 more)

### Community 2 - "Combat"
Cohesion: 0.2
Nodes (11): FPSRevolverClient, laserBeamEffect, RevolverCameraEffects, RevolverConfig, RevolverInput, RevolverLeftArm, RevolverReload, RevolverRemotes (+3 more)

### Community 3 - "Combat"
Cohesion: 0.43
Nodes (7): HunterGuiClient, JumpImpact, RevolverAmmo, RevolverClientEvents, RevolverDash, RevolverShooting, RevolverSkill2

### Community 4 - "Chrono Networking"
Cohesion: 0.47
Nodes (6): chrono, ChronoClientBootstrap, ChronoServerBootstrap, Config, Entity, Replicate

### Community 5 - "Testing"
Cohesion: 0.47
Nodes (6): BotSpawner2, BountyClient, BountyService, DataService, Main, ProgressionService

### Community 6 - "Round System"
Cohesion: 0.6
Nodes (5): DestructibleService, RoundController, SpawnService, State, ZoneService

### Community 7 - "UI & HUD"
Cohesion: 1.0
Nodes (2): HealthBarController, HealthBarSpawner

### Community 8 - "Combat"
Cohesion: 1.0
Nodes (2): RevolverAnimations, RevolverViewModel

### Community 9 - "Types"
Cohesion: 1.0
Nodes (1): Types

### Community 10 - "Ragdoll"
Cohesion: 1.0
Nodes (1): Ragdoll

### Community 11 - "HealthBarManager"
Cohesion: 1.0
Nodes (1): HealthBarManager

### Community 12 - "RoundStatusClient"
Cohesion: 1.0
Nodes (1): RoundStatusClient

### Community 13 - "Audio"
Cohesion: 1.0
Nodes (1): DefaultFootStepRemover

### Community 14 - "Server Bootstrap"
Cohesion: 1.0
Nodes (1): DisableDefaultHealth

### Community 15 - "LocalHealthBarHide"
Cohesion: 1.0
Nodes (1): LocalHealthBarHide

### Community 16 - "ZoneAtmosphere"
Cohesion: 1.0
Nodes (1): ZoneAtmosphere

## Knowledge Gaps
- **38 isolated node(s):** `Types`, `HealthBarController`, `Ragdoll`, `HighNoonCharacterUtil`, `HighNoonChargeUI` (+33 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `UI & HUD`** (2 nodes): `HealthBarController`, `HealthBarSpawner`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Combat`** (2 nodes): `RevolverAnimations`, `RevolverViewModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Types`** (1 nodes): `Types`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Ragdoll`** (1 nodes): `Ragdoll`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `HealthBarManager`** (1 nodes): `HealthBarManager`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `RoundStatusClient`** (1 nodes): `RoundStatusClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Audio`** (1 nodes): `DefaultFootStepRemover`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Server Bootstrap`** (1 nodes): `DisableDefaultHealth`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `LocalHealthBarHide`** (1 nodes): `LocalHealthBarHide`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `ZoneAtmosphere`** (1 nodes): `ZoneAtmosphere`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Main` connect `Testing` to `High Noon Ultimate`, `Combat`, `Chrono Networking`, `Round System`, `UI & HUD`?**
  _High betweenness centrality (0.345) - this node is a cross-community bridge._
- **Why does `FPSRevolverClient` connect `Combat` to `Combat`, `Combat`, `Combat`, `High Noon Ultimate`?**
  _High betweenness centrality (0.328) - this node is a cross-community bridge._
- **Why does `HighNoonModule` connect `High Noon Ultimate` to `Combat`, `Combat`, `Testing`?**
  _High betweenness centrality (0.306) - this node is a cross-community bridge._
- **What connects `Types`, `HealthBarController`, `Ragdoll` to the rest of the system?**
  _38 weakly-connected nodes found - possible documentation gaps or missing edges._