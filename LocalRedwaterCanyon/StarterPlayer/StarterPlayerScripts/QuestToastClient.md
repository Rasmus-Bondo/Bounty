---
tags: [client, localscript, quests, ui]
path: game.StarterPlayer.StarterPlayerScripts.QuestToastClient
type: LocalScript
lines: 345
---

# QuestToastClient

Animates the authored `QuestCompleteNotification` panel when the player completes a quest during gameplay.

## What it does
1. Listens to `QuestCompleteEvent` from the server
2. Normalises the payload — a `{ title, objective, goal }` table, or a bare string as a legacy fallback — into a title line plus an objective line suffixed with the completed `goal/goal` count
3. Queues incoming completions (multiple quests can complete at once) and plays them sequentially with a 0.15s gap
4. `fitWidth()` re-sizes the Canvas width per toast to its own longest line, measured with `TextService:GetTextBoundsAsync`, so a short objective does not sit in a half-empty panel
5. `refreshLayout()` honours the authored X per toast, clamping it only so the panel clears the pixel-pinned top-right buttons on a narrow viewport
6. Drives the panel through a slide-down + scale-pop entrance (Quint/Back easing), a 3s hold, and a slide-up + shrink exit (Quart easing)
7. Collects every transparency in the panel at startup and drives them all from a single NumberValue tween, so the fade stays in sync with the slide and survives edits to the art
8. Stamps the "QUEST COMPLETE" line in with its own scale tween a beat after the panel lands
9. Toggles `ScreenGui.Enabled` around each toast so the panel never flashes on join
10. **Waits for the local character before it resolves the panel.** Redwater runs `Players.CharacterAutoLoads = false` (set in `Main` and `SkinService`), and StarterGui is only copied into `PlayerGui` when the character FIRST spawns — a spawn that is itself deferred through `SkinService.loadCharacter`, which blocks on the profile-backed hunter selection before calling `LoadCharacter`. This script boots from `StarterPlayerScripts` the instant the client starts, so waiting on the panel directly sat in an empty `PlayerGui` for that whole window and tripped Roblox's 5s *"Infinite yield possible"* warning on any slow join — routinely in Studio, where the profile read hits the live DataStore. A `player.CharacterAdded:Wait()` gate ahead of the lookup removes the false positive while leaving the `WaitForChild` after it as a real diagnostic. Deferring the whole script with it is safe: both `QuestCompleteEvent` senders fire off quest PROGRESS (kills, damage, wins), none of which can happen before the player has a character

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `QuestCompleteEvent` | ← Server | [[QuestService]] fires when a daily/weekly quest completes; [[BattlePassService]] fires when a battle-pass weekly quest completes |

### BindableEvents
None

### Direct require()
None

## UI layout
The panel is authored art at `StarterGui.QuestCompleteNotification` — this script creates no GUI instances of its own beyond two UIScale drivers.

- `Canvas` (0.10 scale tall, anchor 0.5/0.5) → `Background` (0.9 × 0.9, anchor 0.5/**0**) → three TextLabels. The authored `0.15` width is only a resting value — `fitWidth()` overwrites it per toast, see Width below. Height is never touched, which is what keeps the font size constant between toasts.
- `QuestNameTitle` (gold) — which track the quest came from, e.g. `DAILY QUEST` / `WEEK 3 QUEST`
- `QuestObjective` (white) — the quest label plus its completed count, e.g. `Get 10 Kills  10/10`
- `QuestComplete` (green) — static text, scale-stamped on entrance
- `Background` is `BackgroundTransparency = 0.65` with its `UIShadow` at 0.85 — the fill is deliberately see-through so the panel does not block gameplay; the gold `UIStroke` and the text stay fully opaque. The fade driver reads these authored values as "fully shown", so retuning them in Studio needs no code change.
- ScreenGui is authored `Enabled = false`, `ResetOnSpawn = false`, DisplayOrder 8600 — above the HUD, below the kill feed (9000), kill cam (9500) and hunter swap (9600). **Authoring it disabled matters:** the script only reaches `resetToHidden()` after `WaitForChild("QuestCompleteEvent")` **and** the character gate in behaviour 10, so an enabled-by-default panel sits on screen for the whole of that wait on join — a window that now runs to the player's first spawn.
- Parked position is derived from the panel's own height, so moving or resizing the art in Studio does not break the slide

## Placement
**Hangs off the top edge of the screen**, both axes authored in Studio.

- ScreenGui is `ScreenInsets = None` + `IgnoreGuiInset = true`, the same space as `ReworkedSettingsGui` and `StatMenuGui`. Under the default `CoreUISafeInsets` the panel floated ~36px down because y=0 sat below the Roblox topbar. It moved from `DeviceSafeInsets` to `None` together with those two so the three stay in **one** coordinate space — the `RIGHT_CLUSTER_PX` clamp below measures the buttons in pixels off the same edge, and it silently mismeasures the moment the panel and the buttons it dodges live in different inset spaces.
- `Background` is top-anchored inside `Canvas`, and `Canvas.Position.Y` is `0.05` scale against a `0.10` tall canvas at anchor 0.5 — so the canvas top, and with it the visible panel, lands exactly on y=0.

X is honoured as authored and only ever **clamped**, never recomputed. The buttons on the right are pinned to the screen edge in **pixels**, so the strip they occupy is a larger fraction of a narrow screen, and a scale that clears them on desktop slides underneath them on a phone:

| Blocker | Extent from right edge | Present on |
|---------|------------------------|------------|
| `ReworkedSettingsGui.SettingsButton` | 44px wide at -10 → **54px** | all |
| `MobileStatsButton` (StatMenuScript) | 60px wide at -62 → **122px** | touch only |

Those buttons share this GUI's inset space, so the pixel figures compare directly against `ScreenGui.AbsoluteSize.X` — the **GUI area's** width, not `Camera.ViewportSize.X`, which is wider on a notched phone. `refreshLayout()` takes the authored centre, pushes it left only far enough to clear the cluster, and keeps it off the left edge. It runs per toast so a resize or orientation flip lands the next one correctly.

At the authored `{0.75, -27}` the clamp is inert on every realistic viewport — 1920, 1151 and 800 wide on desktop, 896 and 667 on touch all land on the authored X untouched. It only bites below ~500px wide on touch, where the panel is nudged ~19px left of authored.

## Width
`fitWidth()` sizes the Canvas to its own longest line each toast, so the panel hugs its text instead of stranding dead space around a short objective. It runs **before** `refreshLayout()`, which reads the new width back out for the button clamp. The panel is centre-anchored, so it grows and shrinks symmetrically around the authored X.

Each line is measured with `TextService:GetTextBoundsAsync` at the font size `TextScaled` will settle on — which is the height-bound size, derived from the authored scales rather than read off `AbsoluteSize`, because the GUI is disabled between toasts and its absolute geometry is stale. Padding is `0.20 × panel height` per side, so it stays proportional on a phone. Clamped to 0.085–0.34 of the GUI width.

**`TextScaled` stays on deliberately.** The measurement is a hint, not a contract: if a device's real font metrics differ from what `GetTextBoundsAsync` reports here, the line quietly shrinks inside the panel rather than overflowing it — text metrics measured in Studio are not reliable proof of what a real phone renders.

Measured at 1920×1080 (authored width was 288px): `Get 20 Kills 20/20` → 242px, `Win 3 Rounds In A Row` → 281px, `Deal 5000 Damage 5000/5000` → 309px, `Headshot 5 Enemies Without Reloading` → 420px.

**Known overlap:** the panel shares an x band with the kill feed on both platforms. The feed anchors its *bottom* edge and grows upward, so on desktop rows only reach the panel once 4 of 5 slots are filled; on mobile the feed is 2 rows starting at y 60 and the second row reaches the panel's y band. DisplayOrder is deliberately left at 8600 (below the feed's 9000) so combat information draws over the notification rather than under it.

