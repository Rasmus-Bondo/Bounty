# Unreleased

Work that has shipped to no one yet. `/changelog` writes here; `/preflight` renames this file to
`YYYY-MM-DD-<release>.md` when the release rolls and drops a fresh empty one in its place.

**Concurrency:** several agents work this project at once. **Never `Write` this file whole** — append
with an `Edit` anchored inside a `## Added` / `## Changed` / `## Fixed` heading, and re-read
immediately before editing, because another agent may have written since. A whole-file write is the
one operation that destroys a concurrent entry without complaining; a stale anchor merely errors,
which is the point.

[Index](../CHANGELOG.md) · [Conventions](CONVENTIONS.md) · Previous release: [Update 2](2026-08-29-update-2.md)

---

- **Shared modules:** `GameEnvironment` touched in all three places (one DEV-only season row), verified byte-identical by length **and** djb2 checksum after the edit (`12552 B` / `3209512831`). Match-place mirror also — `HighNoonModule` and `BotCombat` across Redwater Canyon and Frostbite Claim, verified byte-identical by length **and** checksum after the sync (`16636 B` / `101943 B`). **Lootbox build (2026-09-03):** `Wallet` (four reasons) and `Telemetry` (one event) touched in all three places, verified by length + hash (`7719 B` / `663703730`, `28058 B` / `1779240489`); match-place mirror `DataService` and `TutorialDirector` across Redwater and Frostbite (`26512 B` / `1269809867`, `80703 B` / `1157972711`); the profile-template block and the launch-migration block are byte-identical in all three DataServices (`1220 B` / `237526912`, `2058 B` / `3057621043`).
- **Data-affecting:** yes — the ranked-season payout mark changes key form in the profile. Harmless before 2026-09-12 (nothing has ever paid), a double-pay re-opener after it. See Fixed. **Lootbox build:** profile shape gains `Lootboxes` + `LootboxLaunchV1` (Reconcile-backfilled, no `DATA_VERSION` bump) and four Wallet reasons; the one-way launch migration (Level/XP reset, veteran bundle) is **disarmed** (`LOOTBOX_LAUNCH_ARMED = false`) until the launch publish. See Added.

## Added

- **Lootbox chests: the LOOT tab is now a chest scene** (`LOOTBOX_SPEC.md`, built 2026-09-03). One
  free chest per account level plus a 100-Token chest bought inside the menu; a bought chest banks
  rather than opens. The chest lands on the SkinMenu pedestal, five shots reveal the tier, and the
  loot floats out with its name under it. `LootboxService` (new, started in `Main`'s upper block
  because the chest client waits on its five remotes) rolls tier, items and duplicate refunds and the
  client replays them — the prototype rolled loot client-side. Odds panel and price paint from
  `LootboxConfig` (effective rates 50 / 29 / 14 / 5 / 2 from a 1e6-open simulation; Epic+ guaranteed
  within 20, Legendary within 100). Duplicates refund 35% of shop price, floored before Wallet.
  PolicyService's paid-random-item restriction blocks the Token purchase only, failing closed. The
  tutorial banks one super chest (a guaranteed weapon skin from Icefang / Frostpiercer /
  FrostbiteGrudgekeeper preferring one unowned, plus three skin-free fillers; HellFire is out as a
  pass reward) in Redwater's `TutorialDirector`, and a returning player is routed to the LOOT tab
  after the TRAINING COMPLETE card. The LOOT tab carries a count badge cloned from `DailyNotiFrame`.
  Imported as `StarterGui.ChestMenu`, never over the live `LootboxMenu` that `CollectionClient`
  blocks on. The 10 `LootboxSFX` sounds now carry the `SFX` group (they had none).

  **Not armed.** `LOOTBOX_LAUNCH_ARMED = false` in all three DataServices keeps the launch migration
  (every account's Level/XP to 1/0; veterans paid 5 chests, 3 `xp_25_30` potions, 200 Tokens) and the
  free per-level accrual off, because Studio writes the live store and a test run would reset the
  tester's real account. Flip it in all three places in one pass at the launch publish, after backing
  up the test profile. Until then only the Token purchase and the tutorial chest put a chest in a
  profile.

  **Retired with it:** `CollectionClient`, the old 3D hunter carousel the LOOT tab used to open, is
  disabled on the owner's call (Collection tab + Trading Post cover it). Delete it and the old
  `StarterGui.LootboxMenu` one release later.

  **Revert hazard:** the profile keys and Wallet reasons are in all three places and are harmless
  orphans on a reverted place; the migration, once armed and run, cannot be reverted. `Main` start
  order is load-bearing — LootboxService must stay in the upper block.

  **Verified:** syntax and byte-identical mirrors in all three places; first-draft device matrix
  (phone, 640×480, tablet, 1080p) after moving the odds panel clear of the party strip and the OPEN
  button above the nav diamonds. **Not yet playtested** — buy, open, super-chest routing, the region
  gate and the migration all need a live run.

  **Open:** `StarterGui.ChestAward` is imported but disabled — the spec gives it no trigger. Three
  1.6 MB copies of `WorkingChest` sit in `ReplicatedStorage.Lootbox`; the two backups await owner
  confirmation before deletion. `TEST_ACCOUNT_BONUS_REPLAY` in `TutorialDirector` is still on
  (pre-existing, #119's successor on the board).

## Changed

- **A second DEV ranked-season boundary, Saturday 2026-09-05 18:00 CEST.** `DEV_RANK_SEASONS` in
  `GameEnvironment` gains one row — `1788624000`, DEV season 7 — which closes DEV season 6 and makes
  `RankSeasonRewardService` pay it out two to three minutes later, once the settle elapses. DEV only:
  the live table is untouched and the `env == "Dev"` gate is unchanged, so `Live` and `Unknown` still
  fall through to the five live boundaries.

  This is the re-test of [#1](https://github.com/Rasmus-Bondo/Bounty/issues/1) — the 2026-08-29 dry
  run is what exposed the double pay. It pays only whoever banked RP into DEV's `RankPoints_v6` since
  08-29 20:00 CEST, so someone has to play a DEV Redwater round before Saturday or the season
  correctly pays nobody.

  **Revert hazard:** the row shifts DEV season numbers to **+3** against live, moving DEV's
  `RankPoints_v<n>` windows again. Contained to the DEV universe — separate experience, separate
  stores. The fixture's removal deadline moves with it: #20 now reads after 2026-09-05.

  **Not yet run** — it fires on its own at the boundary.

## Fixed

- **The ranked-season payout can no longer pay the same season twice.** The profile mark recording a
  paid season is now keyed by `tostring(season)` at both the read and the write, so it survives the
  profile's JSON round-trip. Bounty only — `RankSeasonRewardService` is not mirrored. Closes
  [#1](https://github.com/Rasmus-Bondo/Bounty/issues/1).

  Nothing has ever been paid on live: `FIRST_REWARDED_SEASON = 4` and season 4 does not close until
  **2026-09-12 20:00 CEST**, so no live profile carries either key form and no migration is owed. DEV
  profiles written during the 2026-08-29 dry run already hold the string form and are now honoured.

  **Revert hazard — data-affecting once a season has paid.** A mark written as a string is
  invisible to the reverted numeric read, so rolling this place back after 2026-09-12 re-opens the
  double-pay on exactly the profiles that were paid correctly.

  **Not yet playtested.** Closure needs a DEV season boundary crossed, the payout collected, then two
  rejoins with no Token movement and a string key read back off the profile.

- **A Bram now cancels a Dust ultimate outright instead of pausing it.** Being carried by a Breach
  Charge, or slammed into a wall by one, ends High Noon on the spot — no shot, no refund of the
  charge. Previously only the shoot request consulted the action lock, which refuses the trigger only
  *while* the lock is up: the slam stun is shorter than the ultimate's hold window, so Dust kept his
  cone, went on locking the enemies in it, and executed the moment the stun lapsed. Landing the ram
  bought 2.5 seconds; it did not beat the ultimate.

  Covers all four pairings — player or bot Bram, against a player or bot Dust — because both Bram
  implementations write the same two status attributes and the check lives on the victim's side.

  **Revert hazard:** both match places carry it and must ship together. `HunterActionLock` itself is
  unchanged, so nothing else depends on this. The bot path additionally swapped its single
  `task.delay(LockInTime)` for a poll on the same beat as the player's cone scan — reverting restores
  the one-shot timer, not a half-fixed version.

  **Playtested by the owner**, confirmed cancelling in a live round.
