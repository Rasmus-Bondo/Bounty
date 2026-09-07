# Spec — Combat feedback: kill announcement + damage numbers

**Status:** BUILT 2026-09-06, **substantially revised 2026-09-07 after the owner played it** — see the
reversal at the top of §0, which is the single most important thing on this page. The announcement is
now the whole personal-reward surface and `CombatFeedClient` is switched off. Unreleased; still owes a
playtest.

Decisions taken during the original build that still hold: the **bounty stinger is the prototype's
`SFX.Reward.Bounty`** (§5's second option — `BountyMusicClient.playBountyClaimed` is held behind
`BOUNTY_STINGER_ENABLED = false` and the new asset is faded at 2.6s), and the **killstreak breaks on
death** (§7 trap 4). The announcement briefly sat at screen y 0.306–0.384 rather than §2.4's
`y = 0.8357`; the 2026-09-07 pass put it back to the prototype's placement. See
`changelog/UNRELEASED.md` for what shipped and what still owes a playtest.

**Where the prototypes are:** the 4th connected place, **"Bounty - UI Update"**
(placeId `112014319307228`, see [[project_ui_design_place]]). They are demos, not features:
one is a `while true` loop on a Workspace dummy, the other is driven by a Studio-only button
panel. Nothing in them is wired to a game event.

**What this delivers:** the big centre-screen `ELIMINATED <NAME>` / `DOUBLE KILL` moment with
its stinger, the `BOUNTY CLAIMED` slam, and floating damage numbers over the target.

---

## 0. Decisions taken, and the options rejected

Do not re-litigate these. They were settled with the owner on 2026-09-06 — **except the first row,
which the owner reversed on 2026-09-07. Read the reversal below before the table.**

### REVERSED 2026-09-07 — the announcement replaces the feed outright

The owner played the shipped build and asked for the prototype's full behaviour: the assist banner,
the reward lines, and the combat text "replaced" rather than duplicated. Asked directly where the
split should fall, the answer was *"We are removing the right side combat feed and replacing it with
this new system."*

So the row below reads backwards now. What is true instead:

- **`CombatFeedClient` is `Disabled`** (not deleted — it is 1000 lines of per-viewport layout tuning
  and flipping the flag back is the whole of the rollback).
- **Every row it carried moved to the announcement**: eliminations, assists, the Domination objective
  rows, bounty claim and spree bonus, the tutorial instalment, and the two other-player rows
  (`X IS ON A SPREE`, `X TOOK DOWN Y`) as ambient notices that wait for the player's own card to clear.
- **The reward numbers came back** — `SubAnnouncement`, `RewardAnnouncementCash` and
  `RewardAnnouncementXP` were cloned across from the prototype, and §2.2's cuts of `showRewards` /
  `addRewards` / `flyDelta` / `rewardText` / `showAssist` are undone.
- **§2.3's "no assist-side event carries the victim's name" is fixed rather than worked around**:
  `fireCombatReward` gained a trailing `subject` argument and `awardKill` / `awardAssist` an optional
  `victimName`. Both call sites already held the victim. That also let the announcement stop
  listening to `HitConfirm` — `awardKill` is the crediting authority and fires on kills the hit
  pipeline never sees, so one event now carries the line *and* its numbers with no race.
- **The placement went back to the prototype's** `y = 0.8357` (screen 0.643), with the Domination
  capture-bar and `SwapHunterFrame` overlaps accepted explicitly. A four-line stack no longer fits
  above the crosshair, which is what the lifted position was for.
- **§9's "any change to `CombatFeedClient`'s rows" is no longer out of scope.**

The rest of the table stands.

| Decision | Rejected alternative, and why |
|---|---|
| ~~**The announcement is the moment; `CombatFeedClient` stays the ledger.**~~ **REVERSED — see above.** EyeCandy showed only the title line and the header; the right-hand feed kept every `+250 XP / +$120` row. | *EyeCandy replaces the kill rows* — was rejected as surgery on 1021 lines of per-viewport tuning, and as announcing every kill twice in two type sizes. **This is what shipped in the end**, and neither cost was paid: the feed was switched off whole rather than edited, so nothing is announced twice and none of its tuning had to be touched. |
| **Damage numbers ship in both styles** — white body numbers drifting up, yellow `N!` headshot numbers splitting apart. | *Body only.* The split reads as deliberate here: `HitMarkScript` already splits its kill skull into `SkullMarkUpper`/`SkullMarkLower`, so the language is established. |
| **`KillCounterGui` stays parked.** | Building it out. It is `Enabled = false`, has no source for its count, and no agreed HUD slot. |
| **`AnnouncerGui` is ignored.** | Redwater's `DominationGui` already does objective announcements. |
| **The new in-match HUD is NOT ported** (`ModernPlayerPanel` + `PersistentXPBar` + `PlayerLevel`). | This is what forces §2.2 below — the XP/level-up/chest half of the prototype cannot run and must be cut, not stubbed. |

---

## 1. The prototypes, precisely

| Path in "Bounty - UI Update" | Lines | State |
|---|---|---|
| `StarterGui.EyeCandy` (ScreenGui, `DisplayOrder` 50, `DeviceSafeInsets`) | — | Enabled |
| `StarterGui.EyeCandy.AnnouncementController` (LocalScript) | 647 | Driven only by `AnnouncementEvent` (BindableEvent) from a Studio-visible test panel |
| `Workspace.DamageNumberDummy.DamageNumberTestController` (Script) | 167 | `while dummy.Parent do playBurst() end` on a rig |
| `StarterGui.KillCounterGui` | 138 | `Enabled = false`. **Out of scope.** |
| `StarterGui.AnnouncerGui` | — | Static text. **Out of scope.** |

All five EyeCandy labels use **Teko SemiBold** (`rbxassetid://12187376174`) with `TextScaled = true`
— the same face `CombatFeedClient` uses, so no new font decision.

---

## 2. Part A — the announcement

### 2.1 What survives the trim

From `AnnouncementController`, keep:

- `showPrimary` — but only its `main` label path. Text is `richLine(action, playerName, streak)`:
  white `ELIMINATED`, then the victim name in `#F6E525`, then the streak word in white.
- `killWord(count)` — `2..10` map `DOUBLE / TRIPLE / QUADRA / PENTA / HEXA / HEPTA / OCTA / NONA /
  DECA KILL`, falling through to `<N>X MULTI KILL`.
- The multi-kill counter: `MULTI_WINDOW = 8` seconds, counted **client-side** off consecutive
  eliminations. It resets on any non-elimination event.
- `punchIn` (slide in from +85px, overshoot, settle) and `shakeAnnouncement`
  (strength `min(2 + (streak-2)*0.7, 5)` over 7 frames, only when `streak >= 2`).
- `showBounty` + `animateHeader` + `createImpactFlare` — the two header clones flying in from
  `x = -0.1` and `x = 1.1` to collide at centre, then the light-bar flare. This is the best
  animation in the prototype; port it intact.
- `fadeAll` and the `displayToken` generation counter that makes a newer event cancel an older
  one's pending fade. **Keep the token pattern** — without it, two kills 3 seconds apart leave the
  first one's `task.delay` free to hide the second.
- The Studio-only test panel (`controller.Visible = RunService:IsStudio()`), trimmed to
  Eliminate / Bounty / Reset. It is how you iterate on this without a playtest.

### 2.2 What is cut, and why

| Cut | Reason |
|---|---|
| `RewardAnnouncementCash` / `RewardAnnouncementXP` labels, `showRewards`, `addRewards`, `flyDelta`, `rewardText` | §0 decision — the feed owns the numbers. This is roughly 90 lines. |
| `SubAnnouncement` + `showAssist` | The assist line needs a victim name that no assist-side event carries (§2.3). Assists stay a feed row. See §5 for the assist *sound*, which does survive. |
| `showXPProgress` (~100 lines), `showChestReward`, `LevelRewardDisplay`, `ChestViewport` | Hard-requires `PlayerGui["In-gameGui"].Canvas.PlayerFrame.PersistentXPBar` and `.PlayerLevel` at **lines 19-21, before anything else runs**. Redwater's match HUD is `StarterGui.ReworkedHunterGui.ScreenGui` (see [[project_hunter_hud_gui_source]]) and its `PlayerFrame` has only `HealthBarFrame`, `PlayerHunterFrame`, `HealthBarFrameBackground`, `PlayerName`. Those two `WaitForChild` calls would **hang the whole script forever** — the announcement would never appear, and the infinite-yield warning six seconds later points at a line that has nothing to do with kills. Delete the lookups, do not guard them. |

### 2.3 The trigger — and why the obvious one is wrong

The announcement needs **the victim's name**, on the **killer's** client only.

- WRONG: `ProgressionEvents.CombatReward` fires `(kind, xp, cash, tokens)` per kill — right client,
  **no name**.
- WRONG: `Hunters.Shared.Remotes.KillFeed` is `FireAllClients(killerName, victimName, weaponName,
  wasHeadshot, killerTeam, victimTeam)` — has the name, but identifies the killer by
  **DisplayName only**. Display names are not unique and bot rigs use model names, so
  "was that me?" cannot be answered reliably. Do not filter on it.
- RIGHT: **`HitConfirm`.** It already fires to the attacker *and only the attacker*, and the emitter
  already holds the victim character. Extend it — see §4. One signature change serves this **and**
  the damage numbers.

`BOUNTY CLAIMED` is separate and already solved: `BountyEvents.BountyClaimed` reaches the client as
`(killerName, victimName, killerUserId, xp, cash, victimUserId)`. Gate on
`killerUserId == player.UserId`, exactly as `BountyMusicClient:328` already does.

### 2.4 Placement

- Rebuild `EyeCandy` as an authored ScreenGui in `StarterGui` of both combat places, per
  UI_STYLE_GUIDE §1.1 — **clone the prototype's labels across rather than re-typing their
  properties.** Keep `HeaderAnnouncement` and `MainAnnouncement`; delete the other three.
- `DisplayOrder = 8700`. The in-match registry is `CombatFeedGui` 8500,
  `QuestCompleteNotification` 8600, `KillFeedClient` 9000, `KillCamClient` 9500. 8700 puts the
  announcement above the feed it is narrating and below the kill cam, which should cover it.
  **Add the row to the UI_STYLE_GUIDE `DisplayOrder` registry.**
- `MainAnnouncement` sits at `y = 0.8357`. With the reward lines cut, consider raising it —
  Redwater's mobile jump button occupies `y 0.689–0.889` anchored right, and a 0.6-wide centred
  label overlaps its left edge. **Run `capture_device_matrix` on the FIRST draft** (UI_STYLE_GUIDE
  §9), not after it looks right on desktop.

---

## 3. Part B — damage numbers

Port `DamageNumberTestController` to a new `StarterPlayerScripts.DamageNumberClient` in both
combat places. The animation work is done and is good; what changes is where the numbers come from
and what they attach to.

- **Body hit:** white `GothamBlack` 43px + a `(2,3)`-offset shadow at `TextTransparency 0.22`,
  scale `0.35 -> 1.08 -> 1`, drifts up 58px over 0.78s with a random ±3° tilt, fades from 0.48s,
  destroyed at 0.82s.
- **Headshot:** yellow `255,214,52` at 56px, `<N>!`, scale `0.12 -> 1.34 -> 1`. At 0.17s the single
  label is hidden and replaced by two halves — the leading digits, and the last digit + `!` — which
  fly to `(-68,-48)` rotated -15° and `(+76,-37)` rotated +13°.
- Both stack on a `zCounter` so a later number draws over an earlier one.

Changes required for the real game:

1. **Adornee.** The prototype hard-codes `dummy.Head` and parents one persistent `BillboardGui` to
   it. In-game the client must create the billboard on the **victim's** character per hit. Under
   StreamingEnabled the victim's `Head` can be streamed out — `FindFirstChild("Head")` may return
   nil on a model that exists. See [[project_streaming_constraints]]: guard it and skip the number
   rather than yielding.
2. **Cleanup.** The victim dies and respawns; a billboard parented to a dead character must not
   outlive it. Destroy on `AncestryChanged`, and reuse one billboard per victim rather than
   creating one per hit — a 5-shot burst currently means 5 `Instance.new("BillboardGui")`.
3. `MaxDistance = 180` and `StudsOffsetWorldSpace = (0, 2.25, 0)` are tuned on a dummy at close
   range. Re-check across a canyon sightline; Vesper hits from far enough that 180 studs may cut
   them off. **Note:** `BillboardGui` offsets are screen pixels and do not shrink with distance
   ([[reference_billboardgui_offset_pixels]]), so a burst that reads fine at 20 studs will overlap
   itself at 150.

---

## 4. The one `HitConfirm` change (serves both features)

Current signature, in **two** emitters:

```lua
HitConfirm:FireClient(attackerPlayer, isHeadshot, didKill)
```

New:

```lua
HitConfirm:FireClient(attackerPlayer, isHeadshot, didKill, damage, victimName, victimCharacter)
```

**Emitter 1 — `ReplicatedStorage.Hunters.Shared.HunterHitPipeline`** (mirrored; 239 lines).
`_sendHitConfirm` is at :96, called from `Register` at :230. Everything needed is already in
scope: `actualDamage` is computed at **:208** as
`math.min(opts.OldHealth or humanoid.Health, opts.Damage)` — already clamped to remaining health,
which is exactly the number you want on screen. `targetCharacter` is the parameter. Resolve the
victim name the same way `_sendKillFeed` does at :117-119
(`Players:GetPlayerFromCharacter` -> `DisplayName`, falling back to the model name for bots).

**Emitter 2 — `ReplicatedStorage.Hunters.Dust.Modules.HighNoonDamage:282`.** Dust's ultimate runs
its own parallel damage chain and fires its own `HitConfirm`. **It will be missed if you only read
`HunterHitPipeline`** — see [[feedback_fix_every_implementation]]. High Noon without damage numbers
while every other shot has them reads as a bug in the ultimate.

**Backward compatibility:** `HitMarkScript:1004` binds `function(isHeadshot, didKill)` and ignores
trailing arguments, so it keeps working untouched. That is deliberate — do not fold the damage
numbers into `HitMarkScript`. It is 1029 lines of crosshair state machine; the numbers are a
separate concern with a separate lifetime.

**Not every death flows through here.** Zone damage, fall damage and bot-dealt blows credit the
kill via the victim's `LastDamager` attribute on the universal `Humanoid.Died` handlers, and never
touch this pipeline. Those produce no announcement and no damage number, which is correct — the
player did not shoot anyone.

---

## 5. Part C — sounds

**Kill and killstreak are one asset.** There is no separate streak sound: the prototype pitches the
kill stinger up per streak step.

```lua
playSfx(killSound, 1 + math.min(killCount - 1, 8) * 0.065)   -- clamped 0.5-1.75 inside playSfx
```

| Sound | Asset | Note |
|---|---|---|
| Kill / streak | `SFX.KillEffectSound` = `1837715911` (4.22s) | What the prototype's pitch curve was tuned against. Import it. |
| — alternate | `SFX.Fight.KillSound` = `124954333259876` (3.79s) | **Already sits in Redwater, wired to nothing** — grep for `KillSound` returns zero hits. Try it in playtest; swapping is one `SoundId`. |
| Assist | `SFX.Fight.Assist` = `107938430449015` | **Already in Redwater, also unused — and the same asset as the prototype's `SFX.Assist`.** Play it on the existing feed's assist row. Audio only; no assist banner (§2.2). |
| Bounty claim | `SFX.Reward.Bounty` = `1842188284` (**12.33s**) | See the collision below. |

**Every imported Sound must be assigned `SoundService.SFX` explicitly.** None of the prototype
sounds carry a `SoundGroup` — they were auditioned in a place that does not enforce it. An
ungrouped Sound escapes all four settings sliders (CLAUDE.md -> Technology Rules -> Audio).

**The bounty stinger is a collision, not an addition.** `BountyMusicClient:328` already plays
`SFX.BountySFX.BountyClaimed` / `BountyClaimed2` (alternating, ~7s, with a fade-out tail and a
`TutorialMode` suppression) on `BountyClaimed.OnClientEvent`, gated on
`killerUserId == player.UserId` — **the same event, for the same one player, that the new header
fires on.** Adding `Reward.Bounty` on top means two stingers overlapping, and the new asset is
12.33 seconds — long enough to still be playing over the next two kills. Pick one:

- **Default:** keep `BountyMusicClient`'s existing stinger, and let the new `BOUNTY CLAIMED` header
  be a purely visual addition to a cue that already sounds right.
- If the owner prefers the prototype's asset, import it **and** early-return `playBountyClaimed()`,
  and fade `Reward.Bounty` out at ~3s rather than letting it run.

Ask before choosing — it is an audio taste call, not a technical one.

---

## 6. Mirror obligations

The whole gamemode codebase is mirrored between **Redwater Canyon and Frostbite Claim** by
`/mirror`, not by Packages. `HunterHitPipeline`, `HighNoonDamage`, `DamageNumberClient` and the
EyeCandy GUI + controller all need to land in both.

- Redwater and Frostbite only. **Nothing here goes to the Bounty lobby.**
- Run `/mirror` after the edits and before `/preflight`.
- Byte-length + checksum compare is a hard gate. Mirror drift here fails **silently**: Frostbite
  would simply have no damage numbers, with no error anywhere.

---

## 7. Traps

1. **The `In-gameGui` `WaitForChild` at controller lines 19-21 will hang forever in Redwater.**
   Cut it, do not guard it. §2.2.
2. **`HighNoonDamage` has its own `HitConfirm`.** §4.
3. **The prototype's `playSfx` parents clones to `SoundService` and self-destructs on `Ended`, with
   a `task.delay(max(TimeLength + 1, 8))` backstop.** Keep the backstop — `Ended` does not fire for
   a sound whose asset failed to load, and the clones would accumulate for the whole round.
4. **`killCount` is client-side and survives death.** The prototype never resets it on respawn, so
   a kill, a death, and a kill 6 seconds later reads `DOUBLE KILL`. Decide whether that is wanted;
   most shooters break the streak on death.
5. **`RESET` on the round boundary.** The controller has a `RESET` branch that zeroes `killCount`
   and hides every label. Wire it to the round-start / intermission signal, or the first kill of
   round 2 inherits round 1's streak. Related: [[project_round_sweep_settings_trap]].
6. **A `TextScaled` label's `TextBounds` cannot be trusted from a script**
   ([[feedback_device_only_text_metrics]]). The announcement is a single centred label, so nothing
   needs measuring — keep it that way rather than adding a sibling that has to line up.
7. **Do not blanket-toggle `StarterGui` children when screenshot-verifying**
   ([[feedback_startergui_screenshot_restore]]) — several Redwater GUIs are authored `Enabled = false`.

---

## 8. Verification order

1. Syntax-check every edited script via `loadstring(script.Source)` before claiming anything works
   ([[feedback_verify_code]]). `execute_luau`'s `require()` cache is stale
   ([[feedback_plugin_require_cache]]).
2. Studio test panel first: Eliminate x5 in under 8s -> the streak words climb and the pitch rises.
   Bounty -> the header slam. Reset -> everything clears.
3. `capture_device_matrix` on that first draft, before any polish. Phone, 4:3 tablet, windowed PC.
   Check the announcement against the mobile jump button (§2.4).
4. Damage numbers against a live target — solo playtest, revolver body shots then a headshot, then
   Dust's High Noon specifically (§4). **No MCP playtesting** ([[feedback_no_mcp_playtest]]) — hand
   the owner a manual checklist and iterate against what they report
   ([[feedback_iterate_against_live_playtest]]).
5. `/mirror` -> Redwater vs Frostbite clean.
6. Vault `.md` for each new/changed script in `LocalRedwaterCanyon/`, then
   `python update_redwater_canyon_graph.py`, then grep `graph.json` to confirm the new edges are
   real. Frostbite has no vault by design.
7. `/changelog`, then `/preflight`.

---

## 9. Out of scope

`KillCounterGui`, `AnnouncerGui`, the `ModernPlayerPanel` / `PersistentXPBar` / `PlayerLevel` HUD
port, any change to `CombatFeedClient`'s rows, and the lobby.
