---
tags: [shared, modulescript, world-model, vfx, animation]
path: game.ReplicatedStorage.Hunters.Shared.HunterWorldModel
type: ModuleScript
lines: 953
---

# HunterWorldModel

OOP service that owns the lifecycle of a hunter's server-replicated third-person "world model" cosmetic prop (revolver for Dust, cards for Fortuna): template clone, hand resolution, attachment (Motor6D or WeldConstraint), idle animation loop with retries, one-shot action tracks, optional Heartbeat watchdog, and invisibility toggling. Replaces the duplicated rigging that used to live in `RevolverWorldModelService` and inside the original `CardsWorldVisualServer`.

## What it does
1. `.new(config)` — accepts `HunterName` + `HunterSelectionService` (for gating), `Template` + `CosmeticName` (the name the cloned prop will be parented as on the character), `HandTargets` (ordered list — first existing wins), `AttachmentMethod` ("Motor6D" | "Weld"), `AttachmentOffset` (CFrame), `IdleAnimationId`/`IdleAnimationPriority`/`IdleAnimationFadeTime`/`IdleAnimationSpeed`, `IdleRetryCount`/`IdleRetryDelay`, `HandWaitRetries`/`HandWaitInterval`, optional `HeartbeatRecheckInterval`/`HeartbeatReattach`, and Dust-specific VFX config: `SmokeParticleTemplate`/`MuzzleFlashEmitCount`/`MuzzleSmokeEmitCount`
2. `:Start(Players)` wires `PlayerAdded`/`PlayerRemoving`/per-player `CharacterAdded`/`CharacterRemoving`/`GetAttributeChangedSignal("SelectedHunter")`, and (if `HeartbeatRecheckInterval` or `HeartbeatReattach`) one Heartbeat connection that runs the watchdog
3. `:SetupCharacter(player, character)` waits for the humanoid + hand part, resolves the template (`TemplateResolver(player, template)` if the caller supplied one — Dust swaps in the equipped `EquippedWeaponSkin_Dust` world revolver, Fortuna the `EquippedWeaponSkin_Fortuna` card model; anyone without a resolver falls through to `Template`), clones it, strips its scripts, sets each part non-collidable/massless, picks a root part (PrimaryPart → known names → first BasePart), pivots to `hand.CFrame * AttachmentOffset` (or `AttachmentOffsetResolver(player, AttachmentOffset, ...)` when supplied — both skinned hunters need one, see below), attaches via `Motor6D` (Dust path) or internal+hand `WeldConstraint`s (Fortuna path), and snapshots every BasePart/Decal/Texture/ParticleEmitter/Beam/Trail's natural Transparency or Enabled into `state.VisualSnapshot` so `SetHidden` can restore the template's original visibility instead of forcing all parts to Transparency=0
   - **The offset is not applied to the root part's CFrame.** Placement goes through `Model:PivotTo`, and a model's pivot is `PrimaryPart.CFrame * PrimaryPart.PivotOffset`. Imported meshes routinely carry a baked non-identity `PivotOffset`, and two models of the same prop rarely carry the same one — Fortuna's `WorldCards` roots on `Card1Border` at rot(0,90,90) while `WorldPrestigeCards` roots on `Card1` at rot(0,-90,90.2). An offset tuned against one model therefore lands a second model somewhere unrelated, and a correction derived by comparing the two models' *root parts* is computed in the wrong frame. This is why `AttachmentOffsetResolver` exists and why every skin needs its own absolute offset rather than a rotation applied to the default one. Solve for it instead of eyeballing: pivot both models onto a rig hand with the default offset, then take `handToDefaultAnchor * handToSkinAnchor:Inverse() * defaultOffset`.
4. `:CleanupCharacter(character)` / `:CleanupPlayer(player)` — stop all tracks, disconnect per-state signals, destroy the cosmetic, drop player state
5. `:EnsureIdle(player)` — spawns a retry loop (`IdleRetryCount` × `IdleRetryDelay`) that re-attaches the model if it's missing then calls `_playIdle`. Idle is gated by `_canPlayIdle` (character alive, not hidden, no action lock, world model attached)
6. `:StopIdle(player)` — bumps `SetupToken` (cancelling any in-flight `EnsureIdle` task) and destroys the idle track
7. `:SetActionLock(player, locked)` — refcount-based lock that blocks idle while > 0. Fortuna's ultimate calls `SetActionLock(player, true)` for the cast window and `false` after, ensuring the ultimate animation isn't stomped by idle
8. `:PlayOneShot(player, animationId, opts)` — loads + plays a one-shot animation track keyed by `opts.TrackName`. Stops any track with the same name first (using `opts.RestartFade`). `opts` keys: `Priority`, `FadeTime`, `Speed`, `Looped`, `RestartFade`, `TrackName`, `AllowWhileHidden`. Auto-cleans the track on `Stopped`
9. `:StopOneShot(player, trackName, fadeTime)` — stops a named one-shot
10. `:SetHidden(player, hidden)` — when set to true, stops all tracks and applies `Transparency=1` / `Enabled=false` to every part/decal/particle/beam/trail on the cosmetic; when set to false, restores from `state.VisualSnapshot` so the template's natural invisibility (e.g. muzzle anchor parts at T=1) is preserved
11. `:IsHidden(player)` / `:IsActionLocked(player)` / `:GetWorldModel(player)` — public state queries
12. `:EmitMuzzleFlash(player)` / `:EmitMuzzleSmoke(player)` — Dust-only: emits the prop's particle emitters named `MuzzleFlash`/`FlashEmitter`/`Flash`, then for smoke clones the `SmokeParticleTemplate` onto the muzzle attachment (resolved via `MuzzleAttachment` name or `MuzzlePart`'s first attachment) and emits
13. `_attach(player, character)` is the single attach path, called from `SetupCharacter`, `EnsureIdle`'s retry loop, and the Heartbeat re-attach. **It needs both arguments** — the player is what `TemplateResolver` reads the equipped skin off. All three call sites used to pass only the character, so `character` was `nil`, `_attach` bailed on its nil-character liveness check *before* reaching any warning, and no hunter ever got a server-attached world cosmetic (fixed 2026-07-26). Nothing logged, and the per-hunter client idle scripts key off the cosmetic's existence, so the visible symptom was hunters holding nothing while bots — which build their props in `BotVisualClient` instead — held theirs correctly.
14. `:_heartbeatTick()` — runs once per Heartbeat when watchdog enabled. If `HeartbeatReattach` and the cosmetic is missing/destroyed, re-attaches + re-snapshots. If `HeartbeatRecheckInterval` and the interval has elapsed, replays idle if it should be playing but isn't. Fortuna uses both; Dust uses neither

## Dependencies
- **Requires:** [[AnimationLoader]]
- **Required by:** RevolverWorldModelServer (Dust), CardsWorldVisualServer (Fortuna), GrudgekeeperWorldVisualServer (Bram), and `VesperWorldVisualServer` (Vesper, not yet vault-documented)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[AnimationLoader]] | `AnimationLoader.load()` | `_loadTrack` blocks on the fetch and returns a real `AssetFetchStatus`, so `_playIdle` fails honestly and `EnsureIdle`'s retry loop can no longer exit on pass 1 on a false success. Callers of `_loadTrack` **yield** — covers the Fortuna, Vesper and Bram world guns |
| [[AnimationLoader]] | `AnimationLoader.loadCached()` | `PlayOneShot` only. It fires on every revolver shot and `_loadTrack` now yields on a cold clip, so latency wins over certainty here: a dropped one-shot is cosmetic |
