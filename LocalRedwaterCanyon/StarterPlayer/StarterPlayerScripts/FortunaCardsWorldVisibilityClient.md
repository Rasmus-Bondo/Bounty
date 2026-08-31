---
tags:
  - client
  - localscript
  - cosmetic
  - fortuna
  - cards
path: game.StarterPlayer.StarterPlayerScripts.FortunaCardsWorldVisibilityClient
type: LocalScript
lines: 144
---

# FortunaCardsWorldVisibilityClient

Mirrors each remote Fortuna player's in-hand card visibility onto their third-person `CardsWorldCards` prop. Reads the `VisibleCardMask` attribute set by `CardsServer` (which is pushed by `CardsClient` via `CardsHandVisibilityUpdate`) and applies per-card `LocalTransparencyModifier` to `Card1`/`Card2`/`Card3` (plus their `*Border`/`*Silver` siblings) on the world model.

Runs on every client for every other player — the local player's own world cards are still fully hidden by `CardsWorldVisualClient`.

## What it does
1. Skips `Players.LocalPlayer` entirely (handled by `CardsWorldVisualClient`)
2. For each other player, watches `CharacterAdded` / `CharacterRemoving` / `GetAttributeChangedSignal("SelectedHunter")`. Watcher only attaches when the observed player's `SelectedHunter == "Fortuna"`
3. On the watched character, hooks `GetAttributeChangedSignal("VisibleCardMask")` and `ChildAdded` (to catch the `CardsWorldCards` model arriving/respawning). Each time something changes, calls `refresh()` which re-reads the attribute and applies the mask
4. Mask is a 3-bit int: bit 0 = Card1, bit 1 = Card2, bit 2 = Card3. Default when attribute is nil = 7 (all visible). For each card, descendants named `CardN`/`CardNBorder`/`CardNSilver` get `LocalTransparencyModifier = 0` (visible) or `1` (hidden)
5. Cleans up connections on `CharacterRemoving`, `PlayerRemoving`, and hunter switch away from Fortuna

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
