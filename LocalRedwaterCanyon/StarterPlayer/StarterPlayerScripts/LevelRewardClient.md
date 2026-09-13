---
tags: [client, localscript, ui, progression, lootbox]
path: game.StarterPlayer.StarterPlayerScripts.LevelRewardClient
type: LocalScript
lines: 230
---

# LevelRewardClient

Plays the level-up card: a chest flies into a viewport on the left of the screen while the card punches in behind it, holds, and slides back out.

## What it does
1. Listens to `ProgressionEvents.LevelUp` and plays one card per level gained. The remote carries `(newLevel, chestEarned)` — the second argument was added 2026-09-06 for this script
2. Owns `StarterGui.LevelRewardGui.LevelRewardDisplay` (DisplayOrder 8650), imported from the "Bounty - UI Update" prototype's `StarterGui.EyeCandy.Canvas.LevelRewardDisplay`. The prototype's `AnnouncementController` also drove a persistent XP bar in its `In-gameGui`; only the card came across here. The bar was ported separately on 2026-09-13 and is driven by HunterXPBarClient, which stays silent so this card keeps the level-up sound
3. **Two copy states, and neither promises a chest the profile is not owed.** `chestEarned` true → kicker "LEVEL n", title "CHEST EARNED", the chest viewport, and the hint "A new reward is waiting". False → "LEVEL UP" / "LEVEL n" / "Keep it up", the viewport hidden and the text spread across the whole card. It is false for every profile until the lootbox launch arms the free per-level accrual, so pre-launch the card is a plain level-up notice
4. Clones `ReplicatedStorage.Lootbox.WorkingChest` into the viewport's `WorldModel`, anchors every BasePart, strips scripts and Sounds, and `ScaleTo(0.18)`. Missing model → a warn and the plain layout, so the card still fires
5. The chest's flight is a 0.92s eased path driven by a tweened NumberValue: it arrives from `(-6.5, +1.6, -11)` with a 720-degree spin and a sine-arc lift, and `PivotTo` drives its **bounding-box centre** (via `pivot:ToObjectSpace(boundingBox)`) rather than a pivot that sits somewhere inside the crate
6. Landing punch on the card's `ImpactScale` UIScale — 1.14 overshoot, dip to 0.97, settle on 1 — and the card holds `HOLD_TIME` 4.1s before sliding back off
7. Three SFX, all cloned into SoundService and self-destructing: `SFX.Reward.LevelUp` on the card, `Award` as the chest launches, `Award2` on the landing punch. The prototype left these ungrouped; the copies in this place carry the `SFX` SoundGroup
8. **`HIDDEN_X` is NOT the prototype's value.** Its off-screen x was measured inside a 0.70-wide canvas and still left the card 93% on screen, so the entrance read as a pop at the left edge rather than a slide. This one clears the edge by the card's own half-width
9. The card is sized in height-scale with a `CardAspect` UIAspectRatioConstraint (2.0928, ScaleWithParentSize, DominantAxis Height) rather than in scale on both axes. The prototype was drawn against a ~2.45:1 Studio viewport, so its two-axis scale carried that aspect and would squash on 16:9 and 4:3
10. A `token` counter guards every deferred step, so a second level-up landing mid-animation restarts the card cleanly instead of two sequences fighting over it

## Mirror note

Byte-identical to Frostbite Claim's copy (`8691 B` / `274843250`). A Studio-only `L` test trigger
lived here briefly on 2026-09-06 and was removed once the card was signed off, so there is no
known divergence to preserve.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `LevelUp` | ← Server | Fired by [[ProgressionService]] `checkLevelUp` with `(newLevel, chestEarned)` |

### BindableEvents
None

### Direct require()
None
