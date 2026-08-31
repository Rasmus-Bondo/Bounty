---
tags: [server, script, world-model, vfx, animation, vesper, skins]
path: game.ServerScriptService.Hunters.VesperServer.VesperWorldVisualServer
type: Script
lines: 224
---

# VesperWorldVisualServer

Replicated third-person sniper and world animations for Vesper players — the Vesper equivalent of GrudgekeeperWorldVisualServer/RevolverWorldModelServer.

## What it does
0. Resolves its three world clip ids (Idle / Scope / Shooting) from the **Vesper manifest** through a local `worldClipId(name)` helper over [[HunterAnimations]] (2026-08-29) — a plain table read, so the `WaitForChild` hang that once stopped a world visual script at its first lines is structurally impossible now. A missing manifest entry warns with its name and degrades to an empty `AnimationId`, which [[HunterWorldModel]] already skips without erroring. The `WorldAnimations` folder is an unread leftover until Phase 2 deletes it.
1. Builds a shared [[HunterWorldModel]] configured for Vesper: clones the world sniper onto each Vesper player's `RightHand` via `Motor6D`, named `VesperWorldSniper`, gated to `SelectedHunter == "Vesper"`, with the Heartbeat re-attach watchdog enabled.
2. **Gun-skin variants** resolve through a `TemplateResolver` that reads the player's `EquippedWeaponSkin_Vesper` attribute and looks the name up in `ReplicatedStorage.Hunters.Vesper.Weapon.WorldModel.Skins` (currently `Frostpiercer`). Folder-driven — a new world skin is a Model dropped in that folder, no code entry. Default names (`DefaultSniper`/`Default`) miss the folder and fall through to the default `WorldModel.Sniper` template. HunterWorldModel re-runs SetupCharacter itself when that attribute changes.
3. Plays the world **idle hold** (manifest `World.Idle`) on the character's Humanoid Animator at Action priority, looped.
4. **Scope pose**: `ScopeStateChanged` plays the manifest `World.Scope` clip at Action3, looped, then freezes it at its authored last keyframe (2/30s — `AnimationTrack.Length` is 0 on the server for this clip, so the constant is hand-measured). A per-player token invalidates the freeze on release/respawn, and an action lock holds the pose against the idle.
5. **World shoot one-shot**: `FireBullet`, `PinningThrowRequest`, and `UltimateShotRequest` all play the manifest `World.Shooting` clip at Action4, de-duped to one play per 0.055s.
6. `AttachmentOffset` (`RIGHT_HAND_TO_BASE`) seats the sniper's `Base` at the right hand; captured from the `VesperRiggingDummy` rig. Skin models share the default sniper's part layout and extents, so one offset serves every template.
7. Releases scope state on death, respawn, `SelectedHunter` change (mid-match hunter switch), and PlayerRemoving.

The owner's own copy is hidden in first person by HideLocalWorldSniper (keys on the `VesperWorldSniper` cosmetic name, so skin templates are covered automatically).

## Dependencies
- **Requires:** [[HunterWorldModel]], [[HunterAnimations]] (world clip ids from the Vesper manifest — from `ReplicatedStorage.Hunters.Shared`), [[HunterSelectionService]] (Vesper-only gating)
- **Required by:** Nobody (self-running Script)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ScopeStateChanged` | ← Client | [[VesperScopeController]] ADS enter/exit; drives the world scope pose |
| `FireBullet` | ← Client | [[SunspikeClient]] shot request; second listener that only plays the world shoot one-shot |
| `PinningThrowRequest` | ← Client | [[SunspikeClient]] pinning throw; same shoot beat |
| `UltimateShotRequest` | ← Client | [[SunspikeClient]] ultimate shot; same shoot beat |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterWorldModel]] | `.new()`, `:Start()`, `:PlayOneShot()`, `:StopOneShot()`, `:SetActionLock()` | Shared world-model lifecycle: clone + attach the sniper (skin-resolved per player), loop the hold idle, play the scope/shoot tracks |
| [[HunterSelectionService]] | `.IsHunter()` | Gate the world model and every animation to Vesper players only |
| [[HunterAnimations]] | `HunterAnimations.id()` | Resolve the Idle/Scope/Shooting world clip ids from the Vesper manifest |
