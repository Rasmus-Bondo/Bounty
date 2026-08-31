# 27 — Bram's Last Call aura reads as a bounty aura

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner decision: no recurrence in the ~2 weeks since the 2026-08-01 launch. Closed on elapsed time, **not** on a playtest — the status below was still `FIXED (unverified)`.

---

**Status:** the recolour is FIXED (unverified) → [Hotfix 8](../../2026-08-05-hotfix-8.md); the separate
**Highlight-clobber defect measured alongside it is still OPEN** and was deliberately not addressed
· **Sev:** P3 · **Area:** Redwater — Bram / bounty readability

**Reported 2026-08-05 (owner, live play):** The aura Bram gets from his ultimate can be mistaken for
the bounty aura. They should look clearly different so the two do not get confused.

**Notes:**
- **The two really are close, so this is a design decision rather than a bug hunt.** Last Call mounts
  `BramLastCallHighlight` — ember fill `214,106,42` at 0.55, outline `255,170,90`, `DepthMode =
  Occluded`. `BountyService.applyHighlight` mounts a gold/orange Highlight with `AlwaysOnTop`. Both
  are amber Highlights over a whole character; today the only dependable difference is that the bounty
  one draws through walls, which is exactly the cue you cannot use when the target is in the open.
- **Change Bram's, not the bounty's.** Gold-means-bounty is the association carrying weight elsewhere —
  the bounty list, the payout, the "kill the bounty target" daily. Bram's tell was added later
  (2026-07-26) for one narrow job: making his 50% damage-reduction window legible, so it does not read
  as bullets failing to register. Whatever replaces it must keep doing that job at firefight range.
- **Two implementations, and they must stay in sync — this is the "is there a bot version?" case.**
  Player Brams get the highlight from `BramWorldFXClient`, watching the replicated `UltimateActive`
  attribute; bot Brams get it from `playBramUltimateStart` in `BotVisualClient`, because a server-side
  Highlight on a bot rig is invisible (the rendered body is the `ClientBotVisuals` clone). Both files
  state outright that their property sets must match. A colour changed in one place is a bot Bram that
  still looks like a bounty.
- **Check the case where one character carries both.** A Bram who is himself the bounty target has two
  Highlights on the same model at once. What actually renders there is worth measuring rather than
  assuming, and it is the case that decides how far apart the two need to be.
- **Prefer a change of form over a change of hue.** Pick against `UI_STYLE_GUIDE.md`'s palette; a
  different hue (deep red already reads as Bram elsewhere) is the cheap option, but form — ember
  particles, a ground tell, or outline-only with no fill — separates faster at distance and survives
  colour-blind viewers, which hue alone does not.

**Fix (2026-08-05, unverified, unpublished):** Recolour only — the form is unchanged, it is still a
whole-body `Highlight`. Last Call now mounts fill `12,12,15` at `0.5` with outline `240,245,255`
(`DepthMode` still `Occluded`): a blacked-out body with a bright rim, which separates from the bounty
by **value** rather than hue and so survives distance and the orange canyon behind him. Changed in
both implementations in the same pass — `BramWorldFXClient` (new `LAST_CALL_FILL_COLOR` /
`LAST_CALL_OUTLINE_COLOR` constants) and `playBramUltimateStart` in `BotVisualClient` (literals).

The new constants exist because the ult previously reused `EMBER_COLOR`/`FLASH_COLOR`, which are the
**Shrapnel Shell** palette (impact spheres + projectile trail). Recolouring those in place would have
silently repainted unrelated FX, and a later tidy-up that "restores" them would re-create this bug.

Colour was picked from a nine-option sweep screenshotted against the canyon with the bounty aura as a
side-by-side reference. Two candidates were explicitly rejected and should not be revisited: a warm
leather/brown, which is the nearest of all options to the bounty family and also camouflages against
the rock; and a black body with an ember rim, whose outline `220,70,50` sits almost on top of the
bounty's own outline `255,85,0` — at range the rim is the part you actually see.

**What this fix does NOT address — measured 2026-08-05:** the "check the case where one character
carries both" note above was investigated, and the answer is worse than a readability problem.
**Roblox renders only ONE `Highlight` per model, and the last one parented wins.** Measured on three
identical Bram rigs: with Bram's highlight parented last, the bounty's gold wash vanished completely;
re-parenting the bounty highlight last made the same rig pixel-identical to a plain bounty target.
`DepthMode` does not break the tie — Bram's `Occluded` beat the bounty's `AlwaysOnTop` purely on
order. So **an ulting Bram erases his own bounty marker**, or loses his ult tell to it, depending on
which arrives last, and the order is not deterministic in live play. The recolour does not touch this;
only moving Last Call off the `Highlight` channel entirely would. Not yet raised as its own numbered
item — see the note under the table about numbering being referenced by release entries.

**Still to verify (human, live play):** that an ulting Bram no longer reads as a bounty target at
firefight range, and that a **bot** Bram looks identical to a player Bram (the two code paths are
separate and only agree by hand).
