---
tags:
  - server
  - script
  - vfx
  - fortuna
  - cards
path: game.ServerScriptService.Hunters.FortunaServer.CardsWorldVisualServer
type: Script
lines: 298
---

# CardsWorldVisualServer

Fortuna-specific bootstrap for the third-person cards world model. Constructs a [[HunterWorldModel]] instance with Fortuna's config and layers on the Fortuna-only behaviors: cancellable shooting bursts, ultimate action lock, and invisibility mirroring driven by the `CardsOldTransparency` attribute.

## What it does
0. Resolves its three world clip ids (Idle / Shooting / Ultimate) from the **Fortuna manifest** through a local `worldClipId(name)` helper over [[HunterAnimations]] (2026-08-29) — a plain table read, so the `WaitForChild` hang that once stopped a world visual script at its first lines is structurally impossible now. A missing manifest entry warns with its name and degrades to an empty `AnimationId`, which [[HunterWorldModel]] already skips without erroring. The `WorldAnimations` folder is an unread leftover until Phase 2 deletes it.
1. Constructs a [[HunterWorldModel]] with: `HunterName="Fortuna"`, the `WorldCards` template, `CosmeticName="CardsWorldCards"` (preserved for CardsWorldVisualClient compatibility), `AttachmentMethod="Weld"` (internal welds + hand WeldConstraint, not Motor6D — cards don't need joint articulation), the right-hand offset, the manifest `World.Idle` clip id, `IdleRetryCount=80`, `HeartbeatRecheckInterval=0.35`, `HeartbeatReattach=true` — the watchdog re-attaches the welded cards if anything strips them and re-checks idle every 0.35s
2. **Weapon-skin world models** (added 2026-08-07): a `TemplateResolver` reads the player's `EquippedWeaponSkin_Fortuna` attribute against a `worldCardSkins` table (`PrestigeCard` → `WorldPrestigeCards`, `FrozenHand` → `FrozenHand`) and falls back to `WorldCards` for an unlisted skin or missing art, copying the convention Dust's `RevolverWorldModelServer` uses for its revolver skins (plain text: that is a convention this script imitates, not a module it names). Until this landed, every Fortuna held the default cards in third person no matter what was equipped, while her viewmodel, thrown cards and lobby display all honoured the skin. No refresh plumbing lives here — [[HunterWorldModel]] already re-attaches on `EquippedWeaponSkin_<Hunter>` changing.
   - **A skin also needs its own hand offset, and it is not just an axis correction.** [[HunterWorldModel]] places the prop with `Model:PivotTo`, and a model's pivot is `PrimaryPart.CFrame * PrimaryPart.PivotOffset` — not the part's CFrame. The two card models carry different baked `PivotOffset`s on their root meshes (`Card1Border` rot(0,90,90) vs `Card1` rot(0,-90,90.2)) *on top of* being authored on different axes, so a rotation derived in root-part space lands in the wrong frame. `WORLD_CARD_SKIN_OFFSETS` therefore holds absolute per-skin hand offsets, solved for rather than eyeballed (pivot both models with `RIGHT_HAND_OFFSET`, then `Op = handToDefaultCard1 * handToSkinCard1:Inverse() * RIGHT_HAND_OFFSET`); the shipped PrestigeCard value lands its three cards within 0.06 studs of the default fan. `FrozenHand` shares that one value rather than carrying a copy: it has no separately authored world fan, so its Model under `Skins` was built from the three cards in its viewmodel and posed so its `Card1` sits on `WorldPrestigeCards`' `Card1` — the same seating by construction. Re-exporting that viewmodel means rebuilding the fan the same way. The `AttachmentOffsetResolver` is gated on the skin's template actually existing, so missing art falls back to the default model *and* the default offset together.
3. Calls `worldModel:Start(Players)`
4. Listens to `ThrowRequest` (BasicCastCard / Ability1): runs a cancellable burst loop (`playShootingBurst`) keyed by a per-player `burstTokens` counter. Each tick calls `worldModel:PlayOneShot` with the Shooting animation and a `RestartFade`. Ability1 burst count/delay read from `CardsConfig.Ability1.BurstCount`/`BurstDelay`
5. Listens to `UltimateRequest`: cancels any in-flight burst, calls `worldModel:SetActionLock(player, true)` (blocks idle), plays the Ultimate animation via `:PlayOneShot`, then 0.47s later (`ULTIMATE_WORLD_CAST_TIME`) calls `:SetActionLock(player, false)` so idle resumes
6. Watches each character's BaseParts for the `CardsOldTransparency` attribute (set by [[CardsServer]] during the ultimate's invisibility window): when any part has it, calls `worldModel:SetHidden(player, true)` to hide the world cards model (and cancel any burst); when removed from all parts, calls `SetHidden(player, false)` which restores the template's natural transparency via the saved `VisualSnapshot`
7. The invisibility watcher per-player: iterates current character descendants, hooks `GetAttributeChangedSignal("CardsOldTransparency")` on every BasePart, and hooks `DescendantAdded` to wire any new parts. Re-bound on each respawn after a 0.3s settle delay
8. On `PlayerRemoving`: clears the burst token and disconnects the invisibility watcher

## Dependencies
- **Requires:** [[CardsConfig]] (from `ReplicatedStorage.Hunters.Fortuna.Modules`), [[HunterWorldModel]], [[HunterAnimations]] (world clip ids from the Fortuna manifest — from `ReplicatedStorage.Hunters.Shared`), [[HunterSelectionService]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ThrowRequest` | ← Client | Listened to only to trigger the shooting animation; [[CardsServer]] handles the actual damage/raycast |
| `UltimateRequest` | ← Client | Listened to only to trigger the ultimate animation lock; [[CardsServer]] handles the actual ultimate logic |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[CardsConfig]] | `Ability1.BurstCount`, `Ability1.BurstDelay` | Ability1 burst pattern timing |
| [[HunterWorldModel]] | `.new()`, `:Start()`, `:PlayOneShot()`, `:SetActionLock()`, `:SetHidden()`, `:IsHidden()`, `:IsActionLocked()` | Shared world-model lifecycle, idle loop, watchdog, one-shot tracks, action lock, invisibility (replaces ~900L of inline rigging) |
| [[HunterSelectionService]] | `.IsHunter()` | Gate all behavior to Fortuna players only |
| [[HunterAnimations]] | `HunterAnimations.id()` | Resolve the Idle/Shooting/Ultimate world clip ids from the Fortuna manifest |
