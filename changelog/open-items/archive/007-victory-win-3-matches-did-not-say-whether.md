# 7 — "VICTORY — Win 3 matches" did not say whether winning meant 1st or top 3

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#7 — "VICTORY — Win 3 matches" did not say whether winning meant 1st or top 3.**
*(Diagnosed and reworded 2026-08-03, **VERIFIED by the owner the same day**. Fixed in Studio,
shipped in [Hotfix 5](../../2026-08-03-hotfix-5.md).)*

**It tracks 1st place only, and that was never ambiguous in code** — `win` and `podium` are two
separate quest types fed by two separate calls in `RoundController` (~line 1310):
`if placement == 1 then track("win", 1) end` and `if placement <= 3 then track("podium", 1) end`.
Only the player-facing copy was unclear.

**The original note in this file pointed at the wrong module — do not repeat that.** It said to
edit `QuestConfig`. The week 1 quest is not there: `QuestConfig.WEEKLY_COUNT = 0`, and the WEEKLY
tab renders **battle-pass** quests, so the quest is `BattlePassConfig` (`w1_laststand`).

**The card's text comes from two files and only one of them is mirrored.** The label
("Win 3 matches") is `BattlePassConfig`, mirrored, two copies. The category heading ("VICTORY")
is a `type` → title map in Bounty's `StarterPlayerScripts.QuestClient`, **Bounty-only and not
mirrored** — anyone retitling a category edits one place, anyone changing a label edits two.

*What changed:* both `win`-type quests were reworded to the phrasing the podium quests already
used, so the two placement objectives now explain each other rather than competing.
`BattlePassConfig` `w1_laststand` → **"Finish 1st in 3 matches"**; `QuestConfig` `d_win_1` →
**"Finish 1st in a Match"**. The daily was not in the report but had the identical ambiguity and
the identical `VICTORY` heading, and it is seen far more often than a once-a-season pass quest.
Ids were deliberately left alone — they are persisted in profile buckets.
Verified byte-identical across both places after the edit (`BattlePassConfig` 21866,
`QuestConfig` 16880, matching checksums) and both compile.

**Card fit was the one thing worth eyeballing, and it checks out** — neither new string
truncates. Low risk by construction, since both are *shorter* than labels already shipping in the
same box ("Finish 1st in 3 matches" is 23 chars against `w3_finisher`'s 34; "Finish 1st in a
Match" is 21 against `d_become_1`'s 25).
