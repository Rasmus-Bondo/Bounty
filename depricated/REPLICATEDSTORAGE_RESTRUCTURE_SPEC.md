# ReplicatedStorage Restructure Spec

**Source of truth:** `ReplicatedStorage.000Organize` in Redwater Canyon — a faithful, byte-identical
copy of the live scripts, re-parented into the target shape. This document is the executable reading
of that blueprint, including the four decisions it did not settle.

**Applies to:** the hunter restructure below is Redwater Canyon **and** Frostbite Claim -- both carry
the same gamemode codebase and the same old-style ReplicatedStorage, so both get the identical tree
and the identical script rewrites. The root tidy in Part 2 of the Outcome covers **all three places**,
Bounty included, because the modules and remotes it moves are shared.

## Decisions taken (not derivable from the blueprint)

| # | Question | Decision |
|---|---|---|
| 1 | Scope | Both match places. Frostbite gets the same tree + same code edits. |
| 2 | Dust's 7 sounds appear at both `SFX/DustSounds` and `Hunters/Dust/SFX` | **Move.** They live only at `Hunters/Dust/SFX`; `SFX/DustSounds` is deleted and code repointed. |
| 3 | Live instances with no slot in the blueprint | **Placed, never deleted.** See "Orphan placements". |
| 4 | Blueprint typos `VIewmodel` (x4) and `DefeaultGrudgekeeper` | **Corrected** to `Viewmodel` and `DefaultGrudgekeeper`. Every other name is verbatim. |

## Target shape

```
ReplicatedStorage/
  Hunters/
    Shared/                      (unchanged, 34 modules)
    <Dust|Bram|Vesper|Fortuna>/
      Character/     Default/  Skins/
      ClientEvents/
      Config/
      Modules/
      Objects/
      Remotes/
      SFX/
      ViewportFrame              (a ViewportFrame instance, not a folder)
      Weapon/        Viewmodel/{Default,Skins}   WorldModel/{Default,Skins}
      WorldAnimations/
    Fortuna also has: Throwables/{Default,Skins}
```

Everything else at the top level of ReplicatedStorage keeps its current name and contents. The five
folders **`Revolver`, `RevolverDefaultViewmodel`, `SniperDefaultViewmodel`, `Characters`,
`Grudgekeeper` are dissolved** and cease to exist.

`Hunters/<Name>/SFX` is populated for Dust and Fortuna only. Bram's and Vesper's sounds stay at
`SFX/Bram` and `SFX/VesperSFX`, because the blueprint leaves those hunter folders empty and keeps the
top-level ones — unlike Dust, whose sounds it duplicated.

## Instance mapping

`→` means **move the live instance** (not clone). Renames are called out.

### Dust
| Live source | New home |
|---|---|
| `Characters/Dust/Default` | `Hunters/Dust/Character/Default` |
| `Characters/Dust/Skin` | `Hunters/Dust/Character/Skins`  *(renamed)* |
| `Characters/Dust/ViewportFrame` | `Hunters/Dust/ViewportFrame` |
| `Revolver/Modules/*` (28) | `Hunters/Dust/Modules/*` |
| `Revolver/laserBeamEffect` | `Hunters/Dust/Modules/laserBeamEffect` |
| `Revolver/Remotes/*` (11) | `Hunters/Dust/Remotes/*` |
| `Revolver/Objects/LaserBeam` | `Hunters/Dust/Objects/LaserBeam` |
| `Revolver/SmokeParticles` | `Hunters/Dust/Objects/SmokeParticles` |
| `SFX/DustSounds/*` (7) | `Hunters/Dust/SFX/*`, then delete `SFX/DustSounds` |
| `RevolverDefaultViewmodel/ArmsViewModelRevolverNew` | `Hunters/Dust/Weapon/Viewmodel/Default/ArmsViewModelRevolverNew` |
| `RevolverDefaultViewmodel/Skins/{BetaRevolver,HellFire}` | `Hunters/Dust/Weapon/Viewmodel/Skins/` |
| `Hunters/Dust/Revolver/DefaultRevolver` | `Hunters/Dust/Weapon/WorldModel/Default/DefaultRevolver` |
| `Hunters/Dust/Revolver/HellFire` | `Hunters/Dust/Weapon/WorldModel/Skins/HellFire` |

**New assets** — exist only inside `000Organize`, clone them out:
`Weapon/Viewmodel/Skins/Icefang`, `Weapon/WorldModel/Skins/Beta`, `Weapon/WorldModel/Skins/Icefang`.

### Bram
| Live source | New home |
|---|---|
| `Characters/Bram/Default` | `Hunters/Bram/Character/Default` |
| `Characters/Bram/Skin` | `Hunters/Bram/Character/Skins` *(renamed)* |
| `Characters/Bram/ViewportFrame` | `Hunters/Bram/ViewportFrame` |
| `Hunters/Bram/BreachCarryGeometry` | `Hunters/Bram/Config/BreachCarryGeometry` |
| `Grudgekeeper/ArmsViewModelBramNew` | `Hunters/Bram/Weapon/Viewmodel/Default/DefaultViewmodel` *(renamed)* |
| `Grudgekeeper/Skin/FrostbiteGrudgekeeper` | `Hunters/Bram/Weapon/Viewmodel/Skins/FrostbiteGrudgekeeper` |
| `Grudgekeeper/WorldShotgun` | `Hunters/Bram/Weapon/WorldModel/Default/DefaultGrudgekeeper` *(renamed; blueprint spelled it "Defeault")* |
| `Grudgekeeper/FrostBiteGrudgekeeperWorld` | `Hunters/Bram/Weapon/WorldModel/Skins/FrostBiteGrudgekeeperWorld` |
| `Grudgekeeper/WorldModel/{Charging,Idle,Shooting,Unequip}` | `Hunters/Bram/WorldAnimations/` |

### Vesper
| Live source | New home |
|---|---|
| `Characters/Vesper/Default` | `Hunters/Vesper/Character/Default` |
| `Characters/Vesper/Skin` | `Hunters/Vesper/Character/Skins` *(renamed)* |
| `Characters/Vesper/ViewportFrame` | `Hunters/Vesper/ViewportFrame` |
| `SniperDefaultViewmodel/ArmsViewModelSniper` | `Hunters/Vesper/Weapon/Viewmodel/Default/ArmsViewModelSniper` |
| `SniperDefaultViewmodel/Skins/Frostpiercer` | `Hunters/Vesper/Weapon/Viewmodel/Skins/Frostpiercer` |
| `Hunters/Vesper/WorldModel/Sniper` | `Hunters/Vesper/Weapon/WorldModel/Default/Sniper` |
| `Hunters/Vesper/WorldModel/Skins/Frostpiercer` | `Hunters/Vesper/Weapon/WorldModel/Skins/Frostpiercer` |
| `Hunters/Vesper/WorldModel/{Idle,Scope,Shooting}` | `Hunters/Vesper/WorldAnimations/` |

### Fortuna
The whole `Hunters/Fortuna/Cards` folder is dissolved up one level.

| Live source | New home |
|---|---|
| `Characters/Fortuna/Default` | `Hunters/Fortuna/Character/Default` |
| `Characters/Fortuna/Skin` | `Hunters/Fortuna/Character/Skins` *(renamed)* |
| `Characters/Fortuna/ViewportFrame` | `Hunters/Fortuna/ViewportFrame` |
| `Cards/Modules/CardsConfig` | `Hunters/Fortuna/Modules/CardsConfig` |
| `Cards/Remotes/*` (6) | `Hunters/Fortuna/Remotes/*` |
| `Cards/ClientEvents/*` (10) | `Hunters/Fortuna/ClientEvents/*` |
| `Cards/SFX/*` (7) | `Hunters/Fortuna/SFX/*` |
| `Cards/WorldAnimations/*` (3) | `Hunters/Fortuna/WorldAnimations/*` |
| `Cards/Objects/{CardGlow,CardThrowVFX,SparkAttachment}` | `Hunters/Fortuna/Objects/` |
| `Cards/CardModel/Default/Card` | `Hunters/Fortuna/Throwables/Default/Card` |
| `Cards/CardModel/Skin/{FrozenHand,PrestigeCard}` | `Hunters/Fortuna/Throwables/Skins/` *(Skin → Skins)* |
| `Fortuna/Viewmodel/CardsDefaultViewmodel/ArmsViewModel` | `Hunters/Fortuna/Weapon/Viewmodel/Default/ArmsViewModel` |
| `Fortuna/Viewmodel/CardsDefaultViewmodel/Skins/{FrozenHand,PrestigeCard}` | `Hunters/Fortuna/Weapon/Viewmodel/Skins/` |

## Orphan placements (decision 3)

Referenced by running code, no slot in the blueprint:

| Live source | New home | Why |
|---|---|---|
| `Revolver/Objects/WorldRevolver` | `Hunters/Dust/Objects/WorldRevolver` | `RevolverWorldModelServer`, `BotController`, `BotVisualClient` and `WorldRevolverShotSoundClient` all resolve it out of the Objects folder. |
| `Cards/Objects/WorldCards` | `Hunters/Fortuna/Weapon/WorldModel/Default/WorldCards` | Fills the empty `WorldModel/Default` the blueprint left. `CardsWorldVisualServer` and the bots use it. |
| `Cards/Objects/WorldPrestigeCards` | `Hunters/Fortuna/Weapon/WorldModel/Skins/WorldPrestigeCards` | It is the PrestigeCard skin's world model. |
| `Cards/Objects/Cards` | `Hunters/Fortuna/Objects/Cards` | Stays with its siblings. |

Unreferenced author backups — preserved next to their new counterparts rather than deleted:

| Live source | New home |
|---|---|
| `Hunters/Dust/Revolver/PivotBackups` | `Hunters/Dust/Weapon/WorldModel/PivotBackups` |
| `Cards/CardModel/Skin/Backup` (empty) | `Hunters/Fortuna/Throwables/Skins/Backup` |
| `Fortuna/Viewmodel/CardsDefaultViewmodel/BackupDefaultCards` | `Hunters/Fortuna/Weapon/Viewmodel/BackupDefaultCards` |
| `Fortuna/Viewmodel/CardsDefaultViewmodel/Skins/BackupPrestigeCard` | `Hunters/Fortuna/Weapon/Viewmodel/Skins/BackupPrestigeCard` |

`RevolverDefaultViewmodel.Backup`, `SniperDefaultViewmodel.Backup` and `Grudgekeeper.ArmsViewModelMCP`
are named in code behind `FindFirstChild` guards but **do not exist** in either place. Nothing to move.

## Deleted after the move

Empty shells only: `Revolver`, `RevolverDefaultViewmodel`, `SniperDefaultViewmodel`, `Characters`,
`Grudgekeeper`, `SFX/DustSounds`, `Hunters/Dust/{Revolver,Viewmodel,GuiTemplates}`,
`Hunters/Fortuna/{Cards,Viewmodel,GuiTemplates}`, `Hunters/Vesper/WorldModel`, and finally
`000Organize` itself.

## Verification

1. Every path in the target shape resolves, and nothing referenced by a script is missing.
2. `loadstring` every rewritten script — syntax gate.
3. Diff Redwater's new tree against Frostbite's new tree: same names, same depths.
4. The 19 mirrored modules are untouched by this change; `/preflight` still has to pass.

---

# Outcome — executed 2026-08-21

All three places are restructured, rewritten and verified. `000Organize` has been consumed and deleted.

## Part 1 — the hunter tree (Redwater + Frostbite)

| | Redwater | Frostbite |
|---|---|---|
| instances moved | 126 | 123 |
| script rewrites | 141 | 143 |
| scripts compiling | 308 / 308 | 288 / 288 |
| stale references | 0 | 0 |

Redwater's tree was diffed against `000Organize` before the blueprint was deleted: **0 paths missing**,
and the only extras were the 9 deliberate orphan placements. 50 of the 51 edited files are
byte-identical between the two match places; the one that differs is `RoundSystem.Config`, a
per-place map config that is *supposed* to differ, and it took the same edit.

Beyond the mapping table above, these code-level changes were required and are easy to miss:

- **`manifest.HunterFolder`** — Dust was `{ "Revolver" }`, Fortuna was `{ "Hunters", "Fortuna", "Cards" }`.
  Now `{ "Hunters", "Dust" }` and `{ "Hunters", "Fortuna" }`. This is why Fortuna's previously-empty
  authored `Remotes` / `ClientEvents` folders are the ones the runtime now uses.
- **Weapon-skin resolution moved one level up.** The template used to sit beside its `Skins` folder;
  it now sits in `Weapon/Viewmodel/Default/`, so `template.Parent.Skins` became
  `template.Parent.Parent.Skins` in `HunterFirstPersonClient`, `RevolverViewModel`, `CardsClient` and
  `WorldAnimationPrewarmClient`. Miss this and every gun skin silently falls back to the default.
- **`{category, subfolder, modelName}` is a wire format**, sent to `BountyListClient` and
  `HunterSwitchClient`. `subfolder` values changed `"Skin"` → `"Skins"`, and every resolution site now
  walks `Hunters.<category>.Character.<subfolder>`. `"Characters"` as a **CollisionGroup** name was
  left alone in all five places it appears.
- `BotConfig.DefaultCharacter` grew a segment (`{ "Hunters", <H>, "Character", "Default", ... }`), so
  `BountyService`'s decoder moved from `path[3]/path[4]` to `path[4]/path[5]`.
- `RevolverViewModel` cloned a muzzle from `RevolverDefaultViewmodel.Backup`, a rig that exists in
  neither place. The dead chain was replaced with a search of the real default viewmodel.

## Part 2 — the ReplicatedStorage root (all three places)

Loose ModuleScripts went to `Config/` (data) and `Modules/` (behaviour); loose RemoteEvents went to
`Events/`, with telemetry in `Events/TelemetryEvents/`.

| | Redwater | Frostbite | Bounty |
|---|---|---|---|
| root children before | 35 | 35 | 45 |
| root children after | **18** | **18** | **14** |

**The authored instances were the easy half.** ~30 of Bounty's remotes and 8 of the match places' do
not exist in edit mode at all — they are created at boot by helper functions that parented straight
to the root. Moving only the authored copies would have left every one of those helpers recreating a
duplicate at the root where no consumer looks. Every creator was repointed:
`Telemetry.getOrCreateRemote` (mirrored, identical in all three), `BoostService`/`BattlePassService`/
`CollectionService`/`DailyRewardService`/`FriendBonusService`'s `ensureRemote`, `PartyService` and
`TutorialReplayService`'s `getOrCreateRemoteEvent`, `HunterSwitchService`, and the nine inline
creators in `DataService` and `LimitedStockService`. `FollowJoinService` and `FriendJoinService`
already scoped themselves to `Events` and were left alone.

Verified per place: every script compiles, no reference to a moved name resolves at the root any
more, and no script parents an instance to the root except the `Events` folder creation itself.

**All 19 mirrored modules are byte-identical across all three places and at the same paths** —
`ReplicatedStorage.Config.*` for the eleven configs, `ReplicatedStorage.Modules.*` for `TitleRenderer`
and `AnimationLoader`. Two of them drifted mid-job and were reconciled: `MapCatalog` (its comment
names `ReplicatedStorage.MapConfig`, which moved in the match places only) and `BattlePassConfig`
(its comment names the hunter-skin folder, which is now a *different* path in the lobby than in a
match place — the comment names both).

Both vaults were moved to match and both graphs rebuilt (Redwater 230 nodes / 697 edges, Bounty 108 / 303).

## Part 3 -- follow-up pass, same day

### The restructure had broken 11 references

A static resolver was run over every script in both match places: it binds each `local` whose
right-hand side resolves to a real ReplicatedStorage instance, then checks every `.X` /
`WaitForChild("X")` / `FindFirstChild("X")` taken off that binding. It found 11 real breaks, all the
same shape -- **a child that moved one level deeper, read off a variable still pointing at the old
parent.** Part 1's sweep only looked for the five dissolved top-level folder names, so none of these
matched it.

| Script | Was | Symptom |
|---|---|---|
| `Bots.BotCombat` | `Hunters.Bram.BreachCarryGeometry` | hard error on require |
| `BramServer.BreachChargeService` | `:WaitForChild("Bram"):WaitForChild("BreachCarryGeometry")` | infinite yield |
| `Bram.GrudgekeeperClient` | same | infinite yield |
| `BramWorldFXClient` | `bramFolder:WaitForChild("BreachCarryGeometry")` | infinite yield |
| `DustServer.RevolverModule` | `revolverFolder:WaitForChild("SmokeParticles")` | infinite yield |
| `Dust.FPSRevolverClient` | `revolverAssets:WaitForChild("laserBeamEffect")` | infinite yield |
| `Dust.FPSRevolverClient` | `revolverAssets:FindFirstChild("SmokeParticles")` | **silent** -- nil, no smoke |
| `Dust.HighNoonClient` | `revolverFolder:WaitForChild("laserBeamEffect")` | infinite yield |
| `VesperPublicFXClient` | `revolverFolder:WaitForChild("laserBeamEffect")` | infinite yield |
| `LandingImpactClient` | `ReplicatedStorage:WaitForChild("Revolver", 20)` | **silent** -- times out, early return |
| `TutorialClient` | `ReplicatedStorage:WaitForChild("Revolver", 10)` | **silent** -- ult cue never lights |

The two `"Revolver"` lookups are why Part 1's "0 stale references" gate passed: both carry a timeout
and a nil guard, so they never error and never reach a log. **A timed `WaitForChild` behind a nil
guard is invisible to a token sweep and to a playtest alike** -- grep the old name in its timeout
form too, not just the bare path. Fixing the first of them also exposed a dead duplicate in
`TutorialDirector`, which looked Dust's remotes up twice through two variables that now resolve
identically; the dead half was removed.

### Frostbite now has the six missing assets

`FrostBiteGrudgekeeperWorld`, `Fortuna/Objects/Cards`, `Fortuna/Throwables/Skins/FrozenHand`, and the
three new Dust skins (`Viewmodel/Skins/Icefang`, `WorldModel/Skins/Icefang`, `WorldModel/Skins/Beta`).
Copied via `.rbxm`, verified identical by descendant count and a name+class signature.
**Deliberately not wired up.**

### Bram's and Vesper's five empty folders each

Their assets had never moved into their hunter folders -- they were still at the ReplicatedStorage
root, which is exactly why the folders read as empty:

| Was | Now |
|---|---|
| `SFX.Bram` (4 sounds) | `Hunters.Bram.SFX` |
| `SFX.VesperSFX` (10 sounds) | `Hunters.Vesper.SFX` |
| `VFX.{BulletTrailVesper, VesperTrailDefault, VesperUltCurve, VesperUltTrail, VesperUltTrail2}` | `Hunters.Vesper.Objects` |

`Remotes` and `ClientEvents` were empty for a different reason: unlike Dust's and Fortuna's, Bram's
and Vesper's were never authored -- `HunterServerRuntime` creates them at boot from the manifest.
They are authored now (Bram 10 + 11, Vesper 15 + 19), matching what Fortuna already does.
`EnsureRemoteEvent` returns an existing instance, so nothing changes at runtime except that the
client no longer waits on each remote at first boot and the duplicate-BindableEvent race on
`ClientEvents` is gone.

`Bram/Modules`, `Bram/Objects` and `Vesper/Modules` were deleted: nothing exists to put in them (hero
code lives in `ServerScriptService.Hunters.<H>Server` and `StarterPlayerScripts.<H>`) and no code
resolves them. `BulletTrailVesper` moved with the rest but is referenced by nothing -- a leftover
trail variant.

### Dust's assets were the same case, and are now consolidated too

| Was | Now |
|---|---|
| `SFX.DustUltimate` (folder, 4 sounds) | `Hunters.Dust.SFX.DustUltimate` |
| `VFX.BulletTrailDust`, `VFX.DustParticle` | `Hunters.Dust.Objects` |

`DustUltimate` stayed a folder rather than being flattened into `Dust.SFX`: its members are `Start`,
`Mid`, `Eagle` and `Whistle`, and `Start`/`Mid` are far too generic to sit beside `FireSound` and
`ReloadSound`.

That emptied the root `VFX` folder, which was deleted. **`ReplicatedStorage.VFX` no longer exists in
either match place** -- every hunter's effect templates now live under `Hunters.<H>.Objects`.

`Dust.ClientEvents` was the last empty runtime-target folder; its 8 BindableEvents are now authored.
The eighth is `HighNoonAimNudge`, which the Phase-3 refactor dropped from the manifest: `HighNoonGunFX`
fires it and `HighNoonViewModelOrbit` reads it, and **each of those two scripts created it if missing**,
so whichever ran first won. It is declared in `Client.ClientEvents` again, which is what makes the
authored instance legitimate rather than something a future reader deletes as junk. (The old
`RevolverClientEvents` module still lists all 8 -- it is where the declaration survived -- but nothing
requires it any more; it is dead and left in place.)

`Dust.WorldAnimations` was deleted: empty, unreferenced, and Dust is the one hunter whose world clips
are string literals in `WorldAnimationPrewarmClient` rather than `Animation` instances.

**`CrimsonRevenant.Folder` was deliberately left.** It reads as an empty stray, but every Dust
character model has a `Folder` holding cosmetic MeshParts (hat, hair, bandana); that skin simply has
none. Deleting it would have made one model inconsistent with its four siblings.

### Verified

| | Redwater | Frostbite |
|---|---|---|
| scripts compiling | 308 / 308 | 288 / 288 |
| stale tokens | 0 | 0 |
| ungrouped Sounds under `Hunters` | 0 | 0 |
| `Hunters` tree | 372 paths | **identical signature** |
| every edited script | -- | **byte-identical to Redwater** |

Unresolved paths fell 56 -> 33, and the 33 are all expected: guarded optional lookups
(`GuiTemplates`, `RoundStart`, `CardRecall`, `VictoryScreenAvatar`), the `Aria` example in
`HunterImplementationGuide`, multi-line chains the resolver cannot follow, and remotes still created
at boot (`Events.MapVote`, `Events.RequestHunterSwitch`, Dust's `HighNoon*` and its `ClientEvents`).

The Redwater vault carried ~20 stale prose paths from Part 1 and one misplaced file
(`Hunters/Fortuna/Cards/Modules/CardsConfig.md`, now `Hunters/Fortuna/Modules/`). All corrected; every
`.md` frontmatter `path:` now resolves to a real script. Graph rebuilt: 230 nodes / 697 edges,
unchanged, as expected for prose-only edits.

## Still open

- **Playtested on 2026-08-21.** The owner has since exercised most of this in play. Two runtime
  faults surfaced that the static gates could not see, both now fixed: `HighNoonClient` read an
  undeclared `objectsFolder` (crash on ult activation), and seven scripts' **Script Editor
  documents** still held pre-restructure text, which is what Play executes -- so several corrections
  in this document were absent from the running game while `.Source` showed them applied. See the
  `## Fixed` entries in `changelog/UNRELEASED.md`.
- **The new Dust skins are inert** -- in both match places now, but still unreferenced:
  `RevolverWorldModelServer` resolves world skins from a hardcoded table listing only `HellFire`.
  Wiring them up is a separate change (that table, plus a shop / battle-pass entry).
- ~~The changelog entry is not written.~~ **Done 2026-08-21** -- curated into
  `changelog/UNRELEASED.md` (one `Added`, one `Changed`, four `Fixed`). Note the capture held only
  the five `import_rbxm` calls: `execute_luau` mutations are invisible to the `PostToolUse` hook, so
  this work had to be written from the session record rather than from the capture.
- **Two empty folders remain under `Hunters`**, both Fortuna-side and both intentional:
  `Fortuna.Throwables.Skins.Backup`, and `Dust.Character.Skins.CrimsonRevenant.Folder` (see above --
  every Dust model has one).
- **`RevolverClientEvents` is dead code.** Nothing requires it; the runtime replaced it. Deleting it
  is a vault + graph change, so it was left for a deliberate pass.
- Values (`RoundActive`/`RoundStatus`/`RoundTime`) and the GUI templates (`HealthBarGui`,
  `DustUltimateTarget`, `TutorialGlow`) are still at the root -- out of scope for "modules and
  remotes", and easy to fold into a later pass.
