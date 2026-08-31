# Spec — Server-side aim orientation gate

**Status:** NOT BUILT. Deliberately deferred from the 2026-08-29 anti-cheat pass because it changes
the damage path and that pass shipped the same night. Build this in a session of its own.

**Why it exists:** a kill-aura script was used on live (r2726). It is not a damage bypass — it is an
aimbot that sends the *legitimate* `FireBullet` payload with a hand-computed direction. Every server
gate passes because the packet is indistinguishable from a legal shot. The reported behaviour is the
key detail: **the player's aim never physically moves.** The character keeps facing wherever it was
left and shots land anywhere on the map.

---

## 1. The hole

`RevolverModule.isAimDirectionReasonable` (`ServerScriptService.Hunters.DustServer.RevolverModule:28`)
is the only aim check on the shot path:

```lua
return aimFlat.Unit:Dot(facingFlat.Unit) >= math.cos(math.rad(125))
```

125° off the head's flat look vector permits a **250° arc**. Only the ~110° wedge directly behind the
player is rejected, which is why the exploit never needed to turn. It also flattens to XZ, so **pitch
is completely unchecked**.

A byte-identical copy lives in `VesperServer.SunspikeModule:241`. `BramServer.GrudgekeeperModule:472`
takes the same payload and has **no aim check at all**.

Note the check is *structurally* weak as well as loosely tuned: the client owns its character CFrame,
so `head.CFrame.LookVector` is attacker-controlled too. That does **not** make the fix pointless —
see §4.

## 2. Why a single tighter cone does not work

The obvious fix — drop 125° to ~20° — breaks legitimate shots.

On a fast flick the client fires the instant the camera lands on target, but the character's
*rotation* for that frame may not have replicated yet. At shot-processing time the server's newest
head sample can be **behind** the shot direction by up to one ping. A fast flick plus 100–150ms of
lag genuinely produces 60–90° of divergence. Rejecting those is the "my shots don't register" bug,
which is worse for the game than the cheat.

**Looking backward through position history does not fix this case** — it makes it worse. The
problem is the rotation arriving *later* than the shot, not earlier.

## 3. The design: split into a blocking gate and a deferred flag

### 3a. Synchronous gate (blocks the shot)

Replace the 125° constant with **~65°**, still checked against the newest head sample. Wide enough to
survive the flick/replication desync in the worst realistic case; takes the exploiter's usable arc
from 250° down to ~130°.

Add a **pitch term**. Currently `aimFlat`/`facingFlat` discard Y entirely, so a shot straight down at
a target under the map passes. Compare the full unit vectors, or gate pitch separately with a wider
tolerance than yaw (the head's pitch tracks the camera less tightly than yaw does).

### 3b. Deferred re-check (flags only, never blocks)

~250ms after the shot, re-test the recorded direction against the head orientation that has since
arrived. A shot whose direction never matched the player's facing within a **tight** cone (~30°)
anywhere across a ±300ms window is a violation → feed `AntiCheat.CombatChecker` (built 2026-08-29).

The strict threshold lives here, where a false positive costs a flag instead of a lost shot.

**Infrastructure is already present.** `HunterPositionHistory`
(`ReplicatedStorage.Hunters.Shared.HunterPositionHistory`) records tracked part **CFrames** at 1/30
for 0.65s, keyed by character model, and `Head` is in `TrackedBodyParts`. The shooter's own character
is in `GetTrackedEntities()`, so the shooter's head orientation history is already being recorded and
is currently unused. It needs one new method:

```lua
function HunterPositionHistory:GetSnapshotsInWindow(key, fromTime, toTime)
```

`CaptureSnapshot` stores `parts` as an **array** of `{name, cframe, size, hitboxType}` — find the
head by iterating and matching `name == "Head"`.

## 4. What this achieves, honestly

It breaks the current script outright and forces any successor to **rotate the character** to line
up. That rotation replicates, which means:

- other players visibly see them spinning, and
- the server can measure angular velocity of the replicated head between shots — a signal that is
  **not in the payload** and cannot be faked without also being visible.

It does not make a client-aimed hitscan weapon unaimbottable. Nothing does. It converts a silent
cheat into a visible one and hands the detector a signal it did not have.

## 5. Build checklist

Shared helper — put the cone test in one place rather than a third copy:

- [ ] Add `GetSnapshotsInWindow` to `ReplicatedStorage.Hunters.Shared.HunterPositionHistory`.
- [ ] New `ReplicatedStorage.Hunters.Shared.HunterAimValidation` with the synchronous cone test and
      the deferred re-check, so the three hunter modules call one implementation.
- [ ] `ServerScriptService.Hunters.DustServer.RevolverModule` — replace local
      `isAimDirectionReasonable`, keep the call site at `:444`.
- [ ] `ServerScriptService.Hunters.VesperServer.SunspikeModule` — same, `:241` / call site `:487`.
- [ ] `ServerScriptService.Hunters.BramServer.GrudgekeeperModule` — **add** the gate at `:472`; it
      currently has none.
- [ ] Wire the deferred flag into `ServerScriptService.AntiCheat.CombatChecker`
      (`recordExternalViolation`).

Per-place:

- [ ] All of the above in **Redwater Canyon** and **Frostbite Claim**. This is gamemode code,
      reconciled by `/mirror`, not one of the 20 universe-wide mirrored modules.
- [ ] Bounty (lobby) is not affected — no combat.

Verification:

- [ ] Syntax-check every edited script via `loadstring(script.Source)` before reporting done.
- [ ] `/mirror` clean between Redwater and Frostbite.
- [ ] Vault `.md` + graph rebuild for any new module (`HunterAimValidation`).
- [ ] **Live playtest with a high-ping client doing fast flicks** — this is the one that matters. The
      failure mode being guarded against is a legitimate flick shot being refused, and it will not
      reproduce in Studio at 0ms ping.

## 6. Do not do

- **Do not tighten the synchronous cone below ~60° without the ping playtest.** 125° was almost
  certainly chosen for the flick/lag case; going straight to 20° trades a cheat for a worse bug.
- **Do not delay damage** to wait for the rotation to arrive. The deferred check exists precisely so
  the damage path stays synchronous.
- **Do not rely on this alone.** It is one layer; `CombatChecker` is the other.
