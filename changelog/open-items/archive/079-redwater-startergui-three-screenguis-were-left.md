# 79 — Redwater `StarterGui` — three ScreenGuis were left `Enabled = false` that must be `true`

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**`VERIFIED` (fixed 2026-08-08, same session, never published) · Redwater `StarterGui` — three
ScreenGuis were left `Enabled = false` that must be `true`.** Corrected the moment Redwater's
Studio connection came back: `ReworkedSettingsGui`, `StatMenuGui`, `BountyListGui` and
`VictoryShowcase` set back to `true`; `RoundStatusGui` was already correct. **A fifth,
`SwapHunterGui`, was missed by that pass and caught by the user** — the SWAP HUNTER button never
appeared in the kill cam, because `HunterSwitchClient` only toggles `panel.Visible` and never
assigns `gui.Enabled`, so the ScreenGui must stay on. It postdates the confirmed list, which is
why neither the list nor the `RoundClientController` trace covered it. Final audited state is
**6 true** (`BountyListGui`, `ReworkedSettingsGui`, `RoundStatusGui`, `StatMenuGui`,
`SwapHunterGui`, `VictoryShowcase`) and **13 false**, each of the 13 confirmed either
script-driven or a runtime-cloned template. This never reached a published place.
Kept here in full because the *cause* is the reusable part. On 2026-08-08 I disabled all 19 ScreenGuis under
Redwater's `StarterGui` to take a clean edit-mode screenshot, and lost the snapshot of their prior
states (it was a local inside a single `execute_luau` call, and each call is a fresh scope).
I reconstructed the authored values by tracing `RoundClientController` and restored only
`RoundStatusGui = true`. **That reconstruction was wrong.** The user-confirmed authored-`true` set
for Redwater also includes **`ReworkedSettingsGui`**, **`StatMenuGui`** and **`BountyListGui`** —
they are persistent-button-with-hidden-panel HUDs whose ScreenGui stays enabled so the gear /
stats / bounties button shows, while only the child panel's `.Visible` toggles. Nothing in
`RoundClientController` reveals that, which is why the trace looked convincing. `ReworkedSettingsGui`
is the dangerous one: **no script ever re-enables it**, so a stray `false` is permanent and the
settings gear simply disappears — the exact regression already shipped once on 2026-07-27.
`VictoryShowcase` should also read `true`, though it is forced on at runtime by
`ALWAYS_ENABLED_GUIS` so it is harmless either way.
**To fix** (Redwater `StarterGui`, set `Enabled = true`): `ReworkedSettingsGui`, `StatMenuGui`,
`BountyListGui`, `VictoryShowcase`. `RoundStatusGui` is already correct. Everything else stays
`false`. **Done** — applied and read back, and the session's script edits and the new jump icon
were confirmed still present and compiling after the reconnect. See the memory note
`feedback-startergui-screenshot-restore` — this is its
third recurrence, and the fix is mechanical (persist the snapshot outside the tool call, or flip
only the two or three GUIs that overlap the shot).
