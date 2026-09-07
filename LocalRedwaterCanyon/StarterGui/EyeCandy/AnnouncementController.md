---
tags: [client, localscript, ui, combat, announcement, audio, rewards]
path: game.StarterGui.EyeCandy.AnnouncementController
type: LocalScript
lines: 937
---

# AnnouncementController

The centre-screen combat surface, and since 2026-09-07 the only place a personal reward is reported: the `ELIMINATED <NAME>` line with its killstreak word, a sub-line for whatever else landed in the same beat, the running `+CASH` / `+XP` pair, and the `BOUNTY CLAIMED` header slam.

## What it does
1. Resolves five authored labels in `EyeCandy.Canvas` — `HeaderAnnouncement` (screen y 0.150..0.258), `MainAnnouncement` (centre y 0.643), `SubAnnouncement` (0.669), `RewardAnnouncementCash` (0.690, or 0.706 when a sub-line is showing) and `RewardAnnouncementXP` (0.727 / 0.738). All Teko SemiBold, `TextScaled`, `RichText`. The three lower labels were cloned across from the prototype rather than re-typed, per UI_STYLE_GUIDE 1.1.
2. **A beat is the unit of display, not an event.** One moment of combat — the kill, plus whatever else was credited in the same breath, plus the running totals for all of it — shares one card. `startBeat` opens it, `extendBeat` folds a later event into the card already on screen, and one `fadeStack` takes the whole thing away.
3. **`KINDS` maps every reward kind to a verb and a priority.** `kill` (5, "ELIMINATED") > `bounty_survived` / `domination_capture` / `tutorial_step` (4) > `domination_neutralise` (3) > `assist` (2, "ASSISTED ON") > `domination_defend` / default (1). Inside a beat the higher priority owns the main line and the other drops to the sub-line, which is how a kill and the assist or objective defence that share its instant read as `ELIMINATED X` over `ASSISTED ON Y`.
4. `bounty_claim` is in `REWARD_ONLY_KINDS` and takes no line at all: `BountyClaimed` is already slamming `BOUNTY CLAIMED` across the header on the same instant and the kill owns main, so it contributes only its numbers.
5. **Rewards accumulate rather than replace.** The first numbers of a beat punch in showing their total (`showRewards`); later ones fly in as a `+7 CASH` flyer while the line's own figure counts up to meet it over 0.42s (`flyDelta` / `addRewards`). Cash and Tokens share the upper line — only the onboarding instalment ever pays Tokens, so the two cannot contend.
6. Multi-kill: `MULTI_WINDOW` 8s, counted client-side. A second kill inside a live beat retexts main with the new streak word from `killWord` and lets the totals climb rather than restarting the card; the kill stinger is pitched `1 + min(killCount-1, 8) * 0.065` and `shakeAnnouncement` runs at streak >= 2.
7. `showHeader` drives the header slam — `animateHeader` flies two header clones in from x -0.1 and x 1.1 to collide at centre, and `createImpactFlare` fires a light bar out of the impact. Used for `BOUNTY CLAIMED` (with the stinger) and `BOUNTY ON YOU` (without).
8. **Notices** carry the two rows the retired feed held about *other* players — `X IS ON A SPREE`, `X TOOK DOWN Y`. They never interrupt the player's own beat: one is held in a single pending slot and shown when the card clears, and a notice that has waited longer than `NOTICE_STALE_AFTER` (6s) is dropped rather than arriving late.
9. `playSfx` clones the template to `SoundService` and self-destructs on `Ended`, with a `max(TimeLength + 1, 8)` backstop because `Ended` never fires for a sound whose asset failed to load. `playBountyStinger` is separate: the 12.33s asset is held 2.6s then faded over 0.7s so it ends with the header rather than running over the next two kills.
10. Killstreak resets on the local `Humanoid.Died` and on any `RoundActive` change. `RESET` clears both counters, all five labels and any orphaned `_HeaderImpactClone` / `_HeaderImpactFlare` / `_RewardFlyer` / `_RewardTrail`.

## Fade ownership, and why a new row used to show nothing

**A generation token only ever guards a pending `task.delay`. It does not stop a tween that has already started.** `fadeTweens` holds the fade currently running on each label so it can be cancelled, `wake(label)` cancels it and restores full opacity, and `hideLabel` cancels it and hides. Every path that writes text to a label goes through one of them.

This is the second bug the owner reported, and it is a different mechanism from the stuck text above. A row arriving during the stack's 0.5s fade was written correctly and then faded out anyway, because the fade tween was still interpolating that label to `TextTransparency` 1 and a raw property assignment made mid-tween is overwritten again on the next frame. Confirmed in isolation rather than assumed — an edit-mode probe on a throwaway label: assigning transparency 0 mid-tween ends at **1.000**, cancelling first ends at **0.000**.

Starting a *new* tween on the same property does cancel the old one, which is why the paths that call `punchIn` happened to survive and the ones that only assigned text (the multi-kill retext, the sub-line retext, `flyDelta`'s count-up) did not. That is far too subtle to keep relying on, hence the explicit ownership.

`beat.fading` is the other half. It is raised the instant the stack *starts* fading, not when it finishes, and a new event arriving in that window gets a **fresh card** rather than being folded into one that is leaving — otherwise a stale main line would sit above the new row. A kill continuing a streak still carries its running totals across the boundary, because the 8s multi-kill window is more than twice the 3.4s the card is up, so the second kill of a double lands on a fading card more often than not.

## Two tokens, and why the text used to stick

`stackToken` and `headerToken` are separate generation counters. They were a single `displayToken` until 2026-09-07, and that was the cause of the reported stuck-text bug: a bounty kill fires the kill announcement and the header within the same frame, so whichever ran second bumped the shared token and the first one's pending fade failed its `token ~= displayToken` check and returned — leaving its label on screen until the next round boundary. Independent events need independent clocks.

`extendBeat` still bumps `stackToken` even though the card on screen is unchanged, because the beat's previous fade is already armed on the old token and would fire at the original deadline, hiding the addition that just landed. The `beat` table carries the card's identity; the token only ever gates a pending fade or shake.

## Scope

It is now the **whole** personal-reward surface. `CombatFeedClient` is `Disabled` (2026-09-07, owner's call) and every row it carried — eliminations, assists, objectives, bounty rewards, the spree bonus, the tutorial instalment and the two bounty notices — arrives here instead. `COMBAT_FEEDBACK_SPEC.md` section 0 records the reversal of the earlier "the feed owns the numbers" decision.

Suppressed wholesale while `workspace.TutorialMode` is set, read per event rather than at boot because a live server resolves the mode from MemoryStore after this client starts. `tutorial_step` is the one kind exempt from that gate — it is the feedback for the thing the lesson's banner just asked the player to do. `RESET` is exempt too so the counter still clears.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `CombatReward` | ← Server | [[ProgressionService]] `fireCombatReward(player, kind, xp, cash, tokens, subject)` — the single wire for every reward kind, and since 2026-09-07 it carries the victim name as `subject` so the line and its numbers arrive together |
| `BountyClaimed` | ← Server | [[BountyService]] `FireAllClients(killerName, victimName, killerUserId, ...)`; the header when `killerUserId == player.UserId`, a notice otherwise |
| `BountyPlaced` | ← Server | [[BountyService]] `FireAllClients(targetName, targetUserId)`; a notice about everyone else's bounty. Your own arrives as the `bounty_placed` reward kind instead |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `AnnouncementEvent` | ← / → | `EyeCandy.AnnouncementEvent`, its own sibling — the single manual entry point, so a throwaway button or an `execute_luau` fire drives the whole surface without a test panel |

### Direct require()
None.

## Notes
- `DisplayOrder` 8700, unchanged. The feed it used to sit above (8500) is retired; the kill cam (9500) still covers it.
- **It no longer listens to `HitConfirm`.** `ProgressionService.awardKill` is the crediting authority and fires on every credited kill, including ones the hit pipeline never sees, so driving the line from `CombatReward` cannot under-report — and it ends the two-event race for one card. DamageNumberClient still uses `HitConfirm` and is untouched.
- **Placement is the prototype's**, screen y 0.643..0.738, chosen by the owner on 2026-09-07 over lifting it above the crosshair, which a four-line stack no longer fits above.
- **The whole stack drops by `STACK_DROP` and Domination's capture bar lifts to meet it, on every device** — owner's call after playing Domination, where the bar sat square on the top line. Capturing pays a reward, so the two were on screen together on every capture. Positions are resolved by `resolveLayout()` rather than being constants.

  **The test is `TouchEnabled`, and it is a test of WHICH HUD IS ON SCREEN, not of device class.** The floor is the whole constraint and the two HUDs differ: `ReworkedHunterGui.ScreenGui` paints from `0.777` of height, `HunterGuiMobile` from `0.830`. A tablet runs the mobile HUD and therefore wants the touch profile — which is why the first attempt, gated on `height >= 500`, was wrong twice over: it grouped tablets with desktop and read the wrong floor for them, and it excluded phones on the belief they had no room.

  | profile | stack drop | bar y | verified on |
  |---|---|---|---|
  | desktop (`TouchEnabled` false) | 0.017 canvas units | 0.568 | 1658x678 |
  | touch (phones and tablets) | 0.075 canvas units | 0.5936 | 705x338 |

  **Phones do have the room**, which is the correction that made the touch profile possible: measured on 705x338 there is 99.9px between the crosshair dot (ends 180.5) and the first *painted* mobile-HUD pixel — `AmmoCount` at 280.4, **not** the canvas top at 272.8 — against the 83px the bar, its gap and the four-line stack need. Same trap as the desktop HUD, where the bounding box hid 0.010 of height.

  Both profiles were verified by applying the moves and re-measuring rather than by arithmetic. Desktop: bar `0.5321..0.6039`, main top `0.6154`, stack bottom `0.7714`. Touch: `+8.0px` below the crosshair dot, `+8.0px` below the bar, `+6.9px` above the HUD.

  DominationClient runs the **same touch test** and lifts the bar to meet this; the two are one layout and must be changed together.
- The `SwapHunterFrame` prompt (0.709..0.795) still shares the stack's band. It is a transient mid-match prompt rather than a permanent HUD element, and was not part of the Domination fix.
- **`playSfx` did not call `sound:Play()` between 2026-09-06 and 2026-09-07.** Parenting a Sound to `SoundService` does not start it. The line was dropped when the prototype's helper was ported, so **every cue routed through `playSfx` — kill, assist, reward — was silent for the whole life of the feature.** Fixed 2026-09-07.

  It presented as a mixing problem and is worth remembering as one: `playBountyStinger` has its own player and its own `:Play()`, so the bounty header kept working throughout. One cue audible and three not reads as "those three are too quiet", and two rounds of volume raising were spent on it before anyone read the helper. **`SoundService` is where a dead Sound goes to look alive** — it is parented, grouped, `IsLoaded`, has a `TimeLength`, and is doing nothing. When a cue is inaudible, confirm `:Play()` is reached before touching a level.

  `Sound.PlaybackLoudness` is not the way to check this from edit mode — it reports 0 for every sound there, playing or not, so it cannot tell a silent asset from a healthy one.

- **Cue levels, set by ear once they were audible.** `KillEffectSound`, `Assist` and `Reward.Award` at **1.2** — effective 0.6 through the 0.5 `SFX` group. They were briefly at 2.0 (effective 1.0, matching the `GunGui.HeadshotSound` hitmarker), which the owner judged a little too loud on the first playtest where they actually played. `Reward.Bounty` stays at its shipped 0.5. All three move together because they share `playSfx` and were all at one level; if the kill sting later needs to sit above the other two — it is the only one that fires under the gunshot that caused it, where the others land in relative quiet — split them rather than moving all three.
- If a cue turns out to be wrong in **character** rather than level, `SFX.Fight.KillSound` (`124954333259876`, 3.79s) sits in the same folder wired to nothing and the swap is one property. The current kill asset is a 4.22s tail, so volume raises its wash as much as its impact.
- The prototype's XP bar, level-up and chest reel are cut, not stubbed. They hard-required `PlayerGui["In-gameGui"].Canvas.PlayerFrame.PersistentXPBar`, which does not exist here — the match HUD is `ReworkedHunterGui.ScreenGui` — so those `WaitForChild` calls would have hung the whole script. The chest half shipped separately as LevelRewardGui.
- BountyMusicClient's own claim stinger is retired behind a flag so the two do not overlap on the same event.
