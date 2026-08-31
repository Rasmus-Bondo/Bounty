---
tags: [server, modulescript, hunter-switch, character]
path: game.ServerScriptService.PlayerServices.HunterSwitchService
type: ModuleScript
lines: 312
---

# HunterSwitchService

Lets a player QUEUE a swap to a different (owned) hunter mid-round. The swap is **death-gated at both ends**: it can only be REQUESTED while the player is down (the UI is the kill-cam card row in [[HunterSwitchClient]]; `isPlayerDown` enforces the same rule here), and requesting only queues the target — the change is applied on the player's NEXT respawn, a few seconds later at the end of that same kill cam, never as a force-respawn. Because a real respawn fires `Humanoid.Died`, each hunter's ultimate / status effects tear down through their normal death path, so no ability state leaks onto the swapped-in hunter — and it's inherently non-abusable (you already paid with a death), so there's no wind-up or cooldown. The queued selection is applied by a pre-load hook registered with [[SkinService]]`.onBeforeLoadCharacter`, which runs at the top of `loadCharacter` (every respawn) before the selection is resolved, so the fresh character is built as the queued hunter. The `SelectedHunter` attribute flip there is what the client-side HunterClientLoader reacts to when tearing down the old hunter stack and booting the new one.

## What it does
1. `Start()` — creates the `RequestHunterSwitch` (client→server) and `HunterSwitchState` (server→client) RemoteEvents, wires `RequestHunterSwitch.OnServerEvent` to `onRequest`, registers `applyPending` via `SkinService.onBeforeLoadCharacter`, starts the per-player death watch, and clears the per-user pending queue on `PlayerRemoving`
1a. `watchPlayerForDeath` / `watchCharacterForDeath` — connects every player's `Humanoid.Died` (per character, so it goes away with the character) to `pushState`. This is what raises the client's card row: the UI appears on the same authority that gates the request, so the cards can't show a moment before `onRequest` would accept a click. The client driving visibility from its own `Humanoid.Died` produced exactly that — a "you can only swap while you're down" rejection on a click that looked perfectly timed to the player
2. `onRequest(player, hunterName)` — a non-string arg is a state query (the panel opening/refreshing) and is deliberately **not** gated, so the cards can populate. Otherwise validates in order: known roster hunter → round active → **player is down** → owned. Tapping your CURRENT hunter cancels any queued switch (or replies "already playing" if none); re-tapping the already-queued hunter cancels the queue; any other owned hunter is queued
3. `isPlayerDown(player)` — the server-side half of the kill-cam gate. A live humanoid with `Health > 0` is rejected ("You can only swap while you're down."); no character or no humanoid (the respawn gap) counts as down, so a request landing in that window still takes. Without this the rule would be UI-only and an exploiter could fire the remote mid-fight
4. `applyPending(player)` — the `SkinService` pre-load hook; runs at the very start of every respawn's `loadCharacter`, before the selection is read. Consumes the queued hunter (clears it regardless), and if the round is still active, the hunter is still owned, and it isn't already the current hunter, resolves the equipped skin and calls `HunterSelectionService.SetSelection` so the rebuilt character spawns as the queued hunter. Runs before SkinService's spawn lock, so a brief profile read is fine. After consuming the queue (applied OR dropped) it calls `pushState` — the swap-on-respawn has no other client signal, so without this the switch UI would keep showing the stale "Queued"/CURRENT state; by now `GetHunter` returns the just-set hunter and `pendingHunter` is nil
5. Ownership — `Dust`/`Vesper`/`Bram` are free (`FREE_HUNTERS`); anything else must be `true` in the shared profile's `OwnedCharacters` (read via [[DataService]])
4a. `applyPending` resolves the **character** skin only. The swapped-to hunter's **gun** skin is deliberately not read here: [[SkinService]]`.loadCharacter` calls [[HunterSelectionService]]`.RefreshWeaponSkinsFromProfile` for every hunter immediately above this hook, so the `EquippedWeaponSkin_<Hunter>` attribute the new hunter's client reads is already the profile's value by the time `SetSelection` re-publishes it. One authority for gun skins, no drift — and it means the swap picks up a gun skin equipped in the lobby even when the join-time teleport snapshot never carried that hunter
5a. Skin→model resolution is **not** owned here — the local `resolveSelection` is a thin alias for [[HunterSelectionService]]`.resolveSelection`. It moved there so this path and the direct-joiner path (a friends-list join, which resolves its loadout from the profile on first spawn) can never disagree about how an equipped skin NAME maps to a model, which would otherwise bite the next time a hunter is added
5b. Because the swap goes through `HunterSelectionService.SetSelection`, the end-of-round summary follows it: RoundController's `getPlayerHunterSelection` reads the live `SkinService.getSelection` for each post-game entry's `character`, so VictoryShowcaseClient's podium dummy and stats-card portrait both show the swapped-to hunter, not the one equipped in the lobby
6. `pushState` — sends the switch-UI state table (roster, owned map, per-hunter `models`, current hunter, `pendingHunter`, `isDown`, message) to the client. `isDown` is what [[HunterSwitchClient]] shows its card row off, so both sides agree on the swap window by construction rather than by two independent reads of the same death
6a. `buildModelMap` — the `models` field: for every roster hunter, the character model that hunter would actually spawn as wearing this player's equipped skin, built from exactly the `getEquippedSkin` + `resolveSelection` pair `applyPending` spawns from. This is what lets the card row render each portrait in the player's own skin rather than the default (launch issue #22), and pairing it with `applyPending` is what stops the picture disagreeing with the hunter that comes back — including the "equipped a skin, then stopped owning it" case, which both paths resolve down to the default identically. Sent as the RESOLVED `{category, subfolder, modelName}` rather than a skin NAME, so the name→model rule stays solely in [[HunterSelectionService]] (see 5a) instead of being re-implemented client-side; the client already has `ReplicatedStorage.Hunters` to walk

7. **Logs the `HunterSwitch` analytics event via [[Telemetry]], on APPLY rather than on request.** A queued request can still be overwritten or dropped during the kill cam, so only the applied swap is a decision the player actually made. CF02 carries `"Platform|FromHunter"` and CF03 the destination hunter, which turns "phone players abandoning Vesper" into a single readable row. Because the swap costs a death to perform, this is the strongest revealed-preference signal in the game for whether a hunter feels bad to play on a given device — considerably stronger than an accuracy delta, since the player is the one making the judgement

## Dependencies
- **Requires:** [[HunterSelectionService]] (`.SetSelection` / `.GetHunter` / `.IsHunter` / `.resolveSelection`), [[SkinService]] (`.onBeforeLoadCharacter` to register the apply-on-respawn hook), [[DataService]] (`.getPlayerData` for OwnedCharacters + EquippedSkins), [[Telemetry]] (`.log` / `.hunterField` for the HunterSwitch event)
- **Required by:** Main (calls `.Start()`)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RequestHunterSwitch` | ← Client | [[HunterSwitchClient]] queues a switch / cancels / queries state |
| `HunterSwitchState` | → Client | [[HunterSwitchClient]] renders roster, current hunter, and the queued hunter |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterSelectionService]] | `.SetSelection()`, `.GetHunter()`, `.IsHunter()`, `.resolveSelection()` | Flip + read the shared hunter selection gate; map (hunter, equipped skin name) to a character model |
| [[SkinService]] | `.onBeforeLoadCharacter()` | Register the death-gated hook that applies the queued hunter on the next respawn |
| [[DataService]] | `.getPlayerData()` | Read OwnedCharacters (ownership gate) + EquippedSkins (skin to spawn) |
| [[Telemetry]] | `.log()`, `.hunterField()` | Emit the `HunterSwitch` custom event when a queued swap is actually applied |
