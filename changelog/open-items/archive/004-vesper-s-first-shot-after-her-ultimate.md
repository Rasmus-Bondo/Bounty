# 4 — Vesper's first shot after her ultimate was silent

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#4 — Vesper's first shot after her ultimate was silent.** *(Fixed 2026-08-04, **VERIFIED by the
owner the same day**. In Studio, **not yet published** — it ships in the next release alongside
#3.)*

**Not a Sound problem at all — a flag that leaked**, and unrelated to #3 (see above). The standing
note guessed at an unloaded or ungrouped Sound from a viewmodel swap; nothing swaps, and the sound
was never the thing that broke.

`VesperViewModelAnimationClient` set `suppressNextNormalShotSounds = true` on `UltimateShotFired`,
and the **only** place that cleared it was the `AmmoChanged` handler. But Starfall spends its own
shot pool and deliberately freezes the magazine, so `AmmoChanged` never fires for an ultimate shot —
`SunspikeClient` already documents that exact fact where it hand-kicks auto-reload at the end of the
window. The flag therefore survived the ultimate and was consumed by the player's **next basic
shot**, which played its animation with no rifle report. Exactly one shot, matching the report.
Coming out of the ult dry did not help: the auto-reload raises ammo, and the handler only reacts to
a decrease.

**The same defect had a second, unreported half.** `playShotSequence`'s comment states the intent —
*"Starfall shots keep this same animation sequence but provide their own dedicated layered sound in
SunspikeClient"* — but since `AmmoChanged` never arrived, the sequence never ran for an ultimate
shot, so **the ult shot played no viewmodel shoot/bolt-cycle animation at all.**

*Fixed by:* deleting the flag and having `UltimateShotFired` call `playShotSequence(false)`
directly. Both triggers now drive the sequence themselves. Timing needed no adjustment —
`SunspikeClient` gates basic and ultimate fire on the same `BasicConfig.Cooldown`, which is what the
sequence stretches to.

**The bolt-cycle layer is now audible during Starfall, and that was accepted rather than
overlooked.** `SniperReloadRefresh` is part of the sequence; only `SniperShoot`/`SniperShoot2` are
gated, which is what the suppression was always scoped to. Nobody had heard the cycle during
Starfall before, because the sequence never ran. Gating it as well is a one-line change if it ever
reads as cluttered under the layered ultimate report.

**Regression checklist if this area is touched again:** fire Starfall to its last shot and confirm
the next basic shot has its report; confirm the ultimate shots animate and the bolt-cycle layer sits
acceptably under `playUltimateShotSounds`; swap away from Vesper mid-match and back, then repeat —
the teardown path was untouched but the handler it feeds changed.
