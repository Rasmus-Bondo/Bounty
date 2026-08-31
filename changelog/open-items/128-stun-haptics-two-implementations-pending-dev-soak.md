# 128 — The stun overlay ships two haptics implementations and prints to the console

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Status:** OPEN · **Sev:** P3 · **Area:** Redwater Canyon + Frostbite Claim — `StarterGui.StunnedGui.StunnedController`

**Raised 2026-08-27.** Why both paths exist is in the Unreleased *Added* entry and in the source
comment above them.

**Symptom.** On a touch device a stun fires two haptics APIs — `HapticService:SetMotor(Touch,
Large, …)` and a looped `HapticEffect` — and prints two `[StunHaptics]` lines to the developer
console: a support probe once at spawn, and a per-stun line naming which paths ran.

**Neither can be tested in Studio.** Studio on Windows reports no haptics for any input type, and
the plugin cannot run on a handset. The Roblox docs do not settle it either: `HapticService`'s class
description claims mobile support while `SetMotor`'s own page steers to `Gamepad1` and the service
is marked superseded; `HapticEffect` is the current API and the only one with an explicit "Android
and iOS phones" support list. There is no other haptics call anywhere in the project to compare
against.

**Not shippable to live as-is** — the per-stun `print` is console noise on every slam in every
match.

**It shipped anyway, in Update 2 (2026-08-29), by owner decision.** `/preflight` raised it before
the publish and offered to silence the two `print`s while keeping both APIs; the owner chose to
ship as-is. Update 2 also skipped the DEV soak, so the probe line has still never been read on a
handset and nothing here is resolved — the item is unchanged, only now it is noisy on live rather
than on a build nobody was running.

**Test that closes it:** publish DEV Redwater, join it from a phone, and read the probe line at
spawn — it reports `TouchEnabled`, `IsVibrationSupported(Touch)`, `IsMotorSupported(Touch, Large)`
and whether `HapticEffect` constructs. Getting stunned is not required for the probe, only to
confirm the buzz. Then, **in both match places**: delete the losing path, delete `logHapticProbe`
and both `print` calls, delete the TEMPORARY comment block, and re-run `/preflight` so the mirror
gate sees the two copies still matching.

**If the soak is inconvenient, the alternative is to keep both permanently** and delete only the
logging. Two `pcall`'d calls that each no-op where unsupported cost nothing at runtime; the only
thing lost is knowing which one does the work.
