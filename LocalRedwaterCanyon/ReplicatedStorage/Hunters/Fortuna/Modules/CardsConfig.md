---
tags:
  - shared
  - modulescript
  - config
  - combat
  - fortuna
  - cards
path: game.ReplicatedStorage.Hunters.Fortuna.Modules.CardsConfig
type: ModuleScript
lines: 194
---

# CardsConfig

Central configuration table for Fortuna's card-throwing kit (Basic, Ability1, Recall, Ultimate, charge, visuals, lag compensation).

## What it does
1. `Passive`: walk speed (24), double-jump power/cooldown
2. `Basic`: cooldown (1.2s), damage (24/42 headshot), speed (2100), range (150 — raised from 100 on 2026-08-07, full flat damage across the whole reach; Ability1 stays at 100). `Speed` is **cosmetic only** — the throw is hitscan, resolved by a raycast at click time, and speed just sets how long the card visual takes to fly (`getVisualTravelDuration`, clamped to `Visual.MinFlyDuration`/`MaxFlyDuration`). 2100 is picked so `MinFlyDuration` **always** binds (150 / 2100 = 0.071s, under the 0.08s floor even with the muzzle-vs-camera origin offset stretching the visual distance past `Range`), which means Speed is no longer a live knob for the basic throw — every card flies for exactly 0.08s at every distance. That is the point: damage resolves instantly, so the card used to lag the hit by an amount that *grew with distance* (0.08s point-blank, 0.23s at max range), and a gap that varies is what reads as desync. **To retune the gap, change `Visual.MinFlyDuration`, not Speed — and if Range moves again, rescale Speed with it** (Range / Speed must stay under the floor: 1400 at 100, 2100 at 150). Was 220, briefly 440, then 1400 while Range was 100
3. `Ability1` (E key): 5s cooldown, 3-card bursts of 2 burst-waves with 20° spread, damage (16/30 headshot), speed (1400, up from 132 via 260 — same cosmetic-only meaning and same floor-binding rationale as `Basic.Speed`; Ability1 had the worst version of the mismatch at 0.38s because its cards were the slowest of the three damage-dealing throws). Also embeds a `Dash` subtable (Cooldown 5s, Time 0.5s, ramp 28→72→22 with 0.22 ramp-up fraction, AirDashMultiplier 1.0, ThrowDelay 0.15s) — Fortuna dashes at the start of Ability1 then throws cards 0.15s later. Ramp math mirrors `RevolverDashService.GetDashSpeedAt` (plain text: CardsConfig is a table of numbers and requires nothing — it copies that convention, it does not reference the module).
4. `Recall` (Q key): 3s cooldown, damage (22), hitbox radius (3.2), max 42 active cards, diminishing damage multipliers per card hit (`{1, 0.55, 0.35, 0.2}`)
5. `Ultimate` (F key): 22s cooldown, 2.1s invisibility, 20-card outward ring (12/20 headshot damage out, 28 damage on return recall). `OutSpeed` is still **105 over a 35-stud `OutRange` = 0.33s**, so the ring is now the only damage-dealing throw whose cards still visibly lag their (instant) damage, and it varies by ~300ms across the radius. Left deliberately: the ring expanding is the ult's visual payoff, and 35 / 0.08 = 440 would snap it out in a single frame-and-a-bit. Raise `OutSpeed` only if the mismatch bothers players more than losing the spectacle does
6. `UltimateCharge`: max charge (100), per-action charge amounts (hit/headshot/kill for Basic/Ability1/Recall/Ultimate), passive regen (0.1 every 1s)
7. `Visual`: card size/color/material, lifetime (6s), landed rotation randomization, fly duration clamping, and the landed-card glow tint — `GlowColor` (red, the default-card look) plus `GlowColorBySkin`, a per-weapon-skin override table (`PrestigeCard` = white, `FrozenHand` = pale ice blue). Read by CardsServer when it clones the CardGlow billboard onto a landed card.
8. `LagCompensation`: enabled flag, history record rate (1/30s), max history time (0.55s), max rewind time (0.25s), per-part hit radii. `PartRadii` is doing **two** jobs — it is both the rewind sphere set and Fortuna's *only* hit forgiveness, because she has no equivalent of the revolver's `RevolverHitForgiveness` (flat 3.5-stud bubble). Torso radii were raised 1.35→1.9→**2.4** and Head 0.9→1.1→**1.3**, and the eight arm/leg parts were added (5 tracked parts → 13, mirroring `RevolverServerConfig.LagCompensation.TrackedBodyParts`) at 1.1 arms / 1.15 legs, so a graze on a strafing target compensates at all. Head is deliberately the most conservative of the set: a headshot is 42 vs 24, so it is the one radius where over-tuning inflates *damage* rather than just hit rate. Still comfortably under Dust's flat 3.5-stud bubble.
   - **The 2.0 cap is lifted because the cover hole was closed.** `findLagCompensatedHit` used to rely solely on `distance <= wallDistance + 0.25`, which rejects a shot *through* a wall the ray struck but is blind to one *around* a corner the ray sailed past (wallDistance is just `range` in that case). `CardsServer.hasClearLineTo` now fires a real blocking ray at the winning candidate. Do not raise these again without confirming that guard is still in the pass.
   - **Applies to bots as well as players since the same pass.** It previously looped `Players:GetPlayers()`, so none of this table reached bots. Bots are now sampled at their *live* positions rather than rewound — they are server-authoritative and have no ping to compensate for. Be aware the practical gain on a bot is small: they also carry a global 4.5 × 3.0 × 3.4 `BotBodyHitbox` (2.25 half-width) that the direct ray hits first, so 2.4 clears it by only 0.15 studs. Bot-facing generosity is still mostly that hurtbox, which belongs to every hunter, not to Fortuna

## Dependencies
- **Requires:** Nothing
- **Required by:** CardsServer, CardsWorldVisualServer, CardsClient (`.Basic.Range` only — the mobile auto-fire lock cap, added 2026-08-07)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
