# 33 — Onboarding: live to everyone and verified end to end

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Onboarding: live to everyone and verified end to end** (raised: unreleased, 2026-08-09;
mobile/tablet closed 2026-08-10; shipped behind a test gate in Hotfix 13, 2026-08-11; **gate
removed and the whole feature verified on live in Hotfix 14, 2026-08-11**). Status: **VERIFIED**.
Every bullet below is closed. The gate this item existed to stop anyone forgetting
(`TEST_ACCOUNTS_ONLY` in Bounty's `TutorialDispatchService`) came off after the owner ran the
whole flow end to end on live from the allowlisted account, on PC and on a phone; the remaining
surfaces were then closed one at a time the same day, most of them by reading the stored profile
rather than by watching the screen.

**Kept rather than deleted** because it is the record of *how* a feature with no Studio-testable
transport was actually signed off, and because two things sit outside it. Neither is work:

- **§11's checklist was never formally worked through as a list.** Play-testing covered it in
  substance and the live verification went further than the list asks, so this is a bookkeeping
  gap, not a coverage one. Do not treat an unticked §11 as evidence anything is untested.
- **No *stranger* has run the lesson.** Every live run was by its author at expert pace — the
  verified completion took 82 seconds from profile creation to payout — so step timeouts,
  misread instructions and quit-halfway paths are unwalked. Nothing to do but read the Creator
  Hub `Tutorial` funnel (11 steps) and the `TutorialRun` event (outcome + `T<timeouts>|S<exitStep>`)
  as real players arrive: step 1 volume should track the new-player rate, and the drop-off shape
  is the first real signal about pacing. **Raise a new item if that shape looks wrong** — do not
  reopen this one, which is about whether the feature works, not about how it plays.
The lesson was driven repeatedly in Studio across 2026-08-09/10 and then played
through on **PC (happy path and the ignore-the-tutorial path), on touch, and on an iPad Pro M5**,
with the whole 2026-08-10 pass being tuning off those runs — see the release entry for what
changed.

**How the remaining surfaces were closed (2026-08-11, all on live).** A real alt account with 59
matches and Level 17 was backed up, wiped to a blank profile, tested, and restored — the profile
was read straight out of the `PlayerData_v2` DataStore at each stage, so these are recorded
values and not observations of the screen. **Read the profile, not the symptom:** every one of
these had a second explanation that looked identical from the player's seat (a stale server
still running the old build; an account refused by `Completed` rather than by the rule under
test), and only the stored fields tell them apart. `Tutorial.Attempts` in particular is the
witness for anything about dispatch, because `dispatch` increments it *before* teleporting, so
it counts dispatches that were attempted even when the teleport lost.
- **Mobile/tablet: closed.** Every item is either played or gone. The touch copy variants, the
  banner's fit against the bottom-right cluster and the button cues were all tuned on device;
  the *skipped Alt step* no longer exists (that step runs on both platforms now) and the `/ 10`
  progress count no longer exists (removed on both).
- **Live transport: closed 2026-08-11.** Dispatch, the reserved server and the return teleport
  were all exercised by the live run above — the one surface untestable in Studio by definition
  was finally proved by playing it on live, which is what cleared the gate.
- **The first-time profile path: CLOSED 2026-08-11.** A blank profile ran the whole lesson and
  the stored result was exactly right — `Attempts=1` (dispatched once, never retried),
  `Completed=true`, `BonusPaid=true`, `Cash=250` (paid once), `Skipped=false`,
  `MatchesPlayed=0` with `LifetimeKills=10`, so the lesson's own bots credit kills without the
  run counting as a match. Created 14:12:59Z, completed 14:14:21Z: an **82-second run**, which
  also means the live-fire step passed on a kill rather than riding its 30s backstop. Every
  earlier live run had taken the test-account exemption branch instead of this one.
- **The one-time grandfather screen: CLOSED 2026-08-11**, confirmed in both directions.
  *Positive:* the 59-match alt read back `Screened=true, Completed=true, Attempts=0` — never
  dispatched, so it was the veteran heuristics that marked it, not the once-only rule, and the
  `Screened` stamp proves the Hotfix 14 build served it rather than a stale server. *Negative:*
  the blank profile screened as a newcomer and was **not** grandfathered. The pairing is what
  matters; either alone is ambiguous. **The bullet below is the case that made this necessary**
  and it was exercised too: the alt played a match with a friend and still got the tutorial on
  its next solo join, which the old always-on rule would have made impossible. Sandbox coverage
  over seven profile shapes stands behind it; what remains merely unwatched is the migration at
  population scale, and its failure mode is loud — existing players landing in a tutorial.
- **The follow-join fix: CLOSED 2026-08-11.** A fresh profile clicked Join on a friend already in
  a round, landed in that round with no tutorial card, quit, rejoined Bounty alone and got the
  training run. **The proof is `Attempts = 1` in the stored profile, not the absence of a card:**
  `dispatch` increments before teleporting, so a follow-join that had also dispatched would read
  2 whichever teleport won. `ProfileCreateTime` sits a minute *before* `Tutorial.StartedAt` —
  the profile was created and screened during the follow-join and left alone — and
  `SessionLoadCount = 5` traces the route (Bounty → friend's match → Bounty → tutorial → Bounty).
- **EXIT TRAINING mid-lesson, recorded 2026-08-11** so nobody has to re-derive it: it leaves
  `Completed=true` (never re-dispatched), `BonusPaid=false` and `Cash=0` (no reward for an
  unfinished run), `Attempts=1`. Quitting is treated as a decision, not a deferral. Two wrinkles
  worth knowing: `CompletedAt` is stamped even though nothing was completed — `Completed` here
  means "finished with onboarding", not "finished the lesson" — and because `Completed` blocks
  dispatch, the unclaimed 250 that `BonusPaid=false` preserves is not actually reachable again
  without clearing the flag by hand.
- `ONBOARDING_TUTORIAL_DESIGN.md` §11's checklist has still not been formally worked through.
  Play-testing covered it in substance, not as a signed-off list.
- **`Config.TUTORIAL_FORCE_MODE` — CLOSED 2026-08-11**, set `false` in the Hotfix 13 preflight.
  Flip it back by hand to run the lesson in Studio, and remember it also suppresses the kill feed
  and the combat feed in *every* Studio playtest while it is on, since both read the
  tutorial-mode attribute.
- **The two Hotfix 13 banner fixes: VERIFIED 2026-08-11**, both by the owner's own play, and
  both halves of the pair rather than only the obvious one. (a) The training banner and EXIT
  TRAINING no longer appear over a **normal** match after a death — the screen is clean in an
  ordinary round. (b) The fix did **not** cost the lesson its own banner, which has to survive
  the instant respawns training uses: dying during the live-fire step leaves it up. (b) was the
  regression risk (a)'s fix carried and is the one a careless retest would have skipped, since
  it requires deliberately dying *inside* the tutorial. Both were reasoned to a root cause first
  and are now observed.
- **A training server pins Dust server-side** (Hotfix 13), so the lesson no longer depends on the
  teleport payload alone — **VERIFIED 2026-08-11**, including the rejoin case it was written for.
