---
tags: [client, localscript, ui, onboarding, tutorial, matchmaking]
path: game.StarterGui.GameModeGui.GameModeClient
type: LocalScript
lines: 391
---

# GameModeClient

Drives the CHANGE MODE picker and is the only writer of which mode the PLAY sign will start.

## What it does
1. Owns the selection as a `SelectedMode` **string attribute on its own ScreenGui** (`"quickplay"` / `"deathmatch"` / `"tdm"` / `"domination"` / `"tutorial"`), not a module upvalue. The reader is ReworkedUIPlay over in StarterPlayerScripts and the two have no shared require; an attribute is readable, watchable and inspectable in the Explorer, where a BindableEvent handshake would leave a late-connecting reader with no way to ask. Same idiom as MainMenuGui's `SelectedMenuFrame`
2. The attribute is **advisory, not authority** — the server never reads it. The client picks which remote to fire and each remote is owned by the service that validates it, so a tampered attribute can at most start a match the player is entitled to start anyway
3. Paints the five mode buttons on selection: the authored amber `UIGradient` is enabled on the selected one and the rest fall back to the inert TRACK/PARCHMENT pair (style guide 5.4)
4. Swaps the readout on the 3D sign. The mode text on the sign is **not text** — every mode owns a pair of MeshPart letter models parked on the two authored plates, named `<Prefix>Title3D` above the divider and `<Prefix>Blurb3D` below it under `workspace.PlayModel`. All five pairs occupy the same two slots and exactly one is ever visible. The prefixes are `QuickPlay` / `Deathmatch` / `Tdm` / `Domination` / `Tutorial`, built from the mode id through `MODEL_PREFIX`
4a. This replaced a SurfaceGui fallback that existed for one reason: the original letter set was cut for the word DEATHMATCH and had no U, O, R, I or L, so "TUTORIAL" could not be spelled and rendered as flat text on the plate while DEATHMATCH kept its 3D art. The art now exists for all five modes, so the plates' `ModeReadout` SurfaceGuis are held **off** on every repaint rather than driven, and the per-mode blurb copy lives in the art instead of being read off GamemodeConfig
5. Hides the letters with `LocalTransparencyModifier` rather than `Transparency`: this is a client-side preview of a choice that has not been committed, so it must not touch an authored property, and the modifier is client-only by definition. This is also why every set is authored fully **opaque** — the modifier can only ADD transparency, so a set authored invisible could never be shown again
5a. `paintReadout(QUICKPLAY)` is called **before** the `WaitForChild` calls that resolve the dialog, not only from `select()` at the bottom of the file. All five sets are opaque and overlapping, so the window between the sign replicating and the first paint shows every mode's text stacked on top of each other; nothing above that call yields, so the window closes on the frame the script starts
5b. Warns (never asserts) if `deathmatch` / `tdm` / `domination` stop being GamemodeConfig rows, or if `quickplay` / `tutorial` gain one. Both directions fail silently otherwise: PartyService collapses an unrecognised id to deathmatch, so a renamed row turns DOMINATION into a button that quietly starts a free-for-all. An assert would kill the picker, which is worse than a mislabelled button
6. Opens off `Scrim.Visible` changing rather than an `open()` this script calls, because this script is not what opens it — ReworkedUIPlay owns the 3D CHANGE MODE hitbox and writes `Scrim.Visible = true` directly. Hanging the pop-in tween on the property change is what makes that one write get the animation, and keeps the picker openable by hand from the Explorer while building
7. `closeGeneration` invalidates an in-flight close: the fade's `Completed` callback is what sets `Visible = false`, and without the guard a reopen inside that 0.14s window would be shut again by the previous close finishing
8. Resolves `workspace.PlayModel` on every repaint rather than caching it, and runs a short repaint loop after boot (20 x 0.5s). The sign is Persistent so it always arrives, but not always on the first frame, and a streamed-out letter can come back with its modifier cleared. A sign that has not streamed in must never stop a mode being selected. Unlike the version this replaced there is no "nothing to hide" early state to exit on — every mode now has four other letter sets sitting on top of it — so the loop exits as soon as the current mode's title model resolves
9. Starts every join on QUICKPLAY, deliberately **not** persisted to the profile. A sticky TUTORIAL would meet a returning player as a lobby whose PLAY button does not start a match, with nothing on screen explaining why; QUICKPLAY is also the selection that does the most good by default, being the only one that packs a player into a match already running

## Dismissing by clicking outside
Copied from ReworkedSettingsGui's `Backdrop`, which is the click-outside dismiss in this lobby that has always worked: **dismiss on the PRESS**, and decide inside/outside by measuring the press against the card's absolute rect instead of trusting which GuiObject the engine decided the input belonged to. Settings' own comment is the precedent — never trust the backdrop to only see outside clicks.

The first attempt here tracked press-began/press-ended on the scrim and dismissed only when both landed on it. That reasoning was about the scrim, and the scrim is not what has to be right: the only question a dismiss needs answered is *"was this press on the card or not"*, and a rect answers it without depending on hit-test routing at all.

Two signals feed one guarded entry point (`attemptDismiss`) because `Scrim` is a TextButton where `Backdrop` is a plain Frame, so it has a GuiButton's own click machinery layered over the raw input signals — rather than betting on which of `InputBegan` / `Activated` reports an outside press first, both are wired in. The rect test means a press on the card can never dismiss, `DISMISS_ARM_DELAY` (0.25s) means the click that opened the picker can never dismiss it, and `close()` no-ops once hidden, so a doubled report is harmless.

`pointInDialog` grows the card's rect by `GuiService:GetGuiInset()` in every direction. `InputObject.Position` and `AbsolutePosition` disagree about whether the topbar inset is baked in, and which one carries it depends on the ScreenGui's inset mode — this one ignores the inset, Settings' does not. Growing the rect makes the test right under either reading; it costs an insensitive band one topbar tall around the card, against a failure mode of a dismiss that silently never fires.

**The dismiss was never the reason clicking outside appeared to do nothing.** ReworkedUIPlay hit-tests the 3D signs by projecting their bounds into a screen rect, which knows nothing about GUI layering, so the tap that dismissed the picker also hit the CHANGE MODE sign behind the scrim and reopened it in the same frame. That gate lives in ReworkedUIPlay's `tryTeleport`, not here.

## Domination (2026-08-22)

Fourth button: `Dialog.DominationButton`, cloned from `TeamDeathmatchButton` (`Text = "DOMINATION"`),
wired into `BUTTONS` / `READOUT` / `BLURB` off `GamemodeConfig.get("domination")` with an
`Activated → choose(DOMINATION)` connection. The Dialog grew from 0.5 to 0.58 of the screen height to
seat it (Header, Caption, the four mode buttons and Close re-spaced at the old pixel sizes; the
aspect constraint is height-dominant so width follows). Device-matrix checked on HD 1080, Galaxy A06
(800×360) and iPad 9th gen.

## QuickPlay (2026-08-27)

Fifth button, `Dialog.QuickPlayButton`, cloned from `DeathmatchButton` (`Text = "QUICK PLAY"`) and
seated **first** in the stack, above DEATHMATCH. It is the new session default.

`quickplay` is not a GamemodeConfig row and never will be, for the same reason the tutorial is not
one — no match server can run it. It is a routing id that MatchmakingService resolves into a real
mode before a party is dispatched. That makes GamemodeConfig the wrong place for its readout copy,
which is why item 4a's move of the blurb text into the 3D art matters: nothing here reads the
registry for display any more.

Five buttons did not fit the shipped pitch. The band between the Caption's bottom edge (0.266) and
CloseButton's top edge (0.879) is 0.613, and five buttons at the old 0.130 height need 0.650, so
height dropped to 0.108 and the gap from 0.0255 to 0.0155 — first button top at 0.268, last button
bottom at 0.870. The Dialog itself is unchanged (0.34 x 0.58, 1.05 height-dominant aspect, 270-560px
height clamp). Device-matrix checked on HD 1080, HD 720, iPhone 11, Galaxy S25 Ultra, iPad 6 (4:3)
and Galaxy Tab A8.

## Dependencies
- **Requires:** [[GamemodeConfig]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None

## Implicit couplings (no edges)
Deliberately not wikilinked — none of these is a `require()`, a remote or a tag:

- ReworkedUIPlay writes `Scrim.Visible` to open the picker and reads the `SelectedMode` attribute to decide which teleport remote to fire. Both directions are instance/attribute reads
- `workspace.PlayModel` carries the ten 3D letter models this script dims — `QuickPlay` / `Deathmatch` / `Tdm` / `Domination` / `Tutorial`, each a `<Prefix>Title3D` and a `<Prefix>Blurb3D`. `GameModeFrame` / `GameModeInfo` are the two plates they sit on; their `ModeReadout` SurfaceGuis are the retired flat-text fallback and this script now only ever holds them disabled
- `ReplicatedStorage.SFX.ShopMenuSFX.TabsSelect` is cloned for the selection click, with its `SoundGroup` set to `SFX` explicitly (a `:Clone()` inherits the group, an `Instance.new` would not)
