---
tags: [server, modulescript, cosmetics, titles, emotes]
path: game.ServerScriptService.PlayerServices.CollectionService
type: ModuleScript
lines: 489
---

# CollectionService

Bounty-lobby server for two persisted cosmetic systems: **cosmetic TITLES** and a single **account-wide EMOTE**. The player equips one title **per hunter** in `profile.EquippedTitles[hunter]`. Every title belongs to ONE hunter. Titles are **not** all free: each hunter's plain title is, four are bought with Cash/Tokens from the Trading Post ACCESSORIES tab ([[TitleBuyController]]), and the rest are battle-pass rewards. The Collection panel is a wardrobe and never sells one. Emotes from [[EmoteConfig]] are owned when `defaultOwned` or listed in `profile.OwnedEmotes`; the player equips one id in `profile.EquippedEmote` (defaults to `electro_swing`; a legacy/empty `""` is migrated to the default on join, so old random-system players and new players alike get the default). Validates equip requests and mirrors state onto replicated player attributes. Boosts are handled separately by `BoostService`.

**This module is the only ownership gate for titles in the whole game.** That is why Redwater needs no unlock logic: nothing unowned can reach `EquippedTitles` for it to read back.

## What it does
1. `titleOwned(data, titleId)` — the single ownership rule, three ways in: the [[TitlesConfig]] unlock is `free`, OR the id is in `profile.OwnedTitles` (purchased here), OR it is in `profile.Cosmetics.Titles` (granted by BattlePassService). Deliberately one function, so a battle-pass title and a bought one are indistinguishable downstream
2. `ensureTitles(data)` — idempotent guard: guarantees `EquippedTitles` + `OwnedTitles`, and drops any equipped id that is no longer valid for its hunter (via `TitlesConfig.IsValid`) **or that the player does not own**. The second case is the scarcity migration — titles used to be free for everyone, so profiles exist with a flashy title equipped that was never paid for. Those fall back to `""` (no title) rather than to the hunter's free title, so a player who chose "none" keeps none and nobody silently starts wearing something they didn't pick
3. `applyTitleAttributes(player, data)` — sets one `EquippedTitle_<Hunter>` attribute per hunter; the Collection TITLES tab reads these for EQUIP/EQUIPPED
4. `updateDisplayAttribute(player, data)` — sets the replicated `EquippedTitle` attribute to the display **label** of the currently-equipped hunter's title (`""` when none), plus a companion `EquippedTitleId` attribute carrying that title's raw id. LobbySpawn reads both: the label for the text, the id for the cosmetic style its TitleRenderer call applies
5. `sendTitleState(player, data)` — fires `TitleStateEvent` with `{ owned = {[id]=true} }`, built by walking `TitlesConfig.EntryById`. Sends the whole owned set in one go: the Collection wardrobe and the Trading Post grid both consume it, and the shop shows all four hunters at once
6. `equipTitle(player, hunterName, titleId)` — validates the id against the hunter's catalog **and** `titleOwned`, then writes `profile.EquippedTitles[hunter]`, updates the id attribute and refreshes the label. The ownership line is what actually stops a spoofed equip; the client only greys rows out
7. `purchaseTitle(player, titleId)` — server-authoritative buy. The client sends only the id; currency and price always come from `TitlesConfig.UnlockOf`, never the payload. Rejects non-`purchase` titles (a battle-pass title has no price and must not be treated as free), no-ops on already-owned, spends through [[Wallet]] (`title_cash` / `title_tokens`), records `profile.OwnedTitles[id]`, then re-syncs leaderstats, pushes fresh state and fires `ShopPurchaseSuccessEvent`. Shares the `purchaseBusy` re-entrancy guard with the emote purchase
8. `grantTitle(player, titleId)` — unlocks a title outright into `profile.OwnedTitles` (hook for codes / admin grants). Battle-pass rewards do **not** come through here — BattlePassService writes `Cosmetics.Titles` directly and `titleOwned` reads that bucket too
9. `ensureEmotes(data)` — idempotent guard: guarantees `OwnedEmotes`/`EquippedEmote`, drops an equipped emote that is no longer a valid catalog id
10. `emoteOwned(data, id)` — `EmoteConfig.isDefaultOwned(id)` OR `data.OwnedEmotes[id]`
11. `applyEmoteAttribute(player, data)` — mirrors `profile.EquippedEmote` onto the replicated `EquippedEmote` player attribute
12. `sendEmoteState(player, data)` — fires `EmoteStateEvent` with `{ owned = {[id]=true}, equipped }` for the EMOTES tab (owned set built from [[EmoteConfig]] `list()`)
13. `equipEmote(player, emoteId)` — validates the id is a valid, owned catalog emote (`""` = unequip), writes `profile.EquippedEmote`, updates the attribute, pushes fresh state
14. `grantEmote(player, emoteId)` — unlocks an emote into `profile.OwnedEmotes` and pushes state (future earning hook: shop, battle pass, code)
15. `purchaseEmote(player, emoteId)` — server-authoritative Cash buy for emotes, the pattern `purchaseTitle` mirrors
16. On player join, polls `DataService.getPlayerData` until the profile loads, **migrates a legacy/empty `EquippedEmote` to `EmoteConfig.DEFAULT_ID` (`electro_swing`)** — this is where old random-emote-system players (who sit at `""`) get the default so it shows equipped and plays instead of a random pick — publishes all attributes, pushes title ownership **and emote ownership** once (so both tabs are right on first open instead of flashing every row as locked), then connects `EquippedCharacter` changes so the shown title follows the equipped hunter. The `sendEmoteState` call was **missing** until 2026-08-01: `refreshAll` publishes attributes only and pushes no ownership state, so `RequestEmoteState` was emotes' *only* delivery path and a pull that lost the race to the profile load left every owned emote reading locked until the tab was closed and reopened
17. **Both pull handlers wait for the profile.** `RequestTitleState` and `RequestEmoteState` used to read `getPlayerData` once and silently return when it was nil, which answers nothing — and a pull arriving before the profile is the *normal* case on a teleport arrival from Redwater, where the profile is still session-locked by the server the player just left. They now go through `waitForPlayerData`, which polls up to `PROFILE_WAIT_TIMEOUT` (20s), matching what `RequestSkinData` in [[DataService]] does. A weak-keyed pending table allows **at most one waiter per player per remote** so a spammed pull cannot stack coroutines; dropping the extra request is safe here in a way a *time-based* cooldown is not, because the in-flight waiter sends as soon as the profile lands and whoever was turned away is connected by definition
18. Creates `EquipTitleEvent`, `PurchaseTitleEvent`, `RequestTitleState`, `TitleStateEvent`, `EquipEmoteEvent`, `PurchaseEmoteEvent`, `RequestEmoteState`, `EmoteStateEvent`, `ShopPurchaseSuccessEvent` in ReplicatedStorage on `Start()` if missing. **`Start()` is called 3rd in `Main`, immediately after DataService** — the Collection menu's client `Refs` blocks on the emote/title remotes created here before its skin-ownership listener can connect, so starting late left that listener deaf for most of server boot

## Dependencies
- **Requires:** [[DataService]], [[TitlesConfig]], [[EmoteConfig]], [[Wallet]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `EquipTitleEvent` | ← Client | [[TitlesTab]] equip/unequip a title for a hunter (`hunter, titleId`) |
| `PurchaseTitleEvent` | ← Client | [[TitleBuyController]] buys a title from the Trading Post ACCESSORIES tab (`titleId`); price/currency resolved server-side |
| `RequestTitleState` | ← Client | [[TitlesTab]] / [[Panels]] and [[TitleBuyController]] ask for a fresh owned-title set |
| `TitleStateEvent` | → Client | [[TitlesTab]] and [[TitleBuyController]] receive `{ owned }` on join, on request, and after every purchase |
| `EquipEmoteEvent` | ← Client | [[EmotesTab]] equip/unequip the account emote (`emoteId`, `""` = none) |
| `PurchaseEmoteEvent` | ← Client | [[EmoteBuyController]] buys an emote with Cash from the Trading Post |
| `RequestEmoteState` | ← Client | [[EmotesTab]] / [[Panels]] ask for a fresh owned/equipped emote state |
| `EmoteStateEvent` | → Client | [[EmotesTab]] receives `{ owned, equipped }` after request/equip/grant |
| `ShopPurchaseSuccessEvent` | → Client | [[TradingPostController]] plays the purchase confirmation after a successful title or emote buy |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()`, `updateLeaderstats()` | Read/write `EquippedTitles`, `OwnedTitles`, `EquippedEmote`, `OwnedEmotes`; resync the currency leaderstat after a purchase |
| [[TitlesConfig]] | `Titles`, `EntryById`, `LabelById`, `IsValid()`, `UnlockOf()` | Validate title equips, resolve the display label, and read the price/currency for a purchase |
| [[Wallet]] | `spend()` | Charge Cash/Tokens for a title (`title_cash` / `title_tokens`) or an emote (`emote_cash`) — the only currency mutator |
| [[EmoteConfig]] | `get()`, `isValid()`, `isDefaultOwned()`, `list()`, `DEFAULT_ID` | Validate emote equips, build the owned-state map, and migrate legacy `""` profiles to the default emote on join |
