# Bram bot / player weapon — next steps

_Handoff as of 2026-07-24. Redwater Canyon place (id 98517073248449)._

## Done (in Studio edit DataModel — NOT SAVED YET, save the place to keep)
- **`ReplicatedStorage.Grudgekeeper.WorldShotgun`** — new world-model template (clone of the
  first-person `ArmsViewModelBramNew.Shotgun`), scaled to **3.3-stud length**. Used by bots
  (and later real players).
- **`StarterPlayer.StarterPlayerScripts.BotVisualClient`** edits:
  - `LOCAL_WORLD_MODEL_CONFIG.Bram` + `getLocalWeaponTemplate` Bram case → attaches WorldShotgun.
  - `BRAM_HOLD_POSE` (6 Motor6D.Transform CFrames) + arm-lock in the RenderStepped copy loop →
    Bram bots hold the shotgun cradled forward instead of dangling/swinging.
  - Gun offset `CFrame.new(0,0,0, 0,0,-1, 0,1,0, 1,0,0)` is **paired with the hold pose** —
    don't change one without the other.
  - Compiles clean (loadstring-checked).

## Verify first
- Restart the Redwater playtest, spawn a **Bram bot**, confirm it holds the shotgun forward,
  level, believable size. Nudge `BRAM_HOLD_POSE` / offset / scale if the angle or height is off.

## TODO (both still requested, not started)
1. **Shot muzzle/tracer FX for Bram bots** — BotVisualClient's `BotShotFX` handler currently
   only covers Dust/Fortuna/Vesper. Add a Bram branch (Grudgekeeper shotgun: muzzle flash +
   pellet/tracer). Server side broadcasts via `BotCombat` `BotShotFX`.
2. **Real Bram players — third-person parity.** Real Bram players have NO world gun at all
   (Bram is the only hunter with no `HunterWorldModel` server — Dust/Fortuna/Vesper each have
   one). Needs: a Bram world-model server (attach WorldShotgun with the offset above) **plus**
   the same `BRAM_HOLD_POSE` applied to the real character's arms per-Bram-player on every
   client (bigger job than the bot case).

## Context in auto-memory (loads automatically next session)
- `project_bram_hunter.md` — full detail on the above (pose derivation, why the gun swung, etc.).
- `feedback_startergui_screenshot_restore.md` — the StarterGui Enabled cleanup lesson.
- Redwater authored-enabled StarterGui ScreenGuis: `VictoryShowcase`, `VictoryTop3Gui`,
  `DailyQuestGui`, `BountyListGui`. All others authored `false`.
