---
tags: [client, modulescript, ui, collection, state, ownership]
path: game.StarterGui.CollectionGui.CollectionGuiController.State
type: ModuleScript
lines: 196
---

# State

The Collection menu's whole mutable session: what the player OWNS, what they have EQUIPPED, what is SELECTED on each tab. Plus the ownership predicates every tab reads through, and the join-time ownership prefetch.

## What it does
1. **Ownership** (pushed by the server): `ownedSkins`, `ownedCharacters`, `ownedWeaponSkins`, `ownedTitles`, `emoteOwned`. Free titles are implicit rather than listed
2. **Equipped:** `equippedHunter` / `equippedSkin` seed from **replicated player attributes**, not from a remote — which is why they read correctly even in the session where the ownership push was being lost. An attribute is replicated *state*; a RemoteEvent fire is a transient *message*. That asymmetry was the entire "equipped but locked" symptom
3. **Selection:** `selectedHunter` / `selectedSkin` / `selectedWeaponSkin` / `selectedTitle` / `selectedBoost` / `selectedEmote` / `selectedEmoteSkin`
4. **View state:** `rightTab`, `leftMode`, `menuOpen`, and `openToken` — bumped on every open/close so deferred work can compare the token it captured and bail, meaning a fast close during an entrance cannot land a reveal on a menu that is already gone
5. **Predicates:** `isHunterOwned` (three sources: the pushed table, `StoreConfig.FreeCharacters`, and the `Owns<Hunter>` attribute DataService flips on purchase — that fallback is why hunter ownership kept working during the lost-push bug while skins did not), `isSkinOwned`, `isWeaponSkinOwned`, `isTitleOwned`, `isEmoteOwned`
6. **Equipped lookups:** `getEquippedWeaponSkin`, `getEquippedTitle`
7. `applySkinData` — one writer for the `SkinDataEvent` shape, called from both the prefetch and the controller's re-push handler. Every field is type-checked so a nil argument leaves the previous value alone rather than blanking it
8. **Ownership prefetch.** `SkinDataEvent` is a one-shot push fired the instant the profile loads, and a fire that lands before the client connected `OnClientEvent` is **dropped for good**. The old single-file controller connected its handler at the very bottom of a 3872-line chunk, so on a live server the push routinely arrived first and **every owned skin rendered as LOCKED for the whole session**. Connecting here, before any tab has built a grid, means the grids are *built* with real ownership rather than repaired a round trip later. Also sets the client-local `SkinDataReady` attribute that LoadingScreen holds the intro on

⚠ **Every value here is REASSIGNED, not merely mutated.** When this was one file they were plain locals and every reader saw the new value for free. Split across modules, a `local ownedSkins = State.ownedSkins` alias captures the value **once** and then goes stale the moment the server pushes a fresh table — and stale ownership renders every owned skin LOCKED, a bug with no error message attached. Read and write **through** `State`, always. Never alias one into a local, and never replace the `State` table itself.

⚠ **Requiring this module is load-bearing ORDERING**, not just a dependency.

## Dependencies
- **Requires:** [[Refs]], [[Catalog]], [[StoreConfig]], [[TitlesConfig]], [[EmoteConfig]]
- **Required by:** CollectionGuiController, Preview, PreviewMode, Shop, EquipButton, HuntersTab, SkinsTab, TitlesTab, BoostsTab, EmotesTab, Panels

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `SkinDataEvent` | ← Server | [[DataService]] owned skins/characters/gun skins + equipped selection, on join and after purchases |
| `RequestSkinData` | → Server | [[DataService]] asks for a (re)send so a join push that beat the listener is not lost |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `skinDataEvent`, `localPlayer` | The remote and the attribute source |
| [[Catalog]] | `getWeaponSkinList()` | The default gun is always owned |
| [[StoreConfig]] | `FreeCharacters` | Treat free hunters as owned |
| [[TitlesConfig]] | `UnlockOf()` | A `free` title is always owned |
| [[EmoteConfig]] | `isDefaultOwned()` | The two free emotes |
