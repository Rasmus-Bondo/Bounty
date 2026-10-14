# Graph Report - LocalBountyLobby  (2026-10-14)

## Corpus Check
- 6 files · ~2,297 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 6 nodes · 2 edges · 4 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Party System|Party System]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_AltCursorClient|AltCursorClient]]
- [[_COMMUNITY_ViewmodelController|ViewmodelController]]

## God Nodes (most connected - your core abstractions)
1. `PartyPadService` - 1 edges
2. `ProfileService` - 1 edges
3. `PVEDataService` - 1 edges
4. `PartyPadClient` - 1 edges
5. `AltCursorClient` - 0 edges
6. `ViewmodelController` - 0 edges

## Surprising Connections (you probably didn't know these)
- `PartyPadClient` --calls--> `PartyPadService`  [EXTRACTED]
  LocalBountyLobby/StarterPlayer/StarterPlayerScripts/PartyPadClient.md → LocalBountyLobby/ServerScriptService/PartyPadService.md
- `PVEDataService` --calls--> `ProfileService`  [EXTRACTED]
  LocalBountyLobby/ServerScriptService/PlayerServices/PVEDataService.md → LocalBountyLobby/ServerScriptService/PlayerServices/ProfileService.md

## Communities

### Community 0 - "Party System"
Cohesion: 1.0
Nodes (2): PartyPadClient, PartyPadService

### Community 1 - "Server Bootstrap"
Cohesion: 1.0
Nodes (2): ProfileService, PVEDataService

### Community 2 - "AltCursorClient"
Cohesion: 1.0
Nodes (1): AltCursorClient

### Community 3 - "ViewmodelController"
Cohesion: 1.0
Nodes (1): ViewmodelController

## Knowledge Gaps
- **6 isolated node(s):** `PartyPadService`, `ProfileService`, `PVEDataService`, `AltCursorClient`, `PartyPadClient` (+1 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Party System`** (2 nodes): `PartyPadClient`, `PartyPadService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Server Bootstrap`** (2 nodes): `ProfileService`, `PVEDataService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `AltCursorClient`** (1 nodes): `AltCursorClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `ViewmodelController`** (1 nodes): `ViewmodelController`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `PartyPadService`, `ProfileService`, `PVEDataService` to the rest of the system?**
  _6 weakly-connected nodes found - possible documentation gaps or missing edges._