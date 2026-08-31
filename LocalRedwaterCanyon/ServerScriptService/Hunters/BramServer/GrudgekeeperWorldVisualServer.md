---
tags: [server, script, world-model, vfx, animation, bram]
path: game.ServerScriptService.Hunters.BramServer.GrudgekeeperWorldVisualServer
type: Script
lines: 257
---

# GrudgekeeperWorldVisualServer

Replicated third-person Grudgekeeper shotgun and world animations for real Bram players — the Bram equivalent of VesperWorldVisualServer/RevolverWorldModelServer.

## What it does
0. Resolves its three world clip ids from the **Bram manifest** through a local `worldClipId(name)` helper over [[HunterAnimations]] (2026-08-29) — a plain table read, so the `WaitForChild` hang that once took out this whole script (renaming the authored `Unequip`/`Charging` pair to a single `Charge` stopped it at its clip lines, and Bram lost his entire third-person shotgun with nothing in the log but an infinite-yield warning) is structurally impossible now. A missing manifest entry warns with its name and degrades to an empty `AnimationId`, which [[HunterWorldModel]] already skips without erroring. The `WorldAnimations` folder is an unread leftover until Phase 2 deletes it.
1. Builds a shared [[HunterWorldModel]] configured for Bram: clones `ReplicatedStorage.Hunters.Bram.Weapon.WorldModel.Default.DefaultGrudgekeeper` onto each Bram player's `RightHand` via `Motor6D`, named `GrudgekeeperWorldCosmetic`, gated to `SelectedHunter == "Bram"`. A `TemplateResolver` reads `EquippedWeaponSkin_Bram` against `Weapon.WorldModel.Skins` first (folder-driven, same shape as Vesper's and Dust's), so `FrostbiteGrudgekeeper` swaps the gun other players see; an unlisted skin or missing art falls through to the default. One `AttachmentOffset` covers both models — they share a receiver build and pivot.
2. Plays the world **idle hold** (manifest `World.Idle`, `104495381270539`) on the character's Humanoid Animator at Action priority, looped — a single-keyframe static pose that cradles the long shotgun forward instead of letting it dangle off a locomotion arm. This is the same hold Bram bots get via BotController's world idle track. A player character's Animator is owned by that player's own client, so this server-side track alone does not hold on other people's screens: BramWorldIdleClient is the client-side twin that actually makes other Bram players cradle the gun (same pattern as Dust and Fortuna).
3. **World shoot one-shot**: every `FireShotgun` blast plays the manifest `World.Shooting` clip (`109149641341615`, 0.167s) at Action4, de-duped to one play per 0.1s (cosmetic only — the fastest legitimate cadence is Last Call's 0.25s). **Shrapnel Shell (E) reuses the same beat**, the way VesperWorldVisualServer drives its shoot clip off the pinning throw as well as the rifle; the aim-update samples the client streams on that same remote during the cast windup are filtered out, so only the cast animates. Bram bots get the E beat from BotCombat's `_tryShrapnelShell`.
4. **Breach Charge animation**: the charge plays the looped manifest `World.Charge` clip (`76968967438749`) at Action3 for the whole dash. Authored 2026-08-26 to replace an `Unequip` → looped `Charging` pair, whose handoff had to be timed off Unequip's authored keyframe length because `AnimationTrack.Length` reads 0 server-side for a freshly loaded track.
5. The charge clip is driven by watching the character's `IsDashing` attribute, not by the ability code: `RevolverDashService:DoDash` sets it only when a charge actually starts, and every end path clears it (the client's "End" action, BreachChargeService's timeout, the wall slam, death). Nothing in the animation path yields on or gates the ability, so the animation can never delay or halt the charge. A `BreachCharge.Time + 1` safety timer and token guards stop the loop if an `IsDashing` clear is ever missed; `CharacterRemoving` and a `SelectedHunter` change (mid-match hunter switch) also release it.
6. The idle hold is deliberately **not** action-locked during the charge: `Idle` is the only clip that poses `RightHand`, and the shotgun is welded to `RightHand`, so leaving it running keeps the gun gripped correctly while Action3 overrides the arms/torso/head. No world clip poses legs, so locomotion keeps driving the run underneath.
7. `AttachmentOffset` seats `WorldShotgun.Main` at the right hand with the barrel (Main local -X) forward and the top (+Y) up under that pose. It is byte-identical to `LOCAL_WORLD_MODEL_CONFIG.Bram.Offset` in BotVisualClient (bots weld the same placement) — keep the two in sync.
8. Enables the HunterWorldModel Heartbeat watchdog (`HeartbeatReattach` + recheck) to re-attach the cosmetic and replay idle if either is lost (e.g. streaming).

The owner's own copy is hidden in first person by HideLocalWorldGrudgekeeper. Bram's dash roll is suppressed (`AnimationId = ""` on GrudgekeeperModule's dash service) so the shared roll's legs do not fight the charge run.

## Dependencies
- **Requires:** [[HunterWorldModel]], [[HunterAnimations]] (world clip ids from the Bram manifest — from `ReplicatedStorage.Hunters.Shared`), [[HunterSelectionService]] (Bram-only gating), [[GrudgekeeperConfig]] (charge duration for the safety timer)
- **Required by:** Nobody (self-running Script)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FireShotgun` | ← Client | [[GrudgekeeperClient]] blast request; a second listener alongside GrudgekeeperModule that only plays the world shoot one-shot |
| `ShrapnelShellRequest` | ← Client | [[GrudgekeeperClient]] E cast; same second-listener arrangement, ignoring the aim-update samples |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterWorldModel]] | `.new()`, `:Start()`, `:PlayOneShot()`, `:StopOneShot()` | Shared world-model lifecycle: clone + attach the shotgun, loop the hold idle, play the shoot and charge tracks |
| [[HunterSelectionService]] | `.IsHunter()` | Gate the world model and every animation to Bram players only |
| [[GrudgekeeperConfig]] | `.BreachCharge.Time` | Upper bound for the charge-loop safety timer |
| [[HunterAnimations]] | `HunterAnimations.id()` | Resolve the Idle/Shooting/Charge world clip ids from the Bram manifest |
