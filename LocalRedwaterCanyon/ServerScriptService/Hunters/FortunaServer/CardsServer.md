---
tags:
  - server
  - script
  - combat
  - fortuna
  - cards
path: game.ServerScriptService.Hunters.FortunaServer.CardsServer
type: Script
lines: 1857
---

# CardsServer

Server-authoritative combat system for Fortuna's card-throwing kit: basic throws, Ability1 burst, Recall, and a windup/invisibility Ultimate, with its own lag compensation. After the Phase 2 port the init prelude (folder + remote setup, hunter gate, ChargeService construction, HitPipeline construction) is replaced by a single `HunterServerRuntime.Start(fortunaManifest, { ChargeBlockPredicate = ... })` call — ~170 lines collapsed into ~78.

## What it does
1. Requires the [[Manifest|Fortuna Manifest]] and calls [[HunterServerRuntime]].Start(manifest, { ChargeBlockPredicate = ..., PassiveWalkSpeed = 24 }); the predicate closes over `ultimateActiveByPlayer` and `ultimateWindingUpByPlayer` (which the script defines BEFORE calling Start so the predicate captures live references). `PassiveWalkSpeed = 24` (mirrors `CardsConfig.Passive.WalkSpeed`, which loads after this call) tells the runtime to register Fortuna's 24 as her `Passive` base on [[HunterMovement]], so nothing ever treats her resting speed as 16. Her CharacterAdded handler no longer writes WalkSpeed at all — doing so would clobber a slow or an ult already live on the server. Aliases `runtime.Folders.Hunter`, `runtime.IsHunter`, `runtime.ChargeService`, `runtime.HitPipeline`, `runtime.RoundStats`, all 10 declared `runtime.Remotes.*`, and the 5 `runtime.SharedRemotes.*`
2. Gates all behavior on `runtime.IsHunter(player)`; non-Fortuna players are ignored by every remote handler
3. **Basic throw** (`ThrowRequest` = "BasicCastCard"): raycasts a card from the camera/head origin in the aim direction, capped at 3 shots per 1.25s window
4. **Ability1** (`ThrowRequest` = "Ability1"): on cooldown, fires a burst of multi-card volleys with angular spread, tracking continuously-updated aim via `Ability1AimUpdate` so each burst wave can re-aim. Wave count is `CardsConfig.Ability1.BurstCount` (currently 2) with `SpreadDegrees = 20`. The client fires `DashRequest` first, then this handler ~0.15s later.
5. **Dash** (`DashRequest`): fired at the start of Ability1. Handler validates hero + Vector3, then calls `dashService:DoDash(player, moveDirection)`. `dashService` is a Fortuna-specific instance of [[RevolverDashService]] constructed from `CardsConfig.Ability1.Dash` (Cooldown 5s, AirDashMultiplier 1.0 — same speed in air and ground). Cleanup via `dashService:CleanupPlayer(player)` on PlayerRemoving.
5. **Recall** (`RecallRequest`): pulls all of the player's stuck/landed cards back along a line toward the player, dealing diminishing damage per card hit (`Recall.DamageMultipliers`) to anything the line overlaps
6. **Ultimate** (`UltimateRequest`): requires full charge; after a global 0.47s windup, turns the caster invisible (transparency saved/restored via `CardsOldTransparency` attribute; `setCharacterInvisible` also publishes an `UltimateInvisible` character attribute in lockstep with the transparency change, which is what HealthBarController suppresses the overhead bar on), sets two more attributes on the character — `UltimateActive` so MovementChecker skips its horizontal-speed and airborne-duration checks during the buffed-speed window (an Ultimate-priority `FortunaUltimate` base of 31 on [[HunterMovement]], so a slow landing mid-ult composes with it instead of being measured against a snapshot of it), and `UltimateUntargetable` which makes her unlockable by Dust's High Noon (read by HighNoonTargeting for a Dust player, by BotCombat's `_ultimateCandidates` for a Dust bot). The two are separate because `UltimateActive` is also set by Bram's Last Call for its speed headroom, and overloading it handed Bram a High Noon immunity. Untargetable does **not** mean unhittable: her invisibility is transparency only, so ordinary raycasts still hit her. **`UltimateInvisible` is the attribute bot perception reads** (via `HunterCharacterUtil.IsStealthed`, alongside the bot-Fortuna equivalent `BotFortunaInvisible`) — as of 2026-08-06 BotBrain drops a stealthed character from target acquisition, suppresses the `OnDamaged` target lock her opening card ring used to hand out, and falls back to firing at the last position it saw her; BotCombat's `ThinkAbility` refuses to aim any ability at her. Before that, `UltimateUntargetable` had only the two High Noon readers above and the rest of the bot pipeline tracked her live root through the entire ult. It then fires a ring of cards outward, then after `InvisibleTime` becomes visible again, clears both attributes, drops the `FortunaUltimate` base (re-resolving to her passive, or to a slow that landed during the ult — the old hardcoded write to `Passive.WalkSpeed` stomped an active slow), and recalls the cards back for return damage. The windup and the end are both guarded by a per-player ultimate token (`ultimateTokenByPlayer`); `cancelUltimate` — invoked when the player's `SelectedHunter` attribute changes away from Fortuna (a mid-match hunter switch via HunterSwitchService, whose respawn skips Humanoid.Died) — bumps that token so the pending windup/end task.delays no-op, and restores the current (pre-respawn) character's visibility + drops its movement base. This stops the ult firing on the swapped-in hunter (switch during windup) and the invisibility/+move-speed bleeding onto them (switch while active)
7. Ultimate-charge gating: the manifest's `ChargeUpdateRemote = "UltimateChargeUpdate"` flows updates to the client; the runtime composes the hunter gate and the script's `activeByPlayer/windingUpByPlayer` predicate so charge pauses during a Fortuna ult and never fires to non-Fortuna players (no queued events on Dust). The runtime also auto-calls `chargeService:Start()` and auto-hooks `Players.PlayerAdded/Removing` for SetupPlayer/CleanupPlayer — script no longer does any of those manually
8. Own ray-sphere-math lag compensation (not raycast-based — does NOT spawn rewind hitbox parts the way `RevolverLagCompensation` does; plain text, this is a contrast, not a reference): `recordLagHistory` snapshots each tracked body part's position per player every tick (`RunService.Heartbeat`, gated by `CardsConfig.LagCompensation.HistoryRecordRate` ≈ 1/30s) via [[HunterPositionHistory]], and `findLagCompensatedHit` rewinds by `GetNetworkPing + ExtraRewindOffset` (clamped to `MaxRewindTime`), then uses `raySphereIntersectionDistance` against each snapshot position with per-part radii from `CardsConfig.LagCompensation.PartRadii` to resolve hits — independent of Dust's `RevolverLagCompensation`. Two things about this pass are easy to misread:
   - **It is also Fortuna's hit forgiveness**, not just her rewind. She has no `RevolverHitForgiveness` equivalent (Dust's flat 3.5-stud bubble), so `PartRadii` is the *only* near-miss generosity her cards get. That is why those radii are tuned well above true part size — see [[CardsConfig]] for the values and the reasoning.
   - **It covers bots as well as players.** It iterates `HunterCharacterUtil.GetHumanoidModels()`; it used to loop `Players:GetPlayers()`, which silently excluded every bot from the whole table. Players are sampled from the rewound snapshot, bots from their **live** part positions — a bot is server-authoritative and has no ping to compensate for, so rewinding it would drag the sphere off the rig for nothing. Bots consequently carry no `PartSnapshotPosition`, which is what keeps the landing correction in item 14(b) on their live CFrame.
   - `hasClearLineTo` gates the winning candidate with a real blocking raycast before it is accepted. Without it the sphere pass hits targets **around** corners: `distance <= wallDistance + 0.25` only rejects a shot through geometry the ray actually struck, and a ray that sails past the corner has `wallDistance == range` and nothing to compare against. Cards do not penetrate, so this is a plain blocking ray rather than the `BulletPenetration.Pierce` call Dust's forgiveness uses. It runs at most once per candidate character, after the cheap sphere test has already picked a winner
9. **Damage timing**: `raycastCard` resolves the hit with a raycast at the moment of the throw — the card's flight is cosmetic — so `damageHumanoid` is called **synchronously**, not inside the `task.delay(travelDuration, ...)` that lands the card. It used to sit inside that delay, behind an attacker-alive guard, which meant a confirmed hit paid nothing whenever Fortuna was killed during the card's flight: her damage was silently voided on trades, for up to 0.45s of exposure at max range. Only the card *landing* is still delayed, so the visual and the resting card continue to agree. `damageHumanoid` does not yield, so calling it inline in the remote handler is safe
10. On confirmed hits/kills: applies damage via `Humanoid:TakeDamage`, then calls `hitPipeline:Register({...})` which runs the full feedback chain (RegisterDamage → LastDamager → red hit flash → DamageDirection → HealthBarReveal → RegisterKill → HitConfirm → ChargeAward → KillFeed → KillCam); RoundStats are handled by the pipeline
10. Manages physical card instances: spawns/welds them on landing, recalls/destroys them, caps active cards per player (`Recall.MaxActiveCards`), and cleans them up on player removal, target death, or target ancestry change. `attachGlowToCard(card, skinName)` clones the `Cards.Objects.CardGlow` BillboardGui onto the landed card's root part so the card reads as glowing, and `removeExistingCardGlow` strips it (plus the legacy `SparkAttachment`) on recall. The glow is deliberately a BillboardGui, not a ParticleEmitter: a landed card is welded to whatever it hit, so an unlocked emitter leaves its particles behind in world space ("dripping" glow) while a `LockedToPart` emitter locks to the assembly the card is welded into — on a player that assembly is rooted at the HumanoidRootPart, which drew the glow studs away from the card. A BillboardGui is adorned to the card root and renders at the card's live position every frame. The glow is tinted per weapon skin: `attachGlowToCard` takes the skin name resolved by `getCardTemplateForPlayer` (also stored on the card as the `WeaponSkinName` attribute) and looks it up in [[CardsConfig]]`.Visual.GlowColorBySkin`, falling back to `Visual.GlowColor` — so `PrestigeCard` glows white while the default card and any unlisted skin stay red
11. **Hand visibility replication** (`CardsHandVisibilityUpdate`): receives a 3-bit mask from the local Fortuna client whenever its viewmodel card visibility changes; clamps to 0..7 and writes it as a `VisibleCardMask` attribute on the player's character. Cosmetic-only — no combat impact if spoofed. `FortunaCardsWorldVisibilityClient` on each observing client reads the attribute and applies it to the world cards model
12. Both `ThrowRequest` (basic + Ability1 throws) and `UltimateRequest` handlers call [[SpawnProtectionService]].onAttack(player) to drop the spawn shield
14. **Card landing resolution** (in `raycastCard`, applied before the fly FX fires so the visual and the resting card agree): a hit is registered exactly as before, but where the card *rests* is corrected twice. (a) Bots carry oversized invisible aim-assist hurtboxes built by `BotController.createAssistHitbox` (`BotBodyHitbox` 4.5×3×3.4, `BotHeadHitbox` 3.15³, each flagged with a `BotAssistHitbox` attribute), which reach ~2 studs past the visible rig — `isAssistHitbox` detects them and `resolveAssistHitboxLanding` carries the ray on through to the real rig, falling back to `projectOntoPartSurface` on the limb the hurtbox stands in for (`HitboxType == "Head"` → Head, else UpperTorso) when the ray never touches the body (a pure aim-assist hit). Damage, headshots and assist generosity are untouched — only the card's resting place moves. (b) The resting point is captured in the target part's local space (against the rewound centre `PartSnapshotPosition` for lag-compensated hits, the live CFrame otherwise) and re-projected through that part's current CFrame at landing, so the weld no longer freezes in the rewind offset plus the card's flight time. The two corrections still never overlap, but the reason is narrower than it used to be: bots now go through the sphere pass too (item 8), so a bot hit can arrive by either route — what a bot never gets is a *rewound* snapshot, so `PartSnapshotPosition` stays nil for them and correction (b) always re-projects a bot through its live CFrame. A sphere-pass bot hit also names a real rig part rather than a hurtbox, so `isAssistHitbox` is false and correction (a) does not fire
15. Health-pack pass-through: `appendHealthPackPassThrough` reads `CollectionService:GetTagged("HealthPack")` and adds every pack's green `Pickup` + invisible `TouchHitbox` children (NOT the solid `Base`) to both the card pierce `RaycastParams` (`buildRaycastParams`) and the recall sweep `OverlapParams`, so thrown/recalled cards pass through the floating pickup while the base stand still blocks them

**Clears its ability cooldowns on `RoundActive` going true** (2026-08-06): `cooldowns`, `basicCastShotsByPlayer`, `ability1AimByPlayer` and `dashService:ResetAll()`. Fortuna is the hunter that made this necessary rather than merely tidy — her ultimate's **22s** cooldown is the longest in the game and the gap between the buzzer and the next round's first shot is only ~24s, so it was clearing on about two seconds of margin set by constants with no reason to stay put. The aim/cast bookkeeping goes with it: every entry describes a character the round start has already replaced. RevolverModule's copy of this block carries the general reasoning.

## Team modes

In a team mode the card's raycast treats allies as transparent, so a thrown card flies through a
teammate to the enemy behind instead of stopping on a friendly body.

`buildRaycastParams` also stamps the shooter's shot collision group on the params
(`TeamAffinity.shotGroup`), which is what stops cards at the *enemy* base door while leaving her own
door transparent. It is set in the builder rather than at the cast sites, so the basic/ultimate
flight ray, the assist-hitbox landing ray and the `hasClearLineTo` cover test are all covered. The
recall sweep is an OverlapParams box with no line test and still passes through doors, as it does
through every other wall.

## Dependencies
- **Requires:** [[HunterServerRuntime]], [[HunterCharacterUtil]], [[HunterActionLock]], [[HunterPositionHistory]], [[HunterMovement]] (from `ReplicatedStorage.Hunters.Shared`); [[RevolverDashService]] (from `ReplicatedStorage.Hunters.Dust.Modules.RevolverServer`) for Fortuna's Ability1 opening dash; [[Manifest|Fortuna Manifest]] (from `ReplicatedStorage.Hunters.Fortuna.Config`); [[CardsConfig]] (from `ReplicatedStorage.Hunters.Fortuna.Modules`); [[SpawnProtectionService]] (from `ServerScriptService.Combat`); [[QuestEvents]] (from `ServerScriptService.PlayerServices`) for the `ultimateUse` hook. No longer requires [[HunterSelectionService]], [[UltimateChargeService]], [[HunterHitPipeline]], [[HunterRemoteSetup]], or [[RoundStatsService]] directly — all resolved via the runtime., [[TeamAffinity]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ThrowRequest` | ← Client | Fortuna client fires for basic throw / Ability1 |
| `Ability1AimUpdate` | ← Client | Continuous aim updates during an Ability1 burst |
| `RecallRequest` | ← Client | Client requests card recall |
| `UltimateRequest` | ← Client | Client requests ultimate activation |
| `UltimateState` | → Client | Notifies the caster of invisibility start/end + duration |
| `CardFlyFX` | → All Clients | Replicates card flight visuals |
| `CardRecallFX` | → All Clients | Replicates card recall visuals |
| `CardThrowVFX` | → All Clients | Fires the ultimate vanish VFX |
| `HitConfirm` | → Client | Confirms hit/headshot/kill to the attacker |
| `UltimateChargeUpdate` | → Client | Sends current/max ultimate charge to the player |
| `KillFeed` | → All Clients | Shared kill feed remote (from `Hunters.Shared.Remotes`), reused for Cards kills |
| `KillCam` | → Client | Shared kill cam remote (from `Hunters.Shared.Remotes`), reused for Cards kills |
| `DamageDirection` | → Client | Shared damage-direction remote (created here if `Hunters.Shared.Remotes` doesn't have it) |
| `HealthBarReveal` | → Client | Fired to the attacker (only) on every landed hit; shared remote (created here if missing); [[HealthBarSpawnerClient]] spawns a local-only overhead health bar on the victim |
| `CardsHandVisibilityUpdate` | ← Client | Client pushes 3-bit hand-card mask whenever viewmodel visibility changes; server writes it as `VisibleCardMask` attribute on the character for `FortunaCardsWorldVisibilityClient` to consume |
| `DashRequest` | ← Client | Fired at the start of Ability1 with a Vector3 move direction; handler calls [[RevolverDashService]]:DoDash |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterServerRuntime]] | `.Start(manifest, opts)` | Wires hunter gate, remotes, charge service, hit pipeline; returns runtime handle |
| [[Manifest|Fortuna Manifest]] | (table return) | Declarative description of Fortuna |
| [[CardsConfig]] | config tables | Basic/Ability1/Recall/Ultimate/Visual/LagCompensation settings (UltimateCharge values now live in the [[Manifest|Manifest]]) |
| [[HunterCharacterUtil]] | `.IsEnemy()`, `.GetHumanoidFromHit()`, `.GetHumanoidModels()`, `.ShouldIgnoreCombatPart()`, `.IsHeadshotPart()` | Shared hit-target resolution, accessory filtering, headshot detection. `GetHumanoidModels` is what lets `findLagCompensatedHit` and `hasClearLineTo` see bots as well as players |
| [[HunterPositionHistory]] | `.new()`, `:Start()`, `:GetClosestSnapshot()`, `:GetRewindTime()`, `:Forget()` | Shared snapshot loop + ping-based rewind time + closest-snapshot lookup |
| [[SpawnProtectionService]] | `SpawnProtectionService.onAttack()` | Drop the spawn shield on basic throws, Ability1, and ultimate activation |
| [[RevolverDashService]] | `.new()`, `:DoDash()`, `:CleanupPlayer()` | Ability1 opening dash — Fortuna instantiates its own instance from `CardsConfig.Ability1.Dash` (AirDashMultiplier 1.0, 5s cooldown). Separate cooldown table from Dust's instance. |

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Read via `GetTagged` in `appendHealthPackPassThrough`; each pack's green `Pickup` + invisible `TouchHitbox` added to the card pierce raycast and recall sweep Exclude lists (the solid `Base` stand still blocks cards) | [[HealthPackSystem]] |
