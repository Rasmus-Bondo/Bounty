# 56 — The lobby's loading-screen cover is a coincidence of timing, not a gate

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**The lobby's loading-screen cover is a coincidence of timing, not a gate.** `LobbySpawn`'s
initial `rebuildLobbyDummies()` is called flat at the bottom of the file and is sequenced against
nothing; `ReplicatedFirst.LoadingScreen` merely happens to hold a `DisplayOrder = 1000` full-screen
GUI over the window (a 1.5 s `MIN_HOLD_TIME` floor measured from before StarterPlayerScripts run,
plus a 1.2 s sky floor and the camera pan). That is the only reason this class of bug reads as log
noise rather than a visible defect. **Anything new added to the lobby build path must not lean on
it** — gate on `BountyIntroComplete` explicitly, as `startCamera` does.
*(raised: [Hotfix 7](../../2026-08-05-hotfix-7.md))*
