---
tags:
  - client
  - localscript
path: game.StarterPlayer.StarterPlayerScripts.ZoneAtmosphere
type: LocalScript
lines: 176
---

# ZoneAtmosphere

Client-side visual effects when the player is outside the safe zone.

## What it does

1. Creates ColorCorrectionEffect and BlurEffect in Lighting on startup. The effect is created **neutral** (`TintColor` white) — see 6a, the tint is animated per-frame, never parked on the fire colour
2. Each Heartbeat, works out how many studs the player is inside the fire's inner face by reading the rendered fire parts — the client's own copy of the server's `ZoneService.getSafeClearance`, since a LocalScript cannot require a server module
2a. **This is the one place outside `RoundSystem` that knows the map's zone shape** (2026-08-13), and it has to: the linear branch finds `ZoneFire_South` / `ZoneFire_North` by name, which does not generalise to a ring's N segments. The radial branch reads any segment out of the `workspace.ZoneFireRing` folder for the radius (taking the first *present* one, since streaming can drop an individual segment) and the `ZoneCenter` workspace attribute for the centre, which ZoneService publishes once per round. Easy to miss when a new shape lands, and its failure mode is a grade that silently never fires rather than an error
3. Computes distance-based intensity from how far past the wall the player is. `PROXIMITY` (12) is where the grade starts — matched to how far the wall's FX actually spill onto the safe side, since `CrawlerFlameColumn` attachments sit up to 3 studs past the inner face and their particles carry ~10 further — and `FADE_DIST` (12) puts it at **full strength exactly at the inner face, which is where ZoneService starts applying damage**
4. Reads `ZoneFireTime` attribute from the player to compute time-based intensity (scales over 8 seconds). The `/8` is deliberately matched to lethality and should stay tied to it: the burn ramps 5 DPS + 3/s, so `1.5t² + 5t = 150` puts a full-health death at ~8.5s — the grade saturates just as the burn turns fatal
5. Uses the greater of distance and time intensity, so effects ramp up both by going deeper and by staying longer. Since distance now maxes out at the inner face, **crossing into the fire pins the grade at 1.0 and `timeIntensity` is what escalates from there** — distance no longer competes with it
6. At max time intensity, effect values double (brightness, contrast, saturation, blur). `Saturation` is clamped at −1: Roblox does **not** clamp it (setting −3 reads back as −3) and the doubling reaches −1.2 on a long burn
6a. **`TintColor` is lerped from white to the fire colour on the same curve as every other channel.** `ColorCorrectionEffect` has no *amount* parameter for `TintColor` — it is a straight per-frame multiply applied at full strength the instant the effect is enabled. Leaving it parked on `(255,140,40)` at creation meant the orange **popped to 100% the moment `currentIntensity` crossed the 0.01 enable threshold** — ~7 studs before the player took any damage and 5 before the crawler flames reached them — while Brightness (0.003) and Saturation (−0.021) were still imperceptible. The two cues ran backwards against each other: full orange at first contact, but only 29% grade at the damage threshold, not peaking until the wall's *outer* face 20 studs deeper (past where a player is already dead). Fixing this also makes the kill-cam fade in 9 actually fade the tint instead of snapping it off below the threshold
7. Smoothly lerps between current and target intensity for clean transitions
8. Disables all effects when zone phase is below 2
9. **Stands down while the kill cam is up.** Dying to a bot or another player inside the fire leaves the corpse lying past the wall, so the orange tint used to stay burnt over KillCamClient's own death grade for the whole kill cam. KillCamClient publishes a `KillCamActive` attribute on the local player the instant the `KillCam` remote arrives, and the heartbeat fades the tint and blur out at `LERP_OUT` while it is set. The check sits *ahead* of the character/root lookups so the fade still runs to completion if the body is removed mid-fade, and the fade decays from the last live frame's `timeIntensity` (held in `lastTimeIntensity`) so the doubled values don't step down as the time bonus drops out. Killer-less deaths — the fire itself, falls, suicide — never fire the remote and so never raise the flag, leaving burning to death looking like burning to death

## Dependencies

- **Requires:** [[MapConfig]]
- **Required by:** Nobody

## Connections

### RemoteEvents

None - reads workspace attributes (`ZonePhase`, `ZoneCenter`) and player attributes (`ZoneFireTime`, plus `KillCamActive` published locally by KillCamClient) directly.

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[MapConfig]] | `Zone.Shape` | Which boundary geometry to read off the rendered fire parts |
