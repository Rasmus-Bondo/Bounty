# Bullets and Bounty — UI Style Guide

**Status:** living document. Agents may read *and edit* it. When you author UI that establishes a
new pattern, add it here; when you find a rule that is wrong, correct it rather than working around it.

This describes what the UI **is**, derived by scanning every `ScreenGui` in both places
(8,730 descendants in Bounty, 2,736 in Redwater Canyon) — not what someone once intended. Where the
existing UI is inconsistent, this document names the majority pattern as canonical and lists the
exceptions as legacy debt so a future agent does not copy the wrong one.

Read this **before** creating any GUI instance. This is the **single home for everything UI** — both
what it must look like and how you are allowed to build it. `CLAUDE.md` deliberately says nothing
about UI beyond pointing here; if a UI fact is worth writing down, it belongs in this file and
nowhere else.

---

## 1. The look in one paragraph

Weathered western saloon. Dark tobacco-brown panels with **sharp corners**, ringed by a thin
**gold rope** outline that shifts through five stops of tarnished brass. Titles sit on a plaque that
straddles the panel's top edge rather than inside it. Body copy is **parchment tan**, section
headings a **muted leather tan**, numbers and highlights **hot amber**. Buttons are rounded, filled
with a vertical amber gradient and black text; destructive buttons are deep blood red with white
text. Everything carries a soft black `UIShadow`. Motion is short and springy — 0.12–0.28s, `Quad`
for settling, `Back` for anything that should feel physical.

Sharp panels, rounded buttons. That contrast is the signature — do not round the panels.

### 1.1 The one rule that saves the most time: a property read-back is not verification

Every expensive mistake recorded in this document was **silent in a property probe and obvious in a
screenshot**. Two from a single afternoon rebuilding the leave-confirm dialog:

- A `UIStroke` read back `Thickness = 0.007, Transparency = 0, Enabled = true` and drew **nothing**.
- A button label read back `TextColor3 = (255,255,255), TextTransparency = 0, Visible = true` and was
  **invisible** — a `UIGradient` on the button was tinting the text dark red on dark red.

The corollary matters just as much: **a value you read off an existing instance is not necessarily
reproducible by assigning it.** Copying the settings panel's authored `Thickness = 0.004` into a new
stroke produced an invisible stroke; cloning that same stroke produced a correct one. So:

> **Prefer cloning a piece of UI that already looks right over re-typing its property values.**
> If you must author from scratch, screenshot before you build anything on top of it.

### 1.2 Author UI as instances, never build it in code

**Every visual element — `ScreenGui`, `Frame`, `TextLabel`, `TextButton`, `ImageLabel`, `UIStroke`,
`UICorner`, `UIListLayout` — must be created as a real instance in the Studio data model**
(`create_object` / `mass_create_objects`, parented under `StarterGui`, or `ReplicatedStorage` for
templates). Scripts *drive* UI that already exists; they do not construct it.

- **Good:** the script does `local label = gui.Stats.KillsLabel` then sets `.Text`, `.Visible`,
  `.Position`, `.ImageColor3`.
- **Bad:** the script does `Instance.new("Frame")`, sets a dozen properties and parents it at runtime.

Why this is a hard rule and not a preference:

- **A code-built panel does not exist until the game runs.** It cannot be screenshot-verified in an
  edit-only session, cannot be checked in the device simulator, cannot be nudged by hand, and cannot
  be seen at all without a playtest — and playtesting over MCP is not available here
  (`start_playtest` hangs the plugin connection).
- **Layout bugs become invisible.** Wrong anchor, wrong inset, a panel 40px off the edge on a phone —
  all of it is obvious in the Explorer/viewport and undetectable in a wall of `Instance.new`.
- **Two sources of truth.** Half-authored, half-scripted UI means changing a colour or a corner radius
  requires reading code to find out which half owns it.

**The one exception is repeated rows.** Leaderboard entries, card grids, shop tiles, kill-feed lines:
author **one template instance** (hidden, or stored outside `StarterGui`) and `:Clone()` it per item.
The template is still a real authored instance — only the repetition is code. Two gotchas when you
do: a clone reparented into a differently-shaped container keeps `SizeConstraint = RelativeYY` (force
`RelativeXY`, §4.6), and `UIStroke.Thickness` is not pixels, so scale the authored value rather than
assigning an absolute one (§4.2).

Runtime-only property changes are fine and expected — `.Text`, `.Visible`, `.Position` for animation,
`.ImageColor3`, tweens, `UIScale`. The rule is about **structure**, not state.

---

## 2. Color tokens

Use these exact values. If a color is not here, look for the nearest token before inventing one;
if you must add one, add it to this table in the same pass.

### 2.1 Surfaces (browns)

| Token | RGB | Where it is used |
|---|---|---|
| `PANEL` | `47, 32, 23` | Canonical panel body. Daily rewards, settings header plaque, reward strips. |
| `PANEL_ALT` | `48, 33, 23` | Settings panel body. Functionally identical to `PANEL` — prefer `PANEL` for new work. |
| `PANEL_DEEP` | `37, 27, 16` | Recessed areas inside a panel. |
| `INSET` | `33, 22, 16` | Card wells sunk into a panel (daily reward tiles). |
| `FIELD` | `45, 31, 22` · `45, 35, 25` | Text input backgrounds. |
| `TRACK` | `60, 45, 35` | Slider tracks, **off** toggles, inert controls. |
| `BAR_DARK` | `36, 29, 19` → `37, 29, 20` | Menu bar shadow gradient (rot `0`). |
| `PANEL_GRAD` | `27, 25, 23` → `37, 34, 31` | Party-panel body gradient (rot `-90`). |

### 2.2 Gold / amber accents

| Token | RGB | Where it is used |
|---|---|---|
| `AMBER` | `237, 136, 33` | General accent fill. |
| `AMBER_CLAIM` | `240, 176, 42` | Claim / action buttons on reward tiles. |
| `AMBER_FILL` | `247, 158, 23` | Slider fill. |
| `AMBER_TEXT` | `248, 162, 27` | Cash counter. |
| `AMBER_HUD` | `244, 156, 20` | Redwater round timer. |
| `TAN_ACTIVE` | `160, 100, 45` | **On** toggles, Redeem button — the "engaged" state of a `TRACK` control. |

### 2.3 Text

| Token | RGB | Where it is used |
|---|---|---|
| `TEXT` | `255, 255, 255` | Headers, button labels, primary emphasis. |
| `PARCHMENT` | `219, 194, 141` | **Body copy.** Setting row labels, descriptions. The default for reading text. |
| `PARCHMENT_WARM` | `234, 197, 145` · `216, 208, 173` · `255, 244, 220` | Warmer parchment variants. |
| `LEATHER` | `160, 120, 70` | **Section headings** inside a panel (`CROSSHAIR`, `HUD`, `AUDIO`). Deliberately low-contrast. |
| `LEATHER_DIM` | `161, 135, 100` | De-emphasised secondary text. |
| `TAB_IDLE` | `112, 107, 103` | Unselected tab label (shop). |
| `HUD_WARM` | `255, 217, 153` · `255, 205, 110` | Redwater HUD text over the world. |

### 2.4 Semantic

| Token | RGB | Meaning |
|---|---|---|
| `DANGER` | `217, 44, 44` | Close button, Leave Party — bright, small controls. |
| `DANGER_DEEP` | `120, 41, 31` | Destructive **buttons** (Return to Bounty). |
| `DANGER_DARK` | `104, 31, 31` | The `x` glyph itself; darkest red stop. |
| `SUCCESS` | `85, 255, 0` | Quest complete, party joined. Pair with stroke `26, 141, 13`. |
| `FEEDBACK_OK` | `150, 220, 140` | Inline success text. |
| `FEEDBACK_ERR` | `220, 140, 140` | Inline error text. |
| `TOKENS` | `237, 73, 255` | Token currency (purple). Never use purple for anything else. |
| `TEAM_RED` | `168, 38, 34` | TDM red team — score chip plates, team accents. The pads' Crimson lifted for HUD contrast. |
| `TEAM_BLUE` | `48, 92, 180` | TDM blue team — score chip plates, team accents. The pads' Navy lifted for HUD contrast; never reuse for anything non-team. |

The TDM score chips (`RoundStatusGui.TeamScoreRed` / `TeamScoreBlue`, flanking the match timer at
fixed ±56px from center) are the reference use: an **opaque** team-color plate, `UICorner (0.15, 0)`,
black 2px stroke, white Bold `TextScaled` number with a near-black text stroke (the NEWGUI port,
2026-09-13 — before it the plate was at `0.15`, sharp-cornered, with a `38,38,38` stroke). The
`TeamAssignBanner` carries the same corner. On touch they dim with the timers (text/stroke to 0.3,
plate +0.2 off whatever is authored) — see `RoundStatusClient`.

### 2.5 Gradients (copy these verbatim)

**Gold rope** — the signature. Goes on a `UIStroke` that outlines a panel, plaque, or badge.

```
UIGradient.Rotation = 180
0.00 → (160, 103, 33)
0.25 → (228, 172, 70)
0.50 → (186, 122, 38)
0.75 → (207, 141, 57)
1.00 → (197, 135, 51)
```

**Amber button fill** — on the button's `BackgroundColor3 = (255,255,255)`.

```
UIGradient.Rotation = 85
0.00 → (255, 170, 34)
1.00 → (235, 139, 5)
```

**Selected glow** — behind a selected tab / pressed state.

```
UIGradient.Rotation = -90
0.00 → (152, 93, 32)
1.00 → (249, 159, 50)
```

**Hairline gold rule** — a 1–2px divider `Frame`.

```
UIGradient.Rotation = 0
0.00 → (165, 108, 36)
1.00 → (195, 134, 51)
```

**Polished gold text** — on selected tab labels and icons (via `UIGradient` on the label).

```
UIGradient.Rotation = -90
0.00 → (255, 235, 150)   0.25 → (245, 171, 86)   0.50 → (253, 246, 184)
0.75 → (244, 234, 178)   1.00 → (255, 255, 203)
```

**Destructive fill** — decline / leave.

```
UIGradient.Rotation = 85
0.00 → (154, 52, 40)
1.00 → (104, 31, 31)
```

### 2.6 The Modern palette (match HUD only)

The "Bounty - UI Update" redesign, ported into the match HUD on 2026-09-13
(`NEWGUI_PORT_SPEC.md`, built by `NEWGUI_PORT_RESTYLE.luau`). Flat slate cards with one coloured
accent each — **no gold rope, no shadow stroke, no inner rim on the HUD tiles or the portrait**
(the D4 exception, §10). It applies to the **match HUD** (`ReworkedHunterGui`, both templates),
the EyeCandy announcement and the level card. **Lobby panels stay brown/gold (§2.1–2.5).**

| Token | Hex | RGB | Where |
|---|---|---|---|
| `SLATE_900` | `#0E1118` | `14, 17, 24` | Panel slabs (`ModernWeaponPanel`, `ModernPlayerPanel`), keybind badge |
| `SLATE_800` | `#181C26` | `24, 28, 38` | Ability card body; gradient top of the slabs |
| `SLATE_700` | `#252A36` | `37, 42, 54` | Gradient top of an ability card |
| `ULT_CARD` | `#282614` | `40, 38, 20` | Ultimate card body (gradient `#363114 → #0E1118`) |
| `TEXT` | `#E5E8EE` | `229, 232, 238` | Every HUD glyph and label; ability icons are tinted to it |
| `YELLOW` | `#F6E525` | `246, 229, 37` | Ultimate fill, ultimate badge text, the portrait / slab accents. Same yellow as the EyeCandy `+CASH` line |
| `PINK` | `#F427BA` | `244, 39, 186` | The EyeCandy `+XP` line only. It was the skill fill and ready underline until the owner's first look (2026-09-13); the skill tiles no longer use it |
| Skill fill | `#FFFFFF` | `255, 255, 255` | The skill cooldown fill (white since the owner's first look, 2026-09-13; it was pink). The icon is `TEXT` under the fill and `SLATE_900` where the fill covers it — the two-layer recipe is documented in `HunterHudCooldown`'s header. The skill ready underline is `SLATE_900`; the ultimate's stays `YELLOW` |
| `HEALTH_BACK` | `#080A0F` | `8, 10, 15` | Health-bar backing |
| Health segments | `#FFFFFF` · `#BE3037` · `#343842` | — | Full · damage trail · empty (`SegmentedHealthManager` constants match) |
| `BUTTON_FACE` | `#131415` | `19, 20, 21` | The five touch cluster buttons, opaque (FIRE keeps its red) |

Corners on the HUD are **offset** radii: 14 px card, 18 px ultimate card, 10 px fill, 7 px badge,
12 px slab / viewport, 3 px accent lines, 2 px health segment. Type is the primary family in
**Bold Italic** for the ammo count, the player name and the keybind badges. The cooldown fill
draws **above** the card (D3): ready = a full white skill tile / full yellow ultimate tile, cooling =
the colour draining upward off the slate. The skill `CooldownBar` is bottom-anchored with a
positive height and `ClipsDescendants` on, clipping the dark icon copy; the ultimate's bar keeps
the older negative-height convention. A `ModernReadyAccent` underline is toggled `Visible` by `HunterHudCooldown` and
`UltimateReadyFX` and is never visible on a tile that is not ready.

**On touch the geometry is frozen.** `HunterGuiMobile` took this palette as paint only — every
`Size` / `Position` / `AnchorPoint` / constraint is byte-identical to before the port, proven by
the restyle script's before/after snapshot diff and by absolute-rect equality at five device
presets. The one touch-geometry change in the whole port is `BountyListGui`'s 0.242 canvas.

---

## 3. Typography

### 3.1 The three fonts

| Role | Font | Usage |
|---|---|---|
| **Primary** | `rbxassetid://12187376174` | Everything. 395 uses in Bounty, 97 in Redwater. Set via `FontFace = Font.new("rbxassetid://12187376174", Enum.FontWeight.X)`. |
| **Display** | `Oswald` | Big condensed all-caps moments only: `MATCH COMPLETE`, shop tab headers, world-space titles. |
| **Glyph** | `FredokaOne` | The `x` close glyph, nothing else. |

Weights, in order of frequency: `Regular` → `Bold` → `SemiBold` → `Medium`.

- **Bold** — headers, button labels, values that must be read at a glance.
- **SemiBold** — section headings, notification lines.
- **Regular** — body copy, row labels.

### 3.2 Banned fonts

`GothamSSm`, `SourceSansPro`, `LegacyArial`, `GothamSSm` are **not** part of the design language.

- `SourceSansPro` / `LegacyArial` only ever appear on invisible hitbox `TextButton`s (`Text = ""`,
  default props, `BackgroundTransparency = 1`). That is not a style choice — leave those alone.
- `GothamSSm` on **visible** text is legacy debt. Remaining offenders:
  `ReworkedSettingsGui.ReturningLabel` in Redwater, and Bounty's
  `MainMenuGui.TeleportOverlay.StatusLabel`. Restyle them when you touch them; never add more.
  (`StatMenuGui` was the third; it was rebuilt to this guide on 2026-08-07.)

### 3.3 Sizing text

**`TextScaled = true` is the default** (505 of 584 text objects in Bounty). It is what makes the UI
survive going from an ultrawide monitor to a portrait phone.

- **Prefer sizing the box over capping the text.** `TextScaled` fills whatever box it is given, so if
  every box is a *fraction of a panel* and the panel is a fraction of viewport height, the type scale
  is automatically identical on every device — no constraint needed. A fixed `MaxTextSize` breaks
  exactly this: caps tuned on a phone stranded 28px labels inside 96px buttons at 1080p. When a
  button's label would otherwise fill it edge to edge, put the text in a **child `TextLabel` sized to
  ~52% of the button** rather than capping it (the `SwapHunterFrame.Button` + `Title` idiom).
- Use a `UITextSizeConstraint` (the house names it `ResponsiveTextSize`) only where a *short* string
  sits in a box much wider than it is tall and would otherwise balloon — and remember it freezes the
  type at that size on large screens.
- **Type hierarchy is set by box height, not by weight.** A body box taller than the header's plaque
  will render body copy *larger* than the title — `Bold` does not make it read as the title. This
  inverts silently and only shows up at large viewports, where boxes are big enough for the height to
  bind instead of the width. Check header against body at 1080p specifically.
- **Two controls that must look identical need identical box geometry *and* comparable text length.**
  `TextScaled` shrinks whichever label is longer, so a matched pair of buttons renders at two
  different sizes the moment one caption is longer than the other — and the long one starts wrapping
  before the short one does. Equalise the captions (`STAY` / `LEAVE`, not `STAY IN MATCH` /
  `RETURN TO BOUNTY`) rather than trying to correct it with constraints. Put the detail in the body
  copy, which is where the house style keeps it anyway; every house button caption is 1–2 words.
- **A long line is WIDTH-bound, so a taller box does nothing for it.** `TextScaled` picks the largest
  size at which the *wrapped* text fits, and it will happily take one line at a modest size rather
  than two lines at a big one. Measured on the tutorial banner (2026-08-09): the 66-character bounty
  instruction rendered at **33px inside a 46px-tall box** on a tablet, because 33px was where it
  stopped fitting the plate's width — raising the box 30 → 46px moved it by 3px. Widening the plate
  `0.50 → 0.58` of the viewport took the same line to 38px. If a line must be bigger, give it width
  or give it fewer words; height only helps the short lines, which then jump to the box height and
  render much larger than the long ones (an unavoidable side effect of `TextScaled`, not a bug).
- **Never script one label's size from another's `TextBounds`** — it over-reports on real phones and
  both Studio and the device simulator hide it. Mirror `TextScaled` plus an identical
  `UITextSizeConstraint` across labels that must match.
- **`AutomaticSize` defeats `TextWrapped`.** Auto-height text never wraps. If text must wrap, give it
  a fixed box with a reserved line count.
- Fixed `TextSize` is acceptable only where a pixel-pinned element already commits to offsets, and
  even then must be checked on a phone.

---

## 4. Geometry

### 4.1 Corners

**Panels are sharp. Buttons are round.**

| Element | `UICorner.CornerRadius` |
|---|---|
| Panel body, header plaque, reward strip | *(none — do not add one)* |
| Small buttons, toggles, text fields | `UDim.new(0, 4)` |
| Standard buttons, cards | `UDim.new(0, 6)` |
| Large buttons, dialogs-within-dialogs | `UDim.new(0, 8)` |
| Slider track / fill / handle | `UDim.new(0, 7)` (= half of the 14px track height → true pill) |
| Circular badge, avatar, currency pip | `UDim.new(1, 0)` |

Scale radii (`0.05`, `0.025`, `0.15`, `0.1`) appear widely in Bounty's lobby. They resolve against the
**smaller** absolute axis, so the same value reads differently on a wide button than a square tile.
**Prefer offset radii for new work** — they are predictable, and 4/6/7/8 covers every case.

### 4.2 `UIStroke.Thickness` — pixels for new strokes, but never *assign* it on an existing one

The authored GUIs are full of sub-pixel thicknesses (`0.004`, `0.0125`, `0.03`, `0.04`) that render
as clean 1–2px hairlines. **Those numbers do not work on a stroke you create yourself.** Measured
2026-08-05 with a controlled probe (six thicknesses on identical frames, screenshot-compared):

| Thickness on a **newly created** `UIStroke` | Result |
|---|---|
| `0.004`, `0.007`, `0.03`, `0.5` | **invisible** |
| `1`, `1.5`, `2` | renders at 1 / 1.5 / 2 px, as expected |

Element size is *not* the variable — the same `0.004` was invisible at 200×70, 400×140, 597×422 and
900×300. But cloning the settings panel's own `UIStroke` (authored `0.004`) onto the same frame
rendered it correctly, and bumping that clone to `0.007` still rendered. So the file's sub-pixel
values are an artefact of how those instances were originally authored, carried along by `:Clone()`,
and are **not reproducible by setting the property**.

**Rules:**

1. **Authoring a new stroke → use pixels, `Thickness >= 1`.** 1px for button edges and inner rims,
   2px for a panel's gold rope or a header plaque. This is predictable and verifiable.
2. **Touching an existing authored stroke → never assign, always multiply.**
   `stroke.Thickness = base * 1.8`. Assigning a pixel value to an element whose authored value is
   `0.03` can blow the ring up enormously. `EmoteBuyController`, `TitleBuyController` and `BoostsTab`
   all carry this idiom with a comment — copy one of them.
3. **Or just clone a stroke that already looks right** (e.g. the settings panel's rope, gradient
   child included) instead of rebuilding it. Guaranteed match, no numbers to get wrong.
4. **Never mix the two.** A hairline copied from the Explorer into `Instance.new("UIStroke")` will be
   invisible and you will not notice in a property read-back — only in a screenshot.
5. **Transparency was tuned for those sub-pixel values.** The house button edge is
   `Thickness = 0.0125, Transparency = 0.88`; at a real 1px, `0.88` is invisible — use ~`0.55`.
6. If you scale a panel with a `UIScale`, **divide each decorative stroke's thickness by that scale**
   or the hairlines alias away on small screens (`SettingsController.panelStrokes`).
7. On **text**, thickness is a fraction of glyph height and the outlines of neighbouring glyphs merge
   past ~5%. A merged silhouette at `Transparency ≥ 0.90` is a *glow* (word-shaped, which no
   rectangle can be); at low transparency it is an ugly slab. Size text strokes as a fraction of
   `TextBounds.Y` and clamp — see `TitleStyles`.
8. A `UIStroke` **still renders** on a `TextLabel` with `TextTransparency = 1`. That is how the
   ghost-label halo stack works — and it is why **anything that fades text must tween the stroke on
   the same `TweenInfo`**. The tutorial's ✓ was faded by `TextTransparency` alone and left a green
   outline of itself parked in the banner for the rest of the lesson. Same for a `UIShadow` on the
   label, which does not track the text either (§4.4).

### 4.2b A `UIGradient` on a `TextButton` tints the text too

It applies to the label as well as the fill. White text on a dark-red gradient renders dark red on
dark red and **disappears** — this is why every gradient-filled button in Bounty (`INVITE`, `ACCEPT`,
`DECLINE`) uses **black** text.

- Gradient fill → black text, always.
- Need light text? Drop the gradient and use a flat fill (the house destructive treatment:
  `DANGER_DEEP` + white), or move the gradient onto a child `Frame` behind a transparent button.

### 4.3 Stroke recipes

| Recipe | Setup |
|---|---|
| **Gold rope** (panel outline) | `UIStroke` white, `ApplyStrokeMode = Contextual`, with the gold-rope `UIGradient` as a child. |
| **Plaque border** (title on edge) | Same, but `ApplyStrokeMode = Border`, thickness ~`0.04`. |
| **Button edge** | `UIStroke` black, `Thickness = 0.0125`, `Transparency = 0.88`, `Border`. |
| **Shadow stroke** | `UIStroke` black, `Thickness = 0.05`, `Transparency = 0.7`, `Contextual`. Sits *outside* an inner stroke to fake depth. |
| **Inner rim** | `UIStroke` white, thin, `Contextual`, named `InnerStroke`, layered under the outer one. |
| **Selection ring** | `UIStroke` `(255, 200, 60)`, toggled by setting `Thickness` to `4` / `0` (settings swatches). |

### 4.4 `UIShadow`

Every panel, plaque and prominent label carries one. It has **no** `Blur` or `Radius` property —
only `Color`, `Offset`, `Spread`, `Transparency`, `Enabled`. `Offset` and `Spread` are `(0,0)`
everywhere; only `Color` and `Transparency` vary.

**`Offset` and `Spread` are `UDim2`, not `Vector2`.** They read back as `{0, 0}, {0, 0}`, which
looks like a `Vector2` in a property dump; assigning one errors with
`Unable to assign property Offset. UDim2 expected, got Vector2`. Use `UDim2.new(0, 0, 0, 0)`.

**On a `TextLabel` it shadows the label's RECT, not the glyphs**, and it ignores
`BackgroundTransparency` — a shadow on a fully transparent label renders a soft dark plate the full
size of the box. Over the 3D scene that is usually exactly what you want (the tutorial banner's
instruction line is unreadable against a sunlit canyon wall without it and obvious with it), but it
means **the plate is as wide as the label, not as wide as the text**: a full-width label carrying a
short line draws a letterbox bar across the screen. Size the box to the copy. `AutomaticSize` is not
the escape hatch — it defeats `TextWrapped` (§3.3).

**A `UIShadow` is also the cheapest way to make an element read against an unknown background.**
A gold ring on Redwater's bounty cards measured 2.1:1 against a sunlit canyon wall and 1.5:1
against bright sand — the map is orange, so an orange accent camouflages against it. Adding a
black `UIShadow` at `0.5` puts a dark boundary immediately outside the shape, so the edge that
matters becomes accent-against-black (7.4:1) instead of accent-against-world. Reach for this
whenever a coloured element sits over the 3D scene rather than over a panel: **pick the colour for
meaning, then let the shadow carry the contrast** — do not compromise the colour to fix legibility.

| Use | Color | Transparency |
|---|---|---|
| Default drop shadow | `(0, 0, 0)` | `0.5` (119 uses) |
| Heavier | `(0, 0, 0)` | `0.6` |
| Barely-there | `(0, 0, 0)` | `0.93` |
| Gold bloom (selected / hovered) | `(204, 168, 81)` | `0.34` idle · `0.59` dim |
| Hot gold bloom | `(255, 191, 62)` | `0.0` |

### 4.5 Layout

- `UIListLayout` with `SortOrder = LayoutOrder`, `Padding = UDim.new(0, 10)` for stacked setting rows;
  pair with `UIPadding` of `(10, 10, 8, 8)` on the container.
- `UIGridLayout` for the lobby's tab rails and card grids.
- **`UIGridLayout` wraps on *any* overflow — do not use it for a fixed short row.** Three `0.3`
  cells plus two `0.05` gaps is `1.0` on paper and `278.84px` inside a `279px` frame in practice;
  Redwater's bounty row wrapped into a single column on that sub-pixel margin, and the symptom
  (cards stacked vertically) looks nothing like the cause. A horizontal `UIListLayout` cannot wrap,
  and `HorizontalAlignment = Center` centres a partial row for free — which matters when the row's
  item count varies. Give each child its own `Size` when you switch: children that relied on the
  grid to overwrite an authored size keep it under a list layout.
- Rows are `Size = {1, 0}, {0, H}` with `H` in `{18, 22, 26, 34, 44, 50, 58}` — heading 22, simple row
  34, slider row 44.
- **`ScrollingFrame` canvas geometry:** canvas scale is relative to the **parent**, children are
  relative to the **canvas minus padding**. Use an **offset** `CanvasSize` and let `UIListLayout`
  drive `AutomaticCanvasSize`.

### 4.5b Constraints push their siblings — floor the container, not the child

A `UISizeConstraint` on a child does not politely clip it; it **grows the child**, and the child then
displaces whatever sits next to it. A 44px floor once added to the leave-confirm button row grew the
row *upward into the body text* on a 360px-tall phone (measured 4px overlap) — the constraint did its
job and quietly broke the layout above it. This is the mechanism reason §4.6 tells you not to reach
for `MinSize` by reflex: the cure is routinely worse than the symptom.

- **Floor the container instead**, sized so the child's natural proportion already clears the
  minimum. Then the child's constraint never engages and the layout stays in proportion at every
  size. The dialog is floored at 190px precisely so `0.235 × height ≥ 44`.
- If a constraint *must* live on the child, give the child an `AnchorPoint` that makes it grow into
  empty space (`(0.5, 1)` to grow upward off a bottom edge) and re-measure the neighbour it grows
  toward.
- `UIAspectRatioConstraint` + `UISizeConstraint` on the same object is workable but only if the two
  agree: pick a `MinSize`/`MaxSize` that already satisfies the aspect ratio (190 × 1.8 ≈ 342), or
  leave one axis unconstrained (`MinSize = Vector2.new(0, 190)`) and let the aspect derive the other.
- **A `UISizeConstraint` is evaluated BEFORE an ancestor `UIScale`, not after** — so under a responsive
  `UIScale` a `MinSize` is *not* the number of screen pixels you get. Measured: `MinSize` 90 under a
  0.9 scale renders **81px** — a flat 44 lands at 39.6. So whatever floor you pick, pre-divide it by
  the scale the container is about to shrink by (`MIN_TOUCH_TARGET_PX / heightFraction /
  endScreenScale`, as `VictoryShowcaseClient` does for RETURN TO BOUNTY), and derive `heightFraction`
  by reading the child's live `Size.Y.Scale` rather than copying the authored number into the script,
  where it will drift. A `MinSize` that silently under-delivers is worse than none, because it reads
  as solved.

### 4.6 Scaling across devices

Phones are the majority of the player base and Roblox screens run from a small portrait phone to an
ultrawide monitor. **Nothing ships that was only checked at one viewport size.** Concretely, in this
codebase:

- Size and position in **`Scale`**. Offset is for deliberate pixel pins only (Redwater's top-right HUD
  cluster is the sanctioned one), and a pixel pin must then be verified on **both** a phone and a
  *windowed* PC — those are the two sizes it breaks at.
- **Size against viewport height**, not width — width varies far more between devices. Combat buttons
  and HUD clusters are sized as a fraction of viewport height for exactly this reason.
- Lock proportions with `UIAspectRatioConstraint`. Note that `AspectType = FitWithinMaxSize` clamps
  **both** axes, which is why corner-centred badges collide at 4:3.
- **There is no blanket 44 × 44 touch-target floor, and adding one is not a fix.** This guide carried
  that rule for a while; it was imported from phone-OS guidance and never described this game.
  Measured 2026-08-15 across every `GuiButton` in Bounty at 800 × 360 (`samsung_galaxy_a06`
  landscape, the smallest supported screen): **31 of 154 reach 44 × 44 and 123 do not** — tabs,
  toggles, close buttons, claim buttons and every purchase button in the shop. All of it has shipped
  and been played on real phones without a mis-tap problem. Roblox's touch handling is forgiving, and
  the house button shape (100–220px wide, 15–30px tall) is easy to hit despite failing a *square*
  minimum. Do not "fix" an existing button to hit 44, and do not reject a new one for missing it.

  What to watch instead, in priority order:
  1. **Height, not width.** A landscape phone is ~360px tall and panels nest 3–5 deep in `Scale`, so
     height is the axis that collapses — every one of those 123 misses was a height miss, with width
     to spare.
  2. **Spacing between adjacent small targets**, which is what actually causes mis-taps. A lone 20px
     close button in a panel corner is fine; eight 19 × 33 crosshair swatches in a row, or a 23 × 16
     Kick button pressed against a player name, are the ones worth widening.
  3. **Destructive controls** — leave, kick, sell, spend. Give those room whether or not they measure
     44px, because the cost of a mis-tap is asymmetric.

  When a control genuinely needs a bigger tap area than its painted size, two idioms already ship —
  use one of them rather than sprinkling `MinSize` on every button:
  - **Invisible hitbox sibling** (`DailyLoginController`, seven of these on the daily-reward tiles):
    an unpainted `TextButton` pinned over the painted one, carrying the `UISizeConstraint`. The
    painted button keeps its proportion, the hitbox grows, and nothing is displaced.
  - **Floor the container** (`TutorialWelcomeGui.Dialog`, `MinSize (0, 100)`): size the parent so the
    child's authored fraction already clears what you want, and the child needs no constraint at all.
    §4.5b is why constraining the child directly is the trap.
- **The canonical responsive lever is one `UIScale` on the panel's `Canvas`**, interpolated toward a
  `1280 × 720` baseline and clamped. `SettingsController` is the reference implementation:

  ```lua
  local REFERENCE_VIEWPORT = Vector2.new(1280, 720)
  local ratio = math.min(vp.X / REFERENCE_VIEWPORT.X, vp.Y / REFERENCE_VIEWPORT.Y)
  panelScale.Scale = math.clamp(ratio, 0.9, 1)   -- desktop unchanged, phones never below 0.9
  ```

  **When you do this, divide every decorative `UIStroke.Thickness` by that scale** — otherwise the
  hairlines drop below a pixel and alias away on every edge but the top. `SettingsController` tracks
  its strokes in a `panelStrokes` table for exactly this reason.
- Interpolate rather than branching on `TouchEnabled`. A windowed PC is the size a "desktop"
  breakpoint actually breaks at.
- **`TouchEnabled` is two devices, not one, and the game has ONE test for telling them apart:**

  ```lua
  local TABLET_MIN_SHORT_EDGE = 600
  local tablet = viewport and math.min(viewport.X, viewport.Y) >= TABLET_MIN_SHORT_EDGE
  ```

  The **short edge**, so it survives rotation without a second rule. Verified against all 41
  device-simulator presets: the largest phone is 440 on its short edge (`iphone_16_pro_max`) and the
  smallest tablet is exactly 600 (`Redmi Pad SE`, `Fire HD 10`, `Galaxy Tab A8/A9+`) — hence `>=`,
  not `>`, and a 160px gap with nothing in it. Three files use it today: `TelemetryClient` (buckets
  the analytics platform), `TutorialClient` (banner and card sizing), `KillFeedClient` (row budget).
  **Add to that list rather than inventing a fourth threshold** — a phone number applied to a tablet
  is not "too small by a bit", it is the same *physical* size on a panel three times the area, which
  is what reads as tiny.

  **A tablet tier cannot be resolved at load, unlike `TouchEnabled`.** `ViewportSize` reads `(1, 1)`
  for a client's first frames, so anything measured there classifies as a phone and *stays* a phone
  for the whole session — silently, since the value is plausible. Re-solve it in the callback the
  viewport-change signal already drives, and re-apply whatever geometry depends on it. This has
  bitten `TutorialClient` and `KillFeedClient`; it is a *when*, not an *if*.

  This tier is the sanctioned exception to the interpolate-don't-branch rule above, and only because
  the quantity is discrete — a **row or item count** (how many kill-feed rows, how many lines fit)
  has no fractional value to interpolate to. Anything continuous — a size, a position, a text
  size — still interpolates.
- `BillboardGui.Offset` is **screen pixels** and does not shrink with distance or viewport — the
  reason overhead plates crowd on phones.
- `AbsoluteSize` / `TextBounds` are `NaN` before the first layout pass, and `math.clamp` passes `NaN`
  straight through. Guard with `n == n`.
- A cloned template reparented into a differently-shaped container keeps
  `SizeConstraint = RelativeYY` — force `RelativeXY`.

---

## 5. Component recipes

### 5.1 Panel

```
Canvas [Frame]              transparent, holds the UIScale         -- PanelScale [UIScale]
└─ Background [Frame]       bg PANEL, NO UICorner
   ├─ UIStroke              gold rope, Contextual  └─ UIGradient (gold rope, rot 180)
   ├─ UIShadow              black @ 0.5
   ├─ Header [TextLabel]    straddles the TOP EDGE: AnchorPoint (0.5, 0.5), Position Y ≈ 0.017
   │  ├─ UIStroke           Border mode + gold-rope UIGradient
   │  └─ UIShadow
   ├─ CloseFrame [Frame]    top-right, overhanging the corner (Position ≈ {0.94}, {-0.075})
   │  ├─ Button [TextButton]  invisible, oversized hit area (0.6 × 0.6 of the frame)
   │  ├─ Background [Frame]   bg DANGER, UIStroke + ShadowStroke + InnerStroke + UIShadow
   │  └─ TextLabel "x"        FredokaOne, tc DANGER_DARK, black UIStroke
   └─ Content [ScrollingFrame]  UIListLayout + UIPadding, transparent
```

The header plaque overhanging the top edge and the close button overhanging the top-right corner are
the two motifs that make a panel read as *this game's* panel. Keep both.

### 5.2 Setting row

```
SomethingRow [Frame]  Size {1,0},{0,34}  transparent
├─ Label [TextLabel]        Size {1,-60},{1,0}   tc PARCHMENT, primary/Regular, TextScaled
└─ ToggleButton [TextButton] Size {0,50},{0,26}  AnchorPoint (1, 0.5), Position {1,0},{0.5,0}
                             bg TRACK when off / TAN_ACTIVE when on
                             Text "OFF" / "ON", tc PARCHMENT, primary/Bold
                             UICorner (0, 4)
```

Section heading above a group of rows: `Size {1,0},{0,22}`, `tc LEATHER`, primary/**SemiBold**,
`TextScaled`, ALL CAPS.

That `{0,50},{0,26}` toggle renders about **45 × 30** on a 800 × 360 phone — the settings panel's
`PanelScale` floor of 0.9 shrinks it while its taller phone canvas gives some back. Shipped and
tapped at that size; do not grow it to clear a square minimum (§4.6).

### 5.3 Slider

```
SomethingRow [Frame]  Size {1,0},{0,44}
├─ SomethingRowLabel [TextLabel]  Size {1,0},{0,18}   "Master Volume: 67%"  tc PARCHMENT
└─ SliderTrack [Frame]   Size {1,0},{0,14}, AnchorPoint (0,1), Position {0,0},{1,-2}
   ├─ UICorner (0, 7)
   ├─ SliderFill [Frame]    bg AMBER_FILL, Size {f,0},{1,0}, UICorner (0, 7)
   └─ SliderHandle [Frame]  bg PARCHMENT, Size {0,14},{0,14}, AnchorPoint (0.5,0.5), UICorner (0,7)
```

The fill's leading edge is inset by half the handle width so it never overhangs the track ends; the
handle then shifts ~5px left so it reads as sitting *on* the end rather than poking past it. The
label carries the live percentage — sliders in this game are never bare.

### 5.4 Buttons

| Kind | Fill | Text | Corner | Stroke |
|---|---|---|---|---|
| **Primary (amber)** | `bg (255,255,255)` + amber-button gradient rot `85` | `(0,0,0)` primary/Bold | `(0, 6)` | black `0.0125` @ `0.88` Border |
| **Secondary (leather)** | `TAN_ACTIVE` flat | `(255,244,220)` primary/Bold | `(0, 4)` | none |
| **Inert / off** | `TRACK` flat | `PARCHMENT` primary/Bold | `(0, 4)` | none |
| **Destructive** | `DANGER_DEEP` flat, or destructive gradient rot `85` | `(255,255,255)` primary/Bold | `(0, 6–8)` | black `0.0125` @ `0.88` Border |
| **Close `x`** | `DANGER` circle-ish | `DANGER_DARK` FredokaOne | — | triple stroke, see 5.1 |

Amber = affirmative/positive. Red = negative/destructive. In Bounty's party request, `ACCEPT` (amber)
sits **left** and `DECLINE` (red) **right**; follow that ordering for any two-button choice.

### 5.4b Shop purchase button (Trading Post, 2026-08-23)

The Trading Post (`StarterGui.Shop`, `CurrencyShop`) uses a different button family from 5.4 — the
friend's prototype — and it is colour-coded by **currency**, not by affirmative/destructive:

| Currency | `PurchaseableGradient` (rest) | `UnHoverGradient` (hover) | `UIStroke` |
|---|---|---|---|
| **Robux** (teal) | `(29,133,117) → (28,133,118)` | `(69,200,142) → (86,210,155)` | `(110,227,177)` |
| **Cash** (gold) | `(212,178,41) → (211,164,23)` | `(249,241,0) → (255,201,8)` | `(249,236,1)` |
| **Tokens** (magenta) | `(127,30,101) → (179,42,142)` | `(213,50,170) → (255,61,203)` | `(239,57,191)` |
| **Owned** (any) | `OwnedGradient (41,58,81) → (43,59,82)` | — | — |

Anatomy, authored as a Frame (never a TextButton — the hitbox is added at runtime):

```
Frame "BuyButtonRobux|Cash|Tokens"   bg (255,255,255), BackgroundTransparency 0
├─ UICorner (0.125, 0)                scale radius, so it tracks the button height
├─ UIGradient PurchaseableGradient    rot -90, Enabled at rest
├─ UIGradient UnHoverGradient         rot -90, Enabled only while hovered
├─ UIGradient OwnedGradient           rot -90, slate; used only by the Featured bundle panel (see below)
├─ UIStroke                           currency colour, Thickness 0.03 authored (scale it, never assign a pixel value), Transparency 0
├─ Frame TopBarFrame                  (1.015, 0.125) white highlight bar along the top edge
├─ UIShadow
└─ TextLabel PurchaseText             "PURCHASE", primary/Bold, white
```

**`ShopCore.bindPurchaseHover` owns the gradient switch.** Rest = `PurchaseableGradient` + `TopBarFrame`,
white text; hover = `UnHoverGradient` + `UIShadow`, TopBar hidden, **black** text. It forces
`OwnedGradient.Enabled = false` on bind — several authored buttons ship with two gradients on
(`BuyButtonRobux` has Purchaseable + Owned enabled), so **clone one of these and let the binder
normalise it rather than hand-setting `Enabled`**. OWNED is a *sibling* `OwnedButton` Frame that the
tab toggles `Visible` in place of the buy button (hunters / weapons / extras panels); only the
Featured bundle panel, which has no sibling, flips its own `OwnedGradient` and relabels. Label
states: `PURCHASE` (armed), `PURCHASING…` (locked while the server round-trips, 5 s hunters / 12 s
limited), `OWNED`, `SOLD OUT`, and the non-buy variants `JOIN GROUP` / `BOUNTY PASS` / `BUNDLE ONLY`
(disabled — `setEnabled(false)` greys nothing, it only refuses hover and clicks, so the text carries
the state).
**A Robux price on one of these is never the  glyph inside `PurchaseText`.** The glyph renders from a
fallback font whose advance and bearings differ between Studio and the live client (measured
2026-08-23: the vault BUY sat right of centre live, centred in Studio), so `controller.setRobuxPrice`
swaps in a `RobuxPriceRow` built by `ShopCore.attachRobuxPrice` — `rbxasset://textures/ui/common/robux.png`
at 0.7 of the row height + an `AutomaticSize.X` number at `TextSize = 0.98 × row height`, centred by a
horizontal `UIListLayout`, mirroring the label's colour / transparency / Visible / UIStroke. The same
helper sits beside the plain price labels (hunter panel, featured bundle, featured limited).
The chip `+` is the same idea in miniature (`BuyCurrencyButton` Frame with `UIStroke` /
`UIStrokeHover` / `UnHoverGradient` / `PurchaseSymbol`, bound by `ShopCore.bindPlusButtonHover`).

Sounds: hover `UIHover` (rate-limited 45 ms), click `UIClick`, Robux prompt opening
`UIPurchaseButtonPrompt`, server-confirmed purchase `UIPurchaseSucces` (sic) — all in
`ReplicatedStorage.SFX.UIButtonClick`, `SoundGroup = SFX`.

### 5.5 Confirm dialog / modal

Reference implementation: `Redwater → ReworkedSettingsGui.LeaveConfirmFrame`.

```
LeaveConfirmFrame [Frame]     THE SCRIM, not the card. Size {1,0},{1,0}, bg black @ 0.5,
                              Active = true (swallows clicks to the panel and the world behind),
                              Visible = false. Scripts toggle only this.
└─ Dialog [Frame]             bg PANEL, NO UICorner, centred
   ├─ UIAspectRatioConstraint AspectRatio 1.8, ScaleWithParentSize, DominantAxis = Height
   ├─ UISizeConstraint        MinSize (0, 190) / MaxSize (inf, 460)   ← see note below
   ├─ UIStroke 2px + gold-rope UIGradient        ├─ UIShadow black @ 0.5
   ├─ Header [TextLabel]      plaque straddling the top edge, + UIPadding for breathing room
   ├─ Divider [Frame]         gold hairline rule
   ├─ Body [TextLabel]        tc PARCHMENT, TextScaled, no size cap
   └─ ConfirmButtonRow [Frame]  AnchorPoint (0.5, 1) so it grows UPWARD
      ├─ UISizeConstraint     MinSize (0, 44) — this dialog's own floor, not a house rule (§4.6)
      ├─ ConfirmCancelButton  amber gradient + black text, LEFT   (safe / dismiss)
      └─ ConfirmYesButton     flat DANGER_DEEP + white text, RIGHT (destructive)
```

Four things this layout gets right that are easy to get wrong:

- **The scrim is the named frame.** Making the card itself the toggled instance leaves the panel
  behind it clickable — a player can drag a volume slider through an open confirm.
- **`AnchorPoint (0.5, 0.5)` on a centred card.** The original used `(0, 0)` with `Position (0.5, 0.5)`,
  which puts the *top-left corner* at screen centre and hangs the dialog down and right.
- **Floor the dialog height, not just the buttons.** This dialog wants generous buttons because
  leaving a match is destructive (§4.6), but the row's floor *grows the row*, and on a 360px-tall
  phone that pushed it *up into the body text* (measured 4px overlap). Flooring the dialog at 190px
  means the row's authored fraction already clears 44px and the child floor never engages. Copy the
  container floor, not the child constraint.
- **Equal-length button labels.** `TextScaled` shrinks the longer one, so `STAY IN MATCH` /
  `RETURN TO BOUNTY` rendered at two different sizes and the long one wrapped to two lines on a
  phone. `STAY` / `LEAVE` render identically everywhere; the body copy carries the detail.

### 5.5b Tap outside the card to dismiss

Reference implementation: `Bounty → ReworkedSettingsGui.Backdrop` (the original), copied by
`GameModeGui.Scrim`. Two rules, and both exist because the obvious version failed:

- **Dismiss on the PRESS (`InputBegan`), not the release.** A panel opened by a mouse-down becomes
  visible while the button is still held, so the release lands on the new scrim and reads as a
  deliberate outside click — the panel opens and shuts in one click and looks like a dead button.
- **Decide inside/outside by measuring the press against the card's `AbsolutePosition` /
  `AbsoluteSize`.** Never trust which GuiObject the engine decided the input belonged to: a panel
  full of `Active = false` frames (sliders especially) lets a press fall through to the scrim, and a
  press on the card would otherwise dismiss it mid-drag.

```lua
local function pointInPanel(pos)
    local origin, size = card.AbsolutePosition, card.AbsoluteSize
    return pos.X >= origin.X and pos.X <= origin.X + size.X
       and pos.Y >= origin.Y and pos.Y <= origin.Y + size.Y
end

scrim.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if not pointInPanel(input.Position) then setOpen(false) end
    end
end)
```

Two adjustments when the scrim is a `TextButton` rather than a plain `Frame` (as `GameModeGui`'s
is): wire `Activated` into the same guarded function, since a GuiButton layers its own click
machinery over the raw input signals; and set `Selectable = false` so a gamepad cannot land on it.

**If the panel sits over a 3D-projected hitbox, the rect test is not enough.** ReworkedUIPlay
hit-tests the lobby's PLAY and CHANGE MODE signs by projecting their world bounds into a screen
rect, which knows nothing about GUI layering — the only thing normally stopping an outside tap from
also hitting the sign is `gameProcessed`, and that flag is **not dependable on a touch release**.
The dismissing tap reopened the picker in the same frame, which reads as a dismiss that does not
work. Panels over the signs need an explicit refusal in the 3D click path as well; see §7.

### 5.6 Toast / notification

Dark translucent card, `bg (24,24,24) @ 0.65`, `UICorner 0.05`, `UIShadow`, an outer + `InnerStroke`
pair, a title line in `(206,134,41)` primary/SemiBold, a body line in white, and a status line in
`SUCCESS`. Slides/fades in over ~0.18–0.25s and holds. See `QuestCompleteNotification`.

---

## 6. Motion

| Intent | `TweenInfo` |
|---|---|
| Standard settle / fade | `0.22, Quad, Out` (also `0.14` / `0.16` / `0.18` for smaller elements) |
| Anything physical — pop, land, appear | `0.16, Back, Out` (also `0.12`, `0.24`, `0.3`, `0.34`) |
| Click dip (press feedback) | `0.09, Quad, Out` then overshoot `0.16, Back, Out` then settle `0.16, Quad, Out` |
| Show a sidebar / panel | `0.22, Back, Out` in · `0.14, Quad, In` out |
| Slide a tray | `0.35, Quart, Out` |
| Cinematic / camera / black bars | `0.22–0.28, Quint, Out` |
| Number count-up | `duration, Quint, Out` on a `NumberValue` |
| Health / damage bars | `Quart, Out` |

Standard press choreography, from `MenuHandlerScript`: **dip → overshoot → settle**.
`HOVER_LIFT = -3`, `SELECTED_LIFT = -8`, `CLICK_DIP = +2`, `OVERSHOOT_LIFT = -10`;
icon scales `1.06` hover, `1.11` selected, `0.97` click, `1.15` overshoot.

Pops are done with a `UIScale` child (`Instance.new("UIScale")` is fine — it is *state*, not
structure), never by animating `Size`.

---

## 7. Layering

`ZIndexBehavior` is `Sibling` — a child's `ZIndex` orders it only against its own siblings, and its
whole subtree travels with it. Reach for sibling order before reaching for a big `ZIndex`.

`DisplayOrder` registry (Redwater Canyon). **Check this table before picking a number.**

| Order | ScreenGui |
|---|---|
| 0 | `GunGui`, `ReworkedSettingsGui` (closed), `VictoryShowcase`, hunter game GUIs |
| 2 | `HunterGuiMobile` |
| 5 | `RoundStatusGui` |
| 6 | `HunterFireGui`, `HunterSprintGui`, `VesperScopeGui` |
| 7 | `DominationGui` — the Domination score/objective panel; above `RoundStatusGui` (5) so the two resolve deterministically where they share the top-centre band, and above the mobile combat buttons (6) |
| 20 | `StatMenuGui` |
| 25 | `PostGameGui` |
| 40 / 41 | `DailyQuest` / `BountyListGui` |
| 45 | `TutorialGui` — the onboarding lesson banner; above `BountyListGui` (41) and `StatMenuGui` (20) so the instruction line reads through the stats backdrop, below the feeds |
| 100 | `PingFPSGui` |
| 8500 / 8600 / 9000 | `CombatFeed` / `QuestToast`, `QuestCompleteNotification` / `KillFeed` |
| 8650 | `LevelRewardGui` — the level-up / CHEST EARNED card, driven by `LevelRewardClient`. Above the quest toasts (8600) because a level-up is the rarer event, below the kill feed (9000). It sits left-of-centre at y 0.406 and the feeds run right of the crosshair, so the ordering is a tie-break rather than an overlap |
| 8700 | `EyeCandy` — the centre-screen `ELIMINATED <NAME>` / `BOUNTY CLAIMED` announcement; above the `CombatFeed` (8500) it is narrating and below `KillCamGui` (9500), which should cover it |
| 9500 / 9600 | `KillCamGui` / `SwapHunterGui`. `KillCamGui` is cloned per death from the authored template `StarterGui.KillCamGuiTemplate.KillCamGui` (a **Folder** wrapper, like `ReworkedHunterGui`, so `RoundClientController`'s sweep never force-shows the template on respawn) |
| 99998 / 99999 / 100000 | `SlowVignette` / `DamageVignette` / `DamageDirection`, `HealthPackPickup`, `HealingVignetteGui`, `StunnedGui` |
| **100001** | `ReworkedSettingsGui` **while open** — above every HUD and damage overlay |

**100000 is a deliberate tie, not an oversight.** `DisplayOrder` is an integer and 100001 is spoken
for by the open settings menu, so the combat-overlay band has no room left above 100000. The four
GUIs sharing it are all translucent and occupy different parts of the screen (edge vignettes, the
directional arrows, a corner popup, the centred STUNNED label), so their relative order is
cosmetic. Anything that must be *unambiguously* on top of the HUD has to also sit above the settings
menu, which is a different decision — make it deliberately, don't drift into it.
| 900000 / 950000 / 999999 | `Top3` / `VictoryShowcase` / round + cinematic fades |
| 1000000 | `MapVoteGui` — reads against the 999999 fade curtain it sits on, below `MatchCompleteGui` |
| 1000001 | `MatchCompleteGui` |
| 1000002 | `VersionTagController` — documented to sit above everything |

Bounty: `Shop` / `CurrencyShop` / `LootboxMenu` / `ReworkedSettingsGui` / `MobilePlayButtonBackup` 0, `CollectionGui` 2, `ChestMenu` / `ChestAward` 3 (the LOOT tab's chest scene; a full-screen tab panel under the nav like `CollectionGui`, and its purchase panel is placed at canvas x 0.93 so it clears `MainMenuGui.PartyFrame`'s OPEN PARTY strip, which stays up on every tab), `CurrencyHudGui` / `CurrencyHudStackGui` 5, `InviteFriendsGui` 6, `BundleGuiHomeScreen` 7, `MainMenuGui` / `BattlepassGui` 8, `QuestGui` 10, `DailyLoginGui` / `RankLeaderboardGui` 40, `GameModeGui` 45, `GiftGui` 60, `TutorialWelcomeGui` / `TutorialCompleteGui` 80 (the welcome card must cover the menu and the gift popup), `FollowJoinGui` 100. Read off Studio 2026-08-23 — `MainMenuGui` is **8**, not the 1 this line used to claim. **The Trading Post (`Shop`, 0) sits UNDER the bottom nav (`MainMenuGui`, 8) on purpose**: the nav draws over it, so the shop's `Canvas.Content` is fitted to stop above the nav line (0.80) by `ShopController.updateContentFit` rather than by layering. A home-screen widget still has to sit **above `MainMenuGui`** or the menu draws over it — `BundleGuiHomeScreen` shipped at 0 and was invisible behind the menu (it is 7 today, below the 8; re-verify on the home screen before leaning on that ordering).

**`ScreenInsets`:** use `None` (+ `IgnoreGuiInset = true`) for anything that must reach the physical
screen edge — Roblox reserves ~62px on **both** short edges otherwise. Use `DeviceSafeInsets` for HUD
elements that must dodge notches. A `ScreenGui` cloned into `CoreGui` for a screenshot preview
**inherits the harness's insets**, so compare the real properties before trusting a preview.

---

## 8. Streaming, sound, and other traps

- **Both places run `StreamingEnabled`.** A `Model` can replicate as an **empty container** —
  `FindFirstChild` succeeds while its `BasePart`s (and the `Sound`s / `Attachment`s inside them) are
  streamed out. Menu-critical instances go in a `Model` with `ModelStreamingMode = Persistent`.
- **Every `Sound` must carry a `SoundGroup`** (`SFX` / `HitSound` / `Music`). There is no
  `SoundService.Volume` — "Master" is faked by multiplying into each group, so an ungrouped `Sound`
  escapes **all four** settings sliders. UI sound idiom, used identically in six controllers:

  ```lua
  local sound = template:Clone()
  sound.PlaybackSpeed = random:NextNumber(0.94, 1.06)   -- optional, for repeated clicks
  sound.SoundGroup = SoundService:FindFirstChild("SFX")
  sound.Parent = SoundService
  sound:Play()
  ```

  No `Sound` is authored under `StarterGui` — they are cloned from templates at play time.
- **`create_object` mangles `Color3` / `UDim` values.** Verify with an `execute_luau` read-back and
  fix via raw Luau constructors.
- **Repeated rows are the one code exception.** Author *one* template instance and `:Clone()` it. The
  template is still a real authored instance; only the repetition is code.
  **A `GuiObject` renders through a `Folder`** — parking a template in a `Templates` folder under the
  `ScreenGui` does *not* hide it. Author it `Visible = false` and have the clone set `Visible = true`.
- **A list whose length is capped does not need to scroll — size its rows in scale.** A `ScrollingFrame`
  forces offset rows (scale children resolve against the canvas, which `AutomaticCanvasSize` derives
  from the children — circular), and offset rows plus a `MaxTextSize` strand the type: `StatMenuGui`'s
  scoreboard rendered 17px rows inside a 990px panel at 1080p. Redwater holds 10 humans
  (`MATCH_PLAYER_CAP` 7 + `FRIEND_SLOTS` 3) and `Players:GetPlayers()` excludes bots, so a plain
  `Frame` with rows at a fraction of the panel fits the whole board and scales on every device.
  Give the container `ClipsDescendants` as the failsafe if the cap ever rises.

---

## 9. Build and verify — the order that avoids re-work

Rebuilding the leave-confirm dialog took **nine** build → screenshot → fix cycles. Roughly six of
them were avoidable, and the order below is what would have avoided them. Follow it as a sequence,
not a post-hoc checklist.

**Before you build**

1. **Clone, don't re-type.** Take the decorations that already look right — the gold rope `UIStroke`
   with its gradient child, a close button, a header plaque — from an existing panel. See §1.1. Most
   of the diagnosis time went into a hand-authored stroke that a `:Clone()` would have got right.
2. **Reserve the trap list.** Skim §4.2 (stroke thickness), §4.2b (gradients tint text), §4.5b
   (constraints push siblings) and §3.3 (`TextScaled`). Every one of those was hit in a single build.

**First draft — verify wide immediately**

3. **Screenshot it.** Clone the `ScreenGui` into `CoreGui` and `capture_screenshot`. No playtest
   needed, and playtesting over MCP is unavailable (`start_playtest` hangs the plugin connection).
   Compare the real `ScreenInsets` / `IgnoreGuiInset` against the preview harness's first — a clone
   inherits the harness's insets, not the original's.
4. **Run `capture_device_matrix` on the FIRST draft, not the last.** This is the single highest-value
   change to the workflow. Three separate defects — a wrapped button caption on a phone, text capped
   too small at 1080p, and a row overlapping the text above it — were *all present in the first
   build* and were found one at a time across three rounds because each round only looked at one
   viewport. Use a small phone (`samsung_galaxy_a06`, 800×360), a *windowed* desktop (`vga`, 640×480),
   a tablet (`ipad_6th_generation`) and `hd_1080`. "It looks right in Studio" is not a check —
   Studio's default viewport is the one size that is never a player's.
   *Gotcha:* passing `orientation` with a desktop preset errors on the matrix's restore step and you
   lose the images. Only set `orientation` on phone/tablet entries.

**Measure, every viewport**

5. **Assert geometry numerically — eyeballing missed both layout bugs.** Run this at the extreme
   viewports; it catches overlap, spill, off-screen and mismatched labels in one call:

   ```lua
   -- Overlap, spill and off-screen. Deliberately no 44px assertion — see §4.6.
   local D = <dialog>
   local vp = workspace.CurrentCamera.ViewportSize
   local function span(g) return g.AbsolutePosition.Y, g.AbsolutePosition.Y + g.AbsoluteSize.Y end
   local _, bodyBottom = span(D.Body)
   local rowTop, rowBottom = span(D.ConfirmButtonRow)
   local _, dialogBottom = span(D)
   local a, b = D.ConfirmButtonRow.ConfirmCancelButton, D.ConfirmButtonRow.ConfirmYesButton
   assert(rowTop - bodyBottom >= 4,        "row overlaps the text above it")
   assert(dialogBottom - rowBottom >= 0,   "row spills out of the panel")
   assert(a.AbsolutePosition.X + a.AbsoluteSize.X <= b.AbsolutePosition.X, "buttons overlap")
   assert(math.abs(a.Label.TextBounds.Y - b.Label.TextBounds.Y) < 0.5, "labels render at different sizes")
   assert(D.AbsolutePosition.X >= 0 and D.AbsolutePosition.X + D.AbsoluteSize.X <= vp.X, "off-screen")
   ```

   Guard any derived number with `n == n` — `AbsoluteSize` / `TextBounds` are `NaN` before the first
   layout pass and `math.clamp` passes `NaN` straight through.
6. **Compare the type scale against itself at 1080p** — header vs body (§3.3). Hierarchy inversion is
   invisible on a phone.
7. For icon assets, measure `EditableImage` pixel bounds rather than eyeballing "too small" or
   "stray dot".

**Before reporting done**

8. **Do not blanket-toggle `StarterGui`.** Snapshot each `ScreenGui.Enabled` first — many are
   authored `false` on purpose. Then confirm the real subtree's `Visible` / `Enabled` / `DisplayOrder`
   are back where they belong; it is easy to leave the *original* toggled after previewing a clone.
9. **Delete the `CoreGui` preview harness and any probe GUIs.**
10. **Syntax-check every edited script,** and confirm every instance path the script looks up still
    resolves — restructuring UI silently breaks `WaitForChild` chains, which fail at runtime, not now.
11. **Update the vault `.md`** for any script you touched, then run the place's graph update script
    and grep the graph to confirm no wikilink invented an edge.

**Cheap re-runs.** Keep the preview-refresh block (destroy harness → clone → strip `LuaSourceContainer`s
→ set `Visible` → parent to `CoreGui`) in the same `execute_luau` call as your property edits. Re-verifying
then costs one call instead of two, which is what makes running the full matrix early affordable.

---

## 10. Known style debt

Fix these opportunistically; never extend them.

| Where | What |
|---|---|
| Redwater `ReworkedSettingsGui.ReturningLabel` | `GothamSSm/Bold`, fixed `TextSize = 32`, `(219,194,140)`. It is the screen shown **immediately after** the (now restyled) leave-confirm dialog, so the inconsistency is back-to-back and obvious. Highest-value item on this list. |
| Bounty `MainMenuGui.TeleportOverlay` | `GothamSSm/Bold`, and `StatusLabel.TextColor3` is `(65025, 65025, 65025)` — a 255× overflow that happens to clamp to white. |
| Both places | `PANEL` `(47,32,23)` vs `PANEL_ALT` `(48,33,23)` are a 1-unit split with no meaning. Converge on `(47,32,23)`. |
| Bounty lobby | Scale-based `UICorner` radii (`0.05`, `0.025`, `0.15`) resolve against the smaller axis and so read inconsistently across differently-shaped elements. |
| Redwater / Frostbite match HUD | **Deliberate, not debt — the D4 exception (2026-09-13).** The ability tiles, the ultimate tile, the keybind badges and the hunter portrait carry **no** gold rope, shadow stroke or inner rim: the Modern palette (§2.6) is flat slate with one coloured accent. Every other panel in both places keeps the rope. `UltimateReadyFX` lights the `ReadyGlow` layers instead of the (absent) strokes. Do not "restore" the strokes on these tiles. |
