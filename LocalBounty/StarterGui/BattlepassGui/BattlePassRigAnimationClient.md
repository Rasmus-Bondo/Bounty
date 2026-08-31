---
tags: [client, localscript, battlepass, ui, viewport, animation]
path: game.StarterGui.BattlepassGui.BattlePassRigAnimationClient
type: LocalScript
lines: 266
---

# BattlePassRigAnimationClient

Shows the player's **currently equipped hunter, in the equipped skin** in the Battle Pass panel's `Canvas.AnimatedFrame` viewport and plays its looping idle, without touching the real world character. Lives inside the BattlepassGui ScreenGui — a direct port of the Daily Login viewport script.

## What it does
1. On load (and whenever the local `EquippedCharacter` OR `EquippedSkin` attribute changes) swaps the baked-in viewport rig for a clone of the equipped model, resolved the same way LobbySpawn resolves the lobby dummy: Default skin → `ReplicatedStorage.Characters.<Hunter>.Default.<Hunter>Default`, other skins → `Characters.<Hunter>.Skin.<SkinName>` (falls back to Dust / the default look / the first Model child). A `character|skin` key gates rebuilds
2. Preps the clone for a ViewportFrame: strips scripts, anchors only the HumanoidRootPart (so Motor6Ds still animate), disables CanCollide/Touch/Query
3. Sets up the ViewportFrame `Camera` (the finished GUI shipped without one) and frames the hunter **centred** (`CENTER_U = 0.5`) in the tall/narrow AnimatedFrame, fit-inside on the live `AbsoluteSize` aspect (height ≤ 0.86, width ≤ 0.82 of the frame). Re-frames on `AbsoluteSize` change and whenever the panel becomes visible
4. Loads the `DailyLoginLoop` animation (id captured from the original baked rig, with a hardcoded fallback) on the humanoid's Animator, looped at Action priority
4a. **Rebuilds are serialised against their own yields** (`buildId` generation + a `task.defer` coalesce), the same fix carried across from the Daily Login viewport script. The server writes `EquippedCharacter` and `EquippedSkin` as two SEPARATE attributes, so one equip fires the listener twice: the first write resolves the **Default** skin (the skin attribute has not landed yet) and starts a build, the second resolves the real skin and starts another. Both then park inside the yielding `ContentProvider:PreloadAsync` / `Animator:LoadAnimation`, and the stale one usually resumes LAST (it paid the cold preload; the second hits the warm cache) — overwriting `currentTrack` with a track belonging to the rig it had already destroyed. Every later play/stop then lands on that dead track and **the skin on screen never animates**. Invisible on the Default skin, where both writes produce the same `character|skin` key and only one build ever runs, which is why this only ever showed up on a non-default skin. The build now captures its generation up front and bails at each resume that finds itself superseded; the initial `task.spawn` build likewise skips if a listener already built the right rig
5. Play/stop follows panel visibility (`gui.Enabled` + `Canvas`/`AnimatedFrame`/`ViewportFrame` `.Visible`), so it idles while the panel is closed — BattlePassClient toggles `gui.Enabled`. (BattlePassClient also fades `ViewportFrame.ImageTransparency` during its open reveal; this script does not touch transparency)

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
