# 18 — Titles appear before the nameplate fades in

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Status:** **VERIFIED by the owner 2026-08-05**, on the owner's sign-off rather than a reported
playtest run · **Sev:** P3 · **Area:** titles / nameplates — **both places** (`TitleRenderer` is
mirrored) · In Studio, **not yet published**

**Reported:** The Deadeye title shows before players and names fade in. All titles should fade in properly.

**Notes:** Reported against Deadeye but stated as a general fix — the whole title layer should share the nameplate's fade. Watch for the `TextScaled` billboard ghost when adjusting title transparency.

**Cause (2026-08-05): `TitleRenderer.apply` builds every effect instance at its authored alpha and
never consults the host label's current `TextTransparency`.** Applying a title to a label that is
*already* faded out therefore paints a fully-drawn title over an invisible plate.

**The reporter's instinct that it should be general was right, but the defect is not.** Only the
**static** presets leak, because only they lack a per-frame pass: `animate` re-derives `hostAlpha`
every frame (`TitleRenderer:971`) and calls `hideEffects` when it is ~0, so an animated title
self-corrects on the next Heartbeat. `refreshStatic` (`:1167`) never read `hostAlpha` at all — it
only re-fits geometry. Measured on a label held at `TextTransparency = 1`:

| Title | Style | After `apply` | After 0.8s |
|---|---|---|---|
| DEADEYE | `tint` (static) | stroke 0.40, bloom 0.58 / 0.89 | **unchanged — still lit** |
| DEADEYE, `TitleAura=false` | `tint` (static) | stroke 0.40 | **unchanged — still lit** |
| HIGH NOON | `fire` (animated) | bloom 0.52 / 0.86 / 0.95 | 0 lit — self-healed |

The *normal* build order (apply while visible → surface hides the plate) does **not** leak, verified
at 16px and 30px, so this is specifically the apply-onto-a-hidden-label path — which is exactly
`HealthBarController.refreshTitle` on its `GetAttributeChangedSignal("EquippedTitle")` listener
(`:281`), the plate being hidden between reveals for most of its life. `KillCamClient:660` reuses one
label across kills and has the same shape.

**Blast radius: exactly 7 of 28 catalog titles**, being the only ones on a static preset that builds
effects (`plain` builds none, so `tint` and `gradient` are the whole set) — DEADEYE, DRIFTER, EAGLE
EYE (tint), IRON BUCK, THE DEALER (tint), BREACHER, GUNHAND (gradient). That 21 titles fade correctly
is why this was reported as a Deadeye bug.

**Fix (2026-08-05, `TitleRenderer` only, mirrored to both places):**
1. `apply()` parks the effects via `hideEffects` when the host is fully transparent. Safe to park at
   `Transparency = 1` because every surface restores an effect from its `TitleFXBase` **attribute**,
   not the live property (`HealthBarController:85`, `VictoryShowcaseClient:30`), so the fade-in still
   returns each one to its authored alpha.
2. `refreshStatic` takes the same `hostAlpha` gate `animate` has, and rewrites on the hidden→visible
   transition. This closes a **second** leak: its re-fit rewrote every bloom layer's `Transparency`
   from the authored value unconditionally (old `:1189`), so a static title could re-light itself on
   a hidden plate whenever the glyph box moved — and a stud-sized `TextScaled` nameplate re-fits
   continuously as the camera moves. Restoring from the transition rather than from the surface's
   sweep also means a surface with no fade of its own cannot strand the decoration off.

**Verified by probe, since MCP playtesting is unavailable.** Module recompiled from source with
`loadstring` (the plugin's `require` cache holds the pre-edit copy) and driven through four cases:
apply-onto-hidden now parks all 3 effects for both static and animated; apply-onto-visible still
renders all 3 at exactly their authored alphas (0.58 / 0.89 / 0.40, no over-hiding); fading the host
back to 0 restores all 3; fading to 1 re-parks them. Both copies compile and are byte-identical
(58863 bytes, 1555 lines, checksum 1983794402).

**Regression checklist if this area is touched again:** hit a player wearing DEADEYE (or any of the
other six) and confirm no outline of the title appears before the nameplate fades in, and that the
title is fully drawn once the plate is up; confirm an *animated* title (HIGH NOON, fire) is visually
unchanged. Note the seven affected titles are grouped by **style**, not hunter — Dust carries three
of them (DEADEYE, DRIFTER, GUNHAND), so Dust is the fastest hunter to exercise this on.

**The "parked with nothing to restore it" risk was closed by construction, not left to the playtest.**
Only a *registered* state is ever restored, so a preset that builds effects without registering would
be parked permanently. Audited all 12 presets: every one that builds effects satisfies
`animated or gradient or bloom` and is registered — **0 orphans** — and `plain` builds nothing, so
`hideEffects` is a no-op there. Bounty's four surfaces (Collection TITLES rows, the TITLES-tab preview
billboard, the Trading Post card, the lobby dummy nametag) are therefore safe even though none of them
fades its labels: `refreshStatic` rewrites on the hidden→visible transition regardless of the surface.
