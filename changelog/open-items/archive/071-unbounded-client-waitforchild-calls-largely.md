# 71 — Unbounded client `WaitForChild` calls — largely closed 2026-08-03, and the original bullet's inventory was wrong in three ways

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Unbounded client `WaitForChild` calls — largely closed 2026-08-03, and the original bullet's
inventory was wrong in three ways.** It claimed "six on `CameraFolder`" while listing seven paths;
the real count was **eight** (it missed `ReplicatedStorage.Modules.FeaturedSequence:107`, the live
module the dead-UI purge kept when it deleted `CinematicTest`). It placed `BattlePassClient:54` in
**Redwater** — that script is in **Bounty**, and Redwater has no `BattlePassClient` at all, only a
mention of the name in a `BattlePassConfig` comment. And "ten" was never a census: `BattlePassClient`
alone carries ~20 unbounded calls in its first 30 lines. Treat it as a curated list, not a total.

**The eight `CameraFolder` calls are inert and were deliberately left alone.** Verified live:
`workspace.CameraFolder` is `ModelStreamingMode = Persistent` with all 14 `CameraPart*` children
present, so none of them can hang. The "hygiene, no behaviour change" call was correct.

*What was fixed:* `HuntersBuyController:588/1158` re-resolved
`workspace:WaitForChild("CameraFolder"):WaitForChild("CameraPartFeatured")` inline on **every
displayed shop item**, ignoring the `cameraFolder` upvalue already cached at line 122 — and did so
two lines below a `getStandTopPosition()` nil-guard that bails, so the function had a "world isn't
ready, give up" path and then blocked unboundedly right after it. Now cached once as
`featuredCameraPart` beside the other two parts. Bounty `CameraFolder` sites 8 → 6, all six now a
single init-time resolution.

Three client `ReplicatedStorage.Events` sites were bounded to 10s with a guard and a `warn`
(`FriendsInMatchClient:40`, `SettingsController:150`, `GiftPopupClient:11`). **The timeouts had
been on the wrong side** — the three *server* sites (`PlayerSettingsService:134`,
`MouseSensitivityService:25`, `CodeRedemptionService:69`) already passed `, 10` despite facing no
replication at all, while the client ones facing both replication and streaming were bare. The
gain is a diagnostic, not resilience: the failure path was already silent-and-inert either way.

**`LoadingScreen:121` was deliberately NOT bounded — do not "fix" it.** Its inner gates are
unbounded *on purpose* and the comment at line 575 says so: `MAX_HOLD_TIME = 6` caps the reveal
loop at line 644 and `task.delay(MAX_HOLD_TIME + PAN_TIME + 8)` at line 487 is a hard failsafe, so
the veil always lifts. Bounding it would contradict a documented choice for zero behavioural gain.

*Still open:* `QuestToastClient:22` in Redwater (untouched — Redwater was not in scope for this
pass), and the bulk inside `BattlePassClient`, which is not worth a mechanical sweep.
*(raised: [Hotfix 2](../../2026-08-01-hotfix-2.md) — mostly closed 2026-08-03)*
