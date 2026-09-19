---
tags: [shared, modulescript, cosmetics, emotes, config]
path: game.ReplicatedStorage.Config.EmoteConfig
type: ModuleScript
lines: 166
---

# EmoteConfig

Shared catalog of the end-of-match victory **emotes**. An identical copy must exist in Redwater Canyon — edit both together (same rule as BoostConfig / BattlePassConfig).

## What it does
1. Exports `EMOTES` — a map of 21 emote ids to `{ displayName, animationId, defaultOwned, price?, unlockText? }`, plus `ORDER` controlling the grid order. `animationId` is the `rbxassetid` of the emote Animation played on the showcase dummy
2. `price` is the Cash cost in the Bounty emote shop. **A nil `price` means the emote is not for sale** — `CollectionService.purchaseEmote` refuses a price of 0, so dropping `price` is what makes an emote earn-only. It must then be granted from somewhere or nobody can ever get it
3. `unlockText` names where an unpurchasable emote comes from (`"BOUNTY PASS"`), shown in place of a price on the shop card and the Collection tile badge. Only meaningful alongside a nil `price`
4. `get(id)` / `isValid(id)` — catalog lookup + membership test
5. `isDefaultOwned(id)` — true when the emote is unlocked for everyone without a grant (2 of the 21 are free: `electro_swing`, `wild_celebration`)
6. `isPurchasable(id)` — mirrors the server rule in `CollectionService.purchaseEmote` (entry exists, not default-owned, `price > 0`) so a shop card and the server can never disagree about what is for sale
7. `unlockTextOf(id)` — the source badge for an unpurchasable, non-default emote; nil for default and purchasable ones
8. `list()` — stable ordered id list for the UI
9. `defaultOwnedList()` — ids unlocked for everyone (default-owned)
10. `DEFAULT_ID = "electro_swing"` — the default emote: the new-player default in `profile.EquippedEmote`, migrated onto legacy `""` profiles on join by CollectionService, and Redwater's match-end fallback when a player has no valid/owned emote. Must be a `defaultOwned` id

An emote is usable if it is `defaultOwned` OR present in the player's `profile.OwnedEmotes` set (granted via `CollectionService.grantEmote`). The equipped emote is a single account-wide id in `profile.EquippedEmote`, defaulting to `DEFAULT_ID` (never `""`/random for a player who hasn't picked one).

**Eight ids are battle-pass exclusives.** Season 1 (`S6`) took five — paid levels 3/13/18/24/28, with 18 also on the free track: `cowboy_dance`, `showdown`, `lasso_dance`, `hit_the_beat`, `take_the_l`. Season 2 (`S7`) added three more on 2026-09-19, at its own paid levels 3/24/28: `good_vibes`, `attitude`, `coffin_dance`. All eight carry `unlockText` and no `price`, which leaves the purchasable count unchanged at 11. Season 2 carries exactly three — its other two emote slots (L13, L18) were filled with Tokens and chests instead of holding the season open for more art.

**The shop carries every id except `electro_swing`** — 11 purchasable + the 8 pass exclusives + `wild_celebration`, which is default-owned and so reads OWNED for everyone. The live Trading Post (`Shop.Modules.ShopExtrasTab`) builds its emote cards from `EmoteConfig.list()`, so a new id appears there with no GUI work; the authored 9×2 grid noted below belongs to the retired `ReworkReworkedBuyMenu.EmoteBuyController`. `take_the_l` was missing a card entirely until 2026-07-29: the L28 swap below moved it onto the pass but never added it to EmoteBuyController's authored card set, so the one emote whose card exists to advertise the Bounty Pass was the one emote the shop did not show. Adding it took the authored page grid from 8×2 to 9×2.

**The L28 slot was swapped on 2026-07-26** and the two halves are one move, not two: `take_the_l` was default-owned and became the pass reward, and `wild_celebration` came off L28 to become default-owned in its place. The second half is what keeps the catalog reachable — an emote with no `price` and no pass level is obtainable by nobody, and dropping a default without replacing it would have left `wild_celebration` orphaned. Existing players lose `take_the_l` unless they reach L28; that is intended, and nothing breaks for a player who had it equipped, because an equipped emote the player no longer owns falls back to `DEFAULT_ID` at match end.

**Keeping the two copies in step is load-bearing, not cosmetic.** Redwater resolves the equipped emote's animation through this module, so an id present only in Bounty is `isValid == false` there and silently falls back to `DEFAULT_ID` — the player equips an emote in the lobby and a different one plays at match end.

## Dependencies
- **Requires:** Nothing
- **Required by:** EmotesTab (grid + preview + tile badge), Panels + Preview + State (validity, animation id, default-owned), CollectionService (equip validation, owned-state, purchase), EmoteBuyController (shop card price / BOUNTY PASS state), BattlePassClient (animation id for an emote reward card's showcase dummy). Redwater's `RoundController` requires its own copy to resolve the match-end animation

## Connections
None
