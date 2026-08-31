---
tags: [client, localscript, ui, menu, camera, shop]
path: game.StarterGui.ReworkedMainMenuFolder.MainMenuGui.CanvasBottom.MenuHandlerScript
type: LocalScript
lines: 1400
---

# MenuHandlerScript

Main menu bottom bar controller with animated tab selection, bird-flight camera transitions, and shop menu open/close.

## What it does
1. Manages 4 menu tabs: Home, Collection, BattlePass, TradingPost with hover/click/selected animations
2. Moves camera between CameraParts using quadratic Bezier bird-flight curves with banking and motion blur
3. Opens/closes the Trading Post overlay (the `StarterGui.Shop` ScreenGui since 2026-08-23 — `ReworkReworkedBuyMenu` is retired and kept disabled; the local is `tradingPostGui`, resolved with `playerGui:WaitForChild("Shop")`) with staggered slide-in animations for tabs and currency options
4. Animates selection stroke pulse, icon scaling, position lifts, and color transitions on menu frames
5. Creates BlurEffects in Lighting for camera motion and shop overlay
6. Handles close button hover effects with UIScale tweens
7. Queues camera targets during active flight and resolves after completion
8. Also mirrors the bottom-bar hover polish + SFX onto the sibling `CanvasLeft.Frame` action buttons (News / Quests / Leaderboard): `Unhover` sound + grow on MouseEnter, return on MouseLeave, `TabsSelect` sound on click. These are not tabs (no selection state); opening the Quest and Leaderboard panels is wired by QuestClient and RankLeaderboardClient respectively
9. **Mobile notch clearance:** on touch devices (`UserInputService.TouchEnabled`), nudges the whole `CanvasLeft` sidebar right so the News/Quests/Leaderboard buttons clear a landscape camera notch (the menu uses `IgnoreGuiInset`/`ScreenInsets = None`, so the sidebar otherwise hugs the screen edge under the cutout). Measures the device left safe-area inset via a hidden `DeviceSafeInsets` probe ScreenGui (`LeftSafeAreaProbe` in PlayerGui) and shifts by `leftInset + 12px`, re-applying on safe-area/rotation changes. Desktop is untouched
10. **SFX volume routing:** `playShopSound` clones the hover (`Unhover`) / click (`TabsSelect`) sounds from `ReplicatedStorage.SFX.ShopMenuSFX` and assigns `SoundGroup = SoundService.SFX` before playing, so they obey the player's SFX + Master volume settings (SettingsController drives `SoundService.SFX.Volume`)
11. **Camera-arrival signals (fired for other panels):** creates/owns two `BindableEvent`s under `MainMenuGui`. `BlackBarMenuCovered:Fire(frameName)` fires under the black-bar transition once the screen is covered and the camera has instant-cut. `MenuCameraArrived:Fire(frameName)` fires whenever the camera has **finished** landing on a frame's location — both the bird-flight settle (`onCameraMoveFinished`) and the two instant black-bar cuts — so a panel can appear only after the camera lands. The battle pass uses `MenuCameraArrived` to fade in on arrival instead of on the raw tab click
12. **Left sidebar visibility:** the `CanvasLeft` action sidebar (News / Quests / Daily Rewards / Leaderboard) is only shown on the **Home** and **Battle Pass** tabs — Collection and Trading Post take the screen over with their own panels, so `selectMenuFrame` hides it there. Driven from `selectMenuFrame` so every entry point (tab click, black-bar transition, trading post cinematic, `MenuNavigateRequested`) stays in sync. Hides/reveals via a `SidebarVisibilityScale` UIScale + `Visible` (not Position or Transparency — the mobile notch code owns `CanvasLeft.Position` and the hover tweens own descendant transparency); animates only when the camera flies, snaps on the black-bar/cinematic paths since the screen is covered
13. **Selected-tab attribute:** `selectMenuFrame` writes the current frame name to a `SelectedMenuFrame` attribute on `MainMenuGui`, for panels that key off the tab without owning the camera/tab logic (the CurrencyHudGui cash/token chips read it to show only on Home + Battle Pass). Written from `selectMenuFrame` rather than `handleMainMenuClick` so every entry point is covered, and **above the "already selected" early return** so a re-select still republishes. An attribute rather than a BindableEvent so a late-starting listener can pull the current value instead of missing a one-shot fire
14. **Currency vault shortcut (`openCurrencyVaultFromMenu`):** listens to `CurrencyVaultRequested` on `CurrencyHudGui` — the `+` buttons on the shared currency chips. **Resolved with an unbounded `WaitForChild` inside a `task.spawn`**: this script lives in StarterGui too, so it routinely runs before `CurrencyHudGui` has been copied into PlayerGui, and the `FindFirstChild` this originally used lost that race and left the `+` buttons silently dead. Answers **only when the Trading Post ScreenGui is not already enabled** ([[ShopController]] takes the same event when it is, so exactly one side responds). Sets `VaultOnOpen` (`"Cash"`/`"Tokens"`) and `VaultReturnMenuFrame` (the page being left, so the vault's GO BACK can return there) on that ScreenGui, runs `backupEnvironment` + `selectMenuFrame(tradingPostFrame, false)` to keep the bottom-bar selection honest, then enables it. **Deliberately plays no transition of its own** — the vault opens with its own black bars, and two in a row read as a stutter. Also skips the FEATURED cinematic, which is the wrong opening for "I tapped +"
15. **External navigation requests:** owns a `MenuNavigateRequested` BindableEvent under `MainMenuGui`; on `:Fire(frameName)` it looks up the matching bottom-tab frame in `menuFrames` and runs `handleMainMenuClick(frame)` — the same path as a real tab click (camera flight + tab reselect). The Battle Pass X button uses this to return the player Home, and the Collection menu's locked title rows / locked emote tiles use it to hand the player off to the Trading Post or the Bounty Pass. **A programmatic fire does not touch the bottom-bar buttons**, so any panel that closes itself on a real tab click has to close itself before firing — the Collection menu does this in its own `titleShop.navigate`

## Dependencies
- **Requires:** [[WaitForRequired]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `MenuCameraArrived` | → | [[BattlePassClient]] opens/fades the pass in only after the camera lands on `4BattlePassFrame` |
| `MenuCameraArrived` | → | [[CurrencyHudController]] shows the Bounty Pass currency stack on the same signal, so it lands with the pass panel |
| `BlackBarMenuCovered` | → | [[Panels]] / [[ShopController]] / [[CollectionClient]] reveal on the instant black-bar cut (the shop tears its vault down) |
| `MenuNavigateRequested` | ← | [[BattlePassClient]] X button fires a frame name (`"1HomeFrame"`); routed through `handleMainMenuClick` to fly the camera + reselect the tab |
| `MenuNavigateRequested` | ← | [[Shop]] locked title/emote hand-off fires `"5TradingPostFrame"` or `"4BattlePassFrame"` |
| `MenuNavigateRequested` | ← | [[ShopController]] vault GO BACK returning the player to the page they pressed `+` on; [[ShopHuntersTab]] / [[ShopWeaponsTab]] / [[ShopExtrasTab]] BOUNTY PASS buttons fire `"4BattlePassFrame"` |
| `CurrencyVaultRequested` | ← | [[CurrencyHudController]] `+` pressed while the shop is closed; opens it straight into the vault |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[WaitForRequired]] | `waitForRequired(workspace, name)` | `CameraFolder` and `Terrain`, without the engine's 5s "Infinite yield possible" warning. The `CameraPart*` lookups beneath `CameraFolder` need no helper — a Persistent model's descendants arrive with it |
