---
tags: [client, localscript, analytics, telemetry, mobile]
path: game.StarterPlayer.StarterPlayerScripts.TelemetryClient
type: LocalScript
lines: 135
---

# TelemetryClient

Reports this client's platform to the server, and one FPS sample per match.

## What it does
1. **Resolves the platform**, which the server cannot do at all — it has no view of input devices. This script is the reason every platform breakdown in the analytics is possible
2. Classification: `GuiService:IsTenFootInterface()` → Console; touch-PRIMARY (TouchEnabled and NOT KeyboardEnabled and NOT MouseEnabled) → Phone or Tablet by the viewport's SHORT edge at a 600px boundary; everything else → Desktop
3. **Deliberately slightly narrower than the gameplay mobile predicate.** The mobile fire/sprint buttons and aim assist gate on bare `UserInputService.TouchEnabled`, which also catches touchscreen laptops. Those are classified Desktop here on purpose — folding desktop-class hardware into the Phone bucket would poison the ClientPerf and MatchAccuracy numbers the whole mobile-experience question rests on
4. Waits 2s before reading input, then re-checks at 10s. Studio's device emulator flips `TouchEnabled` a beat AFTER client scripts start (the same trap VesperScopeController and the mobile Scope button work around), so reading on frame 1 labels every emulated phone as Desktop. The re-check also covers a real device that reports late; a repeat of the same value is suppressed
5. Fires `ReportPlatform` to [[Telemetry]] once per resolved value
6. **FPS sampling, Redwater only.** Detects which place it is in from the presence of the `RoundActive` BoolValue in ReplicatedStorage (published by RoundController) rather than by PlaceId, so there is one file to maintain across both places. Its absence means the Bounty lobby, where a combat FPS sample means nothing
7. Waits for the round to actually be live, warms up 5s to exclude join-time asset hitches, then samples 30 seconds. Sampling during intermission would report a flattering number for exactly the players whose performance is in question
8. Reports average FPS plus the **worst one-second average** — not the worst single frame, since a lone 200ms hitch is normal and would make every device look broken, whereas a bad second is what players actually feel. 30s is early enough to also capture players who quit mid-match, the cohort whose FPS matters most: a low-FPS abandon is a technical problem, not a design one

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ReportPlatform` | → Server | [[Telemetry]] whitelists and caches it, publishes the `Platform` attribute, persists `LastPlatform` |
| `ReportClientPerf` | → Server | [[Telemetry]] logs the `ClientPerf` event, once per player per server |

### BindableEvents
None

### Direct require()
None
