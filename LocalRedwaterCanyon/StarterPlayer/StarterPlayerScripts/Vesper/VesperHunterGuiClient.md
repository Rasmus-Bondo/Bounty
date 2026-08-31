---
tags:
  - client
  - localscript
  - ui
  - mobile
  - vesper
path: game.StarterPlayer.StarterPlayerScripts.Vesper.VesperHunterGuiClient
type: LocalScript
lines: 1034
---

# VesperHunterGuiClient

Vesper's HUD: ammo pips (4 of the shared template's 6 bullets), Grapple/Pinning cooldown fills, ultimate charge display, the Starfall Sight ult-ammo pips + window countdown, the Deadeye Focus ramp bar shown while scoped, mobile ability buttons, and the visible mobile Fire button. GUI-only — input/combat logic lives in [[SunspikeClient]] and [[VesperScopeController]]. Mirrors CardsHunterGuiClient, cloning the shared `TemplateGameGui` (Vesper has no dedicated GUI art yet).

## What it does
1. Requires [[HunterClientRuntime]] + the [[Manifest|Vesper Manifest]]; exits silently when not on Vesper. `events` aliases `runtime.ClientEvents`
2. Clones `StarterGui.ReworkedHunterGui` into PlayerGui as `VesperGameGui` — `HunterGuiMobile` when `UserInputService.TouchEnabled`, `ScreenGui` otherwise — destroying other heroes' GUI clones (Template/Fortuna/Bram/Iris) first, then overwrites the ability icons with Vesper's art. Note the layout comes from `ReworkedHunterGui`, **not** from `StarterGui.HunterGui.Template.TemplateGameGui`: that older tree still exists and still carries the pre-rework `Ultimate > FrameBorder` shape, but nothing clones it any more. The runtime shape is `UltimateFrame > MainFrame > {Background, CooldownBar, Ability, Cooldown, CooldownFrame}`
3. Ammo display: 4 bullet pips (bullets 5-6 hidden) with the standard hide/show back-ease tweens + rich-text ammo counter pulse, driven by `AmmoChanged`/`Reloaded`
4. Skill cooldowns: Skill1 = Grapple (Q), Skill2 = Pinning (E) — `GrappleCooldownStarted`/`PinningCooldownStarted` forward their seconds into [[HunterHudCooldown]], which owns the fill tween, the countdown label, the countdown thread and the expiry pop; `UltimateCooldownStarted` intentionally ignored (ultimate UI shows charge percent only, Fortuna convention)
5. Ultimate charge fill + "READY" label from `UltimateChargeChanged`, plus the [[UltimateReadyFX]] ember halo — a soft gold glow breathes out from behind the icon at full charge. It is cleared in three places, because the label alone is not enough to infer the state: the charge branch drives it every tick, `setUltimateCharge`'s early return drops it while Starfall is up, and `setUltimateActive` drops it the frame the ultimate is spent (waiting for the next charge push would leave the halo lit for the whole window, since that early return fires first). On respawn (`CharacterAdded`) it re-renders the **cached** charge (`setUltimateCharge(currentUltimateCharge, ...)`), not 0 — the server keeps ult charge across death (the ult stays usable), so zeroing the display would show a wrong status until the next `UltimateChargeChanged`. Mirrors BramHunterGuiClient's respawn handling. The [[HunterHudBump]] tile pop rides the **same three clear points** — it is rising-edge gated on `ultimateWasReady`, re-armed wherever the halo is cleared, so a recharge during or after the Starfall window still pops
6. **Starfall Sight ult ammo + window countdown** (`UltimateActiveChanged` / `UltimateAmmoChanged`). While the ultimate is up the ult icon stops reporting charge entirely:
   - The `Cooldown` label becomes a `%.1f` countdown of the remaining active window (same format as the Q/E cooldown labels), driven by a token-guarded `task.wait(0.05)` loop that also exits on a hunter switch
   - `CooldownBar` snaps to its READY (full) size and linear-tweens to empty over the window, so the fill and the countdown agree — charge reads 0 for the whole window and would otherwise show a dead ultimate at the exact moment it is running
   - `setUltimateCharge` caches incoming charge but returns before drawing while active, then re-renders on End
   - A `UltimateAmmo` row of 3 amber pips (`ULTIMATE_AMMO_COLOR` 255,186,72) is parented **inside** `UltimateFrame.MainFrame`, anchored above its top edge. All geometry is a fraction of the icon's side (the template constrains MainFrame square), so the row rides the icon at every resolution: `ULT_PIP_SIDE` 0.21 (~1.25× the magazine pips), `ULT_PIP_SPACING` 0.26, `ULT_ROW_HEIGHT` 0.25 (must stay above `ULT_PIP_SIDE`), `ULT_ROW_GAP` 0.06. Pips are clones of the magazine's `Bullet1` — same art, gradient and square aspect constraint — but must have `SizeConstraint` forced to `RelativeXY`: the template is authored `RelativeYY` for its grid, which in this wide/short row would resolve the pip's X scale against the row's *height* and collapse it to a fifth of its size. Pips are positioned by hand rather than by a UIListLayout because the spend animation shrinks a pip and a layout would re-flow the survivors sideways
   - Pips pop in / shrink out with the same Back-ease tweens as the magazine pips; only pips that actually changed animate, so the survivors do not re-play their pop-in on every shot
   - The **magazine display dims** to 50% (pips, ammo counter text and its UIStroke) for the window — Starfall never spends magazine ammo, but her remaining basic ammo still matters. Driven by a single `magDimValue` NumberValue tween rather than per-pip tweens; `showBullet` / `setAllBulletsVisible` read `magBulletTransparency()` so a shot during the fade lands at the right transparency. `resetUltimateAmmoDisplay()` does an untweened reset on respawn so an in-flight dim cannot overwrite what `CharacterAdded` sets next
7. **Deadeye Focus ramp bar** — a small amber bar below the crosshair, visible only while scoped (via the `ScopeChanged` bindable). RenderStepped fills it over the 3s RampTime as a client-side mirror of the server timer; resets whenever scope state changes (the server resets its ramp on fire — the bar restarting on the next `ScopeChanged` is close enough for v1; the authoritative bonus is always server-computed)
8. Three [[HunterMobileAbilityButton]] instances over Skill1/Skill2/Ultimate firing `GrappleRequested`/`PinningRequested`/`UltimateRequested`, plus a visible FIRE button via [[HunterMobileFireButton]] (tap style, firing `FireRequested`) — same rationale as Dust's Fire button (TouchTap-anywhere is delayed by the tap-vs-drag heuristic). Was an inline `createMobileFireButton` helper before the shared extraction
9. Sets the player name label; re-creates/resets the GUI on CharacterAdded

## The skill cooldown machinery moved out on 2026-08-06
`setSkillReady`, `startSkillCooldown`, `cooldownVisuals`, `activeSkillTweens`, `skillCooldownTokens` and the two skill-tile `HunterHudBump.new` calls are gone; this script now holds a single `cooldowns` controller and calls `:Start` / `:SetReady` / `:Destroy` on it. The removed block was **character-identical** to Fortuna's, and the phantom-countdown bug they both carried (a countdown thread that survived a cancelled tween and popped a tile that was never on cooldown) is now structurally unreachable rather than fixed in four places. See [[HunterHudCooldown]].

`getChargeSize` and `setFrameSize` stayed — the **ultimate** still uses them, including the Starfall window's bar drain, and only the skill half of their call sites went away. The `HunterHudBump` require stayed for the same reason: the ult tile's rising-edge pop is still driven here, off the same three clear points as the halo.

## Dependencies
- **Requires:** [[HunterClientRuntime]], [[HunterMobileAbilityButton]], [[HunterMobileFireButton]], [[UltimateReadyFX]], [[HunterHudCooldown]], [[HunterHudBump]] (from `ReplicatedStorage.Hunters.Shared`); [[Manifest|Vesper Manifest]] + [[VesperConfig]] (from `ReplicatedStorage.Hunters.Vesper.Config`), [[HunterClientState]]
- **Required by:** Nobody

## Connections
### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `AmmoChanged` | ← | Fired by [[SunspikeClient]] |
| `Reloaded` | ← | Fired by [[SunspikeClient]] |
| `GrappleCooldownStarted` | ← | Fired by [[SunspikeClient]] |
| `PinningCooldownStarted` | ← | Fired by [[SunspikeClient]] |
| `UltimateCooldownStarted` | ← | Declared; intentionally ignored |
| `UltimateChargeChanged` | ← | Fired by [[SunspikeClient]] |
| `UltimateActiveChanged` | ← | Fired by [[SunspikeClient]] — Starfall window start/end (countdown, pip row, magazine dim) |
| `UltimateAmmoChanged` | ← | Fired by [[SunspikeClient]] — empowered rounds left in the ult ammo pool |
| `ScopeChanged` | ← | Fired by [[VesperScopeController]] (Deadeye bar visibility) |
| `GrappleRequested` | → | Mobile button → consumed by [[SunspikeClient]] |
| `PinningRequested` | → | Mobile button → consumed by [[SunspikeClient]] |
| `UltimateRequested` | → | Mobile button → consumed by [[SunspikeClient]] |
| `FireRequested` | → | Mobile Fire button → consumed by [[SunspikeClient]] |

### RemoteEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientRuntime]] | `.Start(manifest)` | Hero gate + ClientEvents resolution |
| [[Manifest|Vesper Manifest]] | (table return) | Declarative description of Vesper |
| [[VesperConfig]] | `.Basic.MagazineSize`, `.Passive.DeadeyeFocus.RampTime`, `.Ultimate.ShotCount`, `.Ultimate.ActiveWindow` | Ammo count, ramp display timing, ult pip count + countdown fallback |
| [[HunterMobileAbilityButton]] | `.new()`, `:Start()` | Mobile touch buttons for the three skill frames |
| [[HunterMobileFireButton]] | `.new()`, `:Start()` | Visible mobile FIRE button → fires FireRequested |
| [[UltimateReadyFX]] | `.new()`, `:SetReady()`, `:Destroy()` | Ember border on the ult icon at full charge |
| [[HunterHudCooldown]] | `.new(canvas, names)`, `:Start()`, `:SetReady()`, `:Destroy()` | The Grapple/Pinning cooldown bars, labels, countdown threads and expiry pops |
| [[HunterHudBump]] | `.new()`, `:Play()`, `:Destroy()` | Tile pop on the **ultimate's** rising edge to full charge (the skill pops are internal to [[HunterHudCooldown]]) |
