---
tags: [client, localscript, ui, combat, announcement, audio]
path: game.StarterGui.EyeCandy.AnnouncementController
type: LocalScript
lines: 415
---

# AnnouncementController

Drives the centre-screen combat moment: the `ELIMINATED <NAME>` title line with its killstreak word, and the `BOUNTY CLAIMED` header slam.

## What it does
1. Resolves the two authored labels in `EyeCandy.Canvas` — `MainAnnouncement` (screen y 0.306..0.384) and `HeaderAnnouncement` (screen y 0.150..0.258) — plus the Studio-only `AnnouncementTestController` panel. Both labels are Teko SemiBold, `TextScaled`, `RichText`.
2. Everything dispatches through the sibling `AnnouncementEvent` BindableEvent, so the three live triggers and the test panel share one code path and one suppression gate. Actions: `ELIMINATED`, `BOUNTY`, `ASSIST`, `RESET`.
3. `showElimination(victimName)` — advances the client-side multi-kill counter (`MULTI_WINDOW` 8s), plays the kill stinger pitched `1 + min(killCount-1, 8) * 0.065`, writes `richLine` (white verb, `#F6E525` name, white streak word from `killWord`), then `punchIn` (slides in from +85px, overshoots, settles). At streak >= 2 it also runs `shakeAnnouncement` — `min(2 + (streak-2)*0.7, 5)` over 7 frames.
4. `showBounty(headerText)` — plays `SFX.Reward.Bounty` through `playBountyStinger`, then `animateHeader`: two header clones fly in from x -0.1 and x 1.1, collide at centre, and `createImpactFlare` fires a light bar out of the impact.
5. A `displayToken` generation counter guards every pending fade, so a newer announcement cancels an older one's `task.delay` instead of being hidden by it.
6. `playSfx` clones the template to `SoundService` and self-destructs on `Ended`, with a `max(TimeLength + 1, 8)` backstop because `Ended` never fires for a sound whose asset failed to load.
7. `playBountyStinger` is separate: the 12.33s asset is held 2.6s then faded over 0.7s, so it ends with the header rather than running over the next two kills.
8. Killstreak resets on the local `Humanoid.Died` and on any `RoundActive` change (round start and intermission both clear it).
9. `RESET` clears the counter, both labels and any orphaned `_HeaderImpactClone` / `_HeaderImpactFlare`.
10. The test panel is `Visible = RunService:IsStudio()` and offers ELIMINATE / BOUNTY / RESET. Its authored `Visible` is `false` so it never flashes on a live client.

## Scope

It shows the **title line only**. Every `+XP` / `+cash` row stays in the right-hand combat feed, which owns the ledger — the prototype announced the same kill in both surfaces at once. Assists get the sound and their existing feed row, but no banner: no assist-side event carries the victim's name.

Suppressed wholesale while `workspace.TutorialMode` is set, read per event rather than at boot because a live server resolves the mode from MemoryStore after this client starts. `RESET` is exempt so the counter still clears.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `HitConfirm` | ← Server | [[HunterHitPipeline]] fires it for every weapon; [[HighNoonDamage]] fires its own for Dust's ultimate. Only `didKill` triggers an announcement — the victim name rides the same payload as the damage number |
| `BountyClaimed` | ← Server | [[BountyService]] `FireAllClients(killerName, victimName, killerUserId, xp, cash, victimUserId)`; gated on `killerUserId == player.UserId` |
| `CombatReward` | ← Server | [[ProgressionService]] `fireCombatReward`; only `kind == "assist"` is read, for the assist sound |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `AnnouncementEvent` | ← / → | `EyeCandy.AnnouncementEvent`, its own sibling — the single dispatch point for the three remote listeners and the test panel |

### Direct require()
None.

## Notes
- `DisplayOrder` 8700 — above the combat feed it narrates (8500) and below the kill cam (9500) that should cover it.
- The main line was raised out of the prototype's screen y 0.643. There it ran into the mobile button cluster on every 4:3 viewport, and sat exactly on Domination's capture bar (screen y 0.608..0.680).
- The prototype's XP bar, level-up and chest reel are cut, not stubbed. They hard-required `PlayerGui["In-gameGui"].Canvas.PlayerFrame.PersistentXPBar`, which does not exist here — the match HUD is `ReworkedHunterGui.ScreenGui` — so those `WaitForChild` calls would have hung the whole script before a single announcement.
- BountyMusicClient's own claim stinger is retired behind a flag so the two do not overlap on the same event.
