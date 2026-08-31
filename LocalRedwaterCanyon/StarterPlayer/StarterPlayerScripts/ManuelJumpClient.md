---
tags:
  - client
  - localscript
  - movement
  - input
path: game.StarterPlayer.StarterPlayerScripts.ManuelJumpClient
type: LocalScript
lines: 187
---

# ManuelJumpClient

Replaces Roblox's default auto-jump with a manually-cooldown-gated jump bound to Space/gamepad A/the platform jump button.

## What it does
1. Disables `Humanoid.AutoJumpEnabled` on character spawn
2. Binds a high-priority `ContextActionService` action (`ManualJumpOnly`) to Space and `ButtonA` that triggers a jump on input Begin and sinks the input (prevents default jump handling from also firing)
3. Also listens to `UserInputService.JumpRequest` (covers mobile jump button) with the same cooldown-gated jump
4. `canJump()` gates on humanoid alive, the `Jumping` HumanoidStateType still being enabled, a 0.28s cooldown since the last jump, and (if `REQUIRE_GROUNDED`) the character not already being airborne
   - The state-enabled check is what makes every movement lock in the game stick. `doJump()` forces the jump with `Humanoid:ChangeState(Jumping)`, which punches through a disabled Jumping state, so a lock applied on the humanoid alone (Bram's breach charge, RevolverDash's post-dash clamp, HighNoonMovement, a HunterStatusEffects stun) was silently bypassed. Gating the input here honours all of them at once. Nothing disables `Jumping` outside those deliberate ability locks — CharacterStateLockClient/Server disable only Swimming/Ragdoll/FallingDown/Physics/GettingUp
4a. **…and `GetStateEnabled` only sees locks this client applied**, which is why item 4 was only half the gate until 2026-08-06. `SetStateEnabled` does not replicate, so a lock the *server* set is invisible to the check above. HunterMovement publishes the `MovementJumpLocked` character attribute for exactly this reason — attributes do replicate — and nothing had ever read it. The gap was visible at the match summary: `RoundController.freezePlayerForVictory` applies a `LockJump` movement override to every player for the whole showcase, and a player could still jump through it for the entire podium. The jump goes nowhere (the freeze also anchors the root) but it still drives the state machine, which is enough to fire the landing/impact effects over the shot. `canJump()` now refuses while the attribute is set, which closes the same hole for every other server-applied lock at once
5. Sets `Humanoid.Jump = false` then `true` one frame later via `task.defer` to force a clean jump state transition, and watches `Humanoid:GetPropertyChangedSignal("Jump")` to immediately cancel any stray auto-set Jump flag while the button is held
6. **Builds the mobile JUMP button** (2026-08-08) and routes its press through the same `canJump()` gate as every other input, latching for 0.12s so a held finger cannot auto-bounce on every Humanoid step. Wiring a button straight to `Humanoid.Jump` would punch through every ability lock — item 4 is the whole reason this is the only place jump input is allowed to originate. It is built **here rather than in a hunter client** because jump is hunter-agnostic: once, at the root, instead of four times and torn down on every hunter switch
   - The gate this script owns is a *grounded* gate, which is right for three hunters and wrong for Fortuna, whose second jump is airborne by definition. She subscribes to the button's own `onPressed` fan-out and runs her air jump herself; nothing about jump ownership moved here. See HunterMobileJumpButton's gotchas for why she got no mobile input at all between the button shipping and 2026-08-08

## Dependencies
- **Requires:** [[HunterMobileJumpButton]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterMobileJumpButton]] | `.new{...}:Start()` | Build the on-screen mobile JUMP button and suppress Roblox's built-in one. The button reports a press; this script keeps the `canJump()` gate |
