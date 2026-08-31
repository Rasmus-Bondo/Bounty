# Graph Report - BaBGraph  (2026-05-08)

## Corpus Check
- Corpus is ~10,437 words - fits in a single context window. You may not need a graph.

## Summary
- 64 nodes · 69 edges · 19 communities detected
- Extraction: 71% EXTRACTED · 29% INFERRED · 0% AMBIGUOUS · INFERRED: 20 edges (avg confidence: 0.78)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Server Combat Pipeline|Server Combat Pipeline]]
- [[_COMMUNITY_Client Scripts & Effects|Client Scripts & Effects]]
- [[_COMMUNITY_High Noon Ultimate System|High Noon Ultimate System]]
- [[_COMMUNITY_Server Infrastructure|Server Infrastructure]]
- [[_COMMUNITY_Chrono Replication Framework|Chrono Replication Framework]]
- [[_COMMUNITY_Client Actions & Abilities|Client Actions & Abilities]]
- [[_COMMUNITY_ViewModel & Camera|ViewModel & Camera]]
- [[_COMMUNITY_Visual FX & FOV|Visual FX & FOV]]
- [[_COMMUNITY_Audio Effects|Audio Effects]]
- [[_COMMUNITY_Sound & VFX Services|Sound & VFX Services]]
- [[_COMMUNITY_Health Bar Display|Health Bar Display]]
- [[_COMMUNITY_Ragdoll Physics|Ragdoll Physics]]
- [[_COMMUNITY_Mobile Input|Mobile Input]]
- [[_COMMUNITY_Target UI|Target UI]]
- [[_COMMUNITY_Revolver Config|Revolver Config]]
- [[_COMMUNITY_Input Handling|Input Handling]]
- [[_COMMUNITY_Left Arm IK|Left Arm IK]]
- [[_COMMUNITY_Remote Events|Remote Events]]
- [[_COMMUNITY_Footstep Audio|Footstep Audio]]

## God Nodes (most connected - your core abstractions)
1. `RevolverModule` - 14 edges
2. `RevolverDash` - 6 edges
3. `Main` - 6 edges
4. `HighNoonModule` - 6 edges
5. `DashDustVFXServer` - 5 edges
6. `FPSRevolverClient` - 5 edges
7. `HunterGuiClient` - 5 edges
8. `chrono` - 4 edges
9. `HighNoonServerConfig` - 4 edges
10. `RevolverClientEvents` - 4 edges

## Surprising Connections (you probably didn't know these)
- `RevolverDash` --conceptually_related_to--> `RevolverDashService`  [INFERRED]
  BaBGraph/ReplicatedStorage/Revolver/Modules/RevolverDash.md → BaBGraph/ReplicatedStorage/Revolver/Modules/RevolverServer/RevolverDashService.md
- `HighNoonFOV` --semantically_similar_to--> `HighNoonGunFX`  [INFERRED] [semantically similar]
  BaBGraph/ReplicatedStorage/Revolver/Modules/HighNoonFOV.md → BaBGraph/ReplicatedStorage/Revolver/Modules/HighNoonGunFX.md
- `HighNoonLocalSFX` --semantically_similar_to--> `HighNoonPublicFX`  [INFERRED] [semantically similar]
  BaBGraph/ReplicatedStorage/Revolver/Modules/HighNoonLocalSFX.md → BaBGraph/ReplicatedStorage/Revolver/Modules/HighNoonPublicFX.md
- `RevolverAnimations` --conceptually_related_to--> `RevolverSkill2`  [INFERRED]
  BaBGraph/ReplicatedStorage/Revolver/Modules/RevolverAnimations.md → BaBGraph/ReplicatedStorage/Revolver/Modules/RevolverSkill2.md
- `RevolverDash` --references--> `JumpImpact`  [EXTRACTED]
  BaBGraph/ReplicatedStorage/Revolver/Modules/RevolverDash.md → BaBGraph/StarterGui/HunterGui/Template/TemplateGameGui/JumpImpact.md

## Hyperedges (group relationships)
- **Chrono Entity Replication System** — chrono_chrono, chrono_client_replicate, chrono_server_replicate, chrono_config, chrono_entity, chrono_types [EXTRACTED 0.95]
- **HighNoon Ultimate Ability System** — highnoon_chargeservice, highnoon_chargeui, highnoon_damage, highnoon_fov, highnoon_gunfx, highnoon_localsfx, highnoon_mobilebutton, highnoon_movement, highnoon_publicfx, highnoon_serverconfig, highnoon_targeting, highnoon_targetui [EXTRACTED 0.90]
- **HighNoon Client Visual/Audio Effects** — highnoon_fov, highnoon_gunfx, highnoon_localsfx, highnoon_publicfx, highnoon_targetui [INFERRED 0.85]
- **Client-side Revolver System** — revolverammo_module, revolveranimations_module, revolvercameraeffects_module, revolvershooting_module, revolverinput_module, revolverreload_module [INFERRED 0.80]
- **Viewmodel Rendering System** — revolverviewmodel_module, revolverviewmodelmotion_module, revolvercameraeffects_module, revolverleftarm_module [INFERRED 0.85]
- **Server-side Damage System** — revolverdamageservice_module, revolverhitforgiveness_module, revolvermodule [INFERRED 0.80]
- **Revolver Combat System** — revolvermodule, revolverimpactfx, revolverlagcompensation, revolverservercharacterutil, revolverserverconfig [EXTRACTED 0.95]
- **High Noon Ultimate System** — highnoonmodule, highnoonclient, highnoonviewmodelorbit [EXTRACTED 0.90]
- **UI Health System** — healthbarspawner, healthbarmanager, localhealthbarhide [INFERRED 0.80]

## Communities

### Community 0 - "Server Combat Pipeline"
Cohesion: 0.28
Nodes (9): RevolverDamageService, RevolverDashService, RevolverHitForgiveness, RevolverImpactFX, RevolverLagCompensation, RevolverModule, RevolverServerCharacterUtil, RevolverServerConfig (+1 more)

### Community 1 - "Client Scripts & Effects"
Cohesion: 0.25
Nodes (9): DashDustVFX, DashDustVFXServer, FPSRevolverClient, HighNoonClient, HighNoonModule, HighNoonViewModelOrbit, HitMarkScript, JumpImpact (+1 more)

### Community 2 - "High Noon Ultimate System"
Cohesion: 0.33
Nodes (7): HighNoonCharacterUtil, HighNoonChargeService, HighNoonChargeUI, HighNoonDamage, HighNoonMovement, HighNoonServerConfig, HighNoonTargeting

### Community 3 - "Server Infrastructure"
Cohesion: 0.29
Nodes (7): BotSpawner2, ChronoClientBootstrap, ChronoServerBootstrap, HealthBarManager, HealthBarSpawner, LocalHealthBarHide, Main

### Community 4 - "Chrono Replication Framework"
Cohesion: 0.53
Nodes (6): chrono, Replicate (Client), Config, Entity, Replicate (Server), Types

### Community 5 - "Client Actions & Abilities"
Cohesion: 0.53
Nodes (6): HunterGuiClient, RevolverAmmo, RevolverClientEvents, RevolverDash, RevolverReload, RevolverSkill2

### Community 6 - "ViewModel & Camera"
Cohesion: 0.5
Nodes (4): RevolverAnimations, RevolverCameraEffects, RevolverViewModel, RevolverViewModelMotion

### Community 7 - "Visual FX & FOV"
Cohesion: 0.67
Nodes (3): HighNoonFOV, HighNoonGunFX, laserBeamEffect

### Community 8 - "Audio Effects"
Cohesion: 1.0
Nodes (2): HighNoonLocalSFX, HighNoonPublicFX

### Community 9 - "Sound & VFX Services"
Cohesion: 1.0
Nodes (2): RevolverSoundService, RevolverVFXService

### Community 10 - "Health Bar Display"
Cohesion: 1.0
Nodes (1): HealthBarController

### Community 11 - "Ragdoll Physics"
Cohesion: 1.0
Nodes (1): Ragdoll

### Community 12 - "Mobile Input"
Cohesion: 1.0
Nodes (1): HighNoonMobileButton

### Community 13 - "Target UI"
Cohesion: 1.0
Nodes (1): HighNoonTargetUI

### Community 14 - "Revolver Config"
Cohesion: 1.0
Nodes (1): RevolverConfig

### Community 15 - "Input Handling"
Cohesion: 1.0
Nodes (1): RevolverInput

### Community 16 - "Left Arm IK"
Cohesion: 1.0
Nodes (1): RevolverLeftArm

### Community 17 - "Remote Events"
Cohesion: 1.0
Nodes (1): RevolverRemotes

### Community 18 - "Footstep Audio"
Cohesion: 1.0
Nodes (1): DefaultFootStepRemover

## Knowledge Gaps
- **29 isolated node(s):** `HealthBarController`, `Ragdoll`, `laserBeamEffect`, `HighNoonCharacterUtil`, `HighNoonChargeUI` (+24 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Audio Effects`** (2 nodes): `HighNoonLocalSFX`, `HighNoonPublicFX`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sound & VFX Services`** (2 nodes): `RevolverSoundService`, `RevolverVFXService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Health Bar Display`** (1 nodes): `HealthBarController`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Ragdoll Physics`** (1 nodes): `Ragdoll`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Mobile Input`** (1 nodes): `HighNoonMobileButton`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Target UI`** (1 nodes): `HighNoonTargetUI`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Revolver Config`** (1 nodes): `RevolverConfig`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Input Handling`** (1 nodes): `RevolverInput`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Left Arm IK`** (1 nodes): `RevolverLeftArm`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Remote Events`** (1 nodes): `RevolverRemotes`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Footstep Audio`** (1 nodes): `DefaultFootStepRemover`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `RevolverModule` connect `Server Combat Pipeline` to `Client Scripts & Effects`, `Server Infrastructure`, `Client Actions & Abilities`?**
  _High betweenness centrality (0.157) - this node is a cross-community bridge._
- **Why does `Main` connect `Server Infrastructure` to `Server Combat Pipeline`, `Client Scripts & Effects`?**
  _High betweenness centrality (0.095) - this node is a cross-community bridge._
- **Why does `RevolverSkill2` connect `Client Actions & Abilities` to `Server Combat Pipeline`, `ViewModel & Camera`?**
  _High betweenness centrality (0.063) - this node is a cross-community bridge._
- **What connects `HealthBarController`, `Ragdoll`, `laserBeamEffect` to the rest of the system?**
  _29 weakly-connected nodes found - possible documentation gaps or missing edges._