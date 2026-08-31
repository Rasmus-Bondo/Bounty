---
tags:
  - shared
  - modulescript
  - gamemode
  - combat
path: game.ReplicatedStorage.Modules.TeamAffinity
type: ModuleScript
lines: 100
---

# TeamAffinity

The one answer to "are these two on the same side" — shared by the server's friendly-fire gate and
the client's aim assist and FX raycasts.

## What it does
1. `teamOf(characterOrPlayer)` returns `"red"` / `"blue"` / nil. Accepts a Player or a character
   Model. A character without its own stamp answers via its Player, and a Player without one
   answers via their character, which covers the sliver before the `CharacterAdded` restamp lands.
   Bot rigs carry their own stamp, written from the BotService record before the rig is parented.
2. `areAllies(a, b)` — **fails open**. Either side answering nil returns false, i.e. shootable. A
   gate that failed closed would turn a stamping bug into an invulnerable player, which is far
   worse than one stray friendly-fire hit and much harder to diagnose from a bug report.
3. `isTeamMode()` reads `workspace.Gamemode` and looks up the row's `teamCount` — the cheap
   top-of-function gate for client callers that skip ally checks entirely in FFA.
4. Holds the **collision-group names** for the spawn houses' force-field doors — `BODY_GROUP`
   (`TeamRed` / `TeamBlue`, worn by rig parts), `DOOR_GROUP` (`BaseDoorRed` / `BaseDoorBlue`, worn by
   the door slabs) and `SHOT_GROUP` (`ShotRed` / `ShotBlue`, worn by RaycastParams and never by a
   part). They live here rather than in TeamBaseService because the **client** needs them too: an FX
   raycast that does not wear the same group draws a tracer through a door the shot cannot cross.
5. `bodyGroup(characterOrPlayer)` and `shotGroup(shooter)` resolve those names, answering
   `"Characters"` and `"Default"` respectively for an unstamped rig or FFA — both groups the doors
   ignore, so the door layer fails open exactly like `areAllies` does.

Bodies and shots need **separate** groups even though the door rule is identical: fighters
deliberately pass through one another, so a ray wearing a body group would pass through every
fighter as well and nothing could be shot at all.

Membership is represented as **attributes**, not Roblox's `Teams` service, so one implementation
serves players and bots alike (bots are Models, which `Teams` cannot hold).

## Dependencies
- **Requires:** [[GamemodeConfig]]
- **Required by:** Domination, BulletPenetration, HunterHitPipeline, HunterCharacterUtil, HunterStatusEffects,
  AimAssistController, HighNoonDamage, HighNoonCharacterUtil, RevolverLagCompensation,
  RevolverHitForgiveness, CardsServer, BreachChargeService, BotBrain, BotController,
  TeamDeathmatch, RoundStatusClient, GrudgekeeperClient, TeamVisualClient, TeamBaseService,
  HighNoonTargeting, BotCombat, GrudgekeeperModule, StarfallSightModule,
  SkinService

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GamemodeConfig]] | `GamemodeConfig.get()` | Resolve the workspace `Gamemode` attribute to a row to read `teamCount` |
