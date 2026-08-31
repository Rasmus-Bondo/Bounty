# Mid-Match Hunter Switch — Handover

_Last updated 2026-07-23. Place: **Redwater Canyon** (`place:98517073248449`). All code lives in Roblox Studio; access via the `mcp__roblox-studio__*` tools._

## 1. Status

Players can switch to another **owned** hunter mid-round via a left-edge `⇄` HUD button. **Dust ⇄ Vesper is fully built and validated on mobile.** Bram and Fortuna are **deferred** — the server already accepts them, but their client stacks have no teardown wiring yet, so they are intentionally hidden from the switch UI.

**Remaining work = wire Bram and Fortuna into the swap** (client teardown + two config flips). That's what this doc is for.

## 2. How the feature works (architecture)

| Piece | Path | Role |
|---|---|---|
| **HunterSwitchService** | `ServerScriptService.PlayerServices.HunterSwitchService` | Server authority. Validates → 5s wind-up → `SetSelection` + respawn → 15s cooldown. Wired in `Main.Start()`. |
| `RequestHunterSwitch` | `ReplicatedStorage` RemoteEvent | Client→server: request a switch / query state. Created by the service. |
| `HunterSwitchState` | `ReplicatedStorage` RemoteEvent | Server→client: roster / owned map / cooldown / pending state. |
| **HunterSwitchClient** | `StarterPlayer.StarterPlayerScripts.HunterSwitchClient` | The `⇄` HUD + owned-hunter panel. Top-level, never torn down. |
| **HunterClientLoader** | `StarterPlayer.StarterPlayerScripts.HunterClientLoader` | On `SelectedHunter` attribute change: `HunterClientState.teardown()` then disable/re-enable every entry script. Top-level. |
| **HunterClientState** | `ReplicatedStorage.Hunters.Shared.HunterClientState` | The teardown registry: `registerCleanup(fn)`, `teardown()`, `generation`. |
| **HunterGate** | `ReplicatedStorage.Hunters.Shared.HunterGate` | `IsHunter` / `GetSelectedHunter` client gating util. |

**Swap flow:** client taps a hunter → `RequestHunterSwitch` → service validates (roster / round active / not pending / off cooldown / not current / **owned**) → 5s wind-up (still vulnerable = anti-escape) → `HunterSelectionService.SetSelection` + `SkinService.loadCharacter` (respawn, no death credited) → 15s cooldown. The `SelectedHunter` attribute flip drives the **client** half: `HunterClientLoader` tears the old hunter's client stack down and re-runs every entry script — the new hunter boots, the others gate straight back out.

## 3. The teardown contract (the load-bearing part)

Disabling a `LocalScript` does **not** disconnect its connections, unbind its render steps, or destroy the GUIs/buttons it made. So every per-hunter client entry script that creates **persistent** state must register a cleanup. Standard idiom (copied from `VesperScopeController` / `SunspikeClient`), placed **after** the hunter gate so off-hunter scripts still early-return before it:

```lua
local HunterClientState = require(huntersSharedFolder:WaitForChild("HunterClientState"))
local ownedConnections = {}
local function conn(signal, fn)
    local c = signal:Connect(fn)
    table.insert(ownedConnections, c)
    return c
end

-- Then convert every TOP-LEVEL persistent connection:
--   X:Connect(function(...) end)   ->   conn(X, function(...) end)
-- (leave transient in-function connections that self-disconnect alone.)

-- At the very end of the script:
HunterClientState.registerCleanup(function()
    -- pcall-guard everything; this runs during a LIVE swap.
    pcall(function() RunService:UnbindFromRenderStep("<YourNamedBind>") end)
    for _, c in ipairs(ownedConnections) do pcall(function() c:Disconnect() end) end
    table.clear(ownedConnections)
    -- destroy mobile buttons, controllers, GUIs; reset camera FOV; stop/destroy anim tracks.
end)
```

**Teardown checklist — undo everything the script created:**
- `UnbindFromRenderStep("<name>")` for every named bind. **A duplicate named bind ERRORS when the loader re-runs the script**, so this is mandatory, not optional.
- Disconnect every top-level `:Connect` (input, remotes, client bindables, attribute/property signals, `CharacterAdded`, `roundActive`).
- `:Destroy()` mobile buttons (`HunterMobileSprintButton`, `HunterMobileAbilityButton`, `HunterMobileFireButton`) — **capture them in a `local`; several existing scripts call `.new({...}):Start()` and discard the handle, which leaks.**
- `:Destroy()`/`:Reset()` controllers (FOV compositors, etc.). Reset `camera.FieldOfView` so the swapped-in hunter doesn't inherit a zoom.
- `:Stop()` + `:Destroy()` animation tracks; stop active sounds.

`HunterClientState.generation` is the safety net for any transient callback a cleanup misses: capture `local myGen = HunterClientState.generation` at boot and `if HunterClientState.generation ~= myGen then return end` inside long-lived callbacks.

## 4. Hard-won gotchas (do NOT re-introduce these — all fixed for Dust/Vesper)

1. **Cleanups must never YIELD.** They run sequentially in `HunterClientState.teardown()`; one `WaitForChild` stalls the whole swap. `HighNoonClient`'s cleanup deliberately avoids `chargeUI:Update` because `HighNoonChargeUI:GetUI` chains `WaitForChild("TemplateGameGui", 10)`.
2. **Mobile combat buttons: clear the `MobileCombatButton` attribute on teardown, not just `Enabled = false`.** `RoundClientController` re-enables any GUI still carrying that attribute on its restore pass — that's what left the Vesper scope button stuck visible after swapping to Dust. Fixed in `VesperScopeController`'s cleanup.
3. **Shared persistent toggle-button visuals must reset in `Destroy`.** `HunterSprintGui` is `ResetOnSpawn=false` and shared by all hunters; leaving it green made the next hunter's button capture green as its "inactive" baseline. Fixed inside `HunterMobileSprintButton:Destroy` (`_applyVisual(false)`), so it's handled centrally now.
4. **Respawn once.** `performSwitch` respawns only if the player is **alive**; if they died during the wind-up, `RoundController`'s respawn timer (`RESPAWN_DELAY = 6s > 5s` wind-up) rebuilds them once off the selection we set. Don't add another `loadCharacter` on the death path.
5. **Every per-hunter script must gate cleanly** (`HunterGate.IsHunter` / `HunterClientRuntime.Start` returning nil) so that when the loader re-runs it for the *other* hunter it early-returns before doing any work or registering a cleanup.

## 5. How to add a hunter to the swap

Do Bram first, then Fortuna (validate each with a playtest before the next).

1. **Audit** every client entry script in `StarterPlayerScripts.<Hunter>/` (plus any top-level script keyed off `SelectedHunter` for that hunter). List each persistent side effect.
2. **Add teardown hooks** to each (Section 3 idiom). Mirror the closest finished script (Section 6 says which).
3. **Verify gating** — confirm each script early-returns for the other hunter when re-run.
4. **Flip the two client config knobs:**
   - `HunterClientLoader.HUNTER_FOLDERS` — add `"Bram"` (then `"Fortuna"`).
   - `HunterSwitchClient.SWITCHABLE` — add `Bram = true` (then `Fortuna = true`).
   - (Server needs nothing: `HunterSwitchService.HUNTER_ROSTER` already lists all four.)
5. **Ownership note:** `HunterSwitchService.FREE_HUNTERS = {Dust, Vesper, Bram}`. **Fortuna is NOT free** — the switch row only shows for owned hunters, so the test account must own Fortuna or it won't appear.
6. **`loadstring`-verify** every changed script (Section 8).
7. **Playtest** (Section 8 checklist), on mobile especially.
8. **Sync vault + graph** (Section 9).

## 6. Concrete inventory — Bram & Fortuna

None of these have teardown yet. All the "big" combat controllers create a `HunterMobileSprintButton` via `.new({...}):Start()` **without storing it** (capture it first) and bind a **named** render step (must `UnbindFromRenderStep`).

### Bram — `StarterPlayerScripts.Bram/`
| Script | Gate | Needs teardown for | Mirror after |
|---|---|---|---|
| `GrudgekeeperClient` (~950+ L) | `HunterClientRuntime.Start` | sprint button (line ~67, unstored), `BindToRenderStep("BramGrudgekeeperViewModel")` (~951), all input/remote/client-event conns, its own viewmodel, `stopGrapple`-style state | **SunspikeClient** |
| `BramHunterGuiClient` (~583+ L) | `HunterClientRuntime.Start` | 3× `HunterMobileAbilityButton` (~541/554/567), 1× `HunterMobileFireButton` (~583), HUD conns | **VesperHunterGuiClient** |

### Fortuna — `StarterPlayerScripts.Fortuna/`
| Script | Gate | Needs teardown for | Mirror after |
|---|---|---|---|
| `CardsClient` (~1844+ L) | `HunterClientRuntime.Start` | sprint button (~55, unstored), `BindToRenderStep` (~1844), all input/remote/client-event conns, its own viewmodel | **SunspikeClient** |
| `CardsHunterGuiClient` (~512+ L) | `HunterClientRuntime.Start` | 3× `HunterMobileAbilityButton` (~470/483/496), 1× `HunterMobileFireButton` (~512), HUD conns | **VesperHunterGuiClient** |
| `CardsWorldVisualClient` | `HunterGate.IsHunter("Fortuna")` | its connections / world visuals | **WorldRevolverAimIdleClient** |
| `CardsClientDebug` | — | **Disabled** (`enabled=false`) — skip | — |

**Also audit (not yet confirmed):**
- Top-level scripts keyed to these hunters (e.g. `FortunaCardsWorldVisibilityClient` sits at top-level `StarterPlayerScripts`, like Vesper's `VesperPublicFXClient`). Decide per script: **hunter-local** (belongs in the cycled folder / needs teardown) vs **global public-FX** (serves all viewers — leave top-level, do NOT cycle). Vesper's `VesperPublicFXClient` is the "global, leave it" precedent.
- `HunterFirstPersonClient` early-returns for Bram/Fortuna (they own their **own** viewmodels — only Vesper uses the shared arms), so their viewmodel teardown must live in `GrudgekeeperClient` / `CardsClient`, not in `HunterFirstPersonClient`.

## 7. Known follow-ups / tech debt

- **SprintController duplication:** every `HunterClientRuntime.Start()` caller makes its own `SprintController`, and none destroy it on teardown (pre-existing; the finished scripts set this precedent). Watch for sprint feeling doubled after a swap-back. If it bites, the clean fix is to have the runtime cache one `SprintController` per boot (or destroy it in a cleanup).
- **Vault debt:** the per-entry-script `.md` "Direct require()" tables don't each list `[[HunterClientState]]` (the edges are captured centrally in `HunterClientState.md`'s Required-by, so the graph is correct). `VesperScopeDepthOfFieldClient` still has no `.md` at all (pre-existing).

## 8. Verifying (no MCP playtest — it hangs the plugin)

**Syntax check** any scripts you touch:
```lua
-- execute_luau, target "edit"
for _, s in ipairs({ game.StarterPlayer.StarterPlayerScripts.Bram.GrudgekeeperClient }) do
    local f, err = loadstring(s.Source)
    print((f and "OK " or "FAIL ") .. s.Name .. (err and (" -> " .. err) or ""))
end
```

**Manual playtest checklist (run in Studio, mobile emulator for the button cases):**
1. Swap **to** the hunter and **back** — no `RenderStep already bound` error in output; ability/viewmodel work both ways.
2. After swapping away, its keys/abilities do **not** fire (no leaked input); FOV isn't stuck zoomed.
3. Mobile: its Scope/Sprint/Ability/Fire buttons disappear when you leave the hunter and reappear when you return; **sprint button not stuck green**; no doubled buttons after a couple of cycles.
4. Fire plays **one** shot sound (not 2–3) after cycling.
5. Swap → **die during the 5s wind-up** → confirm a **single** respawn as the new hunter.
6. Trigger a swap right as the round ends (should cancel, no cooldown).

## 9. Vault + graph maintenance (project rule)

Keep the Obsidian vault in sync (`LocalRedwaterCanyon/` mirrors the script tree). New script → new `.md`; new `require`/Remote/Bindable → update both sides' Connections. After edits run:
```
python update_redwater_canyon_graph.py
```
(regenerates `graphs/RedwaterCanyonGraph/{graph.json,graph.html,GRAPH_REPORT.md}`; `--full` forces a rebuild). Query with `/graphify query "..."`.

## 10. Memory pointer

The auto-memory `project_hunter_switch_midmatch.md` has the condensed version of all of the above (architecture, teardown pattern, and the three playtest fixes with their root causes). It loads automatically next session via `MEMORY.md`.
