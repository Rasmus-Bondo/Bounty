---
name: project_emotes
description: "Emote system (both places) — EMOTES collection tab + equipped emote plays at Redwater match end; catalog (now 18: 2 free / 5 pass-exclusive / 11 shop), persistence, build status"
metadata: 
  node_type: memory
  type: project
  originSessionId: d9244efc-35c9-4bf3-9ebf-05ded7c0799a
  modified: 2026-07-26T20:16:04.464Z
---

**Victory-emote system, built 2026-07-14 (both places).** Player equips ONE account-wide emote in the Bounty Collection menu's EMOTES tab; it plays on their end-of-match showcase dummy in Redwater (replacing the old random pick). Completes the "EMOTES tab unbuilt" follow-up in [[project_collection_panel]].

**Catalog:** new `ReplicatedStorage.EmoteConfig` (mirrored verbatim both places, like [[project_boost_potions]] BoostConfig). Entries are `{displayName, animationId, defaultOwned}` + `ORDER`; helpers get/isValid/isDefaultOwned/list/defaultOwnedList. Animation asset ids originally came from Redwater's `ReplicatedStorage.EndScreenEmote` folder (superseded as source of truth).

> **CATALOG SIZE IS STALE — verified fresh-loaded from source in both places 2026-07-26: 18 emotes, not the original 5** (both copies byte-identical, srclen 7654). Current split: **2 defaultOwned** (`electro_swing` — still `DEFAULT_ID` — and `wild_celebration`), **5 pass-exclusive** (`cowboy_dance`, `hit_the_beat`, `lasso_dance`, `showdown`, `take_the_l`; no `price`, `unlockText = "BOUNTY PASS"`, so `purchaseEmote` refuses them), and **11 shop emotes at 2000 Cash** (applaud, boxer, cool_sit_pose, daydreamer, eager_clapping, low_cortisol, rat_dance, scary_kitten, shuffle, small_wave, tip_toe). Note `take_the_l` used to be defaultOwned and was traded for `wild_celebration` when it became the L28 pass reward. **The old note that battle-pass emote ids are "SEPARATE and inert" is WRONG now** — [[project_battle_pass]] part 3 rewired `grantReward` to call `CollectionService.grantEmote`, so pass emotes are real, granted inventory. Redwater's copy had silently DRIFTED to 5 of 18 ids at one point, which made 13 emotes fall back to `electro_swing` at match end — re-verify both copies are byte-identical after any edit.

**Ownership model (user chose 2026-07-14):** persisted `OwnedEmotes` set, a couple free-by-default. Usable = `EmoteConfig.isDefaultOwned(id)` OR `profile.OwnedEmotes[id]`. Equip scope = GLOBAL (`profile.EquippedEmote` string), NOT per-hunter.

**DEFAULT EMOTE (user chose 2026-07-22, "Full default + migrate"):** electro_swing is the floor — NO random fallback anymore. Added `EmoteConfig.DEFAULT_ID = "electro_swing"` (both mirrored copies). (1) DataService templates (both places) now default `EquippedEmote = "electro_swing"` so new players start equipped. (2) Bounty `CollectionService.onPlayerAdded` migrates any legacy/empty `EquippedEmote == ""` (old random-system players) → DEFAULT_ID on join (one-time, persisted; runs BEFORE refreshAll, NOT inside ensureEmotes so mid-session unequip still shows "" until next join). (3) Redwater `RoundController` renamed `randomEmoteAnimationData`→`defaultEmoteAnimationData` (returns DEFAULT_ID, with a list()[1] safety net); `getPlayerEmoteAnimationData` falls back to it, never random. Net effect: unequip has no true "none" — reverts to electro next load. DEFAULT_ID MUST stay a defaultOwned id.

**Persistence:** added `EquippedEmote=""` + `OwnedEmotes={}` to BOTH DataService templates (shared `PlayerData_v2`, Reconcile-additive). Redwater READS EquippedEmote (unlike titles).

**Server (Bounty `CollectionService`, extended):** `equipEmote` (validate valid+owned, ""=unequip), `grantEmote(player,id)` (future earning hook — shop/BP/code), `sendEmoteState` → `EmoteStateEvent({owned,equipped})`, remotes `EquipEmoteEvent`/`RequestEmoteState`/`EmoteStateEvent` created in Start(); mirrors `EquippedEmote` player attribute. Started in Main after BoostService.

**UI (Bounty `CollectionGuiController`, +~500 lines):** new `leftMode="Emotes"` (3rd mode beside Hunters/Boosts). `2Emotes` left tab → `setLeftMode("Emotes")`. LEFT = `EmotesFrame` (clone of HuntersFrame like BoostsFrame) — temp tiles per emote (purple icon + 2-letter glyph + name), greyed if locked. RIGHT = the pre-built `EmoteFrame` (CanvasRight, had `1Emote` tile template + SelectedGradiant) filled with one FULL-BODY animated viewport per unlocked skin of the EQUIPPED hunter, each looping the selected emote (`renderEmoteViewport`+`playEmoteAnim`, fov 26, dist=size.Y*0.62/tan clamp 8-22). Middle in-world dummy plays emote via `showHunterPreview` extended with optional `emoteAnimationId`. EquipButton EQUIP/EQUIPPED/LOCKED → `EquipEmoteEvent`. Viewports torn down on mode-leave. `buildEmoteUI` runs at startup before buildHunterGrid (pristine frames).

**Redwater match-end:** `RoundController` now requires DataService+EmoteConfig; `getPlayerEmoteAnimationData(player)` resolves equipped emote (valid+owned) else the DEFAULT emote electro_swing (see DEFAULT EMOTE below), never random; attached as `emote={name,animationId}` on each stats entry. `VictoryShowcaseClient.makeAnimationFromServerChoice(rank,emoteData)` prefers `entry.emote`, falls back to the still-sent random `victoryAnimationsByRank`. Each podium/local dummy plays ITS player's emote (keyed via entry, robust vs rank).

**Verified:** all 8 touched scripts loadstring-OK both places; equip/ownership gating sim'd (fresh owns 2 defaults, locked/invalid rejected, grant→equip works, ""unequip); viewport framing math finite on real Dust rig; GUI instance deps confirmed present. NOT runtime-playtested ([[feedback_no_mcp_playtest]]). Vault + both graphs synced.

**Follow-ups:** real earning path for the 3 locked emotes (grantEmote is the hook); rename "showdown" if desired; real emote-tile art (currently temp initials glyph like boosts); animated viewports cost scales with equipped hunter's unlocked-skin count (usually small). Related: [[project_collection_panel]], [[project_boost_potions]], [[feedback_never_partial_overwrite]], [[feedback_verify_code]].
