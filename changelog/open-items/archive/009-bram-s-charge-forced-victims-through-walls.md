# 9 — Bram's charge forced victims through walls, floors and out of the map

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#9 — Bram's charge forced victims through walls, floors and out of the map.** *(VERIFIED in
multi-client playtest by the owner 2026-08-01/02, shipped in
[Hotfix 3](../../2026-08-03-hotfix-3.md).)* Four independent causes, each masking the next; all four
are written up in the release entry. Follow-ups also closed: wall detection widened to ray **OR**
spherecast in all three implementations (playtested and accepted 2026-08-02), and a player
carried by a *bot* Bram is now combat-locked too, via a refcounted pin inside `HunterActionLock`.

**Ruled out — do not re-derive:**
- *"It is a physics push, not a teleport."* A capture showing 0 teleports over 4 studs was a
  threshold artefact; a frame-accurate trace showed `maxStep = 4.89` and `botDist` locking to
  exactly `CarryDistance` for consecutive frames. It is a carry teleport.
- *`_rayParams()` excluding the `WallMap` folder.* Plausible and wrong — only 1 part within 14
  studs is in `WallMap`, and a spherecast sweep hit 72/72 headings with it included *or* excluded.
- *`ActiveBreachPin` as a pin signal.* A Lua field on the combat object, not a Roblox attribute;
  reads nil from outside.
- *`StatusPinnedUntil` as a pin signal* — true when written, **no longer**. `BotCombat._pinVictim`
  never set it, so it read nil for every bot charge. That gap was itself real and was fixed
  2026-08-02; it is a usable bot-charge diagnostic from that date onward.

**Two properties that are load-bearing and easy to undo by accident:** the slam settle is small
*on purpose* (`SlamWallClearance` 2, measured back from the wall face — character geometry
reaches 1.32–1.73 studs forward of the root, so 2 is flush contact with a margin), and it is a
push **back** only, never a pull forward — `WallVerifyDistance` is a generous 18, so an
unconditional teleport would drag a safe victim *onto* a wall they were clear of.
`CarryLaneSpacing` was tuned 3.5 → 1 deliberately; **do not raise it for "safety"** — the clamp
is what makes it safe, not the gap.
