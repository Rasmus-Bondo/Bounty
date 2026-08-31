# 28 — Holding Alt through a kill-cam respawn strands the camera for the rest of the life

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner decision: no recurrence in the ~2 weeks since the 2026-08-01 launch. Closed on elapsed time, **not** on a playtest — the status below was still `FIXED (unverified)`.

---

**Status:** FIXED (unverified) → [Hotfix 8](../../2026-08-05-hotfix-8.md) — **closes only on live play** ·
**Sev:** P2 · **Area:** Redwater — PC input / camera ownership

**Reported 2026-08-05 (owner, live play):** Hold Alt while in the kill cam and keep holding it through
the respawn, and you are stuck in the Alt camera frame for the rest of that life. The only way out is
to die again.

**The report is exactly right and the mechanism is in the source.** `SettingsController.unlockMouse`
(`:295`) snapshots four values on the Alt **press** — `camera.CameraType`, `localPlayer.CameraMode`,
`UIS.MouseBehavior`, `UIS.MouseIconEnabled` — and `lockMouse` (`:330`) writes all four back on the
**release**. Nothing invalidates that snapshot in between. `unlockMouse` and `lockMouse` have exactly
two call sites, the `InputBegan` / `InputEnded` pair at `:380` / `:387`; the script's
`CharacterAdded` connection (`:252`) only closes the panel and never touches the hold. **So a snapshot
taken in one life is restored into the next one.**

That is fatal here specifically because of *what* is true during a kill cam. `KillCamClient` sets
`camera.CameraType = Scriptable` in six places (`:407`, `:780`, `:916`, `:930`, `:974`, `:1024`) and
deliberately leaves the cursor free. So an Alt press during the kill cam saves **`Scriptable`** as the
"normal" camera type. On release — now in a fresh, living character — `lockMouse` stamps `Scriptable`
back onto the live gameplay camera and unbinds its own follow. **The camera is now Scriptable with
nobody driving it**: the Alt bind is gone, the kill cam is finished, and the engine will not touch a
Scriptable camera. The view freezes in space while the character walks out from under it, and the
cursor stays free because `MouseBehavior = Default` was restored from the same stale snapshot.

**"Until they die" is the confirmation, not a coincidence.** The next death is the only thing that
re-establishes camera ownership: `KillCamClient:816` and `RoundClientController:379` / `:397` write
`CameraType = Custom` on that path. Nothing else in the place will take a Scriptable camera back.

**A second aggravator, less certain and worth checking during the fix:** `unlockMouse` captures
`workspace.CurrentCamera` into a local at press time and its render bind steers *that object*, while
`lockMouse` re-reads `workspace.CurrentCamera` at release. If the camera instance is replaced across
the respawn — `RoundClientController` distinguishes `currentCamera` from `latestCamera`, so it treats
replacement as real — the hold spends its post-respawn frames steering a camera nobody renders, and
then stamps the stale snapshot onto the new one. Verify whether the instance is genuinely replaced
before writing a fix that depends on either answer.

**Direction, not a decision:** the gap is the snapshot outliving its character, so the fix belongs at
the character boundary — on `CharacterAdded` while a hold is active, either drop the saved values (and
let whoever owns the new life set the camera) or re-take them against the new life. **Do not simply
restore `Custom` whenever the saved type is `Scriptable`** — pressing *and* releasing Alt inside the
kill cam is a legitimate case where `Scriptable` is correct and the kill cam still owns the camera.

**Repro (PC only — the whole Alt path is skipped on touch):**
1. Die, and while the kill cam is up press and **hold** Alt.
2. Keep holding through the respawn.
3. Release Alt once alive. The camera should stay frozen where it was and the cursor stay free.
4. Confirm you cannot recover it by pressing Alt again, and that dying clears it.
5. Regression case for any fix: press **and** release Alt entirely within the kill cam, and confirm
   the kill cam camera is undisturbed.

**Fix:** the hold now ends at the character boundary instead of crossing it (`SettingsController`,
`releaseHoldForLifeChange`). On `Humanoid.Died` it stands down and touches nothing — the kill cam
already claimed the camera and re-asserts every frame, so the hold stops fighting it too. On
`CharacterAdded` it hands the camera back through `applyGameplayLock`, which writes the four values
every hunter client's own `setGameplayMouseLocked(true)` writes, and converts `CameraType` **only**
when it is currently `Scriptable` — so it un-strands its own camera without taking one off a script
that owns it. A character check in `lockMouse` is the backstop for any path reaching the release
first, which is what keeps repro step 5 working: same character, so the snapshot is restored exactly
and the kill cam is undisturbed. As directed, `Scriptable` is never blanket-converted to `Custom`.

The hand-back is **spawned and gated on the Humanoid**, not inline: on a live server `CharacterAdded`
regularly beats the Humanoid's replication, and an inline liveness check reads false for a character
about to be perfectly alive — skipping the hand-back is exactly what strands the camera. Do not
"simplify" it back inline.

**The second aggravator was checked and is not in play.** `workspace.CurrentCamera` is *not* replaced
across a normal respawn here — if it were, `RoundClientController.bindCurrentCamera` (on
`workspace:GetPropertyChangedSignal("CurrentCamera")`) would have deferred a `restoreCamera` and the
stranded camera would have healed itself, which is precisely what the report says does not happen.
The follow bind re-reads `CurrentCamera` each frame anyway, so a hold spanning a teleport or rejoin
is covered regardless.

**Still to verify (human, live server):** all five repro steps above, step 5 especially.
