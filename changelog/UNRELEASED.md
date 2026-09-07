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

- **Shared modules:** `GameEnvironment` touched in all three places (one DEV-only season row), verified byte-identical by length **and** djb2 checksum after the edit (`12552 B` / `3209512831`). Match-place mirror also — `HighNoonModule` and `BotCombat` across Redwater Canyon and Frostbite Claim, verified byte-identical by length **and** checksum after the sync (`16636 B` / `101943 B`). **Lootbox build (2026-09-03):** `Wallet` (four reasons) and `Telemetry` (one event) touched in all three places, verified by length + hash (`7719 B` / `663703730`, `28058 B` / `1779240489`); match-place mirror `DataService` and `TutorialDirector` across Redwater and Frostbite (`26512 B` / `1269809867`, `80703 B` / `1157972711`); the profile-template block and the launch-migration block are byte-identical in all three DataServices (`1220 B` / `237526912`, `2058 B` / `3057621043`). **New-item bubbles (2026-09-03):** none of the 20 mirrored modules was edited — `TitlesConfig` is only read — but the `SeenItems` template block was added to `DataService` in all three places and verified byte-identical by length + byte-sum (`1453 B` / `122758`). **Bubble polish + left-grid fix (2026-09-06):** none of the 20 touched — Bounty only, four client scripts and a handful of authored GUI instances. **Chest codes (2026-09-06):** none of the 20 touched either, but `CodeRedemptionService` — mirrored by hand, not on the list — had its `CODES` + `resolveCode` block verified byte-identical in all three places (`2682 B` / `439550909`). **Chest chime (2026-09-06):** none of the 20 touched — Bounty only, one client script and one new Sound template. **Daily reward overhaul (2026-09-06):** `DailyRewardConfig` touched in all three places, verified byte-identical (`6378 B`); non-mirrored `BoostService` and `DailyRewardService` edited identically in Redwater and Frostbite. **Level-up card + live XP (2026-09-06):** none of the 20 touched — match places only. Non-mirrored `ProgressionService` and `RoundController` edited identically in Redwater and Frostbite, and the new `LevelRewardClient` written identically, verified byte-identical by length **and** checksum after the pass (`21674 B` / `807935745`, `137606 B` / `1781566845`, `8691 B` / `274843250`). A Studio-only test block briefly diverged Redwater's copy during review and was removed on sign-off; the checksum above is the state after that, re-measured, so there is no divergence to carry. **Kill announcement + damage numbers (2026-09-06):** none of the 20 touched — match places only. Non-mirrored `HunterHitPipeline`, `HighNoonDamage` and `BountyMusicClient` edited identically in Redwater and Frostbite, and the new `AnnouncementController` + `DamageNumberClient` written identically; confirmed by a full match-tier mirror walk rather than per-file checksums (`TOTAL dad63f23`, 9 of 9 roots resolved, both places). **BOUNTY+ (2026-09-06): the mirrored set goes 20 → 21.** New `BountyPlusConfig` is mirrored across all three places from the start (`5401 B` / `259011608`), and `Wallet` (`8048 B` / `1000736210`), `TitlesConfig` (`20275 B` / `762775659`) and `TitleStyles` (`27039 B` / `1871850394`) were touched in all three and verified byte-identical by length **and** checksum. Non-mirrored `BoostService` was edited identically in Redwater and Frostbite (`11573 B` / `1741903406`). **Damage-number scaling (2026-09-07):** none of the 21 touched — non-mirrored `DamageNumberClient` was edited identically in Redwater and Frostbite (`11412 B` / `2812935240`). **Announcement replaces the feed (2026-09-07):** none of the 21 touched — match places only. Non-mirrored `ProgressionService`, `RoundController`, `BotService` and `AnnouncementController` edited identically in Redwater and Frostbite, verified byte-identical by length **and** djb2 checksum after the pass (`22901 B` / `2599006629`, `137791 B` / `2770453168`, `43003 B` / `1096469777`, `38886 B` / `2109387215`). The three new EyeCandy labels were imported into both places from the same `.rbxm` exported out of "Bounty - UI Update", so their authored geometry is a clone rather than a re-typing, and the four announcement Sound volumes were set to the same values in both. **Capture-bar split (2026-09-07):** non-mirrored `DominationClient` joined the same pass and was verified byte-identical across Redwater and Frostbite (`19853 B` / `1540823890`); no authored instance changed in either place, both moves are runtime-only. **Chest spin fix (2026-09-07):** none of the 21 touched — Bounty only, one client script, no authored instance. **Bounty strip lift (2026-09-07):** none of the 21 touched — non-mirrored `BountyListClient` edited identically in Redwater and Frostbite, verified byte-identical by length **and** djb2 checksum after the pass (`30100 B` / `3124521349`); no authored GUI instance changed, the re-pin is entirely at runtime. **Chest scene, eighth round (2026-09-07):** none of the 21 touched — Bounty only, one client script, no authored instance. **Chest scene, ninth round (2026-09-07):** none of the 21 touched — Bounty only, three client scripts, no authored instance; `AnimationLoader` is newly *required* by the BOUNTY+ viewport script but was not edited. **Chest arrival (2026-09-07):** none of the 21 touched — Bounty only, one server module, one new client script and one new authored ScreenGui. **Chest arrival badge + readiness (2026-09-07):** none of the 21 touched — Bounty only, two client scripts (`ChestArrivalClient`, `ChestController`), no authored instance; the withheld badge count is a client-local attribute, nothing server-side moved. **Collection panel fit (2026-09-07):** none of the 21 touched — Bounty only, one client module (`Panels`), no authored instance; the fit is entirely at runtime and the wide-screen path restores the authored geometry from a snapshot. **Lobby multiplier panel (2026-09-07):** none of the 21 touched — Bounty only, one server module (`FriendBonusService`); `BountyPlusConfig` is newly *required* there but was not edited. **Daily chest art (2026-09-07):** none of the 21 touched — mirrored `DailyRewardConfig` was **not** edited despite this being a daily-reward change; it is Bounty only, one client script (`DailyLoginController`), no authored instance. **Testers (2026-09-07):** mirrored `TesterGrantService` touched in all three places, verified byte-identical by length **and** checksum after the edit (`5445 B` / `2431935182`). **BOUNTY+ region gate (2026-09-07):** none of the 21 touched — Bounty only, one client script (`ChestController`) and one server module (`BountyPlusService`), no authored instance; the card's restricted layout is computed at runtime from the authored geometry. **Tutorial chest chips (2026-09-07):** none of the 21 touched — non-mirrored `TutorialDirector` and `RoundController` edited identically in Redwater and Frostbite, verified byte-identical by length **and** djb2 checksum after the pass (`82347 B` / `2616844099`, `137831 B` / `1521762933`); the Bounty side is one server module, two client scripts and the two cards' authored reward rows. **Add `BountyPlusConfig` to the mirrored list in `CLAUDE.md` and `CONVENTIONS.md`** — an untracked mirror is how `QuestConfig` drifted.
- **Data-affecting:** yes — the ranked-season payout mark changes key form in the profile. Harmless before 2026-09-12 (nothing has ever paid), a double-pay re-opener after it. See Fixed. **Lootbox build:** profile shape gains `Lootboxes` + `LootboxLaunchV1` (Reconcile-backfilled, no `DATA_VERSION` bump) and four Wallet reasons; the one-way launch migration (Level/XP reset, veteran bundle) is armed for the **DEV universe only** (`LOOTBOX_LAUNCH_ARMED = GameEnvironment.env == "Dev"`) and stays off on live until the launch publish flips it to `true`. See Added. **New-item bubbles:** profile shape gains `SeenItems` (Reconcile-backfilled, no `DATA_VERSION` bump) whose `Stamped` seed is one-way, stamped on the first load after this ships. See Added. **Live XP:** no schema change, but reverting does not claw back what it paid — round XP and Cash now land as they are earned, so anyone who left a round mid-way keeps earnings the old forfeit rule would have withheld. See Changed. **BOUNTY+:** the profile gains `BountyPlus` (lazily initialised, no `DATA_VERSION` bump), `Wallet` gains the `bountyplus_grant` reason in all three places, and the pass's one-time grant writes 1000 Tokens, 5 chests and four title ids that reverting a place cannot claw back. The permanent +25% XP / +10% Cash also changes what every boosted earn pays out. See Added. **Announcement replaces the feed:** no. It adds a trailing `subject` argument to the `CombatReward` remote and an optional `victimName` to `awardKill` / `awardAssist`, but nothing about what those calls *pay* changed — no Wallet reason, no XP curve, no profile field. Reverting the match places restores the old feed cleanly. See Changed. **Chest scene, ninth round:** no — three Bounty client scripts, presentation and input handling only, no profile field, Wallet reason or curve touched. **Chest arrival:** no. It adds `earnedPending` to an existing push and one new remote, and its per-player counter is in memory only — no Wallet reason, no XP curve, no profile field. What the chests *are* was already banked by the accrual this only animates. See Added. **Collection panel fit:** no — one Bounty client module, layout only, no profile field, Wallet reason or curve touched. See Fixed. **Lobby multiplier panel:** no — one Bounty server module, display only; what the pass pays did not change, only what the lobby reports it pays. See Added. **Daily chest art:** no — one Bounty client script, two icon ids; what the crate days grant did not change, only the picture on the tile. See Changed. **Testers:** no — the top-up is gated on `GameEnvironment.env == "Dev"` and DataStores are universe-scoped, so nothing it writes can reach a live profile. See Changed. **BOUNTY+ region gate:** no — what the pass grants did not change (the 0-chest outcome for a restricted account predates this), only what the card and the popup claim it grants. See Fixed. **Tutorial chest chips:** no — no profile field, Wallet reason or curve changed. The same `Lootboxes.TutorialChestPaid` / `SuperUnopened` write happens, only earlier on a completed run (end of the lesson rather than after the outro hold) and through a named function with two callers. See Changed.

## Added

- **The chests you earned while you were away now fly into the LOOT tab** (2026-09-07, Bounty). The
  free per-level chests were banked in silence: the badge simply read a bigger number than it had
  before the match. Each one now pops in over the middle of the screen, curves down into the LOOT
  diamond, punches it and ticks the badge up one. New
  `StarterPlayer.StarterPlayerScripts.ChestArrivalClient` drives a new `StarterGui.ChestArrivalGui`
  (DisplayOrder 35, `ScreenInsets = None`, holding one ViewportFrame template) — both the GUI and the
  script instance were made through `execute_luau`, so neither is in the hook capture.

  **It fires on the accrual, not on a count**, so it covers both cases with one hook: landing in the
  lobby after a match that levelled you up, and a level landing while you stand in the lobby.
  `LootboxService` now remembers what `syncFreeChests` banked and re-sends it as `earnedPending` on
  every state push until the new `ChestArrivalSeen` remote retires it — the banking push routinely
  beats the client to the listener. Capped at five flights however many chests were earned; retired
  silently while the LOOT tab is already open, or while the tutorial's super chest is routing there.

  **It cannot fire on live until the lootbox launch is armed.** The accrual is gated on the
  `LootboxLaunchV1` stamp and no live profile is owed a free chest yet — the same gate that keeps the
  level-up card's CHEST EARNED line off live.

  **The flight now opens on the chest's face** (owner, 2026-09-07): it was popping in backwards —
  hinge and backboard, no sheriff badge, no buckles. The orbit angle is world yaw and `WorkingChest`
  is authored turned ~40°, so a start of 0 was never pointed at anything in particular. It starts
  from the model's own facing instead, so re-authoring the chest's angle cannot put the flight back
  on its rear. **Owner-checked in Studio** (2026-09-07) through the `K` rehearsal.

  **The badge no longer counts a chest before it has arrived** (owner, 2026-09-07). Two scripts were
  painting `LootNotifFrame`, so it read "2" the moment the menu appeared, blanked itself a beat
  later, then counted back up to "2" — the player was shown a number for chests they had not been
  handed, then shown it taken away. There is one painter now: `ChestArrivalClient` publishes a
  signed `ReplicatedStorage.ChestArrivalOffset` and `ChestController` adds it to its own count.
  Reverting `ChestController` alone brings the flicker back; reverting `ChestArrivalClient` alone is
  safe, because an absent offset reads as 0 and the badge falls back to the plain server count. Only
  the bubble is withheld from — an unflown chest is still banked and openable.

  **And it holds until the player is actually in** (owner, 2026-09-07). `BountyIntroComplete` is set
  in the same frame the loading screen re-enables `MainMenuGui`, so the chests were flying while the
  blur still faded, before the nav bar had been measured, and under the join popups opening on the
  same beat. Six capped gates now, ending in a 0.9s settle; every cap pays the animation out rather
  than swallowing it, and a 30s watchdog clears the offset if a flight never lands. Compiles clean;
  **owner testing on DEV.**

  **Revert hazard: none beyond the feature.** The server half is additive — one field on an existing
  push, one new remote — and its counter lives in memory, never on the profile, so a revert leaves
  nothing behind. Bounty only; the match places are not involved.

  **Verified:** syntax (`loadstring`) on both scripts, every instance path the client resolves checked
  in edit mode, and the chest's viewport framing by screenshot at four orbit angles — which is what
  caught the camera fitting to the chest's longest side and clipping its corners a quarter of the way
  into every spin. **Owner-checked in Studio** (2026-09-07) through the `K` rehearsal, which stays in
  for now. **Not yet exercised by a real level-up** — that needs a DEV place.

- **BOUNTY+, a permanent-perk game pass** (`BOUNTY_PLUS_SPEC.md`, built 2026-09-06). A card on the
  left of the LOOT area sells pass **1968529393**: once, 1000 Tokens, 5 chests and the GOLDEN OUTLAW
  title; then permanently +25% account XP and +10% Cash for as long as the account owns it. Tokens
  are never multiplied — the card promises bonus XP and Cash and nothing else.

  **It is a game pass, not a developer product**, however the brief was worded: the id resolves only
  as `Enum.InfoType.GamePass` and the pass's own `ProductId` field is a decoy. So `ProcessReceipt` is
  not involved and `StoreConfig` gains nothing. New mirrored `BountyPlusConfig` is the single home
  for the id, the percentages and the rounding; new Bounty-only `BountyPlusService` resolves
  ownership, stamps the profile and pays the grant, started in `Main`'s upper block **after**
  `LootboxService` because the grant banks its five chests through it.

  **The boost applies everywhere XP or Cash is EARNED** — the owner's choice over the narrower
  "match earns only". That is `ProgressionService` via `BoostService.getMultiplier` in both match
  places, plus quests, daily rewards and the chest cash roll in the lobby. Battle pass, ranked-season
  payouts, code redemption, bundles and duplicate refunds are deliberately excluded. The pass is a
  third **additive** term, so a 25% potion plus the pass is x1.50, not x1.5625. The quest cards and
  the daily panel draw through the same helper the server grants with, so a card cannot advertise a
  number the payout will not match.

  **The lobby's multiplier panel counts it too** (2026-09-07). `FriendBonusService` built
  `1 + friend% + potion%` and never added the pass, so the bottom-right display told an owner x1.00
  while the match places were paying them x1.25. It adds the same term through `BountyPlusConfig`,
  off the same profile stamp `BoostService.getMultiplier` reads, and re-pushes on the
  `OwnsBountyPlus` attribute-changed signal — ownership resolves seconds after join behind a
  retrying web call, and again on a mid-session purchase, both long after this service's own join
  push. Display only; the earns already had the term, and the panel is the lobby's only multiplier
  surface. **Verified:** compiles, and the term measured off the config — x1.10 Cash / x1.25 XP
  owned, and x1.50 stacked with a 25% potion rather than x1.5625. **Not exercised live:** it needs a
  real owner joining.

  **GOLDEN OUTLAW exists four times**, one id per hunter, because titles are hunter-locked and a
  single id under all four resolves to Fortuna alone. It is the only title on the new `gilded` style
  (presets 12 → 13), which is built entirely from `hue` — already in the schema, used by nothing — so
  `TitleRenderer` did not change.

  **Revert hazard:** the config, the Wallet reason and the four title ids are in all three places and
  must ship together. Reverting a match place alone silently drops the +25% for owners mid-round;
  reverting Bounty alone leaves the match places boosting off a stamp nothing writes any more. The
  grant marks each part as it lands rather than stamping once at the end, so a half-failure completes
  on the next join instead of re-paying the Tokens.

  **The panel's art is imported, not rebuilt** — chrome from the "Bounty - UI Update" place, the
  viewport contents reassembled in Bounty from local assets because the frame is 2 MB whole. Its
  bounding box matches the source exactly, so the ViewportFrame auto-frames the authored composition.
  **One gap:** the covered wagon's wooden body is an invisible stand-in Part — the real union is
  178 KB of baked CSG and `import_rbxm` tops out between 51 KB and 211 KB. It holds the bounding
  volume so nothing else shifts; restoring the geometry needs `upload_asset`.

  **Verified:** all 12 touched scripts compile; mirrors byte-identical (checksums in the metadata
  above). The catalog going 28 → 32 titles and the presets 12 → 13 was asserted through a fresh
  `require`, not the plugin's stale cache. `gilded` was measured rather than eyeballed — its flash
  peaks at 0.457 opacity against chrome's 0.476 and lightning's 0.916, and the aura changed colour on
  all 133 sampled frames — and screenshot-checked at 16 / 24 / 42 px. Device matrix on phone, 4:3
  tablet and a 1280x720 window. **Owner-checked live** (2026-09-06): the panel on phone, tablet and
  PC, and the price resolving to R$399 through `ShopCore.attachRobuxPrice`.

  **Not yet exercised: the grant itself.** Studio writes the live store, so paying 1000 Tokens and
  five chests onto a real profile is waiting on a backed-up test account. Ownership resolution, the
  attribute, and the panel's owned/unowned swap against a real purchase are unconfirmed with it.

- **Kill announcement and floating damage numbers, both match places** (`COMBAT_FEEDBACK_SPEC.md`,
  built 2026-09-06). A kill now puts `ELIMINATED <NAME>` across the centre of the screen with a
  killstreak word (`DOUBLE KILL` … `DECA KILL`, then `<N>X MULTI KILL`), pitched up a step per kill
  off one stinger, shaking harder the longer the run. A bounty claim slams a `BOUNTY CLAIMED` header
  in from both edges. Damage floats off whoever you hit — white body numbers drifting up, yellow
  `N!` headshot numbers that split in half and fly apart.

  New `StarterGui.EyeCandy` (DisplayOrder 8700) + `AnnouncementController`, and new
  `StarterPlayer.StarterPlayerScripts.DamageNumberClient`; both byte-identical across the two match
  places, with the GUI imported from the "Bounty - UI Update" prototype rather than re-authored.
  `SFX.Fight.KillEffectSound` and `SFX.Reward.Bounty` are new in both places, and `SFX.Fight`'s two
  pre-existing, previously unwired sounds (`KillSound`, `Assist`) gained the `SFX` SoundGroup they
  were missing — all four set through `execute_luau`, so not in the hook capture.
  **The kill sting plays at `Volume = 2`,** matching `GunGui.HeadshotSound` rather than the 0.5 it
  was imported with: both SoundGroups sit at 0.5, so 0.5 put it at an eighth of the hitmarker landing
  on the same frame and it was inaudible under gunfire (owner, 2026-09-06). The prototype had no
  SoundGroup at all, which is why it sounded right there and not here.

  **No Studio test panel.** The prototype's ELIMINATE / BOUNTY / RESET buttons were ported and then
  removed the same day on the owner's call — they showed in every playtest. `AnnouncementEvent` is
  still the single dispatch, so firing that bindable by hand drives the whole thing without them.

  **`HitConfirm` grew three trailing arguments** — `damage, victimName, victimCharacter` — in
  `HunterHitPipeline` **and** in `HighNoonDamage`, which runs its own parallel damage chain. This is
  the load-bearing change: it is the only event that reaches the attacker alone while the emitter
  still holds the victim, and it feeds both features at once. Purely additive, so `HitMarkScript` is
  untouched. Miss the `HighNoonDamage` copy and Dust's ultimate is the one weapon with no numbers
  and no announcement.

  **The bounty stinger is a swap, not an addition.** `BountyMusicClient.playBountyClaimed` is held
  behind `BOUNTY_STINGER_ENABLED = false` because the new header plays `SFX.Reward.Bounty` on the
  same event for the same one player. Reverting `BountyMusicClient` alone gives every claim two
  overlapping stingers, one of them 12.33s long.

  **Cut, not stubbed:** the prototype's XP bar, level-up and chest reel. They hard-required
  `PlayerGui["In-gameGui"]`, which no match place has, and would have hung the controller before a
  single announcement. Its reward lines and assist banner are gone too — the combat feed keeps the
  ledger and the assist row; the assist only gained its sound.

  **Revert hazard:** the two client scripts and the GUI are presentation only, but the `HitConfirm`
  signature and the `BountyMusicClient` flag span both places and must ship together. Reverting one
  place leaves it silently without numbers.

  **Verified:** syntax (`loadstring`) on all five scripts in both places; byte-identical mirrors
  (full match-tier walk, `TOTAL dad63f23`, 9/9 roots). First-draft device matrix (phone, 4:3 iPad,
  1280x720, 640x480) caught the announcement running into the mobile sprint button at 4:3 and
  sitting on Domination's capture bar; it was raised to screen y 0.306–0.384 and re-checked clear on
  all four. **Not yet playtested** — the streak ladder, the stinger pitch, headshot splits and High
  Noon specifically all need a live run.

- **Level-up card in Redwater Canyon and Frostbite Claim** (2026-09-06). A level-up now shows a card
  on the left of the screen: a chest flies into a `ViewportFrame` and spins to a stop, the card
  punches in behind it, holds 4.1s and slides off. New `StarterPlayer.StarterPlayerScripts.LevelRewardClient`
  drives `StarterGui.LevelRewardGui` (DisplayOrder 8650); both are byte-identical across the two
  match places. Nothing listened to the `LevelUp` remote before this, so level-ups were invisible
  in a match.

  Ported from the "Bounty - UI Update" prototype's `EyeCandy.Canvas.LevelRewardDisplay`. Its
  persistent XP bar was **not** taken: that lives in the prototype's `In-gameGui`, a HUD neither
  match place has. Two things were re-derived rather than copied, and both are rollback-relevant
  because reverting them reintroduces a visible bug: the card is sized in height-scale under a
  2.0928 `UIAspectRatioConstraint` (the prototype's two-axis scale carried its ~2.45:1 authoring
  viewport and squashed on 16:9 and 4:3), and `HIDDEN_X` is off-screen (the prototype's off-screen
  x was measured inside a 0.70-wide canvas and left the card 93% on screen, so the entrance popped
  rather than slid). Verified on 1080p, iPhone 14 landscape and a 4:3 iPad.

  **The card never promises a chest the profile is not owed.** `LevelUp` gained a second argument,
  `chestEarned`, from a new `isChestOwed` in `ProgressionService` that keys off the same
  `LootboxLaunchV1` stamp Bounty's `LootboxService.syncFreeChests` does. Pre-launch it is false for
  every profile and the card reads "LEVEL UP / LEVEL n" with the chest viewport hidden; once the
  launch arms, it reads "LEVEL n / CHEST EARNED". Nothing in a match place banks chests — the lobby
  still pays them on the next join.

  `SFX.Reward` (LevelUp / Award / Award2) added to both match places, carrying the `SFX` SoundGroup
  the prototype's copies lacked. **The card needs `ReplicatedStorage.Lootbox.WorkingChest` in both
  match places**; without it the card still fires, warns, and falls back to the no-chest layout. The
  chest model was copied across by hand — it is 1.62 MB of unions, 36x over what `import_rbxm` will
  carry, and `upload_asset` has no Open Cloud key configured.

  **Signed off on the card itself, not on a live level-up.** A Studio-only `L` trigger played the
  card on demand while the owner reviewed it, and was removed once approved, so the file is back to
  `8691 B` / `274843250` in both places with no divergence to carry. The trigger only ever called
  the client's own local function; the server path that fires it in a real match — `addRewards` →
  `creditRewards` → `checkLevelUp` → `LevelUp:FireClient(player, newLevel, isChestOwed(...))` — was
  verified by reading it rather than by playing it. **Still unplayed end to end:** a real level-up
  landing mid-round.

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

  **Armed for DEV only.** `LOOTBOX_LAUNCH_ARMED = GameEnvironment.env == "Dev"` in all three
  DataServices, so the DEV universe (separate stores) runs the launch migration (every account's
  Level/XP to 1/0; veterans paid 5 chests, 3 `xp_25_30` potions, 200 Tokens) and pays free per-level
  chests, while live stays off because Studio writes the live store and a test run would reset the
  tester's real account. Set it to `true` in all three places in one pass at the launch publish, after
  backing up the test profile. Until then only the Token purchase and the tutorial chest put a chest
  in a live profile.

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

- **Chest scene, first playtest round (owner, 2026-09-03).** Six fixes to the unreleased lootbox
  build, all in Bounty:
  - **PURCHASE no longer strands on a grey "..."** after a spam-click. The server answers a
    cooldown- or busy-rejected purchase with a state push (`purchaseResult = "cooldown"`) instead of
    dropping it, the client drops clicks inside `REMOTE_COOLDOWN` before they are sent, the busy
    window keeps the button red with its label, and the no-reply fallback is 3 s, not 6.
  - **OPEN / SHOOT stays red while a chest lands or opens**; only an empty inventory greys it.
    `REVEALING` reads OPENING rather than "...".
  - **The camera no longer drifts a little per shot.** The shot shake now swaps its previous
    frame's offset out of `Camera.CFrame` before applying the next and removes it when it ends,
    and the FOV kick holds one rest FOV for the whole run instead of re-reading a half-returned
    value on every kick (a cancelled kick's `Completed` also no longer starts a stray return
    tween). Both restore in `resetChestState`, so a tab change mid-shot is clean. Rationale in
    the source above `playShotFOVKick`; the lobby camera is parked between tabs, so anything left
    behind was permanent.
  - **The LOOT count badge sits on the diamond's apex** like the STORE pill (`0.5, 0.192`, no
    rotation, a 0.28 circle) instead of rotated on its upper-left edge.
  - **The purchase panel is flush right** on every device: `ChestPurchaseFrame` is anchored at
    `(1, 0.5)`, `X = 1.455` of the canvas, which lands its right edge one gap left of the party
    handle's parked position (`closedPosition` in `ReworkedPartyClient`). Device matrix
    (phone, 4:3 tablet, 1080p) with the party parked as at runtime: clear on all three.
  - **Rewards float out as their real 3D model** where one exists — weapon skins as the Trading Post's gun models in side profile, hero skins as the shop's standing rigs, Cash and Tokens as the `MoneyPhysical` coin on its edge — and as their
    2D icon on a billboard where none does (the `BoostConfig` potion icon, the title in its own style through `TitleRenderer`, an emote name card); the tier-coloured union remains the
    fallback for anything unresolvable. Only the fallback is recoloured; real models get a
    tier-coloured outline.

  **Revert hazard:** none beyond the build itself; the server change is additive (one extra push).
  Bounty only — `LootboxService`, `ChestController`, two authored GUI instances.

  **Verified:** syntax (`loadstring`) on both scripts, badge and panel by screenshot / device
  matrix. **Not yet playtested** — the camera, spam-click and 3D reveal fixes need the owner's
  next run (#37).

- **Chest scene, second playtest round (owner, 2026-09-03).** Five changes to the unreleased lootbox
  build, all in Bounty (`ChestController` plus two authored rows in the odds panel):
  - **Any of the five shots can land.** Exactly `stage` shots still hit, but the shot numbers that
    hit are drawn at random once per chest instead of always being the first `stage`, so the last
    shot can still decide the tier. The count never changes; the server's stage is replayed as
    before.
  - **Two guarantee bars in the odds panel.** Rows six and seven (`6PityEpic`, `7PityLegendary`,
    cloned from `ChestXPBar` and the old pity label; the grid is now 1/7 rows) fill from the
    server's pity counters against the config thresholds — `EPIC+ GUARANTEED  7 / 20`. They
    replace the guarantee sentence.
  - **The chest's glow behind every reward replaces the outline.** The chest's `Rays` emitter,
    recoloured and rescaled to the reward and tuned more visible (two rays alive at a time, held
    near opaque, `Brightness` 3), plays from one point (an Attachment on an invisible carrier, as the chest's own does) right
    behind each reward on the camera's side, so the rays stack instead of scattering around the
    reward. Particles only — a neon disc backdrop and a billboard of the same texture (which draws
    the texture's black ground) were both tried and cut the same day; the tier-coloured Highlight
    outline is gone.
  - **Emotes play on a small default Dust rig** — root anchored, limbs released after the pop,
    the clip through `AnimationLoader`; the name card only if the rig or clip is missing.
  - **The duplicate line is coloured:** DUPLICATE in orange, the refund in its currency's colour
    (Tokens `237, 56, 188`, Cash `255, 216, 0`).

  The LOOT badge was **not** moved: it already sits horizontally centred on the diamond's apex like
  the STORE pill at every aspect ratio (its offsets are all in screen height), so "centre it" is
  waiting on the owner saying where — see #37.

  **Revert hazard:** none beyond the build itself. The odds grid is an authored-instance change
  (six rows to seven); reverting the script alone leaves the two bars painted at zero.

  **Verified:** syntax (`loadstring`); the bars by screenshot. **Not yet playtested** — the random
  hit pattern, the glow discs and above all the animated Dust rig (an AnimationConstraint rig with
  free limbs under the hover's per-frame PivotTo has never run live) need the owner's next run
  (#37).

- **Chest scene, third round (owner, 2026-09-03).** Two additions, both in Bounty:
  - **"HIT" / "MISS" flies off every shot.** A call-out pops in small at the bullet or the miss
    hole, grows past full size, arcs up and out to a random side of the camera and fades over the
    back half of a 0.9 s flight (`spawnShotText` in `ChestController`; constants `K.SHOT_TEXT_*`).
  - **The cash / token chips show on the LOOT tab.** `CurrencyHudController` gains a second page:
    the two pills it draws beside the Bounty Pass are laid out as a row over the chest purchase
    panel, sized to it and right-aligned, in the band under the settings gear and the version tag;
    on a phone, where that band is too short, the pair moves up beside the version tag as a
    two-high stack, clear of the XP bar, instead of covering anything. Their `+` opens the currency vault and GO BACK returns to the LOOT tab. Hosted in
    `CurrencyHudGui.LootHolder` (new authored frame) and laid out in pixels from the live
    neighbours, which works because all three GUIs share `ScreenInsets.None`.

  Asked and answered, not changed: a Legendary resets the Epic+ guarantee counter as well as its
  own. That is the spec's rule (§3: the counter is "Epic or better"); separate counters are one
  line in `LootboxService.rollTier` if the owner wants them.

  **Revert hazard:** none; both additive. `LootHolder` is an authored instance — reverting the
  script alone leaves an empty hidden frame.

  **Verified:** syntax on both scripts; the chip row by an edit-mode device matrix (phone, 4:3
  tablet, 1080p) with the party parked and a stand-in version tag. **Not yet playtested** — the
  call-out's motion and the chips' runtime layout and vault round trip need the owner's next run
  (#37).

- **Chest scene, fourth round (owner, 2026-09-03).** Four fixes to the unreleased lootbox work,
  all in Bounty:
  - **HIT / MISS fly from over the chest**, never from where the shot landed — a miss hole on a
    far wall put the word nowhere near the chest. The origin is `K.SHOT_TEXT_LIFT` of the chest's
    live height over its base pivot, jittered sideways by `K.SHOT_TEXT_JITTER` so five call-outs
    do not stack (`spawnShotText` no longer takes a position).
  - **The rarity glow appears as the reward leaves the chest**, not on landing: `attachLootGlow`
    runs at spawn and a new `placeLootGlow` keeps the rays behind the reward through the pop as
    well as the hover.
  - **The emote rig flailed with its name label under it.** Its root is now the PrimaryPart, and
    once the limbs go physical the hover drives the root's CFrame alone instead of pivoting the
    whole model every frame (which wrote CFrames onto simulated limbs); the label is adorned to
    the root part, lifted by the root-to-centre distance, instead of to the Model. Same recipe as
    the Trading Post stand (`ShopStandDisplay.cleanRig`).
  - **The LOOT-tab chips lay across the settings gear and the version tag on a windowed PC.** The
    row was measured off `ChestMenu`'s purchase panel while that GUI was still disabled, and a
    disabled ScreenGui reports the layout of the window it was last enabled in (~380 px tall
    here). `CurrencyHudController` now ignores the panel until `ChestMenu` is enabled (its
    authored-scale fallback stands in, exact for any window) and re-lays on the panel's and the
    gear's geometry signals and on `ChestMenu.Enabled`.

  **Revert hazard:** none; all four are client-side presentation in two scripts.

  **Verified:** syntax on both scripts; the rig's pivot / root maths replayed on a clone in edit
  mode (driving the root reproduces the target pivot exactly); the chip layout checked against
  edit-mode geometry at 1658x678 (the row lands at y 83–117, under the gear's row ending at 54).
  **Not playtested** — the emote rig's physics and the chips' runtime re-lay need the owner's
  next run (#37).

- **Chest scene, fifth round (owner, 2026-09-06): the emote reward plays in a ViewportFrame.**
  Bounty, `ChestController` only. Four rounds of the in-world Dust rig — simulated limbs chasing an
  anchored root the hover moved every frame — never settled into the clip. The reward is now a
  portrait rig card (`rigCardVisual`, `K.LOOT_RIG_CARD_*` / `K.LOOT_EMOTE_CARD_HEIGHT`): a
  ViewportFrame whose WorldModel holds the default Dust rig, root anchored only, the Trading Post
  EXTRAS-card recipe. The clip is prewarmed at build and played when the pop lands; the hover spin orbits the viewport
  camera and its key light so the emote turns with the 3D rewards beside it. The viewport sits in
  its own ScreenGui (`ChestLootViewports`, DisplayOrder -1, no insets), pinned to the invisible
  carrier every frame through `WorldToViewportPoint`, because a ViewportFrame inside a BillboardGui
  draws nothing in the live client — neither Workspace-parented nor PlayerGui-parented, though the
  PlayerGui one rendered in an edit-mode screenshot and shipped invisible for one round (owner's
  playtest, same day). It is destroyed with the carrier through `Destroying`. The old rig path
  (root offsets in the hover, the label adorned to the root, `modelVisual`'s PrimaryPart argument)
  is gone; `cardVisual` takes a width and height.
  - **The rarity glow no longer fills the screen on a hero or weapon skin** (owner's screenshot,
    same day): the rays' carrier was parented inside the reward, and a Model reward's pop is
    `Model:ScaleTo`, which scaled the emitter 12.5x along with the model (measured 4.5 → 56.25
    studs on a clone). The glow now sits beside the reward in Workspace and leaves with it through
    `Destroying`.

  - **`attempt to index nil with 'AdjustSpeed'` in `playOpenChest`** (owner's log, same day): the
    open sequence and the shot step yield mid-run, and a tab change, a fresh chest or a result
    timeout resets the chest under them, nulling the tracks they hold. Both now capture
    `ChestFlow.run`, bumped by every `resetChestState`, and stop after any yield that finds it
    changed.

  - **The Epic guarantee bar reads `EPIC GUARANTEED`, not `EPIC+`** (owner, same day) — the label in
    `refreshProgress` and the authored placeholder on `OddsFrame.6PityEpic.Text` (set through
    `execute_luau`, so not in the hook capture). The guarantee itself is still Epic-or-better.

  - **The lobby chrome fades out on OPEN and back in once the loot has landed** (owner, same day):
    every other ScreenGui under PlayerGui plus this menu's purchase panel and XP bar, over 0.35 s,
    disabled at the end of the fade so invisible buttons take no clicks. Kept: the settings gear,
    the version tag, the ping / FPS readout, the black-bar transition, the emote viewport layer and
    the SHOOT button. Transparencies are snapshotted per element and restored; `resetChestState`
    restores too, so a tab change or a timeout never leaves the lobby blank (the `Chrome` table).
  - **A title reward's styled text sits on a dark pill** (owner, same day: the presets were
    unreadable against the glow) — a `TitleBack` frame behind the title card's text (toast surface
    `24,24,24` at 0.45, 6 px corners) sized from the text's `TextBounds` plus padding and re-fitted
    as the billboard's pixel size changes with distance. Title cards only; the name label above
    every reward stays bare (a first pass the same day put pills under those labels and was
    reverted — the two frames it authored into `ReplicatedStorage.Lootbox.LootLabel` are removed
    again, both through `execute_luau`, so neither is in the hook capture).
  - **The shoot button reads `SHOOT TO OPEN`** while a landed chest waits for its five shots
    (owner, same day); it read `SHOOT`.

  - **Hero skins reveal as rig cards too** (owner's screenshot, same day): the anchored,
    ScaleTo-shrunk world rig left Crimson Revenant's layered clothing undeformed in its T-pose
    shell at runtime and put the Model-adorned labels studs away from their rigs (Frostveil Vesper's
    over the next slot, Bluefrost Dust's off-screen) — none of which the same templates show in the
    Collection tiles' WorldModels. A hero skin now goes through the same `rigCardVisual` as the
    emote: WorldModel rig, root anchored, the lobby idle (`rbxassetid://507766666`) playing, label
    and glow on the carrier, `K.LOOT_RIG_CARD_HEIGHT` 3.8 studs. The remaining Model rewards
    (weapon skins) adorn their label to a `LabelAnchor` part at the pivot instead of the Model,
    whose adornee point is the bounding box.

  - **Studio-only loot preview** (owner, same day): L with the LOOT tab open lands a chest, parks
    the lid open and reveals a scripted batch of five, cycling through every `LootboxConfig.POOLS`
    entry (cash / tokens at their max, every potion, title, hero and weapon skin, two emotes), one
    duplicate of each duplicable kind with the server's refund, and a made-up kind for the generic
    fallback — labels built as `LootboxService.labelFor` builds them. No roll, no server call, no
    chest consumed, no profile write. Gated on `RunService:IsStudio()`, so it is unreachable from any
    published place, DEV included.

  - **The level bar hugs the top edge at 0.8x** (owner, same day): `ChestMenu.ChestProgress` is
    anchored `(0.5, 0)` at `y 0.035`, size `0.16 x 0.029` (was centred at `y 0.1`, `0.2 x 0.036`),
    and the chest icon is `RelativeYY` at 2.6x the bar's height instead of `RelativeXX` at 0.25 of
    its width, so its overhang above the bar is a share of screen height too and one position puts
    the icon's top 4–12 px from the screen top on every aspect (800x360 through 1920x1014). Authored
    values set through `execute_luau`, so not in the hook capture.

  **Revert hazard:** none; client-side presentation in one script and one authored frame. Reverting
  brings the flailing rig back, the mid-open error and the bare title text.

  **Verified:** syntax (`loadstring`); in edit mode the WorldModel rig draws and redraws a stepped
  `electro_swing` pose (a hand moved 1.85 studs over 45 frames); the glow blow-up reproduced and
  measured on a clone. **Owner-checked in Studio** (2026-09-06): the level bar placement. The
  ScreenGui rig cards (the Collection tiles' and shop cards' proven path), the chrome fade, the
  title pill and the preview key have not been confirmed live yet (#37).

- **Chest scene, sixth round (owner, 2026-09-06): the purchase panel is bigger and the LOOT chips
  actually draw on a phone.** Bounty, `ChestController` and `CurrencyHudController`.
  - **The LOOT-tab cash / token chips were missing on every phone.** They are laid out in
    absolute-space pixels off their neighbours but written into a position relative to their own
    ScreenGui, and on a `ScreenInsets.None` GUI those two spaces differ by the topbar and safe-area
    inset — 58 px on a landscape Galaxy A06 — which parked the pair off the top of the screen
    (measured live at y −114 with a height of 60). Every live neighbour read now converts into the
    GUI's own space. A PC never showed it: the same gap there is the 36-px topbar, so the row
    stayed on screen, just higher than intended.
  - **The purchase panel grows to fill the space it has**, on desktop as well as touch. Authored as
    a screen fraction, it came out 125 × 162 px on a phone — ~9 px odds rows — and 300 × 486 at
    1080p. A `UIScale`, with the frame re-anchored to its top-right corner so the growth runs down
    and left away from the gear and the chips, is sized off the nav diamonds' live box. That box is
    aspect-locked, so one rule gives two outcomes: a phone clears it sideways (~1.39), a 16:9
    desktop stops above it (~1.25).
  - **The chips left-align with the panel on a phone.** In the two-high stack layout the pair now
    starts at the panel's left edge and stops short of the version tag, taking its height from that
    gap — 6% shorter chips in exchange for a straight edge down the right-hand column.

  **Revert hazard:** none; client-side layout in two scripts. No authored instance changed — the
  re-anchor and the `UIScale` are applied to the PlayerGui clone at runtime, so reverting the
  scripts restores the authored panel exactly.

  **Verified:** syntax on both scripts; the inset bug measured on a live phone client before the
  fix, and the panel and chip geometry after it computed off those same measurements.
  **Playtested by the owner** (2026-09-06): chips drawing and both frames sized correctly.

- **Chest scene, seventh round (owner, 2026-09-07): spam-tapping OPEN and PURCHASE on a touchscreen
  no longer sends the chest spinning.** Bounty, `ChestController` only. The preview drag kept one set
  of state for every contact point, so a second thumb's movement was measured against the first
  thumb's position — a ~110° jump per event, at the velocity clamp. The drag now belongs to a single
  input object, with a deadzone before a tap counts as one (`InputBegan` has no region test, so a
  near-miss on either button claims a drag), a dropped-sample guard and a floor under the divisor that
  turns movement into spin velocity. **Identity is enforced for touch only** — the mouse reports
  movement as its own `MouseMovement` object, never as the `MouseButton1` one that opened the drag, so
  testing it everywhere would have killed dragging on PC outright. PC behaviour is unchanged.

  **Three chest tweens treated a cancel as a finish**, found in the same pass and fixed with it:
  `tweenChestTo` cancels whatever was driving the chest and `Cancel` fires `Completed`, which
  `playImpact`, `playDrumroll` and `playSpawnLanding` all acted on. `playSpawnLanding` is also
  run-guarded now, like every other yielding sequence, so a reset mid-landing cannot leave the
  orphaned landing driving the next chest or clearing `isSpawning` under it.

  **Revert hazard:** none; client-side input handling in one script, no authored instance touched.
  Reverting brings the spin back on touch.

  **Verified:** syntax (`loadstring`). **Not playtested** — it needs the DEV soak, and a touchscreen
  with two thumbs is the only way to exercise it (#37).

- **Chest scene, eighth round (owner, 2026-09-07): the reward's name scales with the screen, and a
  title's pill is near-solid.** Bounty, `ChestController` only. Everything else in the reveal is
  measured in studs and so tracks viewport height; the name label did not, because a `BillboardGui`
  size authored in offset is screen pixels — a flat 260x64 on every device, a third of the width of a
  landscape phone and a caption under a reward twice its size on a 1440p desktop. It now
  multiplies the template's authored box by `clamp(viewportY / 720, 0.75, 3)`, re-applied on a resize
  and on a camera swap. **The ceiling is 3, not 1 as in `DamageNumberClient`** — a HUD plate should
  not grow on a big screen, but this label hangs beside rewards that do, so capping it at 1 would
  keep the mismatch it is meant to fix.

  A TITLE reward's dark pill went `BackgroundTransparency` 0.45 → 0.12; the tier glow behind the card
  came through it and the styled presets were hard to read.

  **Revert hazard:** none; one client script, no authored instance touched. The `LootLabel` template
  still holds the authored 260x64 the scale multiplies, so reverting the script restores the old
  behaviour exactly.

  **Verified:** syntax (`loadstring`). **Owner-checked at one viewport** (2026-09-07) — the ends of
  the clamp, a phone and a 4K screen, are unexercised and want the DEV soak.

- **Chest scene, ninth round (owner, 2026-09-07): the BOUNTY+ panel, and the lobby fade stops
  toggling GUIs.** Bounty — `ChestController`, `CurrencyHudController` and the panel's
  `DisplayCharacterAnimator`.
  - **The BOUNTY+ outlaw shipped as a heap of loose plates on a real phone.** Two independent
    causes, now fixed rather than worked around. Nothing drove the rig's AnimationConstraints inside
    a WorldModel, which simulates physics; and its four accessory Handles — Beard, Duster, Vest,
    Belt — carry no weld, because a Humanoid builds those when it assembles a character and one
    sitting in a WorldModel never did. The rig boots fully anchored, welds the accessories itself,
    and only comes off the anchors once `AnimationLoader` confirms the idle (`CoolSitPose`) is
    playing; a clip that never arrives leaves it anchored in bind pose instead of folding up. Edit
    mode runs no physics, which is why this looked right in Studio and shipped broken twice.
  - **The camera fits the whole scene instead of measuring the rig.** The first repair sized it off
    head-to-foot height, but `ChestMenu` boots disabled, so that measurement was skipped until the
    LOOT tab opened — by which point the rig had collapsed and reported a fraction of its height,
    and the shot was cut off on all four sides. **Known cost, deliberately left:** the wagon 10–26
    studs behind him and an 11-stud cactus cap how large he can be — 53 px tall on a 799×359 phone,
    against 96 px framed on him and his coins. Trimming that dressing or turning the panel's card
    background on are the two ways out; both art calls, neither made.
  - **The panel fades with the rest of the UI on OPEN**, and the LOOT-tab currency chips are one
    side-by-side row above the purchase panel, which is pushed down far enough to clear the settings
    gear and the version tag on a phone.
  - **The lobby fade no longer enables or disables anything.** It was toggling eight ScreenGuis
    purely to stop clicks on invisible buttons, and re-enabling them — a full relayout, plus a
    932-instance ViewportFrame rebuild for the BOUNTY+ panel — landed on the frame the fade-in
    started, which is what the fade was being blamed for. Input is stopped directly instead
    (`Interactable` on the buttons, `Active` on the objects that sink clicks into 3D): 34 boolean
    writes against eight GUIs' worth of relayout. Two more cuts in the same pass — finding the roots
    walked all ~17,900 PlayerGui instances to locate eight (8–29 ms, and it ran twice per chest),
    and invisible subtrees were being snapshotted and tweened, the rank leaderboard and gamemode
    picker being modals whose entire canvas sits `Visible = false`. The walk is 1463 → 276
    instances, 339 → 186 tweens.
  - **`UIShadow` fades with everything else.** It was the one transparency-carrying class the fade
    did not know about, so ~20 panel shadows held full strength for the whole fade and disappeared
    only when their root was disabled — and popped in ahead of everything else on the way back.

  **Revert hazard:** none beyond the build itself — three client scripts, no authored instance
  changed, and the rig's anchoring and welds are applied to the PlayerGui clone at runtime. One
  behaviour change worth knowing: the fade no longer toggles `MainMenuGui.Enabled`, so the
  listeners in `ShopController`, `CurrencyHudController` and `FriendsInMatchClient` that fired on
  every chest run no longer fire. Nothing in the chest flow depended on them.

  **Verified:** syntax (`loadstring`) on all three scripts; the fade's costs measured in edit mode
  before and after, with the pruned root set proven identical to the old walk.
  **Owner-checked live** (2026-09-07): the fade-in stall is gone. **Not yet playtested:** the
  restored sit pose — physics only runs live, and this rig has shipped broken twice already.

- **Buying a chest plays the store's purchase cue** (2026-09-06, Bounty, `ChestController`). Banking
  a chest was silent. It now plays `SFX.UIButtonClick.UIPurchaseSucces` — the clip the Trading Post
  plays on a buy — off the server's `purchaseResult = "ok"` push rather than the click, so a refused
  buy (`poor` / `restricted` / `cooldown`) and a click the server never answers stay silent.

  **Revert hazard:** none; one client-side helper, no authored instance touched.
  **Verified:** syntax (`loadstring`). **Playtested by the owner** (2026-09-06).

- **A Rare-or-better chest sings while it opens** (2026-09-06, Bounty, `ChestController`). `LootBoxChime`
  is imported from the "Bounty - UI Update" place into `ReplicatedStorage.LootboxSFX` in the **Music**
  group, and plays from the moment the server's roll answers the OPEN press — the earliest the tier can
  be known — for `Rare`, `Epic` and `Legendary` only. Common and Uncommon open on the chest SFX alone.
  It loops through the landing and the five shots and fades out over 0.5 s as the lid opens; the clip is
  barely three seconds, so played once it ran out around the first shot and read as the shot cutting it
  off. Volume is 2 against the lobby bed's 0.5 (`Workspace.MainMenuMusic`) — at a matched 0.5 the chime
  sat inside the music instead of over it.

  **Revert hazard:** none; one client-side helper plus one new Sound template. The template's SoundGroup
  and volume were set through `execute_luau`, so they are not in the hook capture — a place revert takes
  the template with it and the helper then warns and stays silent, leaving the run itself untouched.

  **Verified:** syntax (`loadstring`) after each round. **Playtested by the owner** (2026-09-06), both
  the trigger and the loop.

- **New-item bubbles: a red dot chains from the COLLECTION button down to the individual tile**
  ([#34](https://github.com/Rasmus-Bondo/Bounty/issues/34), built 2026-09-03, Bounty). A player who
  gains a cosmetic — level-up, purchase, battle-pass tier, chest, quest — now gets a bubble on the
  COLLECTION button, on whichever of the six Collection tabs holds it, on the owning hunter's tile
  and on the item's own tile, so following the bubbles always ends on the item. Presence only: no
  glyph, no count. An item is marked seen the instant the cursor enters its tile, or on tap on a
  touchscreen; a parent clears when the last unseen item under it does.

  `NewItemService` (new, started in `Main`'s upper block) derives "new" as owned minus a new
  `SeenItems` profile set, so **no grant site was edited** — which is also why a chest payout badges
  without it knowing lootboxes exist. `NewItemClient` (new, in `StarterGui.CollectionGui`) drives
  every bubble as a sibling layer, finding tiles by attributes the tab modules already set, so none
  of the six Collection tab modules — whose require order is load-bearing — was touched.

  Thirteen authored instances: the `3CollectionFrame` badge, six tab dots, four hunter-tile dots and
  two clone templates. `NewItemDotTitle` exists because a title row is full-width but only ~46px
  tall and the aspect constraint clamps to the shorter axis, so one size cannot serve both it and a
  square tile. All in the STORE pill's red, and the COLLECTION badge sits at `0.5, 0.192` like STORE.

  **Data-affecting.** `SeenItems` lands in all three DataServices (Reconcile-backfilled, no
  `DATA_VERSION` bump). The `Stamped` seed is one-way: the first load after this ships copies
  everything already owned in as seen, so neither the live player base nor a brand-new account opens
  the menu to a dot on every tile.

  **Revert hazard:** the profile key is a harmless orphan on a reverted place, but a stamped profile
  cannot be un-stamped — reverting and re-shipping does not re-badge, it leaves the set as it stands.
  `Main` start order is load-bearing. The bubbles are authored instances, so reverting the scripts
  alone leaves thirteen permanently hidden frames.

  **Verified:** syntax on all four scripts; the seed/diff logic against synthetic profiles (a new
  account and a 14-item veteran both seed to zero dots, all six grant kinds badge, both title homes
  count, spoofed and unowned marks are refused, a topped-up boost does not re-badge); the client's
  aggregation across nine cases; geometry by device matrix on PC, iPhone 13 and a 4:3 tablet — which
  is what caught the first draft rendering rectangles instead of circles. **Not yet playtested** —
  hover-to-clear, the flush surviving a rejoin, and the Titles / Boosts / Emotes grids need a live run.

  **Open:** Daily and Quest still show a `!`, so the bottom-bar and side notifications are not yet
  one look — owner's call whether to align them. The LOOT badge was aligned on 2026-09-06, below.

- **New-item bubbles, first playtest round (owner, 2026-09-06).** Five changes to the unreleased
  bubble chain, all in Bounty:
  - **The LOOT and COLLECTION badges ride the bottom-bar press.** They were the one child
    `MenuHandlerScript` left out of its lift / dip / overshoot set, so a badge hung still while the
    tab rose and swelled underneath it.
  - **Boost tiles show a bubble at all.** The dot was there the whole time, drawn *underneath*
    `BoostsTab`'s owned-count badge, which is wider than it and sits above it. The count badge moved
    to the tile's top **left** so the dot keeps the top-right corner every other grid uses, and
    `dotFor` now derives the dot's ZIndex from its siblings so the next badge cannot bury it. The
    "only the first time you get a given cash/XP duration" rule the owner asked for was already the
    server's behaviour — an id is new until looked at once, and topping up a stack never re-badges.
  - **The six Collection tab bubbles hang over the button's top-right corner.** They were parented
    to the fixed grid cell and inset in *its* scale space; on a phone the button is ~45x20 with a
    TextScaled label filling its height and 76% of its width, so an inset dot has no free corner and
    landed mid-word. They now live inside the button's own `BackgroundFrame` — so they grow with its
    selected-state UIScale — anchored at `(1, 0.25)`.
  - **Title-row bubbles are bigger and in the corner.** A row is ~8:1, so the old `0.05` scale inset
    was 21 px on X against 2.5 px on Y. Same corner rule as the tabs; 12 px to ~20 px on desktop.
  - **The LOOT badge matches the rest of the chain:** the shared red (it was the older, duller
    `217,44,44`), `0.28` to `0.22` so it reads as a pair with the COLLECTION dot beside it, and the
    count nudged up 6% because Oswald draws a digit's ink low in the line box.

  **Revert hazard:** the placements are authored instances but the count badge's corner is in
  script — reverting `BoostsTab` alone puts the count straight back on top of the dot.

  **Verified:** syntax on three scripts; every placement by screenshot at 800x360 and at desktop,
  with the tab geometry also read back numerically. **Not yet playtested** in its final state.

- **Two chest codes, and `100LIKES` switched on.** `GIVEMECRATE` (1 chest) and `BOUNTYPLUS` (2) are
  new in `CodeRedemptionService`'s `CODES` table, and `100LIKES` trades its `active = false` for the
  same window: `startsAt = 1788804000` → `expiresAt = 1790013600`, i.e. **Mon 7 Sep 2026 20:00 CEST
  → Mon 21 Sep 2026 20:00 CEST**. `chests` is a new reward field, banked into `Lootboxes.Unopened` —
  in Bounty through `LootboxService.grantFreeChests`, in the two match places through a local profile
  write beside the weapon-skin one (there is no LootboxService there; the lobby reports the new count
  on the next profile load, as it already does for the tutorial super chest). `grantChests` split
  into a shared `bankChests` body with two entry points: the paid one keeps the plain name and the
  region gate, the free one skips it.

  **Must be published before Monday 20:00 CEST.** `startsAt` only keeps a *shipped* code dark; it
  cannot ship one late, so a publish that slips starts the promo whenever the publish lands.

  **Revert hazard:** no profile-shape change — `Lootboxes.Unopened` already exists — but chests
  already banked survive a revert. Reverting Bounty alone would leave the lobby copy without the
  `chests` branch while the match places still accept the code, burning it for nothing; all three go
  out together as always.

  **Verified:** all three copies compile, and the mirrored `CODES` + `resolveCode` block is
  byte-identical across them (`2682 B` / `439550909`). The window was read back with `os.date("!…")`
  off the loaded table. **Not yet playtested** — no code has been redeemed against the new field.

## Changed

- **Both tutorial cards now name the super chest** (2026-09-07, Bounty + both match places). The
  lesson has banked a super chest since 2026-09-03 and neither card said so: the offer promised
  `250 [cash] and 50 [token]` and the return toast paid out the same two. The offer row is now
  `250 [cash] + 50 [token] + 1 [chest]` and the toast `REWARD [cash]250 [token]50 [chest]1`, using
  the LOOT tab's own art (`121242329495518`) so both cards name the tab the chest lands in.
  `TutorialWelcomeController` and `TutorialCompleteController` only toggle the new chips; the rows
  themselves are authored instances, cloned off the token chip rather than re-typed.

  **The chest is a stamped flag, not an inference from `tutorialComplete`.** The grant is once per
  account (`Lootboxes.TutorialChestPaid`), so a replay banks nothing and must not be told it did.
  The bank moved out of `finishSession` into `bankTutorialChest(s)` with two callers — `runOutro`,
  immediately after `payOut` and **before** `stampReturnTeleportData`, and `finishSession` for the
  Ceiling path that never reaches an outro — and the run that actually banks sets `s.paidChest`.
  `tutorialChest` then rides all three hops `tutorialTokens` had to learn in August: the stamp (EXIT
  TRAINING), `sendHome`'s own `SetTeleportData` (the ordinary return) and `RoundController`'s solo
  drain-retry. On the offer side `TutorialDispatchService.offerPayload` reads the same profile flag,
  so a replaying test account is offered the two currencies alone.

  **The toast had to grow to hold a third chip**: `Toast` aspect `2.6 → 3.15`, list padding
  `0.02 → 0.018`, fractions re-cut — every label is *wider in pixels* than before despite the smaller
  fraction, and content sits at 97% of the row. The offer row's `and` became `+` and repeats before
  the chest; a three-item list joined by two `and`s reads worse. Verified numerically (every label
  height-bound at one `TextBounds.Y`, no spill) and by screenshot at 800x360, 640x480, 1024x768 and
  1080p. **Not yet playtested** — no live tutorial run has been taken end to end against it.

  **Revert hazard:** the banking behaviour is unchanged in substance but the *moment* moved earlier
  on a completed run (end of lesson rather than after the outro hold), which is strictly safer — it
  now matches when the Cash is paid. Reverting a match place alone leaves Bounty's cards reading a
  `tutorialChest` nobody stamps, which is false-negative by construction: the chip hides. Reverting
  Bounty alone leaves the flag stamped and unread. Neither loses a chest — the profile write is the
  same either way. `TutorialDirector` and `RoundController` are not on the mirrored 21 but were
  edited identically in Redwater and Frostbite.

- **Three more playtesters are held at the DEV top-up balance** (2026-09-07, all three places).
  `TesterGrantService.TESTERS` gains JedotisLittleGames (`4659611141`), JacooBoy (`51150355`) and
  YManDuGames — Antidote (`9562522291`), taking the roster 8 → 11. The ids were resolved through
  `GetUserIdFromNameAsync` rather than transcribed, since the table matches on id alone and a
  mistyped one fails silently as a tester who never gets paid.

  **Revert hazard: none beyond the roster.** DEV universe only. `TesterGrantService` is one of the 21
  mirrored modules and all three copies were written in the same pass; a place reverted alone simply
  stops topping these three up when they land there first.

  **Verified:** all three copies byte-identical (`5445 B` / `2431935182`), compile clean
  (`loadstring`), 11 rows. **Not exercised** — it needs one of them joining DEV.

- **Domination's capture bar no longer sits on the centre announcement** (2026-09-07, both match
  places, owner's report from a Domination playtest). Capturing a point pays a reward, so the bar and
  the reward card are on screen together on *every* capture — at the authored `y = 0.6436` the bar
  landed square on the announcement's top line. The bar now lifts and the announcement stack drops to
  meet it, so the bar sits above the text — **on every device**, phones included.

  **The test is `TouchEnabled`, and it is a test of which HUD is on screen rather than of device
  class.** The floor is the whole constraint and the two HUDs differ: `ReworkedHunterGui.ScreenGui`
  paints from `0.777` of height, `HunterGuiMobile` from `0.830`. Desktop drops the stack `0.017`
  canvas units and lifts the bar to `0.568`; touch drops `0.075` and lifts to `0.5936`.

  This shipped first gated on `height >= 500`, which was wrong twice over and is worth recording:
  it grouped **tablets** with desktop even though a tablet runs the mobile HUD and so wants the other
  floor, and it excluded **phones** on the belief they had no room. They have — measured on 705x338
  there is 99.9px between the crosshair dot (ends 180.5) and the first *painted* mobile-HUD pixel
  (`AmmoCount` at 280.4, **not** the canvas top at 272.8) against the 83px needed. Same trap as the
  desktop HUD, whose bounding box hid 0.010 of height: **measure the paint, not the frame.**

  It only fits at all because the `0.44..0.56` band is the transient kill skull rather than the
  aiming crosshair, so the bar is allowed into it — a capture and a kill rarely coincide, a capture
  and its own reward line always do.

  Both profiles verified by applying the moves and re-measuring, then by screenshot. Desktop
  (1658x678, the most vertically cramped PC case): bar `0.5321..0.6039`, main top `0.6154`, stack
  bottom `0.7714`. Touch (705x338): `+8.0px` below the dot, `+8.0px` below the bar, `+6.9px` above
  the HUD.

  **Rollback:** both moves are runtime-only. `CaptureBar`'s authored `Position` is untouched and is
  what a revert lands on, and the announcement's positions resolve from constants, so reverting the
  two scripts restores the old layout with no authored instance to put back.

- **The bounty card strip sits under the timer in TDM, both match places** (2026-09-07, owner's
  report from a phone playtest). The authored 60px top offset on `BountyListGui.Canvas` is the worst
  case of three gamemodes and only two need it — deathmatch stacks a zone label above the match timer,
  domination holds the same band with its capture dials — so in TDM the strip floated a card's height
  below the clock. `BountyListClient` re-pins the canvas off the `workspace.Gamemode` attribute for
  every mode outside `CROWDED_TOP_BAND`, landing the first line of card text 4px under the timer slot
  on any viewport: 27px of lift on a phone, 50px at 1080.

  **Rollback risk: low, cosmetic, one script, no authored instance changed.** A new gamemode that
  draws anything top-centre must be added to `CROWDED_TOP_BAND` — the default is to lift.
  **Verified:** owner playtest on a phone, 2026-09-07.

- **The centre announcement replaces the right-hand combat feed, both match places** (2026-09-07,
  owner's call after playing the 2026-09-06 build). `COMBAT_FEEDBACK_SPEC.md` §0's "the announcement
  is the moment; `CombatFeedClient` stays the ledger" is **reversed** — the spec now carries the
  reversal at the top of that section.

  `CombatFeedClient` is `Disabled` in Redwater and Frostbite. Every row it carried now arrives on the
  centre card: `ELIMINATED <NAME>` / `ASSISTED ON <NAME>`, the Domination objective lines, bounty
  claim and spree bonus, the tutorial instalment, and the two other-player rows as ambient notices
  that wait for the player's own card to clear rather than interrupting it. `SubAnnouncement`,
  `RewardAnnouncementCash` and `RewardAnnouncementXP` were cloned across from the "Bounty - UI Update"
  prototype, so §2.2's cuts of `showRewards` / `addRewards` / `flyDelta` / `showAssist` are undone.

  **The announcement no longer listens to `HitConfirm`.** `fireCombatReward` gained a trailing
  `subject` argument and `awardKill` / `awardAssist` an optional `victimName`, so one event carries
  the line *and* its numbers — which is also what fixes §2.3's "no assist-side event carries the
  victim's name" rather than working around it. `awardKill` is the crediting authority and fires on
  kills the hit pipeline never sees, so this cannot under-report. `DamageNumberClient` still uses
  `HitConfirm` and is untouched.

  **The stuck ELIMINATED / BOUNTY text is fixed in the same pass**, reported by the owner from a
  playtest of the unreleased 2026-09-06 build. Cause: `showElimination` and `showBounty` shared one
  `displayToken`, and a bounty kill fires both within a frame — so whichever ran second bumped the
  token and the first one's pending fade failed its `token ~= displayToken` check and returned,
  leaving its label up until the next round boundary. It happened on **every** bounty claim. The
  counter is now split into `stackToken` and `headerToken`, because the two are started by
  independent events and need independent clocks. A second instance of the same class was found and
  fixed while building the beat logic: `extendBeat` re-arms the fade on a fresh token rather than the
  beat's original one, or the first fade would still fire at the old deadline and hide an addition
  that had just landed.

  **A row triggered during the fade-out then showed nothing at all** — reported separately by the
  owner, and a different mechanism from the stuck text, though both look like "the announcement did
  not appear". A generation token only guards a pending `task.delay`; it does nothing to a **tween
  that has already started**, which keeps interpolating its label to `TextTransparency` 1 no matter
  what text is written underneath, and a raw property assignment made mid-tween is overwritten again
  on the next frame. So a row arriving inside the stack's 0.5s fade was written correctly and then
  faded out by a tween nobody had cancelled. Verified in isolation rather than reasoned about: an
  edit-mode probe on a throwaway label ends at `TextTransparency` **1.000** when the property is
  assigned mid-tween and **0.000** when the tween is cancelled first.

  Fixed by giving fades an owner — `fadeTweens` per label, with `wake()` / `hideLabel()` on every
  path that writes to one. Starting a *new* tween on the same property does cancel the old one, which
  is why the `punchIn` paths survived and the assign-only ones (multi-kill retext, sub-line retext,
  `flyDelta`'s count-up) did not; relying on that was too subtle to keep. The header had the same
  hazard — a second claim inside the previous header's 0.42s fade would have slammed into an
  invisible label. `beat.fading` is raised when the fade *starts*, so an event in that window gets a
  fresh card instead of being folded into one that is leaving and inheriting a stale main line; a
  kill continuing a streak carries its totals across, since the 8s multi-kill window is more than
  twice the 3.4s the card is up.

  **Placement went back to the prototype's** screen y 0.643–0.738, with the Domination capture-bar
  (0.608–0.680) and `SwapHunterFrame` (0.709–0.795) overlaps accepted explicitly on the owner's call —
  a four-line stack no longer fits above the crosshair, which is what the lifted position existed for.

  **Rollback:** flip `CombatFeedClient.Disabled` back to `false` and the old feed returns whole; it was
  disabled rather than edited precisely so none of its per-viewport tuning had to be touched. Doing so
  alone would then announce every kill twice. KillCamClient reads the `FeedBaseYScale` attribute the
  feed published and falls back to 0.565 via `FindFirstChild` when the GUI is absent, so the "KILLED
  BY" card parks at the old desktop constant instead of breaking. **Not yet playtested.**

- **The announcement's kill, assist and reward cues never played at all** (2026-09-07, both match
  places). `AnnouncementController.playSfx` cloned the template, parented it to `SoundService`, wired
  up its cleanup — and never called `sound:Play()`. Parenting a Sound does not start it. The line was
  dropped when the prototype's helper was ported on 2026-09-06, so **every cue routed through
  `playSfx` was silent for the whole life of the feature**, from the original build until now.

  **It presented as a mixing problem, and that is the part worth keeping.** `playBountyStinger` has
  its own player and its own `:Play()`, so the bounty header kept working throughout — one cue
  audible and three not reads as "those three are too quiet", not as "those three never start". Two
  rounds of volume raising were spent on that reading (0.5 → 2.0 on the assist and reward chimes,
  then 2.0 → 6.0 on the kill sting) before anyone read the helper. A Sound parented to
  `SoundService` is grouped, `IsLoaded`, has a `TimeLength` and is doing nothing; **confirm `:Play()`
  is reached before touching a level.** `Sound.PlaybackLoudness` will not settle it from edit mode
  either — it reports 0 there for every sound, playing or not.

  Checked for the same fault everywhere else: eight other scripts clone a Sound into `SoundService`
  and all eight play it. `BountyMusicClient.cloneLocalSound` deliberately does not — it is a factory
  that hands the caller a silent sound to fade up.

  **Levels then set by ear on the first playtest where they actually played**: `KillEffectSound`,
  `Assist` and `Reward.Award` at **1.2** (effective 0.6 through the 0.5 `SFX` group), and
  `Reward.Bounty` at its shipped 0.5. They went to 2.0 first — effective 1.0, matching the
  `GunGui.HeadshotSound` hitmarker that lands on the same frame as a kill — and the owner judged that
  a little too loud. The three move together because they share `playSfx` and sat at one level; if
  the kill sting later needs to sit above the other two, split them rather than moving all three. If
  a cue is wrong in character rather than level, `SFX.Fight.KillSound` (`124954333259876`) sits
  unused in the same folder and the swap is one property.

- **The Fortuna bundle's featured countdown runs two more weeks** (2026-09-07, Bounty). Its deadline
  had elapsed on 2026-09-05, so the FEATURED tab was drawing `OFFER ENDED` with nothing failing
  anywhere. `DEADLINE_UNIX` moves 1788566400 → 1789776000 (Sat 2026-09-19 00:00 UTC / 02:00 CEST) in
  both copies — `ShopFeaturedTab` (what players see) and the parked `TradingPostController`, which
  carries it so a rollback to the old Trading Post does not land on a dead offer. Reverting either
  copy alone re-opens the offer expired. The authored placeholder strings were re-typed to match
  (`11D 22H LEFT` / `ENDS IN 11D 22H 15M`); both are overwritten in the countdown loop's first frame,
  so they are edit-mode cosmetics only. **Not playtested** — constant change, verified by compile.

- **Round XP and Cash are credited as they are earned, not at the buzzer** (2026-09-06, both match
  places). `ProgressionService.addRewards` banked every round earn while `State.roundActive` and
  `RoundController` paid it out through `flushPendingRewards` at the round end; XP has to land live
  or the new level-up card could only ever fire after the match. **This removes the forfeit rule** —
  leaving mid-round used to cost a player the whole round's XP and Cash and now costs them only the
  round-completion bonus. That was deliberate ("play to the buzzer to get paid"), so reverting is a
  design decision, not just a code one. `flushPendingRewards` is still called at the buzzer and is
  still idempotent; it now normally finds an empty bucket and stays as a safety net.

  **The tutorial's economy isolation was riding on the same flag** and had to be made explicit, or
  un-gating would have paid out onboarding bot kills. `roundActive` is true during a lesson on
  purpose (sprint gate, ultimate-charge reset), and the banking was what kept those kills out of the
  wallet. New `ProgressionService.setEarningsHeld(player, held)`: `RoundController`'s tutorial
  session holds that one player for the length of the lesson and lifts it in the wind-down, and
  `TutorialDirector`'s existing `clearPendingRewards` calls still drop the bank unpaid. If you
  revert only `RoundController`, tutorial kills start paying real XP and Cash.

- **The Outlaw Starter Pack now includes three lootbox chests.** `BundleConfig`'s starter pack gains
  a `Chest` grant (`Count = 3`), `BundleService` a branch that banks it, and `LootboxService` a
  `grantChests` entry point that normalises the counters, adds to `Unopened` and pushes the LOOT tab.
  Price stays 250 Tokens — chests are not ownable, so they never enter `priceFor`'s discount
  arithmetic, and the pack is now cheaper than three chests bought at 100 each, capped by the
  one-per-account rule.

  **Region-restricted accounts get the pack without the chests** (owner's call): a Token-bought chest
  is what `ArePaidRandomItemsRestricted` forbids and a bundle is no different, so `grantChests`
  returns 0 for them while the Cash and boosts still land — **and the card stops promising them.**
  `BundleStateEvent` now carries `chestsRestricted` (`LootboxService.isPaidRandomRestricted`), which
  `ShopState.lootboxesRestricted` exposes and `ShopBundlesTab.showsChests` gates: the card's authored
  `LootFrame` chest viewport goes `Visible = false` and the panel drops its chest line. The client
  flag starts restricted, so the art appears when the server allows it rather than the other way
  round. The bundle `Description` deliberately does not name the chests — it would survive both.

  **Revert hazard:** removing the grant costs nothing stored, but chests already banked stay banked,
  and anyone already in `data.PurchasedBundles` never sees the chests at all. An old server that
  pushes no `chestsRestricted` reads as unrestricted, so publish the place and the lobby together.
  Syntax-checked with `loadstring`; **not yet playtested** — the restricted path needs an account
  PolicyService actually flags, and the card's `LootHeader` still reads a hand-authored
  "3x BASIC CHESTS" rather than the grant's count.

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

- **Daily reward loot table overhauled and passive boost removed.** The seven-day streak rewards are
  replaced wholesale: Day 1 → 250 Cash, Day 2 → 3 Crates, Day 3 → 1 XP Boost (30 min), Day 4 →
  500 Cash, Day 5 → 2 Crates, Day 6 → 1 Cash Boost + 1 XP Boost (30 min each), Day 7 → 100 Tokens
  + 5 Crates. The endless Day 8+ tail is now 1 Crate (was 10 Tokens). Crates are a new grant kind
  (`"crate"`) backed by `LootboxService.grantChests` — banked as unopened chests, opened in the LOOT
  tab. Boosts upgraded from 15-min to 30-min (`xp_25_30`, `cash_25_30`).

  The +10% passive Cash & XP boost (earned at streak day 7, kept while the streak held) is removed
  entirely. `BoostService.getMultiplier` no longer reads `DailyPermaBoost`, the Redwater/Frostbite
  `DailyRewardService` no longer sets it, `FriendBonusService` no longer includes it in its
  multiplier breakdown, and the lobby's `DailyLoginController` no longer shows it. The profile field
  `DailyPermaBoost` stays in the schema as a dormant `false` default — `ensureData` still normalises
  it and `applyLapse` still clears it, so any legacy `true` decays on the next streak break.

  Scripts touched: `DailyRewardConfig` (mirrored, all 3), Bounty `DailyRewardService` (added
  `LootboxService` require + `"crate"` grant handler, removed passive state push),
  `DailyLoginController` (crate display + passive UI removal), `FriendBonusService` (passive
  removal); Redwater + Frostbite `BoostService` (passive multiplier removal), `DailyRewardService`
  (passive setter removal).

  **The crate tiles show the chest art instead of a Token glyph** (owner, 2026-09-07, Bounty
  `DailyLoginController`). Days 2, 5, 7 and 8+ were painting `TOKEN_ICON` as a stand-in. They now
  use the two lootbox chest uploads: the lit one on the small reward icon, a pre-darkened twin on the
  big rotated watermark, which also opts out of the tint the single-glyph kinds are drawn with. Cash,
  XP, Token and boost tiles are untouched — the watermark falls back to the old single-image path.

  **Verified:** syntax (`loadstring`), and both asset ids confirmed to resolve to real images by a
  throwaway probe GUI screenshotted in edit mode and removed. **Not seen in the panel itself** —
  whether the wide chest reads at the reward icon's Fit box on a narrow tile wants a playtest look.

  **Revert hazard:** none — code-only, no profile schema change. Reverting restores the old rewards
  and re-enables the passive boost. Existing `DailyPermaBoost = true` values are harmless orphans on
  a reverted place (BoostService reads them again).

  **Verified:** syntax (`loadstring`) on all edited scripts in all three places; `DailyRewardConfig`
  byte-identical across all three (`6378 B`). **Not yet playtested.**

## Fixed

- **The BOUNTY+ panel no longer advertises chests to a player who cannot be given them**
  (2026-09-07, Bounty). `ArePaidRandomItemsRestricted` accounts are banked 0 of the pass's five
  chests — `BountyPlusService` pays them through the region-gated `LootboxService.grantChests`, and
  has since the pass shipped — but the card still listed `x5 BASIC CHESTS` and the purchase popup
  still named five. The perk card now drops that line for them and closes up over it (one row
  shorter; every surviving row keeps its size), and the popup's detail line names chests only when
  chests actually landed. Same treatment the Outlaw Starter Pack already ships, and the reason is
  the same: a card must not promise what the sale will not deliver.

  **Reverting** puts the promise back on the card for restricted players; nothing about what the
  pass *pays* changes either way. The diorama keeps its chests by decision — its camera fits the
  whole scene, so pulling models would reframe the shot for those players alone.

  **Verified:** both scripts compile; the shrunk card was screenshot-checked against the authored
  one in edit mode, and the authored instances are untouched (the layout is computed at runtime and
  restores exactly when the flag clears). **Playtested (owner, 2026-09-07)** by forcing
  `LootboxService.isPaidRandomRestricted` to `true` for one run — Studio's policy always answers
  unrestricted, so that override is the only way to reach this state; it was removed straight after
  and the function verified byte-for-byte back to its published shape. Never exercised against a
  genuinely restricted account, which no one here has.

- **The Collection panels no longer sit under the bottom bar on a 4:3 screen.** The left panel's
  HUNTERS/EMOTES/BOOSTS tab row hangs 11% of the panel's height *below* the panel, and the HOME
  diamond was sitting on top of it — the tabs could not be pressed. Nothing about the panels changed:
  the bar is `0.25` of the screen HEIGHT with a `4.5` aspect constraint, so it is always
  `1.125 x height` wide and centred — 63% of the width at 16:9, where it clears this menu entirely,
  but 84% at 4:3, where the leftmost cell slides underneath. Splitting it into five cells (LOOT)
  narrowed each from `0.25` to `0.2` and moved HOME further left again, which is what finally put the
  diamond squarely on the tabs.

  `Panels` now squeezes `CanvasLeft`, `CanvasRight` and `AbilityPanelNew` in Y — solving for the
  **tab row**, not the panel, because the panel bottoms clear the bar on their own long before the
  tabs do — until the lowest element lands at `0.775` of the gui. The limit is measured against the
  **diamond**, not the bar frame: `CanvasBottom` starts at `0.75` of the screen but its cells are
  empty up there, and HOME's topmost visible pixel is `0.80` — clearing `0.75` threw away 5% of the
  screen for nothing (it did, on the first pass, and the gap was obvious). The two GUIs are also in
  different inset spaces (the bar is `ScreenInsets = None`, this menu is `CoreUISafeInsets`), so that
  `0.80` of the *screen* is `0.787-0.791` of *this* gui once a topbar exists; Studio measures the
  topbar as 0, so the margin is set for the worst case rather than measured. At 4:3 the panels come
  out at 91% of their authored height, with the tabs landing ~10 px above the diamond on an 810-tall
  tablet.

  **Interpolated on aspect, not branched on a tablet test** (UI_STYLE_GUIDE 4.6 — the quantity is
  continuous): at 16:9 and wider the authored Position/Size are written back *from a snapshot*, so
  desktop and every phone are untouched to the digit, and a PC window narrower than 16:9 gets the
  same fit for the same defect. The aspect is read off `Camera.ViewportSize`, never off the
  ScreenGui — this menu is disabled whenever it is closed, including at require time, and a disabled
  ScreenGui keeps a stale `800x600` AbsoluteSize, which is exactly 4:3 and would have fitted every
  desktop as if it were an iPad.

  Same pass: the panels' gold outline is an authored **sub-pixel** `UIStroke` drawn outside the frame;
  its left, right and bottom edges rasterise to a 1 px hairline but the top edge loses that row to the
  frame's own coverage and does not draw at all, which is what read as the panel being cut off along
  the top. The fit multiplies the authored thickness by `1 + narrowness` (multiply, never assign —
  these are authoring-scale numbers, not pixels), so the top border appears at 4:3 and nothing changes
  at 16:9.

  **Revert hazard: none.** One module, runtime-only — no authored instance changed, and the wide-screen
  path restores the snapshot. Bounty only. **Verified:** `loadstring` compile, the arithmetic
  dry-run at four viewports (1920x1080 and 1600x720 write the authored numbers back unchanged;
  1080x810 lands the tabs on 0.775, 20 px above the diamond in Studio's inset-free space and ~10 px
  once a topbar eats into it), and a screenshot of the fit applied by hand in edit mode under the
  `ipad_8th_generation` simulator. **Owner-checked on the tablet sim** (2026-09-07) — the first pass
  cleared the bar frame rather than the diamond and left a visible dead band, which is what set the
  limit where it is.

- **Floating damage numbers are no longer phone-sized-for-a-monitor.** The plate and every number in
  it were authored in absolute screen pixels — a `BillboardGui` in offset units shrinks with neither
  camera distance nor viewport — so a 330x190 plate tuned on a desktop covered roughly half the
  height of a landscape phone. `DamageNumberClient` now multiplies every authored pixel by
  `clamp(viewportY / 800, 0.45, 1)`, the same rule and reference height the podium plates use.
  Desktop is unchanged; a phone lands near half size. Reverting brings the old size back and nothing
  else — the scale is confined to this one script, in Redwater Canyon and Frostbite Claim, verified
  byte-identical by length + djb2 checksum (`11412 B` / `2812935240`). Confirmed on device.

- **The Collection's left grid no longer collapses to one column of full-width cards.** HUNTERS,
  BOOSTS and EMOTES share one sizing pass, and it reserves a 12 px scrollbar lane unless
  `Refs.isTouchOnly` — a flag latched at require time as `TouchEnabled and not KeyboardEnabled`,
  which comes out **false** wherever a keyboard is reported: the Studio device emulator with the
  developer's own keyboard, and handsets that report their on-screen one. A phone panel is only
  ~110-140 px wide, so that lane is up to 11% of it, and losing it is exactly what drops the grid
  under the 56 px tap-target floor. The lane is now given up before a column is; the floor is
  unchanged. `fitLeftGrid` also re-measures when the ScreenGui is first enabled, because the grids
  are built while it is still disabled and a disabled ScreenGui does not lay out.

  Reported by the owner as intermittent, which is the flag: it depends on whether the device
  reports a keyboard, so the emulator does it and a real handset usually does not.

  **Revert hazard:** none — one client module, no authored instance, Bounty only.

  **Verified:** syntax, plus the new arithmetic replayed across seven viewport widths — the emulator
  at 705 and iPhone 7 at 667 flip from one column to two, and every wider device including desktop
  keeps the lane and the exact cell sizes it had before. **Not yet playtested** — `fitLeftGrid` only
  runs at runtime, so edit mode renders the authored scale cells instead.

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

- **Default audio volume lowered from 100% to 50% on first join.** Three layers, all three places:
  the SoundGroup instances (SFX, Music, HitSound) now ship with `Volume = 0.5` instead of the
  engine default 1.0; `PlayerSettingsService` defaults `MasterVolume` to `0.5` so new accounts
  start at half; and `SettingsController` seeds the client at `0.5` instead of `1` so the
  pre-settings-payload window is already at the lowered level. Per-group defaults (SFX, Music,
  HitSound sliders) stay at 1.0 — only the master knob moved, so the relative mix is unchanged.
  Existing profiles keep their saved value; `Reconcile` only backfills missing keys. Closes
  [#36](https://github.com/Rasmus-Bondo/Bounty/issues/36).

  `PlayerSettingsService` is not one of the 20 mirrored modules but exists in all three places and
  must agree — edited in one pass. `SettingsController` likewise.

  **Revert hazard:** none. The SoundGroup volumes and the client seed are stateless; the server
  default only affects accounts that have never touched the slider. No profile migration.

  **Playtested by the owner**, confirmed comfortable on join.
