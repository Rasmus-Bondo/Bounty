# 108 — Victory podium streaming-crash fix is unplayed

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-13 (Hotfix 17) with no recurrence reported. Closed on elapsed time, not on evidence. If it
resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P1 · **Area:** Redwater — `VictoryShowcaseClient`,
`Workspace.FinishSpawns.BoxPlayerSpawns`
*(raised: Hotfix 17)*

---

**Symptom.** When the podium streamed in empty, `getFinishSpawns` passed validation anyway and
`computePodiumFraming` threw on `slots.Player1.Position` with the showcase already committed —
costing that player the entire end-of-match sequence.

**Repro.** Requires the podium to be streamed out at match end, which depends on where the player
died and how far they are from `FinishSpawns`. The `pairs`-over-nil-keys hole was demonstrated
against a simulated streamed-out slot, not against a live stream-out. With `BoxPlayerSpawns` now
`Persistent` the original condition should no longer arise at all, which makes the fixed code path
correspondingly hard to exercise.

**The test that closes it.** Play a full match to the buzzer from the far end of the canyon and
confirm the showcase runs. Then watch the server/client log for `Victory cinematic scene is
incomplete`: `FinishSpawns.VictoryScreenRigSpawn` is a bare Part in a Folder and cannot take
`ModelStreamingMode`, so it is now the **only** remaining producer of that warning — if the warning
appears naming anything else, the streaming fix is incomplete.

**Shipped in:** [Hotfix 17](../2026-08-13-hotfix-17.md) — under `## Fixed`.
