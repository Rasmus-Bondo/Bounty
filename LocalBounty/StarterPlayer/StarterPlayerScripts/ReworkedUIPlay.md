---
tags: [client, localscript, ui, input, teleport]
path: game.StarterPlayer.StarterPlayerScripts.ReworkedUIPlay
type: LocalScript
lines: 990
---

# ReworkedUIPlay

Handles Play and ChangeMode 3D button interaction using screen-projected hitboxes instead of raycasts, with toast notification feedback during teleport via NotificationModule.

## What it does
1. Projects PlayButton and ChangeModeButton (3D parts in Workspace.PlayModel) onto screen space
2. Detects hover and click/tap on PC via mouse position, on mobile via touch events
3. Tweens button group sizes on hover/unhover for visual feedback
4. Fires PlayTeleportEvent to server when the Play button is clicked — **unless the mode picker is set to TUTORIAL**, in which case it fires `TutorialReplayRequest` instead. The picker is a chooser only: it never teleports, the sign shows what is selected, and the existing PLAY button launches whatever is shown. Mode is read from the `SelectedMode` attribute on GameModeGui (see item 13) and relayed as `teleportEvent:FireServer(selectedMode())`. `selectedMode()` admits `"tutorial"` and `"quickplay"` **by name**, then any id GamemodeConfig knows, and calls everything else deathmatch — because the failure that matters is a lobby whose PLAY button does nothing. The two by-name tests are load-bearing: neither pseudo-mode is a registry row, and `quickplay` being the lobby's default means folding it into deathmatch would silently retire the feature for every player who never opens the picker
4a. **CHANGE MODE opens the picker with one instance write** — `GameModeGui.Scrim.Visible = true`, no handshake. GameModeClient watches `Visible` and paints itself, so a lost BindableEvent cannot leave the panel half-open. The `TutorialReplayRequest` remote is resolved off-thread with a 30s bound so a missing tutorial remote can never stall the PLAY wiring; if it is still absent when TUTORIAL is pressed the player gets "Tutorial is unavailable right now." and deathmatch keeps working
4b. **`tryTeleport` refuses outright while the picker is open** (`pickerIsOpen`, 2026-08-17). The signs are hit-tested by projecting their 3D bounds into a screen rect, and a screen rect knows nothing about GUI layering: the only thing normally stopping a click on an open panel from also reaching the sign behind it is UserInputService's `gameProcessed` flag. That flag is not dependable on a touch **release**, and the mobile path acts on `TouchEnded` — so a tap outside the picker card dismissed it and, in the same tap, hit the CHANGE MODE sign behind the scrim and reopened it. Nothing about the dismiss was broken; the panel was reopened within the frame, so from the player's side clicking outside simply did nothing. Worst on a tablet, where the 4:3 sign covers most of the screen and leaves little "outside" that is not also over the sign. The gate lives in `tryTeleport` because all three input paths (PC click, touch tap, and the mobile backup buttons) funnel through it, where `isBlocked()` below is built inside `configureMobilePlayButtonBackup` and only exists on touch devices
5. Uses configurable padding and tap movement limits for mobile vs PC
6. Handles background transparency toggling for hovered button state
7. Shows persistent "Finding match" status toast on click via NotificationModule; updates to "Teleporting to match" on TeleportQueued; shows error toast and resets debounce on TeleportFailed or after 15s timeout. The status names no map on purpose — the server queues the party before matchmaking has chosen a destination, and a retry can re-pick a different one
8. On touch devices, drives the authored `StarterGui.MobilePlayButtonBackup` ScreenGui: strips every descendant's transparency so it is invisible, forces `DisplayOrder = 0`, and wires its `PlayButton` and `ChangeModeButton` to the same `tryTeleport` path. These are real UI hitboxes standing in for the two 3D signs, so a tap landing a few pixels off a projected part still works
8a. **The hitboxes are PLACED FROM THE PROJECTED 3D BOUNDS every frame** (`layoutBackupButtons` on `RenderStepped`, 2026-08-17), not authored at fixed screen coordinates. The authored PLAY box was a fixed 35% x 18% of the screen eyeballed against one device: it covered far more than the sign it stands in for, swallowing taps meant for the scenery around it, and it drifted off the sign entirely on any other aspect ratio. A projected box is correct on every device by construction and follows the sign if a builder nudges it. Padding comes solely from `getHitboxPadding()` (12px on touch) — the placement adds none of its own, since stacking two paddings is how the box got oversized in the first place. Position/Size at runtime is state, not structure; the buttons themselves stay authored instances (UI_STYLE_GUIDE 1.2). The ScreenGui is `ScreenInsets = None` and its `Canvas` is normalised to a full-screen identity frame so offsets map 1:1 to viewport pixels, and the projection (which has the inset removed) is bridged with `GuiService:GetGuiInset()` — skipping that drops both boxes by the height of the topbar
8b. **The two padded boxes overlap, and the overlap is split down the middle.** The signs sit 0.55 studs apart, so at 4:3 the boxes overlapped by 23px on phone and 21px on tablet, and overlapping GuiButtons resolve by draw order rather than intent — `ChangeModeButton` is the later sibling, so the bottom strip of PLAY would have opened the picker instead of starting a match. Which sign is upper is determined from the projected bounds rather than assumed, so the split survives the signs being reordered or moved
9. Gates those invisible buttons hard, because they would otherwise swallow taps meant for whatever is drawn over them. They are enabled only while MainMenuGui is enabled and its `SelectedMenuFrame` attribute reads `1HomeFrame` (or is still nil), and only while none of **eleven** screen-taking panels is showing — QuestGui, DailyLoginGui, RankLeaderboardGui, GiftGui, LootboxMenu, BattlepassGui, CollectionGui, Shop, CurrencyShop (the Trading Post and its vault since 2026-08-23; the retired ReworkReworkedBuyMenu never enables and is not listed), ReworkedSettingsGui's `Canvas`, and GameModeGui's `Scrim`. Layering alone is insufficient: most of those panels' backdrops are `Active = false`, so a tap passes through them. GameModeGui names its frame for the same reason Settings does — it stays Enabled for the whole session and toggles `Scrim.Visible`, so an Enabled test alone would block PLAY permanently. **`isBlocked()` gates only `backupGui.Enabled`**, never the click path, which is why the picker needed its own gate in item 4b
10. Re-resolves MainMenuGui when the cached instance is orphaned and re-registers panels via `PlayerGui.ChildAdded`, since several of the watched ScreenGuis are `ResetOnSpawn = true` and the lobby has `CharacterAutoLoads` on

11. **`workspace.PlayModel` must stay `ModelStreamingMode = Persistent`** — set 2026-08-03, having been `Default` with 100 parts. Lines 18-30 open with **eight consecutive unbounded `WaitForChild` calls** on its children at the top level of the file, so losing the streaming race does not merely degrade the PLAY button: it stalls every line below and the button never wires up at all, for the rest of the session. This is the loudest possible failure in the lobby, which is why the 100 always-replicated parts are worth paying for. Note that adding a **bounded** timeout here would **not** be a fix — it would convert a dead button into a dead button that warns; the parts have to actually be present. The top-level `PlayModel` lookup goes through [[WaitForRequired]], which is a different thing: it loops a timed wait so the semantics stay *wait forever, never return nil*, and only the reporting threshold moves from the engine's 5s to 30s. The eight child waits below it are untouched, and correctly so — they resolve with their parent

12. **`getPartScreenBounds` ignores whether a corner is on screen** (2026-08-17). It projects all eight corners of a part and takes the min/max, and it used to discard any corner `WorldToScreenPoint` reported as off-viewport. On a 4:3 tablet the sign overhangs the left edge, so four of eight corners were dropped and the rectangle collapsed to whatever fitted — PLAY's true 440x143 px hit target became **5x98**, CHANGE MODE's 429x128 became **4x67**. A four-pixel-wide tap target is why CHANGE MODE was "sometimes" unhittable and near-impossible on tablet. The `onScreen` flag reports whether a corner is inside the viewport, not whether its projection is valid: a corner just past the left edge has perfectly good coordinates. Only `Z > 0` matters — a point behind the camera projects to a mirrored, meaningless position — and that check stays, now returning `nil` outright, since a part straddling the camera plane has no honest rectangle
13. **Reads the `SelectedMode` attribute off GameModeGui rather than owning the selection.** GameModeClient is the only writer; this script is the only reader. The attribute is advisory — the server never sees it, this script picks which remote to fire, and each remote is validated by the service that owns it

## Dependencies
- **Requires:** [[NotificationModule]], [[WaitForRequired]], [[GamemodeConfig]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PlayTeleportEvent` | -> Server | [[PartyService]] triggers party teleport |
| `PlayTeleportEvent` | <- Server | [[PartyService]] TeleportQueued/TeleportFailed status |
| `TutorialReplayRequest` | -> Server | [[TutorialReplayService]] PLAY pressed with the picker on TUTORIAL |
| `TutorialReplayRequest` | <- Server | [[TutorialReplayService]] TeleportQueued/TeleportFailed status, handled by the same `onTeleportStatus` as PlayTeleportEvent — only the queued toast differs ("Teleporting to tutorial" vs "Teleporting to match") |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[NotificationModule]] | `ShowStatus()`, `ShowError()`, `DismissStatus()`, `Notify()` | Toast feedback for teleport flow |
| [[WaitForRequired]] | `waitForRequired(Workspace, "PlayModel")` | Resolve the Persistent PLAY model without the engine's 5s "Infinite yield possible" warning, keeping the unbounded-wait semantics the eight child lookups below depend on |
