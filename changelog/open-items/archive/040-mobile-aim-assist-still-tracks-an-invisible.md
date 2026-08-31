# 40 — Mobile aim assist still tracks an invisible Fortuna

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Mobile aim assist still tracks an invisible Fortuna** (raised: Hotfix 9, 2026-08-06).
`AimAssistController` has no stealth check of any kind — the same blind spot the bots had, on the
player side. It is the *only* remaining consumer of a character's position that does not ask
`HunterCharacterUtil.IsStealthed`, so a touch player's aim will still snap onto her through the
whole 2.1s of her ultimate. Arguably worse than the bot version was, since it is auto-aim onto a
target the player genuinely cannot see, and it is the half of the game that most players are on.

**Deliberately deferred by the owner** when the bot fix shipped, not overlooked. The predicate and
the precedent both exist now, so the change is small: gate assist-target selection on `IsStealthed`
the way `BotBrain._targetCandidates` does. **The open question is what "assist drops her" should
feel like**, and it is not the same question the bots answered — a bot losing its target reads as
the bot being fooled, whereas assist releasing mid-drag reads as the controls breaking. Whether it
should hard-drop, decay the pull, or hold the last known point (as `_fight` does) is a feel call
that wants a real handset, which is why it was not guessed at here.

Note the bot fix does **not** partially cover this: bots and aim assist share no targeting code.
