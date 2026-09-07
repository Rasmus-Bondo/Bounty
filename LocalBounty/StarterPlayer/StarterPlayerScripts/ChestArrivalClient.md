---
tags: [client, localscript, ui, lootbox, viewport]
path: game.StarterPlayer.StarterPlayerScripts.ChestArrivalClient
type: LocalScript
lines: 414
---

# ChestArrivalClient

Flies the free chests you earned while you were away from the middle of the screen down into the LOOT tab, and punches the tab as it takes each one.

## What it does
1. **Fires on the free-chest accrual, not on a count.** [[LootboxService]] banks one chest per account level (`owed = Level - LevelClaimed`) on the state push after the player lands in the lobby, and the push carries that number as `earnedPending`. Two situations reach it: returning from a match that levelled you up (the main one — XP is credited in the match place and paid here), and a level landing while you stand in the lobby, since every lobby XP writer ends in `DataService.updateLeaderstats` and LootboxService listens to `PlayerStats.XP`
2. **The count is acknowledged, never read off one push.** `earnedPending` rides on EVERY push until `ChestArrivalSeen` retires it, because the push that banks the chests routinely beats this script to the listener. It also fires `RequestLootboxState` itself rather than relying on ChestController's pull, so it does not depend on that GUI loading. The ack is subtractive, so a level earned while chests are still flying gets its own flight on the next push
3. **A ViewportFrame, not a viewmodel.** The lobby camera is parked between tabs and every effect that borrows it has to hand it back exactly as found. A ViewportFrame brings its own camera and its own scene, so this owes the lobby camera nothing. Clones of `StarterGui.ChestArrivalGui.ChestTemplate` (ScreenGui `DisplayOrder` 35, `ScreenInsets = None`) hold a stripped `ReplicatedStorage.Lootbox.WorkingChest`: parts anchored, and `GlowPart` deleted because a ViewportFrame draws no particles, which leaves it a solid slab wedged under the chest
4. **Camera fit is the XZ diagonal, not the longest side.** The camera orbits in yaw, so the widest the chest can ever project is its diagonal; fitting to the side alone frames it snugly head-on and clips the corners a quarter of the way into every spin. The orbit also starts on the chest's face rather than at world yaw 0 — the slot stores the bounding box's `LookVector` as a yaw offset, so `WorkingChest`'s authored ~40 degree turn no longer decides which side the flight opens on
5. **The flight:** pop in over the middle (Back/Out overshoot from zero), a short hold, then a quadratic curve into the tab whose control point sits under the start and level with the target — so the chest leaves vertically and arrives horizontally, the path it reads as being pulled along. Quad/In easing, shrinking to a fifth and fading over the last quarter, while the camera keeps orbiting. Two pooled viewports, staggered, capped at five flights however many chests were earned
6. **Landing:** the LOOT diamond punches through `UIScale`s named `ChestArrivalPunch` on `Background`, `Icon` and `LootNotifFrame`. Never on the nav cell itself — it anchors at (0, 0) under the UIGridLayout, so a UIScale there grows the diamond down and to the right instead of pulsing in place; its children each anchor at their own centre. MenuHandlerScript owns Size and Position on those children for the hover and never touches UIScale, so the two do not fight
7. **The badge counts up.** ChestController owns `LootNotifFrame` and has already painted it with the new total by the time the chests fly, so this rewinds it to the pre-arrival number and steps back up, one step per landing, always finishing on the total the last push carried. `ChestLand` from `ReplicatedStorage.LootboxSFX` plays per landing, cloned onto SoundService in the `SFX` group
8. **Gates:** waits for `ReplicatedStorage.BountyIntroComplete` (25 s cap, 0.35 s settle) so nothing plays under the loading screen; retires the chests silently if `superPending` is set, because the tutorial's super chest routes the player to the LOOT tab by itself, or if the player is already standing on `2LootFrame` — landing chests in a tab whose chest scene fades the rest of the lobby out reads as a glitch
9. **Coordinate space:** `ChestArrivalGui` and `MainMenuGui` are both `ScreenInsets = None`, which is the only reason a raw `AbsolutePosition` from the nav bar can be handed straight to a Position on this GUI. A pre-layout zero or NaN box falls back to the second of five aspect-locked cells
10. **Studio-only rehearsal:** `K` in the lobby flies three chests with no remote, no ack and no chest consumed. A real run needs an actual level-up on a DEV place, since the accrual is gated on the `LootboxLaunchV1` stamp and no live profile is owed anything yet
11. Feel constants live in one `K` table, the ChestController convention

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `LootboxStateEvent` | ← Server | [[LootboxService]] `earnedPending` (how many to fly), `unopened` + `superUnopened` (the badge total), `superPending` |
| `RequestLootboxState` | → Server | [[LootboxService]] the pull half of the handshake, fired once at load |
| `ChestArrivalSeen` | → Server | [[LootboxService]] retires the chests that have been flown or skipped |

### BindableEvents
None

### Direct require()
None
