# 119 — Three tutorial test switches were ON for the DEV soak

**Area / raised:** per-step tutorial reward (Hotfix 1.2) · **Sev:** P1 · **Status:** VERIFIED

**Closed 2026-08-17 — owner joined live on the listed account (`4284873730` VorFader) after the
Hotfix 1.2 publish and confirmed no tutorial offer card appears.** That is a real verification, not
an elapsed-time closure: the offer card was the visible symptom of `TEST_ACCOUNTS_REPLAY`, and its
absence proves the flip reached live. The repeat-payout half (`TEST_ACCOUNT_BONUS_REPLAY`) was not
separately exercised — it was read back as `false` in both match places and folded byte-identical
before publishing, which is source evidence rather than behavioural.

## Symptom

Three testing switches were turned on on 2026-08-17 — the first two so the per-step tutorial reward
could be driven from a Studio Play, the third so the restored offer card could be seen on a fresh
join. **All three are now `false`; none shipped to live in its test state.**

| Switch | File | Place | Shipped value | Now |
|---|---|---|---|---|
| `TEST_ACCOUNT_BONUS_REPLAY` | `ServerScriptService.Onboarding.TutorialDirector` | Redwater + Frostbite | `false` | `false` — **cleared 2026-08-17, post-soak** |
| `TEST_ACCOUNTS_REPLAY` | `ServerScriptService.Onboarding.TutorialDispatchService` | Bounty only | `false` | `false` — **cleared 2026-08-17, post-soak** |
| `TUTORIAL_FORCE_MODE` | `ServerScriptService.RoundSystem.Config` | Redwater + Frostbite | `false` | `false` — **cleared 2026-08-17, pre-soak** |

`TEST_ACCOUNT_BONUS_REPLAY` is mirrored into **Frostbite Claim**, because that file is match-tier
mirrored and must stay byte-identical. `TEST_ACCOUNTS_REPLAY` is lobby-only. Three edits in total,
all applied. Post-flip: `TutorialDirector` 79312 bytes / fold `86373c7f`, byte-identical across
Redwater and Frostbite; match tier folds `e955962d` in both.

**Still unverified**, which is why this is not closed: nobody has yet joined **live** on the listed
account (`4284873730` VorFader) to confirm no offer card appears and a completed lesson pays nothing
a second time. That is the one check below that a DEV soak could not perform.

**`TUTORIAL_FORCE_MODE` is already off, and it must not be turned back on for a DEV soak.** The gate
is `RunService:IsStudio() or GameEnvironment.isLive ~= true`, and **DEV satisfies the second half** —
a DEV Redwater server has `isLive == false`, so the flag forces *every* DEV match server into the
lesson. A DEV build then cannot test a normal round at all, and the onboarding round trip degenerates
into lobby → tutorial → lobby → PLAY → tutorial. Studio Play is the only place this flag belongs;
anything published, DEV included, needs it `false`. The other two switches do not have this problem
and are fine to leave on through a DEV soak, since DEV DataStores are a separate universe.

`TEST_ACCOUNT_BONUS_REPLAY` is the dangerous one: it is a repeat live payout (250 Cash + 50 Tokens
per run) keyed to a hardcoded UserId, and Studio writes the live data store. `TUTORIAL_FORCE_MODE`
is ignored on a live server with a loud warn, so it is untidy rather than harmful.
`TEST_ACCOUNTS_REPLAY` costs the listed account an offer card to dismiss on every join — harmless
since the card became skippable on 2026-08-17, but it was **not** harmless before that, when it
dispatched the account into the lesson with no way to decline.

## Repro

Not a defect — a deliberate state. To confirm it is still on:

```
grep_scripts "TEST_ACCOUNT_BONUS_REPLAY = true"   → expect 0 hits before publish (Redwater, Frostbite)
grep_scripts "TEST_ACCOUNTS_REPLAY = true"        → expect 0 hits before publish (Bounty)
grep_scripts "TUTORIAL_FORCE_MODE = true"         → already 0 hits; expect it to stay that way
```

## When the three edits happen

**Between the DEV soak and the live publish — not before either.** Owner decision, 2026-08-17: the
per-step reward is being exercised on DEV, and with these switches off there is nothing to exercise
it with, so they ship to DEV on purpose.

The consequence is worth stating plainly, because it is the one property the soak normally
guarantees: **for Hotfix 1.2 the soaked DEV build and the published live build are deliberately not
byte-identical.** Whatever the soak proves about the tutorial's payout, it does not prove about the
live build's payout gating.

The three edits therefore land *after* the version bump, which means they open a fresh capture that
must be curated and archived under `Hotfix 1.2`, and `TutorialDirector` must be re-folded across
Redwater and Frostbite before publishing.

## The test that closes it

Set the two remaining switches back to `false` in every place that carries them, confirm
`TutorialDirector` is still byte-identical across Redwater and Frostbite, then join Bounty on the
listed account and confirm **no** offer card appears and a completed lesson pays nothing a second
time. `TUTORIAL_FORCE_MODE`'s half is already closed: Redwater opens a **normal match** on Play.

## Note

Do not press Play on **Frostbite** while `TUTORIAL_FORCE_MODE` is on: Frostbite has no `Tutorial`
folder, so a forced lesson there resolves no geometry at all. The flag is only mirrored to keep the
file byte-identical.

While these are on, the standing tension they expose is real and outlives them: Bounty's
`TEST_ACCOUNTS_REPLAY` is on, so a listed account replays the lesson, and with
`TEST_ACCOUNT_BONUS_REPLAY` off those replays run **unpaid** — which, now that the award is a
per-step instalment, means no reward row on any step and a lesson that reads as broken. Whoever
turns these off should decide whether the two replay switches ought to be welded together.
