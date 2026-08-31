---
tags: [shared, modulescript, client, ui, mobile]
path: game.ReplicatedStorage.Hunters.Shared.HunterMobileAbilityButton
type: ModuleScript
lines: 259
---

# HunterMobileAbilityButton

Shared OOP class that creates an invisible `TextButton` overlay on top of an ability UI frame so mobile players can tap the on-screen indicator to trigger the ability. Replaces the former Dust-only `HighNoonMobileButton` and Fortuna's inline `createMobileButton` helper in CardsHunterGuiClient.

## What it does
1. `.new(config)` — constructs an instance from `{Player, OnActivated, Frame|ResolveFrame, ButtonName?, MirrorChild?, ZIndex?, WatchGuiRecreate?}`. `MirrorChild` accepts a string or an array of child names; first match wins. `ZIndex` defaults to "auto" (highest descendant + 100). `MirrorChild` falsy → button fills the frame (Dust pattern); truthy → button mirrors the named child's anchor/position/size/rotation (Fortuna pattern over `FrameBorder`/`FrameBorderCooldown`)
2. `:Setup()` — resolves the frame (via `Frame` or `ResolveFrame`), creates or reuses the named `TextButton`, applies anchor/position/size/rotation/ZIndex/visibility, and wires `Activated` to `OnActivated`. `Visible` is gated on `UserInputService.TouchEnabled` so the button only appears on mobile. Returns true on success
3. `:Start()` — entry point. If `Frame` is set, runs `:Setup()` once (Fortuna pattern). If only `ResolveFrame` is set, loops `:Setup()` up to 80 times at 0.25s intervals (Dust pattern). If `WatchGuiRecreate` is set, also subscribes to `PlayerGui.ChildAdded` and rebuilds the button whenever a child of that name is re-added (Dust's `TemplateGameGui` watcher)
4. `:Destroy()` — disconnects activation and PlayerGui connections; the button instance itself is left parented so the GUI tree owns its lifetime

## Dependencies
- **Requires:** Nothing
- **Required by:** HighNoonClient (Dust ultimate button), CardsHunterGuiClient (Fortuna recall / ability1 / ultimate buttons), VesperHunterGuiClient (Vesper grapple / pinning / ultimate buttons), BramHunterGuiClient (Bram breach / shrapnel / ultimate buttons)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
