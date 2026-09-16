# Bounty Pass — Season 2 rework spec

Build spec for a cold session. Written 2026-09-16. Everything here was verified against live
Studio via MCP on that date; re-check anything load-bearing before you act on it.

**Decisions already made by the owner** (do not re-litigate):

- Ranked resets every **2 weeks**; the pass runs **3 weeks**. They no longer turn over together.
  The `BattlePassConfig` comment that claimed they do has already been rewritten.
- This is a **full Season 2 reset** — `SEASON_ID` S6 → S7. Every player's BP level, XP, quest
  progress, track claims and `ownsFullPass` reset. Full Pass is a fresh 800-Token purchase.
- Hunter skins and emotes are being authored by the owner's friend. **Leave those rows as
  placeholders** — do not invent ids, and do not substitute existing cosmetics for them.
- Two of the four lava gun skins go on the pass.
- Boring reward rows (plain Cash) become **lootbox chests**.

---

## 1. Status — what is already done

| Done | Where | Verified |
|---|---|---|
| Cadence comment rewritten | `ReplicatedStorage.Config.BattlePassConfig` ×3 places | 28,907 B, identical checksums, syntax OK |
| 7 Season 2 titles authored | `ReplicatedStorage.Config.TitlesConfig` ×3 places | 22,896 B, identical checksums, `IsValid(hunter,id)` true for all 7, no duplicate ids |

The seven new titles are live in the catalog but carry `hiddenUntilOwned = true`, so they are
invisible to players until the flip. That flag is what makes it safe for a publish to happen
before the season ships — see §6.

| Level | Title | Hunter | Style | Track |
|---|---|---|---|---|
| 2 | CINDERKIN | Dust | tint | paid |
| 7 | HOT STREAK | Fortuna | gradient | paid + free |
| 12 | HEAT HAZE | Vesper | shine | paid |
| 17 | FORGEBORN | Bram | smoke | paid |
| 22 | SUNSCORCH | Dust | glow | paid |
| 27 | EMBERLINE | Vesper | chrome | paid |
| 27 | ASHBORNE | Fortuna | tint | free |

Latest four slots (17/22/27 paid/27 free) are one per hunter, which is the existing rule. No
reserved style is used (`fire`/`lightning`/`bloodmoon`/`holo`/`gilded`) — the season is
fire-*themed*, but `fire` itself is HIGH NOON's apex.

---

## 2. Art manifest — what is still needed

### 2a. From the owner's friend

| Slot | Kind | Track | Notes |
|---|---|---|---|
| L10 | Hunter skin | paid + free | Free for everyone, like SummerDust was. Highest-visibility skin in the season. |
| L20 | Hunter skin | paid | |
| L30 | Hunter skin | paid | Season capstone. |
| L3, L13, L18, L24, L28 | Emote ×5 | L18 also free | Need animation asset ids + display names. |

**Hunter skins** are Models named under:
- `ReplicatedStorage.Characters.<hunter>.Skin` (Bounty — lobby preview)
- `Hunters.<hunter>.Character.Skins` (Redwater + Frostbite — in-match)

Both are required or the skin renders in one place and not the other.

**Emotes** need an entry in `ReplicatedStorage.Config.EmoteConfig` (mirrored): an `ORDER` entry
plus an `EMOTES` row with `displayName` + `animationId`, **no `price`**, and
`unlockText = "BOUNTY PASS"`. Dropping `price` is what makes an emote earn-only —
`CollectionService.purchaseEmote` refuses a price of 0.

### 2b. Lava gun skins — exist, need wiring

Four fire gun skins already exist as **Redwater viewmodels** and are allocated to nothing at all
(they appear in no config — confirmed by grep across all three places):

| Hunter | Skin | Use |
|---|---|---|
| Dust | `CinderSix-Shooter` | **Pass L15** |
| Bram | `MoltenGrudgekeeper` | **Pass L29** |
| Vesper | `EmberpiecerRifle` | left free for shop/chests |
| Fortuna | `InfernoHand` | left free for shop/chests |

Picked Dust + Bram because Dust is the default and most-played hunter (headline value at L15) and
Bram has never had a pass cosmetic. **This is a one-line swap** if the owner prefers the other two
— only the `id`/`character` pair changes.

Note the authored spelling `EmberpiecerRifle` — "piecer", not "piercer". Match it exactly if it is
ever used; do not silently correct it.

**Wiring these two needs work beyond the config row:**

1. **Bounty has no `WeaponSkins` entry for either.** `BattlePassConfig` requires a `gunSkin` id to
   match a Model under `ReplicatedStorage.WeaponSkins.<character>`, and the pass panel renders that
   model in a ViewportFrame. Bounty currently holds only `Dust: HellFire, DefaultRevolver,
   BetaRevolver, Icefang` and `Bram: Grudgekeeper, FrostbiteGrudgekeeper`. Without this the card
   renders empty.
2. **Neither has a world model.** `ServerStorage.PreflightGates` already carries the note
   `Dust skin 'CinderSix-Shooter': no Weapon.WorldModel.Skins entry of the same name`. Without it
   the third-person gun shows the default while first-person shows lava.
3. `SkinCatalog` needs display names, or the Collection row falls back to the raw model name.
4. `PreflightGates` carries three suppressed WARNs for `CinderSix-Shooter` rig clips (`Shoot`,
   `Fanning`, `Reload` resolve to different asset ids than the manifest). Those were acceptable
   while the skin shipped to nobody. **Re-read them before shipping it as a paid reward.**

---

## 3. The 30-row PAID track

Kinds and required fields are documented in `BattlePassConfig` above `Config.PAID` — read that
block first. `TODO` rows are §2a placeholders: leave the row commented out or `nil` rather than
guessing an id, because a `kind = "title"/"emote"/"hunterSkin"` row whose id is not in the real
catalog records a claim nothing can ever read.

| L | Kind | Id / detail | Label |
|---|---|---|---|
| 1 | cash | 100 | `100 Cash` |
| 2 | title | `cinderkin` | `Title: Cinderkin` |
| 3 | emote | **TODO-1** | |
| 4 | **chest** | ×1 | `Chest` |
| 5 | tokens | 50 | `50 Tokens` |
| 6 | cash | 150 | `150 Cash` |
| 7 | title | `hot_streak` | `Title: Hot Streak` |
| 8 | boost | `cash_25_15` | `Cash Boost — 15 min` |
| 9 | **chest** | ×1 | `Chest` |
| 10 | hunterSkin | **TODO-A** | *(also on FREE)* |
| 11 | cash | 200 | `200 Cash` |
| 12 | title | `heat_haze` | `Title: Heat Haze` |
| 13 | emote | **TODO-2** | |
| 14 | boost | `xp_25_30` | `XP Boost — 30 min` |
| 15 | gunSkin | `CinderSix-Shooter` / Dust | `Gun Skin: Cinder Six-Shooter` |
| 16 | **chest** | ×2 | `2 Chests` |
| 17 | title | `forgeborn` | `Title: Forgeborn` |
| 18 | emote | **TODO-3** | *(also on FREE)* |
| 19 | boost | `cash_25_60` | `Cash Boost — 60 min` |
| 20 | hunterSkin | **TODO-B** | |
| 21 | cash | 300 | `300 Cash` |
| 22 | title | `sunscorch` | `Title: Sunscorch` |
| 23 | **chest** | ×2 | `2 Chests` |
| 24 | emote | **TODO-4** | |
| 25 | boost | `xp_25_60` | `XP Boost — 60 min` |
| 26 | **chest** | ×3 | `3 Chests` |
| 27 | title | `emberline` | `Title: Emberline` |
| 28 | emote | **TODO-5** | |
| 29 | gunSkin | `MoltenGrudgekeeper` / Bram | `Gun Skin: Molten Grudgekeeper` |
| 30 | hunterSkin | **TODO-C** | |

Mix: 6 titles · 5 emotes · 3 hunter skins · 2 gun skins · **5 chest rows (9 chests)** · 4 cash ·
1 tokens · 4 boosts = 30.

Season 1 had **eight** plain-Cash rows. This has four, and the four that survive pay more
(100/150/200/300 against 75/100/125/150). The five that were dullest became chests.

## 4. The FREE track

Levels are arbitrary, not every 5th — `BattlePassClient` clones a card into any level listed.
Levels 7, 10 and 18 deliberately repeat the PAID row; claiming either card at a shared level
claims both (`BattlePassService.tryGrantBoth`), which is what lets the two tracks split a reward.

| L | Kind | Id / detail | Label |
|---|---|---|---|
| 1 | cash | 100 | `100 Cash` |
| 5 | tokens | 50 | `50 Tokens` |
| 7 | title | `hot_streak` | shared with PAID |
| 10 | hunterSkin | **TODO-A** | shared with PAID |
| 13 | **chest** | ×1 | `Chest` |
| 15 | boost | `cash_25_30` | `Cash Boost — 30 min` |
| 18 | emote | **TODO-3** | shared with PAID |
| 20 | tokens | 100 | `100 Tokens` |
| 23 | cash | 250 | `250 Cash` |
| 25 | **chest** | ×1 | `Chest` |
| 27 | title | `ashborne` | the free half of the L27 pair |
| 29 | cash | 400 | `400 Cash` |
| 30 | tokens | 100 | `100 Tokens` |

---

## 5. Code changes the chest rows require

**The pass cannot pay a chest today.** `BattlePassService`'s claim handles `title`, `emote`,
`hunterSkin`, `gunSkin`, `boost`, `cash`, `tokens`, and its final branch warns on anything else:
*"a kind no system claims, so nothing would ever read what it wrote."* A `kind = "chest"` row added
without the service change is granted to nobody and warns on every claim.

1. **`BattlePassService`** — add a `chest` branch calling
   `LootboxService.grantChests(player, data, reward.count or 1)`. Requires a `LootboxService`
   require at the top.
   - `grantChests` returns 0 for a player `ArePaidRandomItemsRestricted` covers. **Do not treat
     that as a failed claim** — `BundleService` sets the precedent and deliberately still delivers
     the rest of the bundle. A failed claim here would make the level unclaimable forever.
2. **`BattlePassConfig.ICONS.chest`** — needs an asset id. `Config.ICONS` currently holds only
   `cash`/`tokens`/`emote`. `BattlePassClient` falls through to `Config.ICONS[kind]` for any
   non-boost, non-viewport kind, so adding the icon is the only client change needed. Source the
   id from the LOOT tab or `LootboxConfig`.
3. **`BattlePassConfig` header doc** — `count` is currently documented as *"kind == boost only,
   boosts are the only stacking reward."* Chests stack too now. Update that sentence.
4. Naming: `DailyRewardConfig` calls this kind `crate`, `BundleConfig` calls it `Chest`, and both
   land in `LootboxService.grantChests`. This spec uses `chest`. Pick one and note the other two
   in the comment, or the next person will grep for the wrong string.

---

## 6. The flip — order matters

Do **not** do these piecemeal across publishes. Steps 1–4 go out together.

1. `BattlePassConfig`: `SEASON_ID` S6 → **S7**; `SEASON_NAME` → `"Season 2: <name>"` *(name is
   still an open decision — see §7)*; `SEASON_START` → the chosen epoch; `TEST_ALL_WEEKS_UNTIL` →
   the same epoch (it self-expires and is honoured only in Studio/DEV, so it is safe through a
   publish); `QUEST_PROGRESS_TOKEN` → a new string.
2. `TitlesConfig`: drop `hiddenUntilOwned` from all seven new titles, **and** re-badge the seven
   season-1 titles (DRIFTER, GUNHAND, MARKSMAN, DUSTDEVIL, STAR SIGHT, GUNMETAL, DEVIL'S LUCK) off
   `pass(n)` onto a season-1 detail. They stay in the catalog forever because players own them;
   what they must stop claiming is a level that now pays something else. Two titles both badged
   "BOUNTY PASS L2" is the bug this prevents.
3. Replace `Config.WEEKS` with the §8 quest sets, and both reward tracks with §3/§4.
4. Mirror all of it — `BattlePassConfig`, `TitlesConfig`, `EmoteConfig` are **three** of the 21
   mirrored modules. Verify with a byte-length + checksum compare, not a read-back. `/preflight`
   gates this.
5. Vault `.md` + graph rebuild, changelog entry. Mark the release **data-affecting**: a
   `SEASON_ID` bump cannot be undone by reverting a place.

---

## 7. Open decisions

- **Season name.** `SEASON_NAME` is currently `"Season 1: Dead Man's Hand"` (a poker reference —
  aces and eights). Season 2 is fire-themed. Unresolved; needs the owner.
- **Which two lava guns.** Dust + Bram is this spec's pick; see §2b for the reasoning and how to
  swap.
- **Ship date.** Was going to be Sat 2026-09-19 20:00 CEST (3 weeks after the 08-29 set). Now
  gated on art. Nothing breaks while it slips: `currentWeek()` clamps at `TOTAL_WEEKS`, so S6 sits
  on week 3 with all 21 quests claimable and the panel correctly reads "BOUNTY PASS WEEK 3 OF 3"
  with no countdown. There is no deadline pressure and no wrong state on screen.

---

## 8. The 21 quests — 3 sets of 7

Ready to paste; no art dependency. Ids use the `s3w*` prefix (first set was `w1_`/`w2_`/`w3_`,
second was `s2w*`).

Every week totals **21,500 XP**: 4×2000 + 2×3500 + 1×6500. Verified against the three rules in
`BattlePassConfig`: no type twice in one week (a scoped type counts as its own), each week is its
own week, and a label says what to do and nothing else. Longest label below is 34 chars, the
measured one-line ceiling for the 86×13px box on a phone.

Type vocabulary confirmed live from the `QuestEvents.track` call sites in Redwater. Four types the
current set does not use are drawn on here for freshness: `bountyTime`, `bountyClaim`, `podium`,
`win`. `bountyTime` counts **seconds** (the daily uses 120).

`killAs:Fortuna` is deliberately absent — she is the only hunter that costs money, so such a quest
would be XP a non-owner can never earn, and with no complete-all bonus on this set it would be a
quiet paywall rather than a loud one.

### Week 1 — RIDE OUT. Broad, every quest pays in any mode.

```lua
{ id = "s3w1_saddleup",   type = "roundComplete", goal = 10,    xp = 2000, label = "Finish 10 matches" },
{ id = "s3w1_backup",     type = "assist",        goal = 50,    xp = 2000, label = "Get 50 assists" },
{ id = "s3w1_deadeye",    type = "headshot",      goal = 200,   xp = 2000, label = "Land 200 headshots" },
{ id = "s3w1_wanted",     type = "becomeBounty",  goal = 20,    xp = 2000, label = "Become the bounty 20 times" },
{ id = "s3w1_quickdraw",  type = "kill",          goal = 125,   xp = 3500, label = "Get 125 kills" },
{ id = "s3w1_hotlead",    type = "damage",        goal = 40000, xp = 3500, label = "Deal 40k damage" },
{ id = "s3w1_topdog",     type = "win",           goal = 8,     xp = 6500, label = "Finish 1st in 8 matches" },
```

### Week 2 — WANTED. The bounty's home week.

```lua
{ id = "s3w2_collector",  type = "bountyClaim",  goal = 25,   xp = 2000, label = "Claim 25 bounties" },
{ id = "s3w2_marked",     type = "bountyTime",   goal = 1200, xp = 2000, label = "Survive 20 min as the bounty" },
{ id = "s3w2_onaroll",    type = "killStreak5",  goal = 10,   xp = 2000, label = "Get 10 five-kill streaks" },
{ id = "s3w2_acesleeve",  type = "ultimateUse",  goal = 35,   xp = 2000, label = "Use your ultimate 35 times" },
{ id = "s3w2_frontline",  type = "kill:tdm",     goal = 150,  xp = 3500, label = "Get 150 kills in Team Deathmatch" },
{ id = "s3w2_standtall",  type = "podium",       goal = 15,   xp = 3500, label = "Finish top 3 in 15 matches" },
{ id = "s3w2_sidebyside", type = "teamWin",      goal = 12,   xp = 6500, label = "Win 12 team matches" },
```

`bountyTime` at 1200s sits next to week 1's "become the bounty 20 times" on purpose — 20 bounties
at roughly a minute each is the same order of effort, which is what keeps it a 2000-tier quest.

### Week 3 — THE WHOLE ROSTER. Domination's home week, plus hunter mastery.

The three `killAs` cards and `hunterVariety` look like they fight each other — one asks you to stay
on a hunter, the other to swap off — but they compose: a death-gated mid-match swap keeps each
hunter's kills on its own quest *and* feeds the variety count, so playing three hunters in a match
is the single best line for all four cards at once.

```lua
{ id = "s3w3_dugin",      type = "roundComplete:domination", goal = 12, xp = 2000, label = "Finish 12 Domination games" },
{ id = "s3w3_gunslinger", type = "killAs:Dust",              goal = 50, xp = 2000, label = "Get 50 kills as Dust" },
{ id = "s3w3_longshot",   type = "killAs:Vesper",            goal = 50, xp = 2000, label = "Get 50 kills as Vesper" },
{ id = "s3w3_bruiser",    type = "killAs:Bram",              goal = 50, xp = 2000, label = "Get 50 kills as Bram" },
{ id = "s3w3_finisher",   type = "ultimateKill",             goal = 30, xp = 3500, label = "Kill 30 enemies with your ultimate" },
{ id = "s3w3_stakeclaim", type = "capture",                  goal = 20, xp = 3500, label = "Capture 20 points" },
{ id = "s3w3_manyfaces",  type = "hunterVariety",            goal = 12, xp = 6500, label = "Use 3 hunters in 12 matches" },
```

---

## 9. Unrelated but outstanding

**`TitlesConfig.TITLE_SEASONS` is `{ 4 }` and needs `5` added before the ranked season closes on
Sat 2026-09-26 20:00 CEST.** This is independent of the pass and has its own deadline.

The ranked payout grants `s5_*` title ids that `TitlesConfig` has never minted, and
`CollectionService.grantTitle` rejects an id missing from `EntryById` with a bare `return false`
that `RankSeasonRewardService`'s grant loop ignores. Season 2's top 3 would get their Tokens and a
gift card with no title line — silently, with no warning in the log.

Also note `RANK_SEASONS` currently ends at season 5, so the live ranked season has **no end date**
(`getRankSeasonEnd` returns nil, the flyout prints "SEASON 2" with no countdown, and the payout
never fires). Appending the 2026-09-26 epoch `1790445600` is what closes it.

And `GameEnvironment.DEV_RANK_SEASONS` still carries its `DELETE AFTER 2026-09-05` test fixture.
