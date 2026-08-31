# 125 — Lobby Collection previews depend on an animation fetch to render at all

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Status:** OPEN · **Sev:** P3 · **Area:** Bounty (lobby) — Collection / bundle preview viewports

**Raised 2026-08-24**, while fixing the empty bounty-card portraits in the match places (see that
entry in the release notes). Not observed failing in the lobby — this is the same latent fault, one
step away.

**Symptom if it fires:** a Collection grid tile, or the bundle home card, renders an *empty*
ViewportFrame — not a T-pose, which is what the code comments there anticipate. Only the rig's
rigid meshes (hat, hair) draw; every skinned body part is invisible.

**Mechanism.** Removing a rig's `Animate` LocalScript stops its skinned MeshParts from rendering
inside a ViewportFrame. The match places hit this because their portraits are static. The lobby's
three strip sites do the same thing —

- `StarterPlayer.StarterPlayerScripts.CollectionClient.ViewportIcon` → `cleanModelForViewport`
- `StarterGui.CollectionGui.CollectionGuiController.Viewport` → `Viewport.cleanModel`
- `StarterGui.BundleGuiHomeScreen.BundleHomeController` (inline, in its preview `task.spawn`)

— and render correctly only because each one plays an idle `AnimationTrack` on the rig immediately
afterwards, which drives the pose. **The picture is therefore hostage to an asset fetch.** If
`AnimationLoader.load` fails (a cold CDN, a moderated or deleted id), the existing code warns and
returns, leaving the rig unposed — and now invisible rather than merely still.

**Fix, if taken:** the same one the match places got — disable the scripts instead of destroying
them (`descendant:IsA("BaseScript") → .Enabled = false`). It costs nothing and removes the
dependency; the idle track then only affects whether the preview *moves*.

**Left alone deliberately for now:** all three sites currently render correctly, and the lobby
previews are the most-looked-at UI in the game. Changing three working scripts on the strength of a
failure nobody has seen is not worth doing in the same pass as the match-place fix.

**Test that closes it:** with the fetch made to fail (point the idle id at a nonexistent asset in a
Studio session), a Collection tile still shows its hunter, standing still. Then restore the id and
confirm the tile animates again.
