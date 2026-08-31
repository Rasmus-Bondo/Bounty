# 12 — High Noon locked onto spawn-protected players

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#12 — High Noon locked onto spawn-protected players.** *(VERIFIED in a multi-client playtest by
the owner 2026-08-03. **Shipped in [Hotfix 5](../../2026-08-03-hotfix-5.md).**)* **Never a damage bug** —
`SpawnProtectionService` grants
a native `ForceField` and both High Noon damage paths (`HighNoonDamage:Apply`,
`BotCombat._applyUltimateHit`) go through `Humanoid:TakeDamage`, which a ForceField absorbs, so a
shielded player was already taking zero. The entire cost was in **acquisition**: the target ate one
of the six lock slots and could be the caster's only lock, wasting the ultimate, while the victim
watched lock-on reticles and an execute shot ride an invincible character. The `SpawnProtected`
attribute already existed with **zero readers anywhere in the place**, which is what made this two
lines rather than a new mechanic.

Fixed in both acquisition sites, beside the existing `UltimateUntargetable` (invisible Fortuna)
check that already had exactly this shape: `HighNoonTargeting:FindTargets` for the player (one
filter covers both the 0.08s cone loop and the fire-time `finalScan`, since `HighNoonModule` calls
`FindTargets` for each) and `BotCombat:_ultimateCandidates` for the bot, gated on the existing
`skipUntargetable` flag that only Dust's two scans pass. Protected characters stay in the LOS
ignore list — being unlockable must not also make you a wall.

**Two things that are load-bearing and easy to undo by accident.** The attribute is read **by name**
in both sites, not via a require — `HighNoonTargeting` lives in `ReplicatedStorage` and cannot reach
`ServerScriptService` — so **renaming `SpawnProtected` silently un-fixes this**: nothing errors, the
ult just starts locking shielded players again. And Fortuna's ring and Bram's proximity gate
deliberately still *see* shielded players; their damage is simply absorbed, and filtering them would
change who the ability sees rather than who it can lock.

**Regression checklist if this area is touched again:** ult a player inside their 3s shield (no
reticle, no lock) while a second unshielded enemy in the same cone still locks and executes; have
the shielded player fire once and confirm `onAttack` drops the shield and makes them immediately
lockable; start a lock on someone who then dies and respawns mid-channel (it must not carry into the
new character); and watch a **Dust bot** decline to spend High Noon when a shielded player is its
only candidate.

**Verification technique worth reusing for any spawn-timing bug.** All 43 other spawn points were
temporarily reparented out of `workspace.SpawnPoints`, leaving one marker at `(-0.7, 9.5, -248.4)`
so every respawn landed in a known spot in front of the caster; **all 44 were restored afterwards.**
Three things make one spawn point safe, all checked before doing it: `teleportAllToRoundSpawns`
indexes with `pool[((index - 1) % #pool) + 1]` so it wraps, `getSafeSpawnPool` never returns empty
(last resort is the single deepest-inside spawn — the same point), and `BotService:_spawnPosition`
is a plain `math.random(1, #pool)`. Pick the marker nearest the **zone centre** (Z −250), *not* the
centroid of the spawn layout — that sits at Z −327 and starts feeding players into the closing fire
before the round ends. Expect every player and bot to stack on the one CFrame, and bot patrol to
fall through to `BotPathing`'s random-angle roaming fallback once they are near the only marker.
