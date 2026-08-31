---
tags: [client, localscript, dailyreward, ui, viewport, animation]
path: game.StarterGui.DailyLoginGui.ViewportRigAnimationClient
type: LocalScript
lines: 267
---

# ViewportRigAnimationClient

Shows the player's **currently equipped hunter, in the equipped skin** in the Daily Login viewport and plays its looping idle, without touching the real world character. Lives inside the DailyLoginGui ScreenGui.

## What it does
1. On load (and whenever the local `EquippedCharacter` OR `EquippedSkin` attribute changes) swaps the baked-in viewport rig for a clone of the equipped model, resolved the same way LobbySpawn resolves the lobby dummy: Default skin → `ReplicatedStorage.Characters.<Hunter>.Default.<Hunter>Default`, other skins → `Characters.<Hunter>.Skin.<SkinName>` (falls back to Dust / the default look / the first Model child). A `character|skin` key gates rebuilds
2. Preps the clone for a ViewportFrame: strips scripts, anchors only the HumanoidRootPart (so Motor6Ds still animate), disables CanCollide/Touch/Query
3. Sets up the ViewportFrame `Camera` (the finished GUI shipped without one) and frames the hunter so it stays inside the **clear LEFT zone** of the tall/narrow viewport and never overlaps the reward tiles (which begin at viewport-local u ≈ 0.73). Fit-inside on the live `AbsoluteSize` aspect (height ≤ 0.9, width ≤ 0.58 of the frame) with a pure lateral camera pan biasing the hunter left (centre ≈ u 0.35). Re-frames on `AbsoluteSize` change and whenever the panel becomes visible
4. Loads the `DailyLoginLoop` animation (id captured from the original baked rig, with a hardcoded fallback) on the humanoid's Animator, looped at Action priority
4a. **Rebuilds are serialised against their own yields** (`buildId` generation + a `task.defer` coalesce). The server writes `EquippedCharacter` and `EquippedSkin` as two SEPARATE attributes, so one equip fires the listener twice: the first write resolves the **Default** skin (the skin attribute has not landed yet) and starts a build, the second resolves the real skin and starts another. Both then park inside the yielding `ContentProvider:PreloadAsync` / `Animator:LoadAnimation`, and the stale one usually resumes LAST (it paid the cold preload; the second hits the warm cache) — overwriting `currentTrack` with a track belonging to the rig it had already destroyed. Every later play/stop then lands on that dead track and **the skin on screen never animates**. Invisible on the Default skin, where both writes produce the same `character|skin` key and only one build ever runs, which is why this only ever showed up on a non-default skin. The build now captures its generation up front and bails at each resume that finds itself superseded; the initial `task.spawn` build likewise skips if a listener already built the right rig
5. Play/stop follows panel visibility (`gui.Enabled` + `Canvas`/`AnimatedFrame`/`ViewportFrame` `.Visible`), so it idles while the modal is closed — the DailyLoginController toggles that visibility

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None
