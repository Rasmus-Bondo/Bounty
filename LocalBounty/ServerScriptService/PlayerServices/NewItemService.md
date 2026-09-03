---
tags: [server, modulescript, collection, notifications, profile]
path: game.ServerScriptService.PlayerServices.NewItemService
type: ModuleScript
lines: 343
---

# NewItemService

Server half of the COLLECTION dot chain: which items a player owns but has not yet looked at in the Collection menu.

## What it does
1. **Derives "new" as owned MINUS `SeenItems`**, never stamped at grant time. Cosmetic grants are not chokepointed the way Wallet chokepoints currency — `grantGroupSkins` and both skin purchase handlers write `data.OwnedSkins` directly, chests pay out through DataService's grant helpers, and titles/emotes/boosts are written by three further services. A stamp-on-grant design needs an edit at every one of those sites and silently misses the next one anybody adds, the failure being a *missing* dot, which nothing reports. The diff needs no grant-site edits and picks up an item granted while the player was offline for free
2. Reads the six buckets **the menu itself reads**: `OwnedCharacters`, `OwnedSkins`, `OwnedWeaponSkins`, `OwnedTitles` + `Cosmetics.Titles`, `OwnedEmotes` + `Cosmetics.Emotes`, and `Boosts.Inventory`. Deliberately **not** `Cosmetics.HunterSkins` / `GunSkins`, which the Collection menu never consults — a dot on a tile the grid does not show would be the dead end the chain exists to avoid
3. Titles and emotes each have **two homes** (bought vs battle-pass) and the union is what can be new. Free titles and the two default emotes appear in neither bucket, so they never carry a dot
4. **`seedIfUnstamped` — the one-way anti-spam seed.** On the first load a profile ever gets after this shipped, everything already owned is copied in as seen. One rule covers both cases: a veteran does not open the menu to a dot on every tile, and a brand-new account is not spammed either (its template already grants three hunters and one default gun per hunter). One-way like `Tutorial.Screened`; never re-run
5. Boosts are **consumables**, counted rather than flagged: an id is new until looked at once, and topping up a stack already seen does not re-badge it — otherwise a daily reward would dot the boosts tab every day
6. `MarkItemsSeen` validates every entry against what the player actually owns before writing, so a spoofed fire cannot use `SeenItems` as free profile storage. Capped at 120 marks per call and one call per 0.2s
7. Re-pushes after a mark lands, so the client's optimistic clear is reconciled — a mark the server refused puts the dot back rather than vanishing until the next rejoin
8. `RequestNewItemState` is the pull half of the handshake and waits up to 20s for the profile rather than answering nil, the same shape CollectionService's pulls and DataService's `RequestSkinData` use. One waiter per player

## Dependencies
- **Requires:** [[DataService]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `NewItemStateEvent` | → Client | [[NewItemClient]] the unseen set, on profile load and after every accepted mark |
| `RequestNewItemState` | ← Client | [[NewItemClient]] pulls the state so a join push that beat the listener is not lost, and re-asks whenever ownership changes |
| `MarkItemsSeen` | ← Client | [[NewItemClient]] a batch of hovered items to record as seen |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()` | The profile, for both the ownership buckets and the `SeenItems` set |
