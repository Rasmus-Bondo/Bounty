# 25 — Players kicked by anti-cheat while frozen for the victory showcase

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Status:** **VERIFIED** by the owner 2026-08-05 — live, full match to the buzzer, no kicks during the showcase · **Sev:** P1 · **Area:** Redwater — anti-cheat / round end

**Resolved 2026-08-04 — it was never Vesper, and it was never the grapple.** A fresh export
(`anticheat Errors and warnings by count.csv`) carried the `vY` / `pos` / `move{...}` fields the
diagnostic below was added for, and they name the cause outright: **the end-of-match victory freeze
anchors the character and grants no anti-cheat immunity.** Details under *Diagnosis* below; the
`GrappleGraceUntil` reading that gave this item its original title was a symptom of the same
grapple-never-landed *fall*, not of the kick. Item retitled and re-scoped on that basis.

**Raised 2026-08-03** from two live `[AntiCheat] ... kick detail` logs supplied by the owner while
working #17. **This is not #17, and #17's clamp does not close it.** #17 is a player thrown too far
and landing; this is a player who never lands at all.

**Read of the logs.** `MovementChecker`'s `[  32.1s]` stamp is `tick() - data.startedAt`, and
`startedAt` is set in `CharacterAdded` — so it is **seconds since that character spawned**, not
match time. Both incidents have the identical signature:

- `GrappleGraceUntil` is **negative and frozen**: 32.1−15.35, 33.2−16.36, 34.2−17.38, 36.2−19.43 all
  resolve to ≈16.8s. The attribute stopped moving and never resumed.
- 16.8s is exactly `grapple start + MaxGraceTime (4)`. The watcher `break`s at its deadline leaving
  the last capped value, so a value frozen precisely at start+4 means **the watcher ran the full 4s
  and never once saw `FloorMaterial ~= Air`.** The grapple fired at ≈12.8s and the player had not
  landed 4s later.
- **Then ~15 seconds with no violations at all** (16.8s → 32.1s). Both airborne checks are suppressed
  while `falling` (`vel.Y < -15`) or while the state is Freefall/Jumping/Climbing. So the player was
  descending, unflagged, exactly as designed — they were falling for about a quarter of a minute.
- At ≈30s the fall *stops without ground*: `state=Running floor=Air grounded=false`, `vel.Y >= -15`,
  and `findGround` (5 probes, 25 studs, character-only filter) finds nothing. Flags accrue to the
  threshold and the player is kicked.

**Two unexplained readings — ANSWERED 2026-08-04, and neither needed a new mechanic.** `walkSpeed=0.0`
alongside a sustained non-zero `hSpeed`, across every sample. Both come from the victory freeze:
`RoundController.freezePlayerForVictory` applies `HunterMovement.SetOverride(character,
"VictoryFreeze", 0, { LockJump = true })` — the new `move{...}` field names it verbatim
(`override VictoryFreeze=0.00 (jump locked)`) — and anchors the root one line earlier. **Nothing was
driving the root.** Anchoring stops simulation *without* clearing `AssemblyLinearVelocity`, so the
property keeps whatever the player carried into the buzzer and reports it forever; the give-away is
that `hSpeed`, `vY` and `pos` were byte-identical across 4.1 seconds of samples. The suspicion that
16.0 was Vesper's `Passive.WalkSpeed` was a coincidence — the 2026-08-04 case reads 14.9 on a Dust
player. `VictoryShowcaseClient:1146` was correctly ruled out and stays ruled out.

**The logs supplied were two incidents, not three** — the second and third are the same
`SniperSnugs` kick (identical timestamps and grace values). `flagViolation` prints kick detail on
*every* call at or past the threshold, and one `runChecks` pass can flag twice, so 4→5 and 5→7 both
printed at 61.2s.

**Do not "fix" `MaxGraceTime = 4`.** It is the documented abuse ceiling, and the player was not
flagged during the fall anyway — widening it would buy nothing and weaken the check.

**The diagnostic worked and is why this closed.** `vY` / `pos` / `HunterMovement.Explain` were added
to `MovementChecker` on 2026-08-03 with no behaviour change; the very next export identified the
cause in one pass. Worth repeating on any item that stalls on inference.

---

**Diagnosis (2026-08-04).** `RoundController:1541` ends every match with
`freezeAllPlayersForVictory()`, which zeroes nothing, **anchors the `HumanoidRootPart`** and applies
the `VictoryFreeze` zero override. The showcase then runs `Config.POST_GAME_VICTORY_TIME` = **30
seconds**. Anti-cheat immunity did not cover it:

- `ACImmuneUntil` — `AC_TELEPORT_IMMUNITY` = **8 s**, granted by `SpawnService.teleportPlayerToSpawn`
  as part of the jail teleport 0.15 s before the freeze.
- `ACImmune` — set only in `closeServer()`, i.e. **after** the whole 30 s showcase.

That left a **~22-second window** in which `MovementChecker` judged a body the server itself had
pinned. A player frozen where `findGround` sees nothing within its 25-stud probe accrues
`airborne with no ground` (w1) every 2 s and `airborne for Ns` (w2) every 3 s, **cannot move off the
flag** (anchored) and **cannot decay** (decay requires `grounded`). Kick is then arithmetic. Every
stamp in the `dungeon_parts` incident is predicted by it — jail teleport at 22.6 s of character age,
immunity out at 30.6 s, both timers starting there:

| Log stamp | Predicted from | Flag | Total |
|---|---|---|---|
| 32.6s | 30.6 + `NO_GROUND_GRACE` 2 | no ground, w1 | 1 |
| 33.6s | 30.6 + `MAX_AIRBORNE_TIME` 3 → *"airborne for 3.1s"* | w2 | 3 |
| 34.6s | 32.6 + 2 | no ground, w1 | 4 |
| 36.7s | 34.6 + 2 | no ground, w1 | **5 → kick** |
| 36.7s | 33.6 + 3.1 | airborne, w2 | 7 |

Kicked **14 seconds into a 30-second showcase**, for standing still where the server put them.

**Why that player had no ground under them is a second, separate bug — see the standing concern on
the silent jail teleport.** `pos=(52,1,-250)` is not the jail: `workspace.JailSpawn` is at
`(1.85, -59.69, -141.70)` and a probe from its teleport point hits the jail floor 3 studs down, so a
player who actually *reaches* jail reads `grounded=true` and never flags. At `(52,1,-250)` the
terrain surface is at **Y = 11.89** — the player was ~11 studs *underneath* the canyon floor.

**Fix (2026-08-04, `RoundController`):**
1. `freezePlayerForVictory` sets `ACImmune` itself; `unfreezePlayer` clears it (ahead of its
   character nil-check, since the attribute is on the **player** and would otherwise strand set).
   `closeServer` re-grants it **after** `unfreezeAllPlayers()` rather than before — where the
   unfreeze now immediately cleared it — and before `teleportAllToLobby()`.
2. `freezePlayerForVictory` zeroes `AssemblyLinearVelocity` before anchoring, so a frozen body
   reports 0 instead of carrying stale speed into every future log. Diagnostic value only.

**Deliberately NOT done: exempting anchored characters inside `MovementChecker`.** It looks like the
tidier fix and it is a free bypass — clients can set `Anchored` on their own character parts and have
it replicate. The gate has to stay a server-written attribute.

**Still to verify (human, MCP playtesting unavailable):** finish a match normally and confirm nobody
is kicked during the 30 s showcase; finish a match having fallen out of the map just before the
buzzer (the exact reported case) and confirm the showcase completes and the lobby teleport lands;
confirm anti-cheat still kicks a flyer *during* a live round, i.e. the immunity did not leak outside
the freeze.

**Not closed by this, and not P1 any more:** whatever puts a player under the terrain in the first
place, and the grapple that never lands. Both are now harmless — the player rides out the showcase
and is teleported to the lobby — so they are tracked as the standing concern below rather than here.
