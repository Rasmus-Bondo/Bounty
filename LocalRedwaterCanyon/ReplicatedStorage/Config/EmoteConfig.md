---
tags: [shared, modulescript, cosmetics, emotes, config]
path: game.ReplicatedStorage.Config.EmoteConfig
type: ModuleScript
lines: 166
---

# EmoteConfig

Shared catalog of the end-of-match victory **emotes**. An identical copy must exist in Bounty — edit both together (same rule as BoostConfig / BattlePassConfig). Emotes are equipped in Bounty; this place only reads the catalog to play a player's equipped emote at match end.

## What it does
1. Exports `EMOTES` — a map of 21 emote ids to `{ displayName, animationId, defaultOwned, price?, unlockText? }`, plus `ORDER` controlling the grid order. `animationId` is the `rbxassetid` of the emote Animation played on the showcase dummy
2. `price` is the Cash cost in the Bounty emote shop (this place never sells one). **A nil `price` means the emote is not for sale** — `CollectionService.purchaseEmote` refuses a price of 0, so dropping `price` is what makes an emote earn-only. It must then be granted from somewhere or nobody can ever get it
3. `unlockText` names where an unpurchasable emote comes from (`"BOUNTY PASS"`), shown in place of a price on the shop card and the Collection tile badge. Only meaningful alongside a nil `price`
4. `get(id)` / `isValid(id)` — catalog lookup + membership test
5. `isDefaultOwned(id)` — true when the emote is unlocked for everyone without a grant (2 of the 21 are free: `electro_swing`, `wild_celebration`)
6. `isPurchasable(id)` — mirrors the server rule in `CollectionService.purchaseEmote` (entry exists, not default-owned, `price > 0`) so a shop card and the server can never disagree about what is for sale
7. `unlockTextOf(id)` — the source badge for an unpurchasable, non-default emote; nil for default and purchasable ones
8. `list()` — stable ordered id list for the UI
9. `defaultOwnedList()` — ids unlocked for everyone (default-owned)
10. `DEFAULT_ID = "electro_swing"` — the default emote: the new-player default in `profile.EquippedEmote`, migrated onto legacy `""` profiles on join by CollectionService (Bounty), and Redwater's match-end fallback when a player has no valid/owned emote. Must be a `defaultOwned` id

An emote is usable if it is `defaultOwned` OR present in the player's `profile.OwnedEmotes` set (granted via `CollectionService.grantEmote`). The equipped emote is a single account-wide id in `profile.EquippedEmote`, defaulting to `DEFAULT_ID` (never `""`/random for a player who hasn't picked one).

**Eight ids are battle-pass exclusives.** Season 1 (`S6`) took five — paid levels 3/13/18/24/28, with 18 also on the free track: `cowboy_dance`, `showdown`, `lasso_dance`, `hit_the_beat`, `take_the_l`. Season 2 (`S7`) added three more on 2026-09-19, at its own paid levels 3/24/28: `good_vibes`, `attitude`, `coffin_dance`. All eight carry `unlockText` and no `price`, leaving 11 of Bounty's shop cards purchasable. (Bounty's shop lists every id except `electro_swing`; `take_the_l` only got a card on 2026-07-29, having been left out when the L28 swap below moved it onto the pass.)

**The L28 slot was swapped on 2026-07-26**: `take_the_l` was default-owned and became the pass reward, while `wild_celebration` came off L28 and became default-owned in its place (an emote with no `price` and no pass level is obtainable by nobody). This place only reads the catalog, so the consequence here is the fallback path — a player who had `take_the_l` equipped and did not earn L28 no longer owns it, and RoundController plays `DEFAULT_ID` instead.

**Keeping the two copies in step is load-bearing, not cosmetic.** RoundController resolves the equipped emote's animation through this module, so an id present only in Bounty is `isValid == false` here and silently falls back to `DEFAULT_ID` — the player equips an emote in the lobby and a different one plays at match end. This copy had drifted to only 5 of the 18 ids before the S3 pass; 13 emotes were unplayable.

## Dependencies
- **Requires:** Nothing
- **Required by:** RoundController (resolves each player's victory-showcase emote); WorldAnimationPrewarmClient (plain text: that script's own file declares the require, and a wikilink here would point dependency → dependent)

## Connections
None
