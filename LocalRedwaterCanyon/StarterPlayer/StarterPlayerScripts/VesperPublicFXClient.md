---
tags: [client, localscript, fx, vesper]
path: game.StarterPlayer.StarterPlayerScripts.VesperPublicFXClient
type: LocalScript
lines: 487
---

# VesperPublicFXClient

Persistent observer presentation for clients who are **not** playing Vesper — shot tracers/audio, grapple cable, and the Pinning Round trail + zone. Exists because the victims and bystanders of Vesper's abilities are usually on other heroes, whose clients never load the hero-gated `SunspikeClient`. Same placement convention as `BramWorldFXClient` and `HighNoonPublicFXClient`.

Gated **per event** on `isLocalVesper` — every handler returns immediately while the local player is on Vesper, since `SunspikeClient` owns the identical listeners for her.

## What it does
1. **Live hunter gate** — `isLocalVesper` is seeded from `HunterGate.IsHunter(player, "Vesper")` at load and kept current by `HunterGate.ConnectHunterChanged`; each remote handler early-returns while it is true. It is deliberately NOT a load-time `return`: this script sits at the StarterPlayerScripts root and HunterClientLoader only restarts the per-hunter *folder* scripts (plus HunterFirstPersonClient) on a mid-match switch, so a player who switched **to** Vesper kept these listeners wired alongside a freshly booted `SunspikeClient` and heard/saw every grapple, shot layer and pinning effect **twice**. The live read also covers the mirror case — a player who switches **away from** Vesper resumes seeing other Vespers' public FX instead of going blind to them for the rest of the round
2. **Shot FX** on `ReplicateShot`: positional two-layer shot audio (`SniperShoot`/`SniperShoot2`, or `UltimateShotFirst`/`UltimateShotSecond` with a 0.1s offset for Starfall Sight) on a throwaway anchored audio part, plus a tracer via [[laserBeamEffect]]. Ultimate shots additionally bloom a Neon ball at both ends of the ray
3. **Grapple cable** on `GrappleFX`: `"Launch"` plays the grapple sound at the caster's root; `"Hit"` / `"Miss"` draw a dark cylinder cable from the caster's shoulder to the anchor for TravelTime + 0.1s / 0.15s, re-solved every RenderStepped so it tracks the moving caster
4. **Pinning Round trail** on `PinningLaunchFX`: clones `Hunters.Vesper.Objects.VesperUltTrail2` (a Part carrying one Beam), recolours it to the blue pinning gradient, and dead-reckons it locally every RenderStepped at the server-supplied speed/direction — so every observer sees the same flight with no per-frame projectile replication
5. Trail raycast mirrors [[PinningRoundService]]`:_buildRaycastParams` (thrower's character, `RewindHitboxes`, HealthPack `Pickup`/`TouchHitbox` but not `Base`), and additionally **passes through gameplay-only volumes** — anything carrying the `BotAssistHitbox` attribute or named `RewindHitbox`. Those are invisible and deliberately oversized, and on a client bot visual they are the *only* queryable parts (`BotVisualClient`), so stopping on one used to freeze the beam in open air far from the real landing point
6. A local ray hit is treated as a **hint only** — `PinningImpactFX` is authoritative. The trail dissipates over 0.15s (Beam Brightness/Width tweened to 0) instead of freezing in place, and a `Debris:AddItem` backstop sized to the flight window guarantees the anchored part can never be stranded
7. Trails are keyed by caster through `throwerKey`, which substitutes a shared `UNKNOWN_THROWER` sentinel when the caster arrives as `nil`. Bots are Models in `workspace.ArenaBots`, so a distant one streams out and its Instance reference crosses the RemoteEvent as nil — previously that made `activeProjectiles[thrower] = state` throw "table index is nil". The launch and impact handlers use the same key, so a streamed-out caster's trail still renders and is still cleared on impact
8. **Pinning zone** on `PinningImpactFX`: cleans up that thrower's trail — which happens **before** the `isLocalVesper` gate, since a player who switched to Vesper mid-flight still owns a trail `SunspikeClient` never saw — then blooms a ForceField ball from 2 studs to the full 25-stud radius over 0.6s (matching the server's zone expansion), holds for the effect duration, then fades out
9. Zone ambience: a looped `ForceFieldZone` sound crossfades in/out as the local player's root crosses the sphere's current radius, so you can hear when you are standing in a slow field
10. Waits for the server-created `Hunters/Vesper/Remotes` folder before wiring listeners

## Dependencies
- **Requires:** [[HunterGate]] (from `ReplicatedStorage.Hunters.Shared`), [[VesperConfig]] (from `ReplicatedStorage.Hunters.Vesper.Config`), [[laserBeamEffect]] (from `ReplicatedStorage.Hunters.Dust.Modules`)
- **Required by:** Nobody (self-running LocalScript)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ReplicateShot` | ← Server | [[SunspikeModule]] / [[StarfallSightModule]] broadcast shot endpoints + style |
| `GrappleFX` | ← Server | [[GrappleHookService]] Launch/Hit/Miss verdict + anchor point |
| `PinningLaunchFX` | ← Server | [[PinningRoundService]] origin/direction/speed/flight time for the local trail sim |
| `PinningImpactFX` | ← Server | [[PinningRoundService]] authoritative landing point + zone duration |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterGate]] | `.IsHunter(player, "Vesper")`, `.ConnectHunterChanged()` | Seed and maintain `isLocalVesper`, the per-event gate that keeps this script silent for Vesper, who has `SunspikeClient` |
| [[VesperConfig]] | `.GrappleHook`, `.PinningRound` | Cable duration, pinning radius/durations, trail speed fallbacks |
| [[laserBeamEffect]] | `(startPos, endPos, trails, options)` | Shot tracers for basic and ultimate fire |

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Read via `GetTagged`; each pack's `Pickup` + `TouchHitbox` added to the pinning trail raycast Exclude list so the round passes through like it does server-side | [[HealthPackSystem]] |

## Notes
Bots fire `PinningLaunchFX` / `PinningImpactFX` / `ReplicateShot` / `GrappleFX` directly from [[BotCombat]] with the bot **Model** as the caster; `resolveVesperCasterCharacter` accepts either a Player or a Model.

The gate used to run once at load, which broke mid-match hunter switching in both directions (fixed 2026-07-28): a player who switched **to** Vesper had already passed the gate, so this script and the newly booted SunspikeClient both answered `GrappleFX`/`ReplicateShot`/`PinningLaunchFX`/`PinningImpactFX` — the grapple (Q) sound was the audible symptom, playing twice on every cast — while a player who switched **away from** Vesper had returned out of the script and saw no other Vesper's public FX for the rest of the round. Both are now per-event checks of the live `SelectedHunter` attribute. Bram's and Dust's public-FX scripts never had the load-time self-gate, so they are unaffected.
