---
tags: [shared, modulescript, client, ui, mobile, feedback]
path: game.ReplicatedStorage.Hunters.Shared.HunterHudShake
type: ModuleScript
lines: 222
---

# HunterHudShake

Shakes the combat HUD when the local player lands: the HUD canvas bobs, and the five mobile cluster buttons pulse. One entry point, `Play(playerGui)`, called from LandingImpactClient.

## What it does
1. `Play(playerGui)` — the whole surface. Runs the canvas bob and the button pulse; a missing HUD, a PC client with no touch cluster, a nil `playerGui` and a shake already in flight are all absorbed here rather than at the call site
2. **The canvas MOVES.** A decaying vertical bob plus a small X jitter over `DURATION` (0.26s), written as an offset against the `Position` captured when the shake started. The envelope is `(1 - progress)^2` so nearly all the motion is in the first half and it lands exactly on zero; the bob is `sin`, which starts at zero and goes positive, and +Y is *down* in GUI space — so the HUD's first move is a drop
3. **The buttons SCALE.** Each dips to `DIP` (0.06s Quad/Out) and settles back to 1 (0.20s Back/Out), driving the `BreatheScale` UIScale authored under every cluster button
4. Finds the HUD by **structure**, not name — a top-level enabled ScreenGui whose `Canvas` holds both an `AbilityFrame` and an `UltimateFrame`. The live HUD's ScreenGui is named per hunter (`TemplateGameGui` / `FortunaGameGui` / `VesperGameGui` / `BramGameGui`), and StarterGui's copy of the design folder is inside a Folder rather than top-level, so the templates can never be matched by mistake. The same rule HunterIntroTags and HunterMobileSprintButton use
5. Reads the cluster's gui-name list off `HunterMobileClusterLayout.GuiNames` rather than keeping its own, so a sixth button added to the layout cannot be silently left out of the shake

## Two surfaces, two mechanisms — they are not interchangeable
**The canvas can be moved because nothing else owns its position.** The only `Canvas.Position` writers in the place are GunGui's crosshair, the quest toast and the victory showcase, and all three are different ScreenGuis.

**The buttons cannot.** Their `Position` belongs to `HunterMobileClusterLayout`, which rewrites both axes from scratch on every pass. An offset written here would be clobbered mid-shake, or — worse — left behind if a pass landed between the last frame and the restore.

**And the buttons must tween rather than join the same `RenderStepped` loop.** The onboarding lesson breathes a cued cluster button on that same UIScale with an infinite reversing tween, and it stands aside by watching for its own tween to be *cancelled* (TutorialClient's `BUMP_RECOVERY`). Starting a tween triggers that hand-off; a per-frame property write does not, and the two would fight for the length of the shake. The whole pulse is 0.26s, inside the 0.38s the lesson waits before re-arming.

## The rest scale is 1, never a live read
HunterHudBump captures its rest at construction and is right to. This module cannot: it resolves its targets at `Play` time, and if the onboarding breathe happens to be mid-swing the live scale reads up to 1.22 — capturing that would settle the button there permanently. 1 is the authored value on all five and the value TutorialClient itself hands back.

For the same reason it **never creates a UIScale**. Only one per GuiObject takes effect, so a second one added here would either be ignored or silently kill the onboarding cue, depending on which was parented first. `MobileJumpButton` and `MobileScopeButton` had no `BreatheScale` — the lesson never cues those two — so one was authored on each on 2026-08-26 to match the other three.

## Tuning
| Constant | Value | What it is |
|---|---|---|
| `BOB` | 0.007 | Vertical amplitude, as a fraction of the HUD ScreenGui's box |
| `JITTER` | 0.002 | X roughening; moves with `BOB`, never tuned alone |
| `SWINGS` | 1.5 | Down, up, settle |
| `DIP` | 0.96 | How far a button compresses |
| `DURATION` | 0.26 | Canvas motion, and the ceiling the pulse fits inside |

Amplitudes are fractions of the ScreenGui's own box, which is the space `Canvas.Position` is expressed in — so there is no `AbsoluteSize` read and no pre-layout NaN guard, and one number means the same thing on every device.

`BOB` 0.012 and `DIP` 0.92 were the first draft and read as too loud in a playtest. Both are down about 40%.

## A retrigger restarts, it does not stack
A bunny hop lands twice inside 0.26s. Two `RenderStepped` loops would each add their own offset to the same frame and whichever wrote last would leave the HUD off its rest by the other one's offset, so a generation counter invalidates the old loop — and the *newer* shake restores the old rest before capturing its own. The superseded loop deliberately writes nothing on its way out. The buttons need none of this: a new tween on a property cancels the old one, and a cancelled dip declines to settle.

## Dependencies
- **Requires:** [[HunterMobileClusterLayout]]
- **Required by:** LandingImpactClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterMobileClusterLayout]] | `.GuiNames` | The cluster's ScreenGui names, so this module does not keep a second copy of the list |
