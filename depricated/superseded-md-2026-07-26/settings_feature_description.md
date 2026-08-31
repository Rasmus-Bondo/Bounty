# Settings — Feature Descriptions

---

## Mouse Sensitivity
A slider controlling how fast the camera turns in response to mouse movement. Affects aim speed during free-look and aiming. Range: 0.1–10 (default: 1.0). Stored per-player in DataStore.

---

## Potato Spec Mode `[NEEDS RESEARCH]`
A single toggle that applies a preset bundle of low-end graphics settings — disables shadows, reduces render distance, turns off particle effects, and lowers texture quality — to improve frame rate on weak hardware (mobile, low-end PCs). Roblox exposes `Lighting` properties and `workspace.StreamingEnabled` but full graphics quality is controlled via `settings().Rendering.QualityLevel`, which is **client-side only** and may require `UserGameSettings`. Needs a spike to confirm which properties are actually scriptable from a LocalScript in an experience.

---

## Crosshair Color
A color picker (or preset palette of 6–8 colors) that changes the tint of the on-screen crosshair. Useful for players who struggle to see the default color against bright desert terrain.

---

## Crosshair Size
A slider controlling the crosshair's screen size. Range: Small / Medium / Large, or a numeric scale. Helps players on low-res mobile screens or those with visual preferences.

---

## Sound (Master Volume)
A master volume slider that scales all in-game audio proportionally. Acts as a global multiplier over the individual category volumes below.

---

## SFX Volume
Controls the volume of in-game sound effects: gunshots, reloads, footsteps, impacts, and ambient canyon sounds. Independent of music so players can hear gameplay clearly while keeping music low.

---

## Music Volume
Controls background music volume (lobby theme, round music, intermission jingle). Separate from SFX so players can mute music without losing gameplay audio feedback.

---

## Hit Sound Volume
Controls the volume of the hit-confirmation sound (the "tick" that plays when a shot connects). Kept separate because some players want it loud for feedback while others find it distracting.

---

## Announcer Volume `[NOT IMPLEMENTED]`
Controls the volume of any voice or text-to-speech announcer lines (e.g. "First Blood", "Round Start", "You Win"). Feature does not exist yet — decide whether the game will have a voiced announcer before adding this slider. If announcer is added, it should be its own `Sound` object family so this slider can target it cleanly.

---

## Show Ping / FPS
A toggle that displays a small HUD overlay showing the player's current ping (ms) and frame rate (FPS). Useful for diagnosing lag. Ping via `Players.LocalPlayer:GetNetworkPing()`, FPS via `RunService.Heartbeat` delta. Positioned in a corner, styled to match the western UI theme.

---

## Redeem Code
A text input field where players enter a promo code to receive in-game rewards (currency, cosmetics, etc.). Fires a RemoteEvent to the server, which validates the code against a DataStore list of valid/redeemed codes and returns a success or error message. Standard anti-exploit: server does all validation, one redemption per player per code.

---

## Shadows On/Off
A toggle that enables or disables shadow casting from `Lighting`. On lower-end devices, shadows are one of the biggest frame rate costs. Implementation: set `Lighting.GlobalShadows` from a LocalScript (this is client-side). Should default to **On** for PC and **Off** for mobile (detect via `UserInputService.TouchEnabled`).

---

## Summary of Items Needing Follow-up

| Setting | Status | Blocker |
|---|---|---|
| Potato Spec Mode | Research needed | Confirm which Roblox rendering properties are scriptable client-side |
| Announcer Volume | Not implemented | Decide if voiced announcer is a planned feature |
