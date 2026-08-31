# 125 — Lobby Collection previews depend on an animation fetch to render at all

[Archive index](ARCHIVE.md) · [Open items](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-24 — WITHDRAWN, the premise was wrong.** Raised and closed the same day, kept
because the measurement is worth having.

**Status:** WITHDRAWN · **Sev:** P3 · **Area:** Bounty (lobby) — Collection / bundle preview viewports

**What it claimed:** that the lobby's three rig-strip sites (`CollectionClient.ViewportIcon`,
`CollectionGuiController.Viewport`, `BundleGuiHomeScreen.BundleHomeController`) rendered only
because they play an idle track immediately after destroying the rig's `Animate` script — making
the picture hostage to an animation fetch, and a failed fetch an *invisible* preview rather than
the T-pose the loader is written to prevent.

**Why that was wrong.** The failure needs a **Motor6D-jointed** rig. Every preview rig the lobby
renders is AnimationConstraint-jointed — all fourteen under `ReplicatedStorage.Characters` (0
Motor6D, 15 AnimationConstraint each, checked one by one) plus the bundle card's authored
`LetTheHuntBeginVesper`. Those render **with their scripts destroyed**: verified by screenshot in
the lobby, destroy and disable side by side, with no animation played at all — indistinguishable.
The idle track was never what was holding the picture up.

The generalisation came from the match-place bug, where it was only ever reproduced on Dust's
portrait template — the one Motor6D rig of the four. It should have been checked against a lobby
rig before being written down.

**What was done anyway:** the three lobby sites now disable rather than destroy, same as the match
places. It is insurance, not a fix — no behaviour changed, and the code comments say so. Joint type
is an export detail nobody checks, and the bundle rig in particular is authored into the place file
where it can be swapped without anyone reading the code.
