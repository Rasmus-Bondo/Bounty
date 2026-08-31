---
name: project-bram-hunter
description: "Bram (close-range bruiser) — built in Redwater 2026-07-06; kit decisions, the Reinhardt-style pinning Q, world-gun wiring, and what's still open"
metadata: 
  node_type: memory
  type: project
  originSessionId: f6c613fe-ae1f-462c-b25b-daff4591333e
  modified: 2026-08-01T17:50:02.168Z
---

Bram: close-range bruiser, **225 HP**, Grudgekeeper multi-pellet shotgun, Breach Charge (Q), Shrapnel Shell (E), Last Call ultimate (50% damage reduction, 25% lifesteal, cooldown-reduction-on-hit, faster cadence). Design doc: `bram_implementation_guide.md` at the project root, same convention as [[project_vesper_hunter]]'s.

**Scripts** (all vault-documented): `ReplicatedStorage.Hunters.Bram.Config.{Manifest,GrudgekeeperConfig}` · `ServerScriptService.Hunters.BramServer.{GrudgekeeperModule,GrudgekeeperDamageService,BreachChargeService,ShrapnelShellService,LastCallModule,GrudgekeeperWorldVisualServer}` · `StarterPlayerScripts.Bram.{GrudgekeeperClient,BramHunterGuiClient,HideLocalWorldGrudgekeeper,BramWorldIdleClient}` · ungated `StarterPlayerScripts.BramWorldFXClient`.

## Kit decisions the user confirmed (not re-derivable from code)

- Grudgekeeper is a **multi-pellet raycast fan**, not a cone-volume check: 8 pellets (placeholder count) in a ≈7.6° half-angle cone, solved from the design's "8 stud radius at 60 studs". The design's flat damage numbers (100/50 near, 25/15 far) are the **ceiling if every pellet connects**, split per-pellet.
- **Thick Hide is only the 225 max-health stat.** The "small sustain" flavor text maps to no actual heal/regen mechanic.
- Shrapnel Shell **fires immediately** on ability use (not via the normal trigger), travels straight, and does **not** consume the 2-round magazine.
- Breach Charge's speed/damage/knockback numbers were left to placeholder judgment, flagged `[ASSUMPTION]` in the guide.

## The Brakk→Bram rename (a trap worth remembering)

The asset shipped under the codename "Brakk". Because `category` doubles as the `SelectedHunter` gate value, `HunterSelectionService` mapping `Bram → "Brakk"` meant `SelectedHunter` became `"Brakk"`, never matched the manifest's `"Bram"`, and **none of Bram's scripts ever activated** — and `DEFAULT_HUNTER = "Brakk"` wasn't even a valid key, so it silently fell back to Dust. Renamed 2026-07-07; `HUNTER_ASSET_NAMES` is now identity for all four. Verified 2026-07-26: `ReplicatedStorage.Characters` = Bram, Dust, Fortuna, Iris, Vesper, no "Brakk" anywhere. (`Iris` is a placeholder asset for a future hunter, no kit scripts. The hunter GUI cleanup tables still list `"IrisGameGui"`.)

**Cross-place caveat:** the Bounty teleport path builds `category` directly with no asset mapping, so its payload must send `"Bram"`.

## Breach Charge (Q) — Reinhardt-style pinning charge

Reworked 2026-07-23. The **movement is unchanged** (3s steerable run, `ChargeStartSpeed` 24 → `ChargePeakSpeed` 42, `ChargeTurnRateDegrees` 125 A/D steering); only the END behaviour changed. A frontal box (`Pin` sub-config in `GrudgekeeperConfig.BreachCharge`) grabs enemies Bram rams and carries them; ramming a wall while carrying ≥1 victim **slams for 50 dmg + 2.5s stun**; whiffing releases for 15 dmg, no stun.

User's three calls: A/D steering kept · **no Bram self-penalty** after a slam · slam = 50 dmg, the stun is the payoff.

**Architecture:** one shared Heartbeat loop over `ActiveCharges` owns pin scan (object-space box off Bram's HRP, tracks steering) + carry + wall detection. Bot victims are dragged server-side by CFrame; player victims are followed by their OWN client via a directed `BreachChargeFX` "Pin"/"Unpin" message (reuses the grapple-pull pattern). Wall detection is **client-detect + server-verify**: `detectBreachWall` fires `BreachChargeRequest("WallHit")`, the server re-raycasts within `WallVerifyDistance` and requires live pins before granting the stun, so a spoofed WallHit whiffs. `BreachChargeRequest` actions are `Start`/`WallHit`/`End`. Dragged victims reuse `KnockbackGraceUntil`, which MovementChecker already honours — no anti-cheat edit needed.

**New shared primitive:** `HunterStatusEffects:ApplyStun(char, dur)` — 100% slow through the slow system (for cross-instance bookkeeping + the client SprintController hand-off), plus jump lock and a `StatusStunned` attribute.

**Rules that came out of three playtest rounds — don't undo these:**
- **Never anchor a character to hold it still.** Anchoring a carried bot's HRP and teleporting per-tick tore the dynamic limbs off the torso, and a slam that killed it left a floating anchored torso. Move the *unanchored* assembly by CFrame instead. Freezing a bot also needs `WalkSpeed = 0`, not just the lock flag — see [[project_bot_freeze_gotcha]].
- **Stall detection was deleted, deliberately.** Inferring "rammed a wall" from speed < `StallSpeed` read false-zero off Bram's *replicated* position between updates and slammed in open space. The forward raycast is now the sole trigger (it excludes Bram and all pinned victims so a carried body can't occlude it). `StallSpeed`/`StallGrace` remain as **vestigial config keys** (`GrudgekeeperConfig` L71, `BreachChargeService` L45) — flagged for cleanup, do not "restore" the feature.
- **Firing during the charge is a no-op**, not a cancel. It used to call `finishBreachCharge("Input")`, which turned every slam into the 15-dmg release path.
- The grab box is a **plow, not a needle**: `BoxDepth` 13 × `BoxHalfWidth` 6 × `BoxHalfHeight` 6, `MinForwardDistance` -1.5, `CarryDistance` 6 (at 4 the collidable captive sat on Bram's face and deflected him).
- `WallVerifyDistance` must exceed the client's `ChargeWallCheckDistance` **plus replication lag** — the client-owned HRP at charge speed lags the server by ~speed×latency, or valid slams get rejected as "no wall".
- A server-initiated slam sends a `BreachChargeFX` `"ChargeEnd"` back to the charger so the client stops its local loop instead of grinding the wall to the 3s timeout.

**Stun had to be enforced separately from movement.** `ApplyStun` only locks movement/jump and sets the attribute; nothing read it, so stunned actors could still shoot. Bots: gated `BotCombat:FireAt` + `ThinkAbility` (BotBrain reaches them on a path that skips the movement early-return). Players: a `StatusStunned` check in each hunter's client combat gate (`isCombatAllowed` in GrudgekeeperClient/SunspikeClient/CardsClient, `isLocalCombatAllowed` in Dust's FPSRevolverClient) — one spot each, covering fire + abilities + reload. **As of 2026-08-01 all of those read `HunterActionLock.IsLocked` instead of the raw attribute**, because `StatusStunned` alone left the entire pin/carry phase ungated — see [[project_hunter_action_lock]].

## World gun — "copy Vesper, swap the model"

Bram originally had **no `HunterWorldModel` server at all**, so real third-person Bram players carried nothing. Now `GrudgekeeperWorldVisualServer` (mirroring Vesper's) builds one from `ReplicatedStorage.Grudgekeeper.WorldShotgun`, cosmetic name `GrudgekeeperWorldCosmetic`, with HeartbeatReattach; `HideLocalWorldGrudgekeeper` hides the owner's own copy in first person. Bots get theirs from `BotVisualClient.LOCAL_WORLD_MODEL_CONFIG`.

**The lesson, learned over two failed playtest rounds:** the Grudgekeeper and the sniper share a barrel axis (`Main` local +X) and grip geometry, so "copy Vesper, swap the gun" means copy the offset **verbatim** — hand-deriving a bespoke rotation from the shotgun's geometry put the hand on the muzzle, then the muzzle over the shoulder. Final shared offset, used identically by both the bot config and the server's `RIGHT_HAND_OFFSET`:

```lua
CFrame.new(0.01416015625, -1.336212158203125, -0.50341796875)
  * CFrame.new(0, 0, 0,  0, 0, -1,  1, 0, 0,  0, -1, 0)
```

**A hardcoded arm pose is the wrong mechanism — don't retry it.** An early fix baked 6 Motor6D `Transform` CFrames (`BRAM_HOLD_POSE`) to cradle the gun; the user's verdict was "very bad" and it was ripped out entirely. The engine-native way is an **Action-priority looping hold animation** on the rig, which cradles the arms and lets the welded gun follow. Bram now has his own clip set — see [[project_bram_world_animations]].

Bot shot FX shipped too (neon muzzle flash + PointLight, 6-pellet orange beam fan, layered `SFX.Bram.ShootFirst`+`Shoot`). Full bot ability kit: [[project_bram_bot_abilities]].

## Bounty trading post display

Bram is in the HUNTERS tab as a free hunter ("CLOSE-RANGE SHOTGUNNER") and in the weapon-skins tab; `DataService.DEFAULT_WEAPON_SKINS` seeds `Bram = "Grudgekeeper"`. His gun was copied cross-place and **re-baked to a canonical orientation in Bounty**, so it does NOT match the Redwater model's orientation — `HuntersBuyController.WEAPON_DISPLAY.Bram` drives its pose explicitly rather than through the shared lookAt.

Two traps from tuning that display:
- **A model's `WorldPivot` rotation does not necessarily match its visible geometry.** The Grudgekeeper's mesh is baked with the barrel drooping ~20° below the pivot's local X, so laying the pivot flat left the gun nose-down. Measure the *parts* (PCA over part centres, or world-axis projection), never the pivot. Two part centres also lie — `HandleTape` is laterally offset from the barrel line and reported an 11-14° lean where PCA showed 3°.
- **`Camera.FieldOfView` is VERTICAL.** A gun stood upright is ~4.6 studs tall; at the ~8-stud closeup distance ~11 studs are visible vertically. Final: user wanted it **standing vertical**, `displayScale` 4.5, `standRaise` 1.83 (floats it to eye-level centre, Y≈10.44). `explicitIconOrient` stays horizontal — a thin vertical gun fills the round icon badly.

## Still open

- ~~Server-side anti-cheat backstop for `StatusStunned`~~ — **DONE 2026-08-01**, shipped alongside the ram gate: [[project_hunter_action_lock]].
- `StallSpeed`/`StallGrace` vestigial config keys (above).
- Breach Charge cooldown is still **6s**, untouched from before it became hard CC — flag as a tunable.
- Bram's asset folder rename is done, but the GUI cleanup tables still carry `"IrisGameGui"` for the unbuilt Iris.

Related: [[project_bram_world_animations]], [[project_bram_bot_abilities]], [[project_hunter_world_cosmetic_attach]], [[project_slow_basewalkspeed_contract]], [[project_bot_freeze_gotcha]], [[feedback_no_mcp_playtest]].
