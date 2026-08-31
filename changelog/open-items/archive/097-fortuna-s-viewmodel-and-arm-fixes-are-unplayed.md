# 97 — Fortuna's viewmodel and arm fixes are unplayed

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-12 (Hotfix 15) with no recurrence reported. Closed on elapsed time, not on evidence. If it
resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P1 · **Area:** Redwater — Fortuna first person
*(raised: Hotfix 15)*

---

**Symptom.** Two separate faults on Fortuna's first-person view, both fixed in Hotfix 15 and neither
seen in motion:

1. Her viewmodel model had drifted one level out of the container her manifest names, so she would
   have spawned with no arms and no cards, and neither card skin would have loaded. Restored by
   moving the instance back — **this is an authored instance move, not a script change.**
2. Her new smooth arm meshes ignored the visibility rules the blocky arms follow: the left arm hung
   on screen permanently, and the right stayed solid through the ultimate's invisible window.

**Repro.** Neither was reproduced in play. #1 surfaced only as a `WorldAnimationPrewarmClient`
warning fired from a session on a different hunter; #2 was found by reading the transparency code.

**The test that closes it.** Play Fortuna through one full round: arms and cards present on spawn;
left arm hidden except during the ultimate cast and the reload fade; right arm fading with the arm it
is welded to during the ultimate. Repeat on both card skins — `PrestigeCard` and `FrozenHand` — since
the resolver runs per template and only the default was reachable before.

**Watch for regression on the instance move.** The `Skins` folder is a sibling of the template by
convention (`template.Parent.Skins`), so anything that relocates the model breaks the skins with it.

**Shipped in:** [Hotfix 15](../2026-08-12-hotfix-15.md) — two entries under `## Fixed`.
