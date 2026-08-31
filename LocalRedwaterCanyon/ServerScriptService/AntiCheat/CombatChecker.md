---
tags: [server, script]
path: game.ServerScriptService.AntiCheat.CombatChecker
type: Script
lines: 387
---

# CombatChecker

Observational anti-cheat for the hitscan fire remotes — detects aimbot signatures in shot payloads without ever blocking a shot.

## What it does
1. Attaches its **own** `OnServerEvent` listener to each hunter's fire remote, alongside the hunter module's. Roblox runs connected listeners independently, so nothing in this script can block, alter or delay damage, ammo or hit registration. Every handler body is additionally `pcall`'d. This isolation is the whole design premise: it shipped the same night as a live publish precisely because it cannot break combat
2. Watches three remotes — `Hunters.Dust.Remotes.FireBullet`, `Hunters.Vesper.Remotes.FireBullet`, `Hunters.Bram.Remotes.FireShotgun` (Bram's is **not** named `FireBullet`). Each is resolved in its own `task.spawn` with a 30s `WaitForChild`, and a missing one warns and leaves that hunter unwatched rather than aborting the others. Fortuna is deliberately absent — her basic is a thrown projectile on `ThrowRequest` with a different payload shape, and an aura against it must lead a moving target rather than point at one
3. **Signal A — sustained aim divergence** (weight 2): the angle between the claimed `cameraDirection` and the character's actual `Head.CFrame.LookVector`, both flattened to XZ exactly as the shot path's own `isAimDirectionReasonable` does. Flags when **≥60% of a 12-shot window** exceeds 70°, with a minimum of 8 shots. Deliberately a *ratio over a window*, not a per-shot test: one wide shot is a fast flick plus replication lag and means nothing, while most of a window being wide is the reported kill-aura, which never turns the character at all. Re-flags at most every 4s.

   **Shots taken mid-dash are not sampled.** `RevolverDashService` sets `AutoRotate = false` for the roll (0.46s plus a 0.12s restore) so the camera swings without the body following, which makes a legitimate shot genuinely point away from the character's facing. **Known gap:** the `IsDashing` attribute this checks covers Dust only. Bram's Breach Charge does the same thing — his client clears `AutoRotate` and hard-writes the root CFrame to the charge direction each frame, and firing mid-charge is legal by design (it commits the charge rather than cancelling it) — but nothing sets `IsDashing` for it. `BreachChargeService` only ever *clears* that attribute, and `S.IsBreachCharging` is a client-side table field, not an attribute. One charge is too few shots to reach the 60% ratio alone, so it ships documented rather than patched on publish night — but it is one of the reasons kicks stay off
4. **Signal B — metronomic cadence — OBSERVATION ONLY, it never scores** (`CADENCE_SCORES = false`): mean absolute deviation of the last 8 inter-shot intervals, warned when below 12ms. The aura schedules every shot at exactly `now + cooldown` forever, where human trigger intervals jitter by tens of milliseconds.

   It carries no weight because **there is no sound server-side way to exclude mobile auto-fire**, which is a legitimate metronome firing on a fixed `FireInterval`. `AutoFireLocked` looks like the gate and is not one: all four hunter clients publish it with `player:SetAttribute` from a **LocalScript**, and client-side attribute writes do not replicate upward, so the server never sees it — nothing server-side reads it today. Deliberately replicating it would not help either, since it would then be a client-controlled flag a cheat could simply assert to silence the signal. The read is left in the code because it costs nothing and becomes correct the moment a server-side writer exists. Intervals over 3s are treated as a lull (reload, cover, respawn) and clear the window. Its value for now is calibration data: read real numbers off a live server before deciding whether the separation between a script and a touch player is wide enough to score at all
5. Accumulates weights against `VIOLATION_THRESHOLD` (5), decaying 1 every 20 seconds of clean play — slower than MovementChecker's 2s because a combat flag needs a whole window of shots behind it and must not be erased by one quiet reload
6. Every flag carries a context string: hunter, `ping`, the `AutoFireLocked` state, root position, and the signal's own measurements (divergence ratio, or cadence mean and deviation). Uses `warn` rather than `print` for the same reason MovementChecker does — the Creator Hub error dashboard captures warnings and errors only. On reaching threshold it emits the full flag history, up to `FLAG_HISTORY_LIMIT` (6) entries
7. **`ENFORCE_KICKS` is `false`.** It collects evidence and warns; it does not kick. Beyond the uncalibrated thresholds, one false-positive path is **known and unsolved**: a client whose replication stalls leaves the server holding a frozen copy of the character while shots keep arriving carrying fresh directions, which reads as a run of wide shots — exactly the shape Signal A scores. MovementChecker's own comments document that this game really does see stalled clients, and Hotfix 16 had to cut its delta weight for precisely this reason. Nothing in this script can separate that from an aura, so the thresholds must be judged against real traffic before anyone is disconnected by them

## Why it exists
Built 2026-08-29 after a kill-aura script was used on live (r2726). That script is not a damage bypass — it sends the legitimate fire payload with a hand-computed direction and obeys every server gate (fire cooldown, server-held magazine, server-stamped reload), so nothing on the shot path can distinguish it from a human pulling the trigger. Its one observable tell is that the player never turns.

This is the **detection** half of the response. The **blocking** half is the aim orientation gate specified in `AIM_ORIENTATION_GATE_SPEC.md` at the project root, which tightens the 125° cone in each hunter module and adds a deferred re-check that feeds this script. That gate changes the damage path and is deliberately built separately.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FireBullet` | ← Client | [[FPSRevolverClient]] fires Dust's shot; this script observes the payload for aimbot signatures |
| `FireBullet` | ← Client | [[SunspikeClient]] fires Vesper's shot; same observation path |
| `FireShotgun` | ← Client | [[GrudgekeeperClient]] fires Bram's blast; same observation path |

### BindableEvents
None

### Direct require()
None
