---
tags: [client, localscript, ui, loading, camera]
path: game.ReplicatedFirst.LoadingScreen
type: LocalScript
lines: 748
---

# LoadingScreen

Custom Bullets and Bounty intro/loading screen that holds the camera on a sky shot until the game is ready, then pans down to the lobby while fading the main menu in.

## What it does
1. Seizes the camera as the **very first** thing it does — before any `WaitForChild` — setting it Scriptable with no `CameraSubject`, then binds a render-step hold at `RenderPriority.Camera + 10` that re-asserts Scriptable / no subject / the intro CFrame every frame until the reveal. This is what guarantees the intro always starts on the sky: PlayerGui only receives StarterGui's contents when the character spawns, so the old order (wait for `MainMenuGui`, *then* point the camera) left a window where the default camera followed the just-spawned character at its locked lobby slot — invisible on a cold join, but plainly visible on a warm teleport arrival back from Redwater, where the lobby renders instantly. Holding every frame also means a later character spawn or `CurrentCamera` swap can't take the shot back mid-intro
2. Builds a custom loading GUI on a top-most ScreenGui — an opaque veil, "BULLETS AND BOUNTY" title, animated "Loading the frontier..." flavor text (ellipsis cycle), and an indeterminate marquee progress bar — and only calls `RemoveDefaultLoadingScreen` once the veil is parented, so Roblox's own screen covers every frame before ours. A `BlurEffect` on Lighting (`BountyLoadingBlur`) tweens up to 16 alongside it, so the sky revealed in step 3 sits behind a soft blur
2b. **Progress bar sizing is viewport-relative.** Everything else on the screen is scale-sized and TextScaled, so it tracks the viewport on its own; the bar was the one piece authored in raw pixels, and pixels are not a constant share of the screen — a 24px bar is 2.2% of a 1080p monitor but ~3.5% of a phone's usable ~368px-tall canvas, with a fixed 10px track inset eating most of it and the fixed 112px marquee chunk covering a third of the track instead of an eighth. Bar width, the track inset and the marquee chunk are expressed in scale outright; the properties with no scale component — bar height, UICorner radii, UIStroke thickness — are derived from viewport height against a 1080p reference (clamped 0.55–1.2, since pure proportion would thin the bar to 9px on a phone) and re-derived on every `AbsoluteSize` change, so rotation and window resizes are covered. Desktop geometry is unchanged to the pixel
3. Resolves `CameraFolder.IntroCameraPart` (falling back to the lobby `CameraPart` view pitched straight up), applies it as the held shot, then fades the veil out to reveal the sky. Everything before that point happens behind the opaque veil, so a late-replicating `CameraFolder` can never show the ground
4. Disables the entire `MainMenuGui` ScreenGui in a parallel thread (started before the camera-part waits, since it has to outlast character spawn) so it can't pop in or flicker during the sky shot — MenuHandlerScript sets up its default Home tab selection (and the shared glow stroke it parents onto the Home tab) completely invisibly
5. Gates the reveal on real readiness: `game:IsLoaded()`, character spawned, `LobbySpawns` present, the `EquippedCharacter` attribute set (profile loaded), **cosmetic ownership in hand** (the `SkinDataReady` attribute, below), the one-shot settings push received, and the menu resolved — floored at `MIN_HOLD_TIME` (1.5s) and capped at `MAX_HOLD_TIME` (6s), plus a `MIN_SKY_TIME` (1.2s) floor measured from when the sky shot actually went up (on a warm arrival readiness can land before the world does)
5b. **The `SkinDataReady` gate.** Ownership (owned skins / hunters / gun skins) does **not** ride on the player attributes above — it arrives separately on `SkinDataEvent`, a one-shot push whose payload is dropped for good if it lands before the client connected its listener. So `EquippedCharacter` proves nothing about it: it was correct in the exact failure this gate exists for, where owned skins rendered LOCKED all session while the equipped hunter/skin looked right. CollectionGuiController's early prefetch handler sets this **client-local** attribute once it actually holds the payload (a client `SetAttribute` never replicates to the server but every LocalScript on that client can read it), so the menu is never revealed over empty ownership state. The wait is **unbounded on purpose**, exactly like the settings gate — the `MAX_HOLD_TIME` cap on the reveal loop is what keeps a stalled or erroring controller from trapping anyone behind the veil. Note this is a soft coupling by attribute name, deliberately not a wikilink: nothing here requires or is required by that script
6. Preloads the character's descendants with `ContentProvider:PreloadAsync` before revealing
7. At reveal: snapshots every `MainMenuGui` descendant's now-settled transparency, forces them all transparent, re-enables the ScreenGui, then tweens the whole menu in from transparent over the 1.75s camera pan down to the lobby angle — while fading the loading GUI out. The pan is driven by the render-step hold itself (quad ease-out lerp, same curve/duration the old CFrame tween used) so the camera has exactly one author for the whole intro
7b. **The blur clears over the pan, not after it.** `fadeOutBlur` is a one-shot guarded by `blurFadeStarted` and is kicked off the moment the pan starts, so the lobby comes into focus as the camera comes down and is fully sharp when the shot settles. It used to be faded only inside the reveal-completion function, which runs *after* the pan has already landed — so the loading UI faded out, the menu faded in and the camera settled with the lobby still blurred at full strength, and the fade then played over an intro that was visibly already over, which reads as the blur never clearing rather than as a fade. The completion function and the watchdog still call `fadeOutBlur` (0.35s) as a safety net for the paths that never reach the reveal; the guard makes those a no-op on the normal path
8. Sets the `BountyIntroComplete` attribute on ReplicatedStorage once the pan completes, keeps holding for another 0.25s so the handoff to LobbySpawn's camera lock can't drop a frame to the default camera, then unbinds and destroys the loading GUI (the blur destroys itself a beat after its own fade, since it lives on Lighting rather than under the ScreenGui). A watchdog re-enables the menu and fires the same handoff if anything stalls, since the menu is hidden while the intro runs

## Dependencies
- **Requires:** [[WaitForRequired]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PlayerSettingsResponse` | ← Server | [[PlayerSettingsService]] one-shot settings push, awaited only as a load-readiness gate |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[WaitForRequired]] | `waitForRequired(parent, name)` | `CameraFolder` and its `CameraPart` for the sky shot, without the engine's 5s "Infinite yield possible" warning. **Required lazily, at the sky-shot section rather than at the top** — this runs in `ReplicatedFirst`, before ReplicatedStorage is guaranteed to have replicated. By that point the veil is up and the camera is seized, so the wait happens behind the loading screen |
