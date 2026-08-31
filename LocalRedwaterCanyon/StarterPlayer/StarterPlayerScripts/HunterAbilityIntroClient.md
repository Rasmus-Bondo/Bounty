---
tags: [client, localscript, ui, onboarding, hunter-intro, settings, mobile]
path: game.StarterPlayer.StarterPlayerScripts.HunterAbilityIntroClient
type: LocalScript
lines: 286
---

# HunterAbilityIntroClient

Decides **when** the hunter ability tags are on screen; [[HunterIntroTags]] draws them.

The problem it solves: a new player presses PLAY in the lobby and lands in Redwater holding a hunter they never chose, looking at two ability icons and an ultimate they have no name for. The full ABILITIES panel exists in Bounty's Collection menu, which is exactly the screen a press-play newcomer skips. Note the confusion is *what the buttons do*, not which keys they are — the authored HUD already carries `Q` / `E` / `F` badges (`TAP` on mobile).

This was a centre-screen card and is deliberately not one. Redwater starts shooting the moment you spawn, so a panel large enough to explain three abilities was a wall between a new player and their first fight. Each ability instead gets a 2-4 word action phrase floating above its own HUD icon. The **passive is not shown at all** — it is not something the player presses.

## What it does
1. Resolves the hunter from the `SelectedHunter` player attribute (falling back to `SelectedHunterCategory`) and requires that hunter's [[Manifest]] to read `Abilities.Slots`. Each slot's `Tag` field is the phrase drawn. A hunter whose manifest has no `Abilities` block simply gets no tags — a silent no-op beats three empty labels over the HUD
2. **Visibility is a player setting, not hidden state.** The `AbilityDescriptions` attribute — published by SettingsController from the persisted profile setting (plain text: an attribute read is not a code-level connection) — selects between `"On"` (always visible while alive in a live round), `"Default"` (`HoldSeconds` of live combat per trigger) and `"Off"` (never)
3. **An absent attribute is not `"Default"`.** Until SettingsController publishes the saved value, nothing is drawn: guessing would flash the tags in front of a player who has turned them **Off**. SettingsController deliberately does not seed a value optimistically, and falls back to `"Default"` only once its request retries are exhausted
3a. **Tutorial override:** while the `workspace.TutorialMode` attribute is true, `getMode()` returns `"On"` regardless of the setting — the tutorial's ability steps point the banner at those icons, and a player whose setting is Off must not be told to press an unlabelled one (design 5.5). The setting itself is never written, so the player's own choice resumes in a real match
4. **Only two things start a Default window:** joining the match, and switching hunters. An ordinary respawn does **not** — by then the player has had it, and in a deathmatch a per-respawn restart is indistinguishable from leaving the tags on permanently. `pendingTrigger` is consumed once the player is actually alive in a live round, so a trigger landing during intermission or a kill cam is honoured on the next spawn rather than burnt
5. The Default clock only advances while the tags are genuinely on screen, so the window is not spent on a respawn screen or during intermission
6. **Re-attaches rather than assuming one HUD.** The hunter's own GUI client rebuilds the HUD on every spawn and every switch, which destroys the tags with it; the loop notices the labels lost their parent and re-attaches (retried at most every 0.25s). This is what carries a run across a death
7. One `Heartbeat` pass owns the whole decision. Kept in a single place because "should the tags be up right now" is the only question this script answers — the previous version split it across event handlers and grew a per-life guard, a seen map and a token counter that all had to agree
8. A hunter switch **cancels instantly, without a fade**: half a second of the previous hunter's phrases sitting over the new hunter's icons teaches exactly the wrong thing. The new hunter then earns its own window
9. Switching the setting to Default from the panel mid-match starts a window immediately, rather than silently waiting for the next hunter switch to prove it works
10. Platform is chosen with the same bare `TouchEnabled` test the hunter GUI clients use to pick between ReworkedHunterGui's `ScreenGui` and `HunterGuiMobile`; all sizing is delegated to the module, which measures the icon it attaches to

## History
Replaced a `SeenHunterIntro` profile set (and `HunterIntroService` with it) that showed the intro once per hunter, ever. The setting supersedes it: it is visible, changeable, and testable without touching a profile. Hunter-agnostic and parented at the `StarterPlayerScripts` **root**, like HunterSwitchClient — HunterClientLoader tears down per-hunter folders on a mid-match switch, and this has to survive that and re-point at the new hunter. (Plain text, not wikilinks — this script neither requires nor messages either of them.)

## Dependencies
- **Requires:** [[HunterIntroTags]] (from `ReplicatedStorage.Hunters.Shared`); the selected hunter's [[Manifest]] (from `ReplicatedStorage.Hunters.<Name>.Config`)
- **Required by:** Nobody

## Connections
### RemoteEvents
None — the visibility mode arrives as a player attribute set by SettingsController, so this script owns no remote of its own.

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterIntroTags]] | `.findHosts()`, `.attach()`, `.fade()`, `.HoldSeconds` | Draw the tags and share their constants |
| [[Manifest]] | (table return) | Read the selected hunter's `Abilities.Slots` — the `Tag` phrase per Q/E/F |
