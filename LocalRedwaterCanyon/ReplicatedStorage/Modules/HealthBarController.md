---
tags: [shared, modulescript, ui, health]
path: game.ReplicatedStorage.Modules.HealthBarController
type: ModuleScript
lines: 542
---

# HealthBarController

OOP module that creates and manages animated overhead health bars on characters, re-triggered explicitly per hit rather than passively watching `HealthChanged`.

## What it does
1. `SetupCharacter` clones a BillboardGui template and attaches it above a character's head (once per character, tracked in `self.ActiveBars` — not a character attribute, since each HealthBarSpawnerClient instance only needs to track its own attacker's view)
2. `RevealDamage` is the main entry point: if a bar already exists for that character, it directly re-invokes the same update/tween function with the character's current `Health`; otherwise it calls `SetupCharacter` to create one
3. Deliberately does **not** keep a persistent `Humanoid.HealthChanged` connection — `Health` is a single shared property with no attacker info, so a permanent listener would make a bar react to damage from *any* attacker, not just the one who triggered that specific reveal (this caused a real bug: Player1's bar would reappear when Player3 hit the same target). Every visual update is now driven explicitly by a `RevealDamage` call.
4. Animates the health bar width via TweenService on each `RevealDamage` call
5. Shows a trailing "damage trail" bar that follows the health bar after a short delay
6. Auto-shows the GUI on **every** `RevealDamage` call, then fades it out after a configurable delay. Because each call is a confirmed hit this viewer just dealt (there is no passive `HealthChanged` listener), the bar always appears — including reveals where the target has healed at/above its last-shown value between the viewer's hits (e.g. a bot that grabbed a health pack — `HealthPackSystem` heals `IsBot` characters as well as players). The health direction only selects the tween style — fast drop + trailing bar for damage, linear rise for a heal-since-last-look — never *whether* the bar shows. (Previously the reveal was silently skipped when `newHealth >= oldValue`, so landed hits on a healing bot showed no bar at all.)
7. Caches transparency values for all GUI descendants to enable smooth fade in/out
8. Hides Roblox's default health display (`DisplayDistanceType = None`)
9. `SetupCharacter` seeds its internal "previous health" baseline to `MaxHealth` (not current `Health`) and immediately runs one manual update against the live `Health` value — this guarantees the very first reveal always animates a drop, even though `Health` has typically already replicated to its post-hit value by the time the caller runs this (since the server applies damage before firing the reveal remote)
10. Cleans up `self.ActiveBars[character]` when the character leaves the DataModel (`AncestryChanged` with no parent)
11. Populates a `PlayerName` TextLabel (if present in the template) with the target's `DisplayName`, falling back to `character.Name` for NPCs — set once during `SetupCharacter` so the name fades in/out with the rest of the bar via the existing transparency cache
11a. Populates a `PlayerTitle` TextLabel (if present in the template) shown under the bar with the character's equipped cosmetic title — read from the player's replicated `EquippedTitle` / `EquippedTitleId` attributes (published by the server's TitleDisplayService) and rendered through [[TitleRenderer]], which sets the text *and* its cosmetic style (gradient, halo, flames); empty text for NPCs/bots or players with no title. Set before `BuildTransparencyCache` so it fades in/out with the rest of the plate. Also re-read via a `GetAttributeChangedSignal("EquippedTitle")` listener so a title that only replicates to this (the attacker's) client *after* the bar was first built still appears; the listener is disconnected when the character leaves the DataModel. Because that late path builds effect instances *after* the cache was snapshotted, it folds them in via `AddToTransparencyCache` — otherwise they would never fade with the plate
11b. **Sets `TitleAura = false` on that label, so [[TitleRenderer]] builds no bloom ghosts for a nameplate** (2026-07-30). A bloom ghost is a copy of the word, and for a host inside a BillboardGui the renderer sizes those copies from `TextBounds.Y` — which **over-reports on real phones while being exact in Studio**, so the copy draws bigger than the text and reads as a wrong-sized outline behind the title. The match-summary podium plate escaped the same bug by dropping `TextScaled` for a fixed `TextSize`, which is exact *there* because that billboard is sized in **pixels**; `HealthBarGui` is sized in **studs** (`7.5 × 1.6`), so its text genuinely has to rescale with camera distance and a fixed size is not available — not building the ghosts is what is left. Costs almost nothing visually: the renderer's own size LOD already drops the aura below 16px of rendered text, which a nameplate is at or under past close range. **Does not cover `specular` (chrome) or `flash` (lightning)** — those draw *on* the glyphs, so `TitleAura` leaves them alone by design and they stay exposed to the same drift. Gradient, tight stroke and particles are unaffected, so a title still renders in its own style
12. Suppresses the bar whenever the victim is invisible from a Fortuna ult (`isUltimateHidden` helper): `updateBars` short-circuits with a `forceHidden()`, and `AttributeChangedSignal` listeners force-hide the bar mid-display if the caster turns invisible while a bar is already up. Covers both **player** Fortuna (the `UltimateInvisible` attribute, published by CardsServer from inside `setCharacterInvisible` so it can't drift from the real window) and **Fortuna bots** (the `BotFortunaInvisible` attribute, set by BotCombat only during the actual invisible window — NOT the 0.47s pre-invisibility windup, and NOT Dust's High Noon, which also sets `BotUltimateActive`). The bar's floating BillboardGui doesn't inherit character transparency, so without this it would give away the invisible caster's position
12a. This check is deliberately **not** keyed on `UltimateActive`. That attribute is the shared MovementChecker speed-headroom flag that *every* hunter's ultimate sets, so reading it here hid the overhead health bar of any non-Fortuna ulting hunter: Bram (and Bram bots) showed no health bar for the full 10s of Last Call despite being completely visible. Same trap HighNoonTargeting fell into before it moved to `UltimateUntargetable` — when a check means something Fortuna-specific, it needs its own purpose-named attribute

## Dependencies
- **Requires:** [[TitleRenderer]]
- **Required by:** HealthBarSpawnerClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TitleRenderer]] | `apply()`, `BaseTransparencyAttribute` | Render the `PlayerTitle` line in its cosmetic style; the attribute lets `recordTransparency` snapshot effect instances at their authored alpha instead of fully opaque |
