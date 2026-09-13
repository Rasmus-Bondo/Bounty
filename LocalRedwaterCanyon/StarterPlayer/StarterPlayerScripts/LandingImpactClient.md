---
tags: [client, localscript, camera, ui, feedback]
path: game.StarterPlayer.StarterPlayerScripts.LandingImpactClient
type: LocalScript
lines: 180
---

# LandingImpactClient

Short camera kick when the local character lands, plus the HUD's landing shake, plus Dust's dash kick.

## What it does
1. Tracks `workspace.CurrentCamera`, rebinding on `GetPropertyChangedSignal("CurrentCamera")` so a camera swap (kill cam, victory showcase) does not leave a stale reference.
2. On `Humanoid.StateChanged`, records that the character was airborne on `Freefall`/`Jumping`, and fires the kick only on a `Landed` that follows one — `Landed` alone also fires for stepping off a kerb. On the `Jumping` edge (not `Freefall`), also calls `HunterHudShake.Jump` for a take-off stretch on the HUD panels — stepping off a ledge enters `Freefall` first, so only real jumps stretch. Fortuna's air jump raises `Jumping` too, so her double jump stretches twice.
3. `playCameraShake` connects a plain `RenderStepped` loop for `DURATION` (0.08s) and multiplies `camera.CFrame` by a random XY offset that fades to zero. An `isShaking` guard stops overlapping landings from stacking loops.
4. `STRENGTH` is 0.0515, not either historical value. This effect was previously produced by two `JumpImpact` LocalScripts inside the deleted `StarterGui.HunterGui` folder, which fired **together** on every landing (0.045/0.08s and 0.025/0.07s) writing independent random offsets to the same camera. Their amplitudes added in quadrature, so a single emitter at 0.045 read noticeably weaker; `sqrt(0.045^2 + 0.025^2)` reproduces the shipped feel from one place.
5. On the same `Landed` edge, calls `HunterHudShake.Play` with the local `PlayerGui` — the HUD bob and the mobile button pulse. **Landings only, never the dash below:** the dash already moves the camera twice (here and in FPSRevolverClient), and a HUD that shook on every dash in a chain would be the loudest thing on the screen.
6. For Dust only (gated through `HunterGate.IsHunter`), listens to the `DashCooldownStarted` BindableEvent and fires the same camera kick, rate-limited to one per 0.12s so a dash chain cannot stack into a rumble.
7. Runs at the root of `StarterPlayerScripts`, ungated: every hunter lands, so it serves all viewers and must survive hunter swaps rather than living in a per-hunter folder.

## It owns the landing gate; the motion is split
"Was airborne, and is now grounded" lives here once, and every piece of landing feedback hangs off it. The camera kick stays in this file because it is four lines and touches nothing but the camera; the HUD shake is a module because it has to negotiate with the mobile cluster's layout and with the onboarding lesson's UIScale. A second script re-deriving the gate would drift out of step with this one on exactly the edge cases the gate exists for.

`HunterHudShake` is resolved on a spawned thread and read through a nil check at the call site. The camera kick is the part that must not be held up by a `WaitForChild`, and a client that somehow comes up without the Shared folder should still land with a jolt rather than not at all.

## Why it reads as a gun shake
Every viewmodel compositor binds at `BindToRenderStep`, `RenderPriority.Camera.Value + 1`. A plain `RenderStepped` connection runs **after** that, so the camera is jittered once the viewmodel has already been placed for the frame. The viewmodel is left one frame behind the camera, which is what makes the arms and gun appear to wobble against the screen.

## Dependencies
- **Requires:** [[HunterGate]], [[HunterHudShake]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None.

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `DashCooldownStarted` | ← | RevolverDash fires it when Dust's dash goes on cooldown; this adds the camera kick on top of the dash camera movement FPSRevolverClient already applies. Plain text on purpose — RevolverDash.md and FPSRevolverClient.md declare this connection from the firing side, and wikilinking it here too forms a reciprocal pair that the graph resolves backwards |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterGate]] | `HunterGate.IsHunter(player, "Dust")` | Gate the dash listener so only Dust wires it |
| [[HunterHudShake]] | `HunterHudShake.Jump(playerGui)` | The take-off stretch on the HUD panels — jump edge only |
| [[HunterHudShake]] | `HunterHudShake.Play(playerGui)` | The HUD squash on landing |
