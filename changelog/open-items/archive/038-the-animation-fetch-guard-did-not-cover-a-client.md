# 38 — The animation fetch guard did not cover a *client's* fetch failure of a server-played clip

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**The animation fetch guard did not cover a *client's* fetch failure of a server-played clip**
(raised: Hotfix 10, 2026-08-07). Status: **VERIFIED** 2026-08-07 — owner sign-off, mobile + PC,
all four hunters. P3 — shipped in the release that raised it.
`AnimationLoader` made a failed clip download report honestly instead of leaving a rig in its
default pose, but `HunterWorldModel` and `BotController` are **server-side**. A server-played track
replicates as an asset id and each client fetches it independently, so the guard protected the
server's own load (a real failure: if the server cannot fetch, nobody sees the animation) and could
do nothing about a client that fails to fetch the same id — precisely the case the original log
showed, `(x2)` matching the two clients, not the server.

Closed by new `StarterPlayer.StarterPlayerScripts.WorldAnimationPrewarmClient` (Redwater, ungated
at the root), four tiers: 12 hunter world-gun clips at script start; the **local player's own
viewmodel** as soon as `SelectedHunter` resolves; 48 bot clips deferred to local-character-spawn
plus a 3s cushion; then every hunter's viewmodel and the 18-emote catalog behind that. Two retries
and a warn at 45s naming anything that never fetched. Resolved live in edit mode: all 12 tier-1
ids reach `Success`, 20 distinct viewmodel clips and 18 of 18 emote ids collect, and all five dead
viewmodel sets are excluded.

**What the sign-off covers, precisely.** Mobile and PC, all four hunters — the absence of harm: no
new warns, no join-time hitch from the deferred sweeps, every hunter's own gun animating. That is
the whole of what a clean session *can* show, because **the fix only does anything when a fetch
fails**, and that is a transient CDN condition nobody can induce on demand. The retry-and-warn path
itself remains exercised only by pointing an id at a known-bad asset temporarily; it is unproven in
play and is expected to stay that way. Recorded so a future reader does not mistake this entry for
evidence that the failure path was observed working.
