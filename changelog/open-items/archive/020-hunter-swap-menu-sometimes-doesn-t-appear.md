# 20 — Hunter swap menu sometimes doesn't appear

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Status:** **VERIFIED** by the owner 2026-08-05 — live; a timing race, so absence of the symptom over a full match is the available evidence · **Sev:** P2 · **Area:** Redwater — hunter switch

**Reported:** The kill-cam hunter swap card row (the mid-match hunter selection UI) sometimes fails to show up after a death.

**All three original notes were wrong, and it is worth knowing why before touching this area again.**
It is not the kill cam, not `HunterClientState` teardown, and not a prior death's cleanup — none of
those touch the panel. The authored asset was also ruled out live and is correct
(`Enabled=true`, `ResetOnSpawn=false`, `DisplayOrder=9600`, all four cards carrying a complete
`IconDisplay` / `SelectButton` / `HunterName` / `UIStroke` / `UIGradient` / `SelectGradient`), so this
is **not** the 2026-07-26 authoring traps recurring. `RoundClientController`'s ScreenGui sweep was
cleared too: `setScreenGuisVisible(false)` snapshots `Enabled` and `(true)` restores it, and both
branches land on `true` for `SwapHunterGui`. `RoundActive` is a stable authored BoolValue, never
recreated, so the client's cached reference cannot go stale. No other script writes the GUI at all —
the only other mention in the place is a comment in `SettingsController`.

**Cause (2026-08-05): the panel can only ever be RAISED by a server state push, and one dropped
evaluation was permanent.** `swapFrame.Visible` is written in exactly one place,
`HunterSwitchClient.refreshVisibility`, which has three callers — the state push, `CharacterAdded`
and the `RoundActive` change. **`CharacterAdded` forces `serverDown = false` on the line above, so
it can only ever hide.** That leaves the push as the sole way up.

`refreshVisibility` evaluates `serverDown and not isLocallyAlive() and RoundActive` and early-returns
when the answer has not changed. So when the server's death push landed *before* this client's
`Humanoid.Health` had replicated to 0, it set `serverDown = true`, saw a live humanoid, returned —
and **nothing was scheduled to look again.** The client sat on "server says down, panel hidden" for
the rest of that life. The local `Humanoid.Died` fired a state query but did **not** re-test
visibility, so recovery depended entirely on that round trip, i.e. on a single connection.

**And that connection had its own gap.** `watchCharacter` disconnected `diedConnection` at the top,
then yielded on `WaitForChild("Humanoid", 10)`, then could bail at `character ~= player.Character`
and leave it **nil for the whole life**. Two `SkinService.loadCharacter` calls in quick succession —
the death-respawn timer racing a round-start reload — is exactly that window. Lose the push race
*and* have the hook missing, and the button never appears for that death. That combination is why it
is intermittent per-death rather than per-session, and why it would track lag and deaths near a round
boundary.

**Fix (2026-08-05, `HunterSwitchClient` only — no server change, no authoring change):**
1. The local `Humanoid.Died` now **re-tests visibility** as well as firing its query. It does not set
   `serverDown`, so the server keeps owning the earliest moment the button may appear — it only
   re-reads a flag the server has already set. It cannot lead the server's own view either: the
   client's health reaching 0 is a *consequence* of the server writing it, so `isPlayerDown` already
   agrees by the time it runs.
2. `watchCharacter` is **generation-guarded** and drops the old connection only once a replacement
   has actually resolved, so no ordering of concurrent respawns can leave the hook nil.
3. A `warn` fires when a push reports down while the humanoid still reads alive — **the diagnostic
   is the confirmation**, as with #10 and #25: the next live export says whether the race is real and
   how often it fires. **Its presence is expected, not a failure.** If exports stop carrying it, the
   recovery in (1) is redundant and the shape can be reconsidered.

**Second, independent defect fixed in the same pass — blank portraits.** `buildPortrait` resolved the
hunter model with `FindFirstChild` in a file where every other sibling lookup is a `WaitForChild`.
`ReplicatedStorage.Characters` is **~5,300 descendants across five models**, and the `WaitForChild`
on the *folder* resolves long before its children land — so a miss was silent and **permanent**,
since nothing retries: the card rendered as an empty box with a name under it for the whole session,
which reads as "the swap menu didn't come up". Now a bounded `WaitForChild`, built **off-thread**
(card registration runs before the remotes are wired, so waiting inline would hold up the state
listener and the priming query) and calling `render` again when a late portrait resolves. This one is
per-session rather than per-death, so it is a plausible second source of the same report rather than
the same bug.

**Verified by simulation, since MCP playtesting is unavailable.** The **real shipped source** was
recompiled with `loadstring` and run in a `setfenv` sandbox (stub Players / ReplicatedStorage /
remotes, a real `SwapHunterGui` clone, a real `RoundActive` BoolValue) across five scenarios — the
race, normal ordering, a local death with no push (the panel must **not** lead the server), two
`CharacterAdded` in flight, and a round ending while down: **11 of 11 passed**, and the new `warn`
fired exactly in the race scenario. The regression was then **reproduced**: the same harness run
against a copy of the source with only the new re-check removed leaves the panel hidden after the
local death (`false`), against `true` with it in. `HunterSwitchClient` compiles (626 lines).

**Still to verify (human, MCP playtesting unavailable):** die repeatedly in a live match — ideally on
a phone and with some latency — and confirm the SWAP HUNTER button appears every single time; check
the client log for `[HunterSwitchClient] down push arrived while local humanoid still alive`, whose
presence is the win condition; confirm all four portraits render rather than empty boxes on a cold
join; confirm the panel still cannot be opened while alive, and that a card tap is never answered
with "You can only swap while you're down".
