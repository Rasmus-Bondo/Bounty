---
tags: [client, localscript, ui, release, diagnostics]
path: game.StarterPlayer.StarterPlayerScripts.VersionTagController
type: LocalScript
lines: 225
---

# VersionTagController

Draws the always-visible build tag in the top-right button row, immediately left of the settings gear. Identical copy must exist in both places — edit both together.

## What it does
1. Requires [[GameEnvironment]] and reads `buildString()` — the human version plus the live place version, e.g. `Hotfix 3 r2084`
2. Creates its own `VersionTagGui` ScreenGui in PlayerGui with `DisplayOrder = 1000002` and `ResetOnSpawn = false` — the highest order in the place, above MatchCompleteGui's 1000001 and the open settings panel's 100001 — so no menu can cover it and nothing that bulk-toggles StarterGui children can switch it off
3. Adds a single `AutomaticSize` TextLabel anchored on its own right edge at `(1, 0.5)` — sized exactly to its text, so there is no invisible box over the corner, and the string grows *leftward* away from the buttons as the version gets longer
4. Renders dim white (`TextTransparency = 0.35`) over a fully opaque black `TextStroke`, which keeps it legible against both Redwater's pale sky and the dark lobby
5. Scales `TextSize` off `Camera.ViewportSize.Y` against a 700-stud desktop reference, clamped to 7–15. Rebinds the viewport listener whenever `workspace.CurrentCamera` is replaced — spectating, kill cams and respawns swap the camera outright, and a connection left on the old one would stop firing silently
5a. **Touch devices take a further ×0.8 cut with a lower floor of 6** (`MOBILE_TEXT_SCALE` / `MOBILE_MIN_TEXT_SIZE`, added 2026-07-30). The height scaling alone landed phones at 7–8, which still read larger in the hand than the same figure does on a monitor. Measured effect: a 418-tall phone goes 8 → 6, a 440-tall phone 8 → 7, an iPad 15 → 12; desktop is untouched at every width (a windowed 614 stays 11, 1080p stays 15) because the branch is gated on `TouchEnabled`, not on viewport size. **The floor of 6 is a deliberate trade against the tag's own purpose** — the desktop floor of 7 exists because below it the stamp stops surviving JPEG recompression in a Discord bug report, which is the entire reason the tag is on screen. Raise `MOBILE_MIN_TEXT_SIZE` first if bug screenshots start coming back unreadable
6. `TouchEnabled` is read inside `applyScale` rather than resolved once at load, so Studio's late emulator flip corrects itself on the next re-run. It drives **both** the text size and the horizontal offset

## Placement
Moved out of the top-left corner on 2026-08-03: the Roblox chat window opens there and covered the tag outright in both places. That corner belongs to the engine and can be taken away at any time, which makes it the worst possible home for a stamp whose whole job is to be in a bug screenshot.

The tag now hangs off the **left end of the top-right button row**, which is the only space in that corner free on both platforms:

| Neighbour | Extent from right edge | Present on |
|-----------|------------------------|------------|
| `ReworkedSettingsGui.SettingsButton` | 44×44 at y 10, right edge −10 → **54px** | both places, all devices |
| `MobileStatsButton` (created by StatMenuScript) | 60×44 at y 10, right edge −62 → **122px** | Redwater, touch only |

So `RIGHT_CLUSTER_GEAR = 54` / `RIGHT_CLUSTER_GEAR_AND_STATS = 122`, plus `EDGE_PAD = 8` — the same resolve-from-platform pattern QuestToastClient uses for its own X clamp. Those buttons are pinned in **pixels**, so the strip they occupy grows as a fraction of the screen as the viewport narrows; an X authored in scale that clears them on a monitor slides underneath them on a phone.

`ROW_CENTRE_Y = 32` is the row's vertical centre, copied from the buttons (y 10, height 44).

**Directly under the gear was rejected.** KillFeedClient owns that band — its frame's top edge is 60px down on touch and 96px on desktop, and rows stack *upward* into the corner as kills come in.

### The wide offset is Redwater-only
The Stats button exists only here — Bounty's top-right holds nothing but the gear on every device (audited 2026-08-03: no lobby script pins anything else into that band on touch). Keying the wide offset on `TouchEnabled` alone therefore stranded the lobby tag 68px from its gear on a phone with empty screen in between, so it is gated on the place as well:

```lua
local HAS_TOUCH_STATS_BUTTON = GameEnvironment.place ~= "Bounty"
```

Resolved from the **place**, not by looking for the button. `StatMenuScript` creates it with a runtime `Instance.new`, so a probe would either race it or have to watch for it and visibly jump the tag once it appeared. `GameEnvironment.place` comes from `game.PlaceId`, is settled before that line runs and cannot change mid-session — which is exactly why it is resolved once at load while `TouchEnabled` is re-read on every `applyScale`.

Anything that is not Bounty — including `"Unknown"`, if a place id ever falls outside the `ENVIRONMENTS` table — takes the **wide** offset. Sitting 68px further left than needed is a cosmetic gap; sitting underneath a button is a tag nobody can read. If Bounty ever gains a top-right button of its own, this is the line to revisit.

Net result: **62px in on desktop in both places, 62px on touch in Bounty, 130px on touch in Redwater.**

### ScreenInsets = None, and why that is safe here
`ScreenInsets.None`, matching ReworkedSettingsGui, StatMenuGui and KillFeedGui.

That enum value has a bad name in this file — it was tried **twice** while the tag lived top-left and shipped broken both times (2026-07-30), along with a negative-X-offset attempt that a ScreenGui simply clipped, eating the first four characters of the build string on device. But the thing that broke was never the enum. `None` drops the topbar inset along with the device inset, and there is no "clear the topbar but not the device band" value, so the top-left placement had to **re-derive** its vertical offset by hand from a number that reads **0 in Studio** (`GuiService:GetGuiInset().Y`, or a `CoreUISafeInsets`-vs-`None` probe delta). A wrong value there looks perfect locally and is only caught on a handset; both attempts dropped the tag onto Redwater's BOUNTIES panel.

Nothing is derived now. Y is 32 because the neighbouring buttons are at y 10 and 44 tall; X is measured back from the same right edge they are pinned to. Those buttons live in this same inset space and are field-proven in it on real devices, so the tag inherits their correctness instead of recomputing it. Putting this GUI in a *different* space would be the actual bug — geometry in two inset spaces cannot be aligned to each other, and on a notched phone `CoreUISafeInsets` would strand the tag 62px inboard of the buttons it is meant to sit beside.

Verified in the device simulator at three viewports, gap to the cluster exactly 8px in every case: 1658×678 desktop (label x 1517–1596, gear left edge 1604, kill-feed line 58px clear), iPhone 16 Pro Max landscape touch (label right edge 8px left of the Stats button, bottom 25px above the kill-feed line), and a 640×480 windowed PC (label left edge still 81.5% across the screen).

## Why it scales rather than using a fixed size
Roblox reports phone viewports at 360–440 studs tall against 720–1080 for desktop, so a flat 13px was ~1.2% of a 1080p screen but ~3.6% of a phone's — the identical tag read as a discreet stamp on a monitor and an intrusive banner in the hand.

**Tuned twice against real handsets.** The first pass (620 reference, floor of 9) was still too large on a phone, because the *floor* rather than the scaling was setting phone sizes — every phone clamped to 9 regardless of viewport. The 700/7 values land every phone and tablet between 1.79% and 1.94% of screen height against desktop's 1.39%, closing a gap that started at 3× down to 1.4×, and let phones genuinely vary (7 on a 360-tall Galaxy A06, 8 on a 440-tall iPhone 16 Pro Max).

7 is about the practical floor: below it the tag stops surviving the JPEG recompression of a Discord bug report, which is the entire reason it is on screen. The ceiling of 15 stops it creeping into frame on a large monitor.

## Why it is always on screen
A bug screenshot is taken at the moment the bug happens. Putting the version behind the settings menu means players usually don't fetch it, and the panel covers the very thing being reported.

The GUI is built in code rather than authored in StarterGui so that it can be checksum-compared against its mirror the way the shared config modules are; an authored instance tree would drift silently.

## Dependencies
- **Requires:** [[GameEnvironment]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `GameEnvironment.buildString()` | Version + place version string for the tag |
