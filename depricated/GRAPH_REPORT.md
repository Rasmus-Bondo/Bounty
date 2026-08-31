# Graph Report - BaBGraph  (2026-05-03)

## Corpus Check
- Corpus is ~3,063 words - fits in a single context window. You may not need a graph.

## Summary
- 31 nodes · 46 edges · 7 communities detected
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 2 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Server Combat Core|Server Combat Core]]
- [[_COMMUNITY_Client Weapon & HUD|Client Weapon & HUD]]
- [[_COMMUNITY_Ultimate Ability|Ultimate Ability]]
- [[_COMMUNITY_View Model Orbit|View Model Orbit]]
- [[_COMMUNITY_Bot Spawner|Bot Spawner]]
- [[_COMMUNITY_Local Health Bar|Local Health Bar]]
- [[_COMMUNITY_Footstep Audio|Footstep Audio]]

## God Nodes (most connected - your core abstractions)
1. `FPSRevolverClient` - 12 edges
2. `HighNoonModule` - 10 edges
3. `HighNoonClient` - 9 edges
4. `RevolverModule` - 7 edges
5. `HunterGuiClient` - 6 edges
6. `Main` - 4 edges
7. `DashRequest (RemoteEvent)` - 3 edges
8. `HitConfirm (RemoteEvent)` - 3 edges
9. `HighNoonVisual (RemoteEvent)` - 3 edges
10. `DashDustVFXModule` - 2 edges

## Surprising Connections (you probably didn't know these)
- `RevolverModule` --semantically_similar_to--> `FPSRevolverClient`  [INFERRED] [semantically similar]
  BaBGraph/ServerScriptService/Combat/RevolverModule.md → BaBGraph/StarterPlayer/StarterPlayerScripts/FPSRevolverClient.md
- `HighNoonModule` --semantically_similar_to--> `HighNoonClient`  [INFERRED] [semantically similar]
  BaBGraph/ServerScriptService/Combat/Ultimates/HighNoonModule.md → BaBGraph/StarterPlayer/StarterPlayerScripts/HighNoonClient.md
- `HighNoonClient` --calls--> `laserBeamEffect`  [EXTRACTED]
  BaBGraph/StarterPlayer/StarterPlayerScripts/HighNoonClient.md → BaBGraph/ReplicatedStorage/Revolver/laserBeamEffect.md
- `FPSRevolverClient` --references--> `FireBullet (RemoteEvent)`  [EXTRACTED]
  BaBGraph/StarterPlayer/StarterPlayerScripts/FPSRevolverClient.md → BaBGraph/ServerScriptService/Combat/RevolverModule.md
- `ReplicateShot (RemoteEvent)` --references--> `FPSRevolverClient`  [EXTRACTED]
  BaBGraph/ServerScriptService/Combat/RevolverModule.md → BaBGraph/StarterPlayer/StarterPlayerScripts/FPSRevolverClient.md

## Hyperedges (group relationships)
- **Revolver Combat Flow** — fps_revolver_client, revolver_module, hitmark_script, laser_beam_effect [EXTRACTED 0.90]
- **High Noon Ultimate Flow** — highnoon_client, highnoon_module, highnoon_viewmodel_orbit [EXTRACTED 0.90]
- **HUD BindableEvent Bus** — fps_revolver_client, hunter_gui_client, bindable_ammochanged, bindable_reloaded, bindable_dashrequested, bindable_skill2requested [EXTRACTED 0.90]

## Communities

### Community 0 - "Server Combat Core"
Cohesion: 0.25
Nodes (9): DashDustVFXModule, HealthBarModule, HitMarkScript, Main, DashRequest (RemoteEvent), FireBullet (RemoteEvent), HitConfirm (RemoteEvent), ReplicateShot (RemoteEvent) (+1 more)

### Community 1 - "Client Weapon & HUD"
Cohesion: 0.36
Nodes (9): AmmoChanged (BindableEvent), DashCooldownStarted (BindableEvent), DashRequested (BindableEvent), Reloaded (BindableEvent), Skill2CooldownStarted (BindableEvent), Skill2Requested (BindableEvent), FPSRevolverClient, HunterGuiClient (+1 more)

### Community 2 - "Ultimate Ability"
Cohesion: 0.46
Nodes (8): HighNoonClient, HighNoonModule, HighNoonAimUpdate (RemoteEvent), HighNoonChargeUpdate (RemoteEvent), HighNoonRequest (RemoteEvent), HighNoonShootRequest (RemoteEvent), HighNoonShot (RemoteEvent), HighNoonVisual (RemoteEvent)

### Community 3 - "View Model Orbit"
Cohesion: 1.0
Nodes (2): HighNoonAimNudge (BindableEvent), HighNoonViewModelOrbit

### Community 4 - "Bot Spawner"
Cohesion: 1.0
Nodes (1): BotSpawner2

### Community 5 - "Local Health Bar"
Cohesion: 1.0
Nodes (1): LocalHealthBarHide

### Community 6 - "Footstep Audio"
Cohesion: 1.0
Nodes (1): DefaultFootStepRemover

## Knowledge Gaps
- **6 isolated node(s):** `HealthBarModule`, `BotSpawner2`, `HighNoonViewModelOrbit`, `HitMarkScript`, `LocalHealthBarHide` (+1 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `View Model Orbit`** (2 nodes): `HighNoonAimNudge (BindableEvent)`, `HighNoonViewModelOrbit`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Bot Spawner`** (1 nodes): `BotSpawner2`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Local Health Bar`** (1 nodes): `LocalHealthBarHide`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Footstep Audio`** (1 nodes): `DefaultFootStepRemover`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FPSRevolverClient` connect `Client Weapon & HUD` to `Server Combat Core`, `Ultimate Ability`?**
  _High betweenness centrality (0.384) - this node is a cross-community bridge._
- **Why does `HighNoonModule` connect `Ultimate Ability` to `Server Combat Core`?**
  _High betweenness centrality (0.237) - this node is a cross-community bridge._
- **Why does `RevolverModule` connect `Server Combat Core` to `Client Weapon & HUD`, `Ultimate Ability`?**
  _High betweenness centrality (0.198) - this node is a cross-community bridge._
- **What connects `HealthBarModule`, `BotSpawner2`, `HighNoonViewModelOrbit` to the rest of the system?**
  _6 weakly-connected nodes found - possible documentation gaps or missing edges._