# 131 — Bram's first-person shoot throws the arms and gun too high

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Status:** FIXED (partially verified) · **Sev:** P2 · **Area:** Redwater Canyon + Frostbite Claim — Bram first-person viewmodel

**Raised 2026-08-29** by owner playtest, during the animation-system Tier C work. Being worked in a
separate session as of the same day.

**Symptom.** Firing Bram in first person throws the arms and the Grudgekeeper upward far enough to
read as unnatural. First described as "in between shots where he cocks another bullet"; on a second
look it is the shoot motion itself, on every shot.

**Repro.** Play Bram in either match place and fire. Visible every shot; no skin, mode or device
dependency found.

**Fixed 2026-08-29 in code, per the owner decision below** — the procedural `BramShotgunKick`
recoil was deleted and the Shoot clip is now cut at 0.30 s, before its pump beat. Diagnosis and
rollback are in the release entry (`UNRELEASED.md`, Fixed). Owner playtested and accepted the look
at the normal 0.5 s cadence. **Still open for the other half of the closing test:** Last Call's
0.25 s cadence, and the Frostbite Claim copy.

**Ruled out, so the next pass does not repeat it** — this is the only record of these measurements
until a release entry carries the fix:

- **Not the clip ids and not the Tier C migration.** `Animations.Viewmodel` matches the default rig
  *and* the `FrostbiteGrudgekeeper` rig id-for-id in both places, with zero `Animations.Skins`
  overrides, so the migration hands the Animator exactly the clip the rig used to hand it.
- **Not the playback timing.** Scaling the clip to the firing cadence was tried on 2026-08-29 and
  reverted the same day; it changed nothing the owner could see.
- **Measured on the rig** (Animator stepped in edit mode, peak Y relative to the idle pose, rig
  scale): the current clip `93041883597128` lifts the gun **+1.96
  studs at 0.48 s** (RightArm +0.89, LeftArm +1.62). The clip it replaced, `78350631756950` in
  `ServerStorage.Unused.Grudgekeeper.BackupDefaultBram`, moves it **−0.02**. Played at `Core`
  instead of `Action2` — i.e. blended with the looping Idle rather than overriding it — the same
  clip shows exactly **half** the lift, so amplitude here is a question of blend weight as much as
  of authoring.
- **The "divide by ~13.9 for in-game" scaling in the line above was wrong** and made these numbers
  read ~14x too small; corrected 2026-08-29. The template measures `GetScale()` **1.019** in both
  match places against `VIEWMODEL_SCALE = 1`, so authored poses play at essentially 1:1. The 13.9x
  figure traces to a stale comment beside the `ScaleTo` call in `GrudgekeeperClient`.

**Test that closes it:** fire Bram in first person in both match places, at the normal 0.5 s cadence
and during Last Call's 0.25 s, and confirm the gun stays framed the way the other three hunters' do;
`HunterViewmodelContract.Report()` still reads 0 fail / 0 warn in both places afterwards.

**Owner decision 2026-08-29: no replacement clip is coming** — the fix is in code, not art.
