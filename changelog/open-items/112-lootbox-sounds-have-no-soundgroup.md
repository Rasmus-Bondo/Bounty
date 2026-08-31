# 112 — Lootbox sounds have no SoundGroup

**Area:** Audio / Bounty · **Sev:** P3 · **Status:** OPEN
**Raised:** 2026-08-13, during the HellFire sound-group sweep

## Symptom

Ten Sounds under `ReplicatedStorage.LootboxSFX` in Bounty carry no `SoundGroup`:

```
BulletMiss   ChestLand   ChestLand2   ChestOpenSound   OpenChestSound
RevolverShot RevolverSpin ShotImpact  WoodImpact       WoodSubImpact
```

All at `Volume 0.5`. There is no `SoundService.Volume`, and "Master" is faked by multiplying into
each of `SFX` / `HitSound` / `Music` — so an ungrouped Sound is reachable by **none** of the four
settings sliders. A player who mutes the game still hears these.

They are the last ten in the experience. After the sweep that raised this, every other Sound across
all three places carries a group: Redwater 108/108, Frostbite 99/99, Bounty 41/51.

## Why it is P3 and not P2

**The only script that references `LootboxSFX` is disabled.**
`StarterGui.LootboxMenu.Canvas.HuntersBuyFrame.CanvasMiddle.BuyHunterFrame.PurchaseFrameRobux.TextButton.ChestController`
is a `LocalScript` with `Disabled = true`, and it is the sole match across all 171 Bounty scripts.
So these sounds almost certainly never play today.

That makes this a landmine rather than a live bug: whoever re-enables the lootbox flow gets ten
unmutable sounds and no reason to suspect why. It is cheap to close now and expensive to diagnose
later.

## Repro

Not reproducible while `ChestController` is disabled. Enable it, open the lootbox flow in Bounty,
set every audio slider to zero, and the chest/impact sounds still play.

## The test that closes it

Set all ten to the `SFX` group — the same group every other weapon and impact sound in the
experience uses — then confirm `ReplicatedStorage` in Bounty reports zero ungrouped Sounds. One
`execute_luau` pass; no playtest needed, because the property either resolves to a SoundGroup or it
does not.

Deliberately **not** done in the sweep that raised this: the owner asked for the lootbox set to be
filed rather than fixed, so that a dead feature's audio is not quietly revived as a side effect of
an unrelated audit.

## Release entry

None yet — not fixed. The sweep that found it is in `changelog/UNRELEASED.md` ("35 revolver sounds
were reachable by no volume setting at all").
