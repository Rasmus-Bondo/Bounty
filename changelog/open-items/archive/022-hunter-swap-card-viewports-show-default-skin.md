# 22 — Hunter swap card viewports show default skin instead of equipped skin

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner decision: no recurrence in the ~2 weeks since the 2026-08-01 launch. Closed on elapsed time, **not** on a playtest — the status below was still `FIXED (unverified)`.

---

**Status:** FIXED (unverified) → [Hotfix 8](../../2026-08-05-hotfix-8.md) · **Sev:** P3 · **Area:** Redwater — hunter switch

**Reported:** The ViewportFrames in the kill-cam hunter swap card row render each hunter in their default skin. They should show whichever skin the player has equipped for that hunter.

**The first standing note was wrong, and it is the thing to know before touching this area again.**
The equipped skin is **not** known client-side at death time. The only skin attributes the client
has are `SelectedHunterCategory` / `SelectedHunterSubfolder` / `SelectedHunterModelName`, and those
describe the **hunter the player is currently playing** — one hunter, not four. (`HunterPortraitClient`
reads exactly those three for the HUD portrait, which is why *that* portrait was always right and
these four were not.) There is no per-hunter equipped-skin attribute, and `EquippedSkins` lives in the
profile, which is server-only. So this could never have been a client-only change; the card row had
no way to know what Vesper was wearing while you were playing Dust.

**Fix (2026-08-05, `HunterSwitchService` + `HunterSwitchClient`):**
1. **Server — `buildModelMap`, a new `models` field on the `pushState` table.** For every roster
   hunter it resolves `resolveSelection(hunter, getEquippedSkin(player, hunter))` — *exactly* the
   pair `applyPending` spawns from, deliberately reusing both rather than re-deriving. That is what
   makes the picture and the spawn agree by construction, including the "equipped a skin, then
   stopped owning it" case, which both paths degrade to the default identically. Sent as the
   **resolved** `{category, subfolder, modelName}`, never a skin name, so the name→model rule stays
   solely in `HunterSelectionService` (the drift its note 5a exists to prevent) — the client already
   has `ReplicatedStorage.Characters` to walk.
2. **Client — `applyPortraitModel`, called from `render`.** Swaps the rig inside the cloned
   ViewportFrame's `WorldModel` for a clone of the named model, then re-derives the camera off the
   new rig (skins differ in height and silhouette). Four properties it has to have, each for a
   reason: **not at build time** — portraits are built at card registration, which runs before the
   state remote is even connected, so the card renders in its authored default immediately and is
   re-dressed on the first push; **idempotent** — `render` runs on every push, and rebuilding the rig
   each time would flicker all four portraits mid-kill-cam; **generation-guarded** — a later spec has
   to beat one still resolving; **off-thread** — resolving a skin model yields on `WaitForChild`, and
   `render` is called from the state handler.
3. **`Default` maps to the authored template clone, not `Characters/<Hunter>/Default`.** The template
   *is* the default look; re-resolving would introduce a second rig that then has to be kept
   identical to it forever. Confirmed the two are not interchangeable in the way you would assume:
   Bram's authored viewport rig is named `BramDefault` while every other hunter's is named `Rig`.
4. **A model that fails to resolve leaves the default portrait standing and warns.** A wrong picture
   beats an empty box, which reads as a broken menu — the exact symptom of #20.
5. **The dressing is isolated from the visibility path.** `render` runs from the state handler
   **above** `refreshVisibility`, and its card loop is a shared `pairs` pass, so a throw while
   dressing a portrait skips every later card *and* the visibility call — the SWAP HUNTER button
   stays hidden for the rest of that life with nothing scheduled to look again, i.e. **#20's exact
   failure mode by a new route**. This feature introduced one and it was caught by fuzzing the
   payload, not by reading the diff: `state.models and state.models[hunter]` passes a truthy check
   and then **throws** on a non-indexable value such as a number, and the button demonstrably never
   appeared. Not reachable from our own server (`buildModelMap` always returns a table) but it is a
   remote payload, and the file already type-checks `state` and `state.message`. `models` is now
   type-checked and the `applyPortraitModel` call is `pcall`ed. **Anything added to `render` in
   future must hold this property** — the swap window cannot depend on cosmetics resolving.

**`Anchored` is deliberately left alone**, against the instinct from the portrait-anchoring rule
(HUD portraits anchor root-only). These cards are **static** — no `Animate`, no animation loaded —
and the authored templates are unanchored `AnimationConstraint` rigs that already render correctly.
No physics runs inside a viewport, so there is nothing to hold still, and root-only anchoring is what
makes welded accessories snap to their joint-defined position instead of the authored one. If a
portrait accessory ever looks moved, this is the first thing to check.

**Verified by simulation + screenshot, since MCP playtesting is unavailable.** The **real shipped
`HunterSwitchClient` source** was recompiled with `loadstring` and run in a `setfenv` sandbox (stub
Players / remotes / UserInputService, a real `SwapHunterGui` clone, the real
`ReplicatedStorage.Characters`) — 6 of 6 passed: skin applied per hunter; a push carrying **no**
`models` field leaves the default standing and does not throw (so an older server payload degrades
rather than breaks); Skin→Default restores the authored rig; a spec resolving to a non-Model leaves
the default standing and warns exactly once; rapid re-spec lands on the last one; camera re-framed to
`PORTRAIT_DISTANCE` (4.60) on every swap. Re-pushing the same state rebuilt **zero** rigs
(idempotency). `HunterSelectionService.resolveSelection` was sandboxed separately — with `require`
stubbed, so DataService/ProfileService are never touched, since Studio writes the LIVE store — and
all 7 authored skins across the four playable hunters resolve to real Models. A second suite fuzzed
the `models` payload across 12 malformed shapes and asserts on the **button**, not the portrait —
handler survives, `swapFrame.Visible` still goes true, all 4 cards still render: **12 of 12, against
1 failure before the guards**, plus both retire paths (respawn push, round ending while down).
Screenshot-verified via
a CoreGui clone: Vesper renders unmasked and Fortuna in Ivory Gambler while Dust and Bram keep their
authored look, all four framed identically; an all-`Default` push is pixel-identical to the previous
behaviour, so a player with nothing equipped sees no change. Both scripts compile (312 / 759 lines).

**Still to verify (human, MCP playtesting unavailable):** die in a live match with a non-default skin
equipped on a hunter you are **not** currently playing, and confirm that card shows it; confirm the
portrait does not flicker or pop while the kill cam is up (that is the idempotency check, and the one
thing simulation can only approximate); confirm a hunter with no skin equipped looks exactly as it
did before; confirm cold-join still renders all four portraits rather than empty boxes (#20's
symptom, which this path now also touches).
