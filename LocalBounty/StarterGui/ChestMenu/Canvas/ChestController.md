---
tags: [client, localscript, ui, lootbox, menu]
path: game.StarterGui.ChestMenu.Canvas.ChestController
type: LocalScript
lines: 2315
---

# ChestController

The LOOT tab's chest scene: purchase panel with odds, the OPEN / SHOOT run, the 3D chest landing, laser shots, bullet reveals, glow, loot reveal and the LOOT-tab bubble. Merged on 2026-09-03 from the "Bounty - UI Update" prototype (the whole UI layer and every feel constant) and the old live copy (the Persistent-model streaming fix).

## What it does
1. **Connects the `LootboxStateEvent` handler before any scene construction** and fires `RequestLootboxState` right after — the profile-load push can beat a long build, and a fire with no listener is dropped for good. The state drives the purchase panel, the held-chest count, the XP progress bar (`ChestProgress.ChestXPBar`) and the bubble
2. **Replays the server's roll instead of rolling.** OPEN fires `OpenLootboxEvent(boxType)`, lands the chest while the reply is in flight, then waits for `LootboxResultEvent` (8s cap). The run lands exactly `stage` bullets — `shouldShotHit` is `successfulBulletCount < stage`, every later shot misses — and the reveal spawns exactly the items it was given, ascending by tier so the headline lands last. The only `Random` left (`visualRandom`) places miss holes and loot spin phases. A rejected or missing reply resets the chest and re-requests state
3. **Streaming:** `Workspace.PersistentMarkers.ChestShootPart` and `Workspace.SkinMenu.PreviewPart` through `WaitForRequired` — a loose root-level part does not replicate until it streams in, and this wait is at the top of the file
4. **A bought chest banks:** PURCHASE fires `PurchaseLootboxEvent`, the next push (carrying `purchaseResult`) clears the busy flag, and the buy button stays up so a player can stock up. The prototype's OWNED swap is unused; `AfterPurchaseText` shows the held count. A super chest is opened before any standard one, and the title reads SUPER CHEST for it
5. Odds panel painted from `LootboxConfig.DISPLAYED_ODDS` with the authored tier colours, plus a sixth row (`OddsFrame.6Pity`, cloned from `5Legendary`) for the pity guarantee; price from `LootboxConfig.PRICE_TOKENS`. A `restricted` state hides the price and greys the button as UNAVAILABLE IN YOUR REGION
6. **Loot labels:** each loot object gets a clone of `ReplicatedStorage.Lootbox.LootLabel` (BillboardGui, two lines cloned from the odds labels) — the item name in its tier colour, and after a beat the duplicate conversion (`DUPLICATE +210 TOKENS`), so a repeat reads as a near-miss rather than a silent swap
7. **Bubble:** `MainMenuGui.CanvasBottom.Frame.2LootFrame.LootNotifFrame` (a clone of `DailyNotiFrame`, counter-rotated so its digits read upright on the diamond) shows `unopened + superUnopened`, capped at `99+`, resolved with `FindFirstChild` so a missing bubble degrades to none. TextScaled, never sized from TextBounds
8. **Menu wiring:** opens on `MenuCameraArrived` / `BlackBarMenuCovered` for `"2LootFrame"` (with a 2s fallback off `SelectedMenuFrame`), closes — destroying the chest, loot and holes — when `SelectedMenuFrame` moves off the tab. Nothing enables the ScreenGui directly
9. **Post-tutorial routing** (spec 7c), profile-driven: when `superPending` is true, waits for `BountyIntroComplete`, then for `TutorialCompleteGui` to show and hide if TeleportData says a card is coming, then fires `MenuNavigateRequested("2LootFrame")` — once per session, so backing out is respected and the next join routes again
10. Every cloned Sound is given the `SFX` SoundGroup; feel constants live in one `K` table because the flat list of ~90 locals plus the new wiring exceeded Luau's 200-register cap

## Dependencies
- **Requires:** [[WaitForRequired]], [[LootboxConfig]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RequestLootboxState` | → Server | [[LootboxService]] pull half of the join handshake |
| `LootboxStateEvent` | ← Server | [[LootboxService]] counters, XP progress, restricted flag, price, `purchaseResult` |
| `PurchaseLootboxEvent` | → Server | [[LootboxService]] bank one chest |
| `OpenLootboxEvent` | → Server | [[LootboxService]] roll the chest on the pedestal |
| `LootboxResultEvent` | ← Server | [[LootboxService]] the resolved tier and items to replay |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `MenuCameraArrived` | ← | [[MenuHandlerScript]] the camera settled on a tab; opens on `2LootFrame` |
| `BlackBarMenuCovered` | ← | [[MenuHandlerScript]] mid black-bar cut to a tab; opens on `2LootFrame` |
| `MenuNavigateRequested` | → | [[MenuHandlerScript]] routes to the LOOT tab after the tutorial |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[WaitForRequired]] | `waitForRequired(Workspace, name)` | Resolve the Persistent `SkinMenu` and `PersistentMarkers` models without the 5s warning |
| [[LootboxConfig]] | `DISPLAYED_ODDS`, `PRICE_TOKENS`, `TIER_ORDER`, `TIER_INDEX`, `MAX_STAGES`, pity thresholds | Paint the panel from config and size the run |
