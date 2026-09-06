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

- **Shared modules:** `GameEnvironment` touched in all three places (one DEV-only season row), verified byte-identical by length **and** djb2 checksum after the edit (`12552 B` / `3209512831`). Match-place mirror also — `HighNoonModule` and `BotCombat` across Redwater Canyon and Frostbite Claim, verified byte-identical by length **and** checksum after the sync (`16636 B` / `101943 B`). **Lootbox build (2026-09-03):** `Wallet` (four reasons) and `Telemetry` (one event) touched in all three places, verified by length + hash (`7719 B` / `663703730`, `28058 B` / `1779240489`); match-place mirror `DataService` and `TutorialDirector` across Redwater and Frostbite (`26512 B` / `1269809867`, `80703 B` / `1157972711`); the profile-template block and the launch-migration block are byte-identical in all three DataServices (`1220 B` / `237526912`, `2058 B` / `3057621043`). **New-item bubbles (2026-09-03):** none of the 20 mirrored modules was edited — `TitlesConfig` is only read — but the `SeenItems` template block was added to `DataService` in all three places and verified byte-identical by length + byte-sum (`1453 B` / `122758`). **Bubble polish + left-grid fix (2026-09-06):** none of the 20 touched — Bounty only, four client scripts and a handful of authored GUI instances. **Chest codes (2026-09-06):** none of the 20 touched either, but `CodeRedemptionService` — mirrored by hand, not on the list — had its `CODES` + `resolveCode` block verified byte-identical in all three places (`2682 B` / `439550909`). **Chest chime (2026-09-06):** none of the 20 touched — Bounty only, one client script and one new Sound template.
- **Data-affecting:** yes — the ranked-season payout mark changes key form in the profile. Harmless before 2026-09-12 (nothing has ever paid), a double-pay re-opener after it. See Fixed. **Lootbox build:** profile shape gains `Lootboxes` + `LootboxLaunchV1` (Reconcile-backfilled, no `DATA_VERSION` bump) and four Wallet reasons; the one-way launch migration (Level/XP reset, veteran bundle) is armed for the **DEV universe only** (`LOOTBOX_LAUNCH_ARMED = GameEnvironment.env == "Dev"`) and stays off on live until the launch publish flips it to `true`. See Added. **New-item bubbles:** profile shape gains `SeenItems` (Reconcile-backfilled, no `DATA_VERSION` bump) whose `Stamped` seed is one-way, stamped on the first load after this ships. See Added.

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

## Fixed

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
