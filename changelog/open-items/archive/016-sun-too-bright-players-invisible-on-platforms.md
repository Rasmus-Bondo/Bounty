# 16 — Sun too bright; players invisible on platforms

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#16 — Sun too bright; players invisible on platforms.** *(VERIFIED in playtest by the owner
2026-08-03. **Shipped in [Hotfix 5](../../2026-08-03-hotfix-5.md).**)* Fixed by
a single property: **`Lighting.SunRays.Enabled` → `false`**. Nothing else changed; every other
lighting value is still at its authored baseline. Redwater only — `Lighting` is not a mirrored
module, so Bounty is unaffected.

**"Turn the sun down" was the wrong lever, and this is the part worth not re-deriving.**
`Lighting.Brightness` (3.5) scales the *directional light landing on surfaces*, not the sun disc
or its halo. Dropping it 3.5 → 2.5 visibly darkened the canyon rock while the sun disc stayed
**pixel-for-pixel identical** — so it dims the player standing on the platform without touching
what is blinding the viewer, making the silhouette *worse*. `Brightness` is still 3.5 and should
stay there.

**Ruled out by the owner in a live playtest — do not re-test these:**
- *`Bloom` was the cause.* It was the leading hypothesis from the numbers (`Intensity` 1.0 vs
  Roblox's 0.4 default, `Size` 24, `Threshold` 2 — a wide additive kernel that should smear a
  bright sky over a thin silhouette). **It had no observable effect.** `Bloom.Intensity` is
  still 1.
- *`Sky.SunAngularSize`.* In an **edit-mode** A/B, 11 → 5 appeared to fix it almost completely
  and looked like the surgical single-property answer. That result did not hold up: **this
  effect is only visible with the game running**, and edit-mode captures do not resolve the
  lighting pipeline the same way. Left at 11. Treat any edit-mode-only lighting comparison in
  this place as indicative at best.

**Geometry worth keeping, because it is independent of the render path.** At the reported
framing — standing on the ground looking up at a ridge — the sun sits **15° off the camera axis
inside a 35° half-FOV**, at **46.7° elevation** with `ClockTime` 14.5. Players looking up at
platform height are looking straight into it. That is structural, so if the residual wash-out is
ever revisited, raising `ClockTime` toward 12 (which lifts the sun *out of* that sightline) and
`OutdoorAmbient` (0.275 grey, all that keeps a backlit player's underside off black) are the two
untried levers. Both change the map's warm late-afternoon grade, which is why neither was
touched here.

**Note on scope:** the owner reported the fix as helping *"a little"* and elected to close the
item on that basis. The worst of the glare is gone; if players are still reported washing out on
platforms, this is the entry to reopen rather than a fresh diagnosis.

**Trap for anyone testing visibility in this map:** `Workspace.WallMap` is 65+ barrier parts at
`Transparency = 1`. Raycast-based "is there sky behind this target?" checks count them as
occluders and return false negatives unless invisible geometry is filtered out.
