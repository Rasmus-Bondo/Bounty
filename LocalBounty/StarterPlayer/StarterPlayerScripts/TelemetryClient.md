---
tags: [client, localscript, analytics, telemetry, mobile]
path: game.StarterPlayer.StarterPlayerScripts.TelemetryClient
type: LocalScript
lines: 135
---

# TelemetryClient

Reports this client's platform to the server. Identical file to Redwater's copy; its FPS-sampling half is inert here.

## What it does
1. **Resolves the platform**, which the server cannot do at all — it has no view of input devices. This script is the reason every platform breakdown in the analytics is possible
2. Classification: `GuiService:IsTenFootInterface()` → Console; touch-PRIMARY (TouchEnabled and NOT KeyboardEnabled and NOT MouseEnabled) → Phone or Tablet by the viewport's SHORT edge at a 600px boundary; everything else → Desktop
3. **Deliberately slightly narrower than the gameplay mobile predicate.** The lobby's mobile UI paths gate on bare `UserInputService.TouchEnabled`, which also catches touchscreen laptops. Those are classified Desktop here on purpose — folding desktop-class hardware into the Phone bucket would poison the per-platform numbers the whole mobile-experience question rests on
4. Waits 2s before reading input, then re-checks at 10s. Studio's device emulator flips `TouchEnabled` a beat AFTER client scripts start, so reading on frame 1 labels every emulated phone as Desktop. The re-check also covers a real device that reports late; a repeat of the same value is suppressed
5. Fires `ReportPlatform` to [[Telemetry]] once per resolved value. Reporting from the lobby is what gives the `MatchLoop` funnel its Platform breakdown, since Roblox reads funnel custom fields from step 1 only and step 1 is fired here in Bounty
6. **The FPS sampler is inert in this place.** It looks for a `RoundActive` BoolValue in ReplicatedStorage to decide which place it is in rather than checking PlaceId, so there is one file to maintain across both places. Bounty has no such value, so the sampler returns early and `ReportClientPerf` is never fired — a ClientPerf chart mixing lobby framerate with combat framerate would be misleading

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ReportPlatform` | → Server | [[Telemetry]] whitelists and caches it, publishes the `Platform` attribute, persists `LastPlatform` |

### BindableEvents
None

### Direct require()
None
