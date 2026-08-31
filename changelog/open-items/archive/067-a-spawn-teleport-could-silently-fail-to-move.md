# 67 — A spawn teleport could silently fail to move the player

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**A spawn teleport could silently fail to move the player — FIXED (unverified) 2026-08-04.**
`SpawnService.teleportPlayerToSpawn` sets `ACImmuneUntil` on the line *before* it writes
`root.CFrame`, and in the #25 incident the immunity demonstrably applied while the position did
not — so it cleared the `Health <= 0` guard and **the CFrame write itself was discarded**, the
known "server CFrame write on a player-owned character" trap. Proven rather than inferred:
`ACImmuneUntil` has exactly one writer, and `ensureAllPlayersAlive` does not teleport (it only
calls `SkinService.loadCharacter`), so nothing else could have opened that window.

**The round-END case was the harmless one.** At round START the same failure costs the whole
match — the player stays at the jail spawn, 59 studs under the map — and
`teleportAllToRoundSpawns`' `unplaced` retry **cannot** catch it, because that list only collects
the guard failures; a discarded write still returns `true`.

*Fixed by:* `verifyTeleport`, which re-measures the root against its target 0.35 s later and
repairs only past 30 studs. The healthy path is untouched — the tolerance is loose because the
spawn drops the player 4 studs up, so they are in free fall for the window (~12 studs) and can
sprint another 8, against a measured failure of 119. The repair branches on `Anchored`
(`SetNetworkOwner` **throws** on an anchored part; an anchored root is already server-driven and
takes the plain write) and otherwise takes ownership, rewrites, and hands ownership back
explicitly — retrying for up to 10 s if the root is anchored when the restore comes due, since an
abandoned restore leaves the player server-simulated and feels like permanent lag.
`sendPlayerToJailSpawn` also now warns instead of discarding the `false` return.

**Deliberately not done:** taking ownership unconditionally on every spawn. It would put a brief
server-simulated window on every respawn in the game to fix something rare. *(raised: #25)*
