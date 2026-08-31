# 123 — Frostbite spawn houses: several spawn markers sit on navmesh islands, so a bot spawning there cannot path out

**Status:** OPEN · **Sev:** P2 · **Raised:** Domination bot investigation (2026-08-22)

## Symptom

Found while probing why Domination bots stood around (see the Domination entry in
[UNRELEASED](../UNRELEASED.md)); it is **pre-existing and affects TDM too**. On Frostbite Claim, with
the bot agent (`PathAgent` 2.55 / 6.4, jump links allowed for the probe), `ComputeAsync` from the red
house's spawn markers reaches the outside of one of its own doors from only **5 of 12** markers
(Points 4, 5, 8, 9, 11 do; 1, 3, 6, 7 reach nothing at all; 2, 10, 12 reach one side of a door —
probably the inside — but not pad A), and from the blue house **10 of 12** (Points 1 and 2 reach
nothing). Every marker sits on its house's `Bridge` part at one height (red Y 7.4, blue Y 5.4) with
≥ 7.8 studs of headroom, so it is navmesh fragmentation across the bridge rather than a ceiling or a
step. Redwater's houses were fine in the same probe (both bases reach all three pads).

A bot that spawns on an island stands in the house until BotPathing's stuck recovery /
`DirectEscape` happens to walk it off — or for its whole life if it never does.

**Re-measured 2026-08-23**, marker → ground twenty studs outside the house, `BotConfig.PathAgent`
(2.55 / 6.4, no jump), which is what the shipped probe now uses:

| House | Reaches the map |
|---|---|
| Frostbite red | **5 of 12** — Points 4, 5, 8, 9, 11 |
| Frostbite blue | 10 of 12 — 1 and 2 are islands |
| Redwater red | 12 of 12 |
| Redwater blue | 12 of 12 |

**Redwater is not affected**, and the original line above is right. A draft of this item claimed
Redwater's red house was 11 of 12; that was measured in the EDIT-mode dressing, where the spawn
house and the `TeamModeRemovals` props it replaces are *both* in the workspace. In the dressing a
team mode actually runs — props parked — all twelve reach the map. **Probe the dressing the mode
runs, not the one the place is saved in**; parking `TeamDeathmatchRemove` first is what makes an
edit-mode probe mean anything on either map.

Two things this rules out. **Agent size is not the cause:** the same five Frostbite markers pass at
radius 2.0 as at 2.55, so shrinking the capsule fixes nothing. **The one-way doors are not the
cause:** every slab carries a `PathfindingModifier` with `PassThrough = true`, and flipping
`CanCollide` on all of them changes the route out by zero waypoints.

A floor-grid probe of the Frostbite red house shows the navmesh reaching only its southern strip;
the north rooms are floor at the right height (all twelve markers sit on a `Bridge` part at Y 7.36)
with no navigable connection to the exit or to each other. The islands are {4,5,8,9,11} — the only
one that reaches outside — plus {2,10,12}, {3,6}, {1} and {7}.

**Worked around, not fixed (2026-08-23).** `TeamDeathmatch` now probes the markers once per server
and seats bots on the reachable ones first — see the Fixed entry in
[UNRELEASED](../UNRELEASED.md). That stops bots being stranded; it does not give them back the
house's north rooms, which stay a no-go area for every bot on the map. This item closes on the
geometry, not on the workaround.

## Repro

Edit mode, Frostbite: for each `Points` child of `RedTeamBase` / `BlueTeamBase`, `ComputeAsync` from
the marker to `door.Position ± LookVector * 6` for each `*BaseDoor`, with the `BotConfig.PathAgent`
dimensions. Or play a TDM / Domination round on Frostbite and watch which red bots never leave the
house.

## The test that closes it

Every spawn marker in both houses reaches the outside of at least one of its own doors with the bot
agent (12 / 12 each). Likely fixes: re-run the marker generator with a navmesh-reachability check, or
bridge the seams with a `PathfindingLink`. Diagnosis belongs in the release entry that closes it.
