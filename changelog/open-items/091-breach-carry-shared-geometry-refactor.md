# 91 — Breach Carry shared-geometry refactor

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**Breach Carry shared-geometry refactor — DONE 2026-08-05 (unverified, unpublished).** Bram's
charge existed in **four** implementations (`BreachChargeService`, `GrudgekeeperClient`,
`BramWorldFXClient`, `BotCombat`) with the *geometry* layer — wall test, clear-space clamp, slam
settle, carry point — hand-copied between them. That is what made a fix in this area land three or
four times, and it was the direct cause of the `_slamPin` concern above, now closed. All four now
call `ReplicatedStorage.Hunters.Bram.BreachCarryGeometry`; see `UNRELEASED.md` for the full entry
and `BREACH_CARRY_SHARED_REFACTOR.md` for the spec, which was updated in place with the divergences
the migration actually found.

The unblocking precondition was met: **#5, #6, #9 and #23** all read `VERIFIED` before this
started, so a playtest regression here is attributable to the migration.

**Four behaviour changes ride along and are the things to watch in a playtest** — the two
`_slamPin` fixes above, a client wall test that had been ignoring `RespectCanCollide` for its
entire life (its cached `RaycastParams` was built first by the ground check, which does not set the
flag), a bot carry clamp that a third-party character in the path turned into a no-op, and — found
by playtest on 2026-08-05, after the migration — the **player**-Bram slam leaving player victims
short of the wall while bots landed flush. That last one was long-standing, not caused by the
migration: the settle was applied on the victim's client behind a guard measured against the
client's own position, which became the *lagging* copy when the server took ownership of carried
players on 2026-08-01. It is now written server-side by the same call the bot branch uses, so both
victim types land on the identical point. Parity
for everything else was proven by an A/B harness: 10,944 wall-test comparisons across the map with
zero mismatches, 4,800 clamp cases, and the settle/carry/plane helpers matching their old inline
forms to within float noise. **`workspace.CHARGEPOINT` no longer exists** — it was deleted from the
Redwater workspace some time after Hotfix 3 — so the two recorded baseline sites could not both be
reused and the sweep was broadened across real map geometry instead. Any future note citing those
ray/sphere percentages should know the site is gone.

**Still open from the spec:** the *Related findings* sweep of the other three hunters for the same defect class, since the
root cause is shared — two findings and one open question, all detailed there:
**Dust's bot block is the only one that hardcodes player-facing tuning** (dash and Fan cooldowns
as literals, where Fortuna, Vesper and Bram bots all read their hunter's config — plus one
probable fan-cadence drift that must be confirmed before it is touched, since the value may be a
validation floor rather than the real rate); **Dust has two independent config tables**
(`RevolverConfig` and `RevolverServerConfig`, no `require` between them), which is *why*, and is
the real fix; and **Vesper bots never use their ultimate** — no `_tryVesperUltimate` exists
anywhere and `BotCombat:TryUltimate` excludes her, with no comment marking it deliberate in a
file that comments its other deliberate bot omissions. **That last one needs an owner decision,
not an implementer's.** *(raised: `_slamPin` standing concern, 2026-08-05)*
