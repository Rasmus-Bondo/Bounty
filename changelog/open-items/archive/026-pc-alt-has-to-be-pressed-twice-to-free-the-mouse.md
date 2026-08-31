# 26 — PC: Alt has to be pressed twice to free the mouse, and again after every death

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner decision to retire the launch-issue list.

**This one did not close on "no recurrence" and the record should not read that way.** It was
**reopened the same day** after two shipped fixes failed on the first Alt hold of a live session,
and the `GuiButton.Modal` reimplementation that replaced the mechanism is **in Studio, unreleased
and unplayed**. It also does not reproduce in Studio at all, so nothing but live play can confirm
it. If the first-hold failure appears again, raise it as a **new id** — do not reopen #26.

---

**Status:** **REOPENED 2026-08-11** after two shipped fixes — reimplemented on `GuiButton.Modal` in
Studio the same day (unreleased); **it does not reproduce in Studio, so it closes only on live play**
· **Sev:** P2 · **Area:** Redwater — PC input / settings

**Reported 2026-08-05 (owner, live play):** On PC you still have to press Alt twice before the cursor
comes free, and after dying you have to do it again.

**Notes:**
- **Establish the shape before fixing it.** Alt is documented as a *hold*, not a toggle:
  `SettingsController` frees the cursor while `LeftAlt`/`RightAlt` is down and re-locks (and
  force-closes the panel) on release. So "press twice" most likely means *the first hold does nothing
  and the second one works* — not that a toggle is stuck out of phase. Those two have different
  causes and the report does not distinguish them.
- **This is a recurrence of a bug already fixed once — start from that fix, not from scratch.** The
  "first Alt press after joining does nothing, a later one works" symptom was traced to PlayerModule's
  `CameraUtils`, which keeps a `MouseBehavior` property-changed handler installed while the player is
  in `LockFirstPerson` and snaps a one-shot `Default` straight back to `LockCenter`. The fix re-forces
  the free cursor **every render step** (`forceUnlockedCursor`, inside the head-follow bind), drops
  `Player.CameraMode` to `Classic` and takes `CameraType` to `Scriptable`. All of that is still in the
  file, so either some path re-establishes the lock in a way the per-frame guard does not cover, or
  the guard is not armed yet on the first hold.
- **The per-life half is the sharper clue, and it is new — the old bug was per-session.** Something on
  the respawn path re-locks. Candidates: a hunter client's `setGameplayMouseLocked(true)` on spawn /
  round start (the hold defends against that landing *mid*-hold, but not necessarily against it
  landing between holds), and the fact that `KillCamClient` and `HunterSwitchClient` both deliberately
  leave the cursor **free** while the player is down — so the `CameraType` / `CameraMode` /
  `MouseBehavior` state Alt saves on press may be captured free and restored into a life that expects
  the lock. Check what the saved table actually holds across a death.
- **PC only.** The whole Alt path is skipped on touch devices, which tap the gear directly, so nothing
  here should change mobile.
- **Where to look:** `SettingsController` behaviour 4 and its sub-bullet (the Alt hold and
  `forceUnlockedCursor`) and behaviour 16 (the `Humanoid.Died` / `CharacterAdded` auto-close), plus
  whichever hunter client owns `setGameplayMouseLocked`. The vault names `SettingsController` as the
  only Alt handler in the place — confirm that against live source before assuming no second writer.

- **#28 is very likely this same defect seen more clearly**, and it is diagnosed. Read it before
  touching anything here: the Alt hold snapshots camera and cursor state on press and restores it on
  release, and **nothing invalidates that snapshot when the character changes underneath it**. Fix
  that and re-test this one before hunting a separate cause.
- **That last note was right.** Owner confirmed 2026-08-05 that this only ever reproduced on the
  live server and never in Studio — which is the signature of the #28 race, not of a second cause:
  the polluted snapshot can only be taken inside the death → respawn window, and that window is
  seconds wide live and a frame or two wide in Studio.

**Fix:** #28's fix, plus two independent hardening changes in the same block that could each produce
"needs pressing twice" on their own. See the `UNRELEASED.md` entry for the full write-up.
1. The stale snapshot restored into a fresh life (#28) — the shared root cause.
2. **Ordering:** the cursor is now freed *before* the camera goes `Scriptable`, matching
   `KillCamClient.claimCameraOnDeath`. Reversed, PlayerModule parks with its `LockCenter` override
   still installed and nothing ever restores it, so the per-frame `Default` write loses every frame
   and the whole hold stays centre-locked. This is the old "first press after joining does nothing"
   bug's actual mechanism, still present in the ordering after the earlier per-frame fix.
3. **`WindowFocusReleased` ends the hold.** Alt-tabbing is a press whose release is never delivered,
   which latched the hold open — the next press then early-returned and only its release re-locked,
   which is *literally* "press twice".

**Still to verify (human, live server — Studio cannot reproduce it):** after a death, press Alt once
and confirm the cursor frees on the first hold; repeat across several deaths in one match; Alt-tab
mid-hold and confirm the next press behaves.

**Reopened 2026-08-11 (owner, live play, third report):** the first Alt hold of a live session still
does nothing — on the Hotfix 13 build, i.e. with every fix above shipped. Rather than a third round of
the same ownership fight, the mechanism was replaced outright in `SettingsController` the same day
(in Studio, unreleased):

- **The hold now works by engine rule, not camera surgery.** A 1×1 transparent authored
  `AltUnlockModal` TextButton (`StarterGui.ReworkedSettingsGui`) with `Modal = true` is made
  `Visible` while Alt is down. A visible Modal GuiButton means *"the mouse will not be locked unless
  the right mouse button is down"* — engine-level, sitting **above** the first-person lock the two
  shipped attempts kept losing to, and indifferent to `CameraType` / `CameraMode` / `MouseBehavior`
  entirely, so it cannot behave differently in Studio and live.
- **Nothing is saved, restored, or handed back any more.** The gameplay lock stays asserted by the
  hunter clients for the whole hold and is merely suppressed; hiding the button is the re-lock. The
  snapshot / life-boundary hand-off machinery from the fixes above is deleted, which also makes the
  #28 camera-stranding failure unrepresentable. The only state the hold still manages is the cursor
  icon: re-shown per frame during the hold, set by rule (`isAliveInRound`) on release.
- **Verify on live, same list as above, plus:** the camera neither strands nor jumps on release, and
  right-drag during a hold rotates the camera (expected — same engine rule) without re-locking after
  the drag ends.
