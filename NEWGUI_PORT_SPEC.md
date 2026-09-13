# NEWGUI port — moving the "Bounty - UI Update" redesign into Redwater Canyon and Frostbite Claim

**Status:** plan, 2026-09-13, **all twelve decisions resolved with the owner the same day (§2)**.
Nothing has been built. Surveyed live against three connected places: `Bounty - UI Update`
(`place:112014319307228`, the design scratch place), Redwater Canyon and Frostbite Claim. Written so
a cold session can build from it without asking anything further.

**Scope:** everything under `StarterGui.NEWGUI` in the design place (12 ScreenGuis), plus the
owner's follow-up request: a jump effect on parts of the HUD when the player jumps and a bounce when
they land (§7).

> **The rule that overrides everything below — on touch, geometry is frozen and only paint changes.**
> The live `HunterGuiMobile`, the five cluster buttons and their runtime scalers are placed and
> sized correctly on phones and tablets **today**, tuned on real devices over several weeks. This
> port does not re-open that. Every `Size`, `Position`, `AnchorPoint`, constraint and layout on an
> existing touch instance stays byte-identical, **enforced by a before/after snapshot diff inside the
> restyle script that fails the build if anything moved** (§5.1). New decorations are sized in scale
> inside existing frames. The device matrix and geometry assertions run **once, at the end, as
> proof** — not as an iteration loop — and the owner looks at one phone once (§5.2). Owner's hard
> requirement, 2026-09-13.

---

## 1. Inventory — what is in NEWGUI and what has already been transferred

Fingerprinted by descendant count, script byte length and a property-level diff of every instance.
Frostbite matches Redwater on every item below (same counts, same script sizes), so "live" means
both match places.

| NEWGUI ScreenGui | Live counterpart | State | Work |
|---|---|---|---|
| **`In-gameGui`** (634 desc, attrs `VisualStyle=EyeCandy Modern Western`, `ModernReworkVersion=1`) | `StarterGui.ReworkedHunterGui.ScreenGui` (desktop) + `.HunterGuiMobile` (touch), 616 desc each | **Not transferred.** No match place has an `In-gameGui`. | The main job — §3, §4, §5. |
| **`KilledByGui`** (3 desc, no script) | none — `KillCamClient` builds its `KILLED BY` / name / title block in code (lines 526–597) | **Not transferred**, no controller anywhere. | §6.1 |
| **`AnnouncerGui`** (3 desc, "ENEMY TEAM IS NOW CONTROLLING A POINT") | none — `StarterGui.EyeCandy.AnnouncementController` owns centre announcements; nothing in either place emits a "controlling a point" line | **Not transferred**, no controller, no event feeds it. | §6.2 |
| `BountyListGui` | both places, `BountyListClient` byte-identical (30100 B) | Transferred earlier; the **design carries a later restyle** and the **live copy carries later fixes** (gilded stroke gradient + label shadow, 2026-08-29; TDM re-pin, 2026-09-07). | Property merge — §6.3 |
| `DominationGui` | both places, `DominationClient` byte-identical (19853 B) | Transferred 2026-08-29. Design differs only in a flat-black treatment (shadows off, `#000000` bars/circles); live has extra gradients + a stroke. Direction ambiguous. | Decision D7 — §6.4 |
| `RoundStatusGui` | both places, script identical | Transferred. Design adds three `UICorner (0.15,0)` and hardens the team-score strokes. | Tiny merge — §6.5 |
| `StunnedGui` | both places, script identical | Transferred 2026-08-29. **Live is newer** (gradient stroke on the STUNNED label). | Nothing to port. |
| `HunterFireGui`, `HunterJumpGui`, `HunterReloadGui`, `HunterSprintGui`, `VesperScopeGui` | both places | These were copied **into** the design place as context (design-only attribute `MobileHunterHudCompanion=true`). Only delta: opaque `#131415` faces (`BackgroundTransparency` 0 vs live 0.35/0.5) and a second white ring on SCOPE. | Decision D6 — §6.6; it is a **module-constant** change, not an instance change. |

Two things in the design copies are preview state, not design intent, and must not be ported:
`Enabled = true` on every ScreenGui and `Visible = true` on frames the live controllers author
hidden (`TeamScoreRed/Blue`, `TeamAssignBanner`, `CaptureBar`, `StunnedGui.Canvas`, the three bounty
card holders).

### 1.1 The HUD is a fork of an older HUD, so it is a merge, not an import

The design place keeps `StarterGui.Backup/In-gameGui` (581 desc) and `In-gameGui_PreModernRework`
(581). That is the shape the live `ReworkedHunterGui` had **before** the readiness work of August:
the live template has since gained, and the design `In-gameGui` **lacks**, every one of these:

| Missing from the design `In-gameGui` | Who needs it | What breaks if it ships missing |
|---|---|---|
| `MainFrame.Cooldown` TextLabel in all three tiles | `HunterHudCooldown` (`FindFirstChild("Cooldown")`), Cards/Vesper/Bram `ultimateCooldownLabel = ultimate:WaitForChild("Cooldown")` | Dust: no countdown readout, silently (`HunterHudCooldown` tolerates nil). Fortuna/Vesper/Bram: **`WaitForChild` hangs the HUD client**. |
| `MainFrame.BumpScale` UIScale in all three tiles | `HunterHudBump`, `TutorialClient` (`FindFirstChild("BumpScale")`) | No readiness pop; tutorial tile cue silently absent. |
| `UltimateFrame.MainFrame.ReadyGlow` (24 authored `UIShadow` layers) | `UltimateReadyFX` | No ult-ready ember glow. |
| `SegmentedHealthManager` LocalScript under the ScreenGui | the health bar itself | **Health bar never moves.** |
| `PlayerHunterFrame` strokes (`UIStroke` + gradient, `InnerStroke`, `ShadowStroke`, `UIShadow`) and the tile `Background` strokes | `UltimateReadyFX` reads `Background.UIStroke` / `InnerStroke` on the ult tile (tolerates nil — verify at build) | Cosmetic; the design drops them on purpose (flat "Modern" look). |
| `AmmoCount.UIStroke`, `PlayerName.UIStroke`, bullet/gun `UIGradient`s | `VesperHunterGuiClient` reads `ammoCountLabel:FindFirstChildWhichIsA("UIStroke")` (tolerates nil — verify) | Cosmetic. |

So the correct move is the reverse of an import: **clone the live template, apply the design's
deltas onto it**. The design's genuinely new instances are cloned in from the design place
(`export_rbxm` of the subtrees) rather than re-typed — UI_STYLE_GUIDE §1.1.

---

## 2. Decisions — resolved with the owner, 2026-09-13

The decision is the first sentence of each line. The alternatives that were on the table are kept
in brackets so nobody re-opens them.

- **D1 — HUD method: merge the design deltas onto the live `ReworkedHunterGui` templates.**
  Keeps every tuned stroke/glow/segment and every script contract. [Rejected: import the design GUI
  and re-add the six missing pieces by hand.]
- **D2 — Readiness cue: keep `ReadyGlow` + `BumpScale` AND wire the design's `ModernReadyAccent`
  underline as an extra element that shows only when ready.** [Rejected: accent replaces the glow;
  glow only.]
- **D3 — Cooldown fill: draw the coloured `CooldownBar` ABOVE the card.** In the design it sits
  behind a 92 %-opaque `Background` (ZIndex 4 under 5) and reads as a faint tint; swap the order so
  the drain is readable mid-fight. Ready = full colour. [Rejected: tint as designed; translucent
  card; decide on the first draft.]
- **D4 — Gold rope strokes: drop them on the tiles and portrait, as the design does.** Flat slate
  cards with coloured accents. They stay on every other panel; record the exception in
  UI_STYLE_GUIDE §10.
- **D5 — XP bar and level: NOT ported.** `PersistentXPBar` and `PlayerLevel` stay in the design
  place; the Update 3 level-up card remains the only in-match XP feedback. No `LevelProgress`
  attribute, no `HunterHudProgress` module. [Rejected: server-fed bar; client-computed curve.]
- **D6 — Mobile button faces: adopt the opaque `#131415` faces and the SCOPE white ring, all five
  buttons.** A constant change in `HunterMobileFireButton` (FIRE keeps its red, transparency → 0),
  `HunterMobileJumpButton`, `HunterMobileReloadButton`, `HunterMobileSprintButton` (`INACTIVE_BG`
  / `ACTIVE_BG` pair) and `VesperScopeController`, in **both** places, plus the authored instances —
  the modules rewrite the colour at runtime, so editing the instances alone does nothing.
  [Rejected: keep translucent; FIRE alone translucent.]
- **D7 — DominationGui: adopt the flat-black look, keeping the live gradients and stroke.** Shadow
  images off, bars and pad circles black; the 2026-08-29 `ProgressText` / `BarFill` gradients and
  the capture-bar stroke stay. [Rejected: leave live; full design look without gradients.]
- **D8 — KilledByGui: replace `KillCamClient`'s code-built `Title` / `KillerName` labels with the
  authored card**, keeping the `KillerTitle` cosmetic-title slot and the feed-clearance placement.
  [Rejected: separate card; skip.]
- **D9 — AnnouncerGui: fold into the EyeCandy announcement lane.** A new label in
  `EyeCandy.Canvas` driven through the existing `AnnouncementEvent` bindable, fed by the
  `DomOwner_<letter>` attribute changes `DominationAudioClient` already watches, with relative team
  wording ("YOUR TEAM" / "ENEMY TEAM", never a colour name). No new ScreenGui. [Rejected: own
  ScreenGui at the design's y ≈ 0.22; own ScreenGui placed later; skip.]
- **D10 — Jump / land targets: the portrait panel, the weapon/ammo panel, and the ability +
  ultimate tiles (scaled via their holders).** No whole-canvas lift on takeoff — the existing
  landing bob stays as the only canvas motion. Amplitudes are tuned in a live playtest (§7).
- **D11 — BountyList: full restyle.** Square portraits, black ring + drop shadow, 0.242 canvas,
  raised name label, darker reward stroke; the live gilded stroke gradient and label shadow stay.
  [Rejected: portrait style only; leave live.]
- **D12 — RoundStatus: adopt all of it.** Three `UICorner (0.15, 0)` plus the opaque strokes and
  backgrounds on the team scores. [Rejected: corners only; leave live.]

---

## 3. The HUD — shape contract that must survive

Every hunter HUD is a clone of `ReworkedHunterGui.ScreenGui` (PC) or `.HunterGuiMobile` (touch),
selected by `UserInputService.TouchEnabled` in each of the four HUD clients (`Dust.HunterGuiClient`,
`Fortuna.CardsHunterGuiClient`, `Vesper.VesperHunterGuiClient`, `Bram.BramHunterGuiClient`), then
renamed per hunter. The two templates stay named exactly as they are; the design's `In-gameGui`
name is never used in a match place.

Instance names the live scripts resolve — **all of these must exist after the merge**:

```
<template ScreenGui>
  SegmentedHealthManager            LocalScript (authored under the ScreenGui)
  Canvas                            structure-matched by HunterIntroTags.findHosts,
                                    HunterHudShake.findCanvas, HunterMobileSprintButton:
                                    a top-level ENABLED ScreenGui whose Canvas has
                                    AbilityFrame AND UltimateFrame
    WeaponFrame
      BulletCounter/Bullet1..6      HunterGuiClient x4
      GunDisplayImage               Vesper + Bram set .Image
      AmmoCount                     RichText; Vesper reads its UIStroke (nil-tolerant)
    AbilityFrame                    UIGridLayout lays out the HOLDERS
      1Ability/MainFrame            Background, CooldownBar, Cooldown, CooldownFrame(+TextLabel),
      2Ability/MainFrame            Ability, BumpScale, ResponsiveAspect
    UltimateFrame/MainFrame         + ReadyGlow; Background.UIStroke / InnerStroke read by
                                    UltimateReadyFX; HighNoonClient finds MainFrame
    PlayerFrame
      HealthBarFrame/HealthBar, DamageTrailBar, HealthBarEmpty   20 "<n>Bar" segments each
      PlayerHunterFrame/ViewportFrame                            HunterPortraitClient swaps the rig
      PlayerName
      HealthBarFrameBackground
    UIAspectRatioConstraint         10 (desktop) / 7.4 (mobile)
```

Cards/Vesper/Bram also carry `MIRROR_BORDERS = { "Background", "CooldownBar" }` — they copy
border properties between skill tiles by those names.

Constants **outside** the HUD that encode its geometry and must be updated with it:

| Where | What | Today | After (desktop) |
|---|---|---|---|
| `DominationClient` (~line 172) and `EyeCandy.AnnouncementController` (~line 94) | "the HUD paints from …" — the top edge they dodge | 0.777 (`ScreenGui`) / 0.830 (`HunterGuiMobile`) | 0.764 (canvas 0.22 H centred at 0.874) / mobile unchanged if §5 keeps the canvas shape. Their comments say the two are one layout: change both together. |
| `HunterMobileSprintButton.CANVAS_PER_JUMP = 1.1504` | tablet row scale, derived from the mobile canvas (0.95 W × 0.23 H, aspect 7.4) | — | unchanged **only if** the mobile canvas keeps that shape (§5 recommends it does). |
| `KillCamClient.ROUND_STATUS_HEIGHT = 58` | unrelated to the HUD, listed so nobody "fixes" it here | — | — |

ScreenGui-level properties are **taken from the live templates, not the design**: desktop
`DisplayOrder 0`, `CoreUISafeInsets`; mobile `DisplayOrder 2`, `ScreenInsets None`,
`IgnoreGuiInset true`, attribute `MobileHunterHud = true`. The design's `DisplayOrder 20` collides
with `StatMenuGui` and its `DeviceSafeInsets` would shift the mobile canvas relative to the cluster.

---

## 4. The HUD — desktop deltas to apply onto `ReworkedHunterGui.ScreenGui`

Numbers are `Size @ Position` in scale unless marked px. Left = live today, right = design.
Colours: slate `#0E1118` / `#181C26` / `#252A36`, text `#E5E8EE`, yellow `#F6E525`, pink
`#F427BA` — the same yellow/pink the shipped EyeCandy announcement uses, so the palette is already
in game. Font: same family (`rbxassetid://12187376174`), weight **Bold / Italic** in the design where
live uses SemiBold or Regular.

### 4.1 Frame geometry

| Frame | Live | Design |
|---|---|---|
| `Canvas` | (1, 0.198) @ (0.5, 0.866), aspect 10 | (1, 0.22) @ (0.5, 0.874), aspect 10 |
| `WeaponFrame` | (0.182, 1) @ (0.909, 0.5) | (0.21, 0.82) @ (0.885, 0.52) |
| `AbilityFrame` | (0.182, 1) @ (0.727, 0.5) | (0.19, 0.82) @ (0.665, 0.49) |
| `UltimateFrame` | (0.182, 1) @ (0.5, 0.5) | (0.145, 0.82) @ (0.505, 0.49) |
| `PlayerFrame` | (0.364, 1) @ (0.182, 0.5) | (0.33, 0.92) @ (0.165, 0.5) |

`AbilityFrame.UIGridLayout` in the design reads `CellSize (0.5,1)`, `CellPadding (0.015,0)`,
`FillDirection Vertical`, both alignments Center — yet renders two tiles side by side. Keep the
live `Horizontal` grid and only add the 0.015 padding; re-check the render.

### 4.2 WeaponFrame

| Element | Live | Design |
|---|---|---|
| `BulletCounter` | (0.389, 0.19) @ (0.778, 0.551) | (0.4, 0.13) @ (0.7, 0.64) |
| `Bullet1..6` | white, `UIGradient` child | `ImageTransparency 0.1`, no gradient |
| `GunDisplayImage` | (0.78, 0.78) @ (0.3, 0.441), white + gradient | (0.45, 0.58) @ (0.28, 0.5), `ImageColor3 #E5E8EE`, `ImageTransparency 0.06`, no gradient |
| `AmmoCount` | (0.389, 0.307) @ (0.778, 0.305), white, gradient, stroke 0.02 | (0.42, 0.29) @ (0.7, 0.4), `#E5E8EE`, Bold/Italic, no gradient, no stroke |
| **new** `ModernWeaponPanel` | — | (0.88, 0.58) @ (0.52, 0.56), ZIndex 1, `#0E1118` BgT 0.14, `ModernCorner` 12 px, `ModernGradient` `#181C26→#0E1118` rot 90; child `Accent` (0 px, 4 px) × 0.62 pinned to the right edge, `#F6E525`, corner 3 px |

### 4.3 Ability tiles (`1Ability` / `2Ability` → `MainFrame`)

| Element | Live | Design |
|---|---|---|
| `MainFrame` | 0.64 @ (0.5, 0.5) | 0.63 @ (0.5, 0.47) |
| `Background` | BgT 1, four strokes/shadows | `#181C26` BgT 0.08, ZIndex 5, `ModernCorner` 14 px, gradient `#252A36→#0E1118`; strokes removed (D4) |
| `CooldownBar` | `#3F3F3F` opaque | `#F427BA` BgT 0.12, `ModernCorner` 10 px, **ZIndex raised above `Background`** (D3 — the design has it behind the card) |
| `Ability` icon | 0.8 @ (0.5, 0.5), white | 0.68 @ (0.5, 0.46), `#E5E8EE` |
| `CooldownFrame` (keybind badge) | 0.4 × 0.4 @ (0.5, 1), `#242424`, strokes, shadow | 0.38 × 0.30 @ (0.5, 0.94), `#0E1118`, `ModernCorner` 7 px, label Bold/Italic `#E5E8EE` |
| `Cooldown` label, `BumpScale` | present | **absent — keep the live ones** |
| **new** `ModernReadyAccent` | — | (0.42, 0) × (0, 3 px) @ (0.5, 0.93) anchor (0.5, 1), `#F427BA`, corner 3 px |

### 4.4 Ultimate tile

Same as 4.3 with: `MainFrame` 0.7 @ (0.5, 0.47); `Background` `#282614`, gradient
`#363114→#0E1118`, corner 18 px; `CooldownBar` `#F6E525`; icon 0.72; badge label `#F6E525`;
`ModernReadyAccent` 0.5 wide, `#F6E525`. Keep `ReadyGlow`, `Cooldown`, `BumpScale` (D2).

### 4.5 PlayerFrame

| Element | Live | Design |
|---|---|---|
| `HealthBarFrame` | (0.58, 0.22) @ (0.67, 0.496), aspect 8.5 | (0.61, 0.22) @ (0.61, 0.44), ZIndex 20 (layers 21–23), aspect 8.5. Segments: 20 per layer in both; the design bars carry one extra child each (≈ a corner) — harmless to `SegmentedHealthManager`, which iterates the layer's children by name |
| `HealthBarFrameBackground` | BgT 1 | `#080A0F` BgT 0.08, ZIndex 5, + `ModernCorner` 7 px |
| `PlayerHunterFrame` | (0.76, 0.76) @ (0.174, 0.5), `#353535` BgT 0.3, gold strokes + shadow | (0.27, 0.88) @ (0.15, 0.5), BgT 1, `ModernCorner` 14 px, **new** `ModernAccent` 0.58 × 4 px along the bottom `#F6E525`; strokes removed (D4) |
| `ViewportFrame` | (1, 0.996), BgT 1 | (0.94, 0.94) @ centre, `#1E2026` BgT 0.08, `ModernCorner` 12 px. The authored rig is a placeholder — `HunterPortraitClient` swaps it |
| `PlayerName` | (0.383, 0.2) @ (0.618, 0.727), Regular, white, gradient + stroke | (0.43, 0.18) @ (0.53, 0.72), Bold/Italic, `#E5E8EE`, gradient white→`#585858`, no stroke |
| **new** `ModernPlayerPanel` | — | (0.811, 0.68) @ (0.495, 0.54), ZIndex 1, `#0E1118` BgT 0.14, corner 12 px, gradient |
| `PersistentXPBar`, `PlayerLevel` | — | **not ported (D5)** — leave them in the design place |

### 4.6 Not ported: XP bar and level (D5)

`PersistentXPBar` and `PlayerLevel` stay in the design place. If they are ever revisited, the feed
is `Player` attributes `XP` / `Level` (published by `DataService`, lines 660–661) plus a
server-published progress fraction — the level curve is already duplicated three times and must not
get a client-side fourth copy. Without the bar, the design's `HealthBarFrame` (y 0.44) and
`PlayerName` (y 0.72) leave a gap inside `ModernPlayerPanel`; re-centre the health bar on the first
draft if it reads as empty.

### 4.7 Build method

Write the restyle as **one idempotent `execute_luau` script** that takes a template
(`ScreenGui` or `HunterGuiMobile`) and a profile (`desktop` / `mobile`) and:

0. **Snapshots geometry first** — for every existing descendant, keyed by path: `Size`,
   `Position`, `AnchorPoint`, `SizeConstraint`, `AutomaticSize`, `Rotation`, `Visible`, and every
   `UIAspectRatioConstraint`, `UISizeConstraint`, `UIGridLayout`, `UIListLayout`, `UIPadding`
   value. Serialised to strings so the comparison in step 5 is exact.
1. Clones the design's new subtrees from a staging folder (`ReplicatedStorage.__NewGuiStaging`,
   filled by `export_rbxm` from the design place → `import_rbxm`; each subtree is well under the
   ~45 KB import cap) into their parents, skipping any that already exist.
2. Assigns the property deltas. **In the `mobile` profile the whitelist is paint only** —
   `BackgroundColor3`, `BackgroundTransparency`, `ImageColor3`, `ImageTransparency`, `TextColor3`,
   `TextTransparency`, `FontFace`, `ZIndex`, `UICorner.CornerRadius`, `UIGradient`, `UIStroke`,
   `UIShadow`. Nothing in the step-0 set is ever written to an existing instance on mobile; §4.1's
   frame geometry applies to the **desktop** template only. In the `desktop` profile the §4.1–§4.5
   geometry is written as well. Gradients and corners are cloned, not typed — UI_STYLE_GUIDE §1.1.
3. Removes the strokes/shadows listed under D4 (paint — removing a stroke moves nothing).
4. Leaves untouched everything in the §3 contract that the design lacks.
5. **Re-reads the step-0 set and asserts zero deltas on every pre-existing instance** (both
   profiles — on desktop the §4.1 writes are the *expected* deltas and are listed explicitly; any
   other delta fails). Then checks every new instance: sized in `Scale` of its parent (px offsets
   only on the 3–4 px accent lines) and its absolute rect inside its parent frame's rect. The
   script **errors with the offending path** instead of leaving a moved frame for a screenshot to
   catch. A build that fails here is reverted, not patched.
6. Deletes the staging folder when both templates are done.

Keep that script in the repo next to this file (`NEWGUI_PORT_RESTYLE.luau`) — **Frostbite is then a
re-run, not an import**: the whole `ReworkedHunterGui` folder is ~1,234 instances with two rigs and
will not fit through `import_rbxm`. `/mirror` covers the scripts afterwards.

The hook does not capture `execute_luau` edits (see the changelog-hook memory) — the changelog entry
for this work is written by hand from this spec.

---

## 5. The HUD — touch (mobile twin)

The design has **no** mobile `In-gameGui`, and none is authored from scratch. The mobile HUD is
the live `HunterGuiMobile` — whose placement and sizing were tuned on real phones and tablets over
several weeks and are **known correct today** — with the design's paint applied inside it.
"Convert to the current touch layout" therefore means exactly this: **every existing touch instance
keeps its geometry byte-for-byte; only colours, fonts, corners, gradients, strokes and
transparencies change; every new instance is sized in scale inside an existing frame.** This is the
owner's hard requirement (2026-09-13): built right the first time and proven by an automated diff,
not by repeated phone and tablet checks.

What `HunterGuiMobile` does differently from the desktop template today (all of this is frozen):

| | Value | Why |
|---|---|---|
| ScreenGui | `ScreenInsets None`, `IgnoreGuiInset true`, `DisplayOrder 2`, attr `MobileHunterHud` | same inset space as the five cluster buttons, so clearances are measurable in absolute px |
| `Canvas` | (0.95, 0.23) @ (0.5, 0.875), aspect **7.4** (= `min(0.95 W, 0.23 H)`) | `CANVAS_PER_JUMP` is derived from this shape |
| `WeaponFrame` | (0.245, 0.36) @ (0.2325, 0.19) — top-left of the canvas | frees the right side for the cluster |
| `GunDisplayImage` | `Visible false` | no room |
| `BulletCounter` | (0.455, 0.55) @ (0.25, 0.7) anchor (0, 0.5) | |
| `AmmoCount` | (0.3, 0.95) @ (0 + 5 px, 0.7) anchor (0, 0.5) | |
| `AbilityFrame` | (0.235, 1) @ (0.695, 0.5); grid `CellSize (0.485, 0.97)`, `CellPadding 0.03`; `MainFrame` 0.78 | tiles are tap targets — larger than desktop's 0.64 |
| `UltimateFrame` | (0.22, 1) @ (0.5175, 0.5); `MainFrame` 0.73 | |
| `CooldownFrame` (keybind badge) | `Visible false` | no keys on touch |
| `CooldownBar` | BgT 0.45; `Ability` icon `ImageTransparency 0.15` | translucent cards so the scene reads through (the 2026-08-15 mobile-card change) |
| `PlayerFrame` | (0.29, 1) @ (0.145, 0.5); `PlayerHunterFrame` anchor (0, 0.5) at x 0 | |

### 5.1 Frozen on touch — the contract and how it is enforced

**Frozen** (never written by the restyle in the mobile profile; the step-0/step-5 diff in §4.7
proves it):

- Every existing instance's `Size`, `Position`, `AnchorPoint`, `SizeConstraint`, `AutomaticSize`,
  `Rotation`, and every `UIAspectRatioConstraint`, `UISizeConstraint`, `UIGridLayout`,
  `UIListLayout`, `UIPadding` under `HunterGuiMobile` — the table above and everything beneath it,
  including the tile `MainFrame` sizes (0.78 / 0.73), the `BulletCounter` grid and the 8.5
  health-bar aspect.
- The `Canvas` shape (0.95 × 0.23, aspect 7.4, y 0.875) and the ScreenGui's `ScreenInsets None`,
  `IgnoreGuiInset true`, `DisplayOrder 2`, `MobileHunterHud` attribute.
- `Visible` on `GunDisplayImage` (false) and on every `CooldownFrame` badge (false).
- The five cluster buttons' `Size`, `Position`, `UISizeConstraint`, `UIAspectRatioConstraint`,
  `Icon` size — owned by `HunterMobileClusterLayout`; D6 changes colour constants only.
- The runtime scalers — `HunterMobileClusterLayout`, `HunterMobileSprintButton.scaleAbilityRow`
  with `CANVAS_PER_JUMP = 1.1504`, `HunterIntroTags` — **no edits**. They measure the frozen
  frames, so frozen frames keep them correct on every device they are correct on today.
- `DominationClient` / `AnnouncementController` mobile paint line (0.830) — stays, because the
  canvas does not move.

**Allowed** (paint): `BackgroundColor3`, `BackgroundTransparency`, `ImageColor3`,
`ImageTransparency`, `TextColor3`, `TextTransparency`, `FontFace`, `ZIndex`,
`UICorner.CornerRadius`, `UIGradient`, `UIStroke` (add / remove / recolour), `UIShadow`.
`FontFace` changes weight only (same family) and every label is already `TextScaled`, so a bolder
face re-fits its frozen box — assert `TextFits` at 800 × 360 rather than resizing any box.
Keep the mobile card translucency (`CooldownBar` 0.45, icon 0.15) and apply D3 (fill above the
card) here too; re-tune the *transparency* if the darker slate reads wrong, never the size.

**New instances** (`ModernWeaponPanel` + `Accent`, `ModernPlayerPanel`, `ModernReadyAccent` × 3,
`ModernAccent`, `ModernCorner`s, the D10 `ImpactScale`s at rest 1): each sized in `Scale` of its
parent (px offsets only on the 3–4 px accent lines), parented **inside** an existing frozen frame,
never past that frame's rect. Nothing new is parented directly under `Canvas`, and nothing new
changes a holder's or `MainFrame`'s `AbsoluteSize` — decorations must never become the thing a
scaler measures. **Never a `UIScale` on `Canvas`, `AbilityFrame` or `UltimateFrame`** (the sprint
module writes their `Size`; `HunterIntroTags` measures tile `AbsoluteSize`, which includes any
ancestor UIScale, and would scale twice).

`ModernWeaponPanel` on touch: the mobile `WeaponFrame` is a 0.245 × 0.36 box with `AmmoCount`
left-anchored and `BulletCounter` at (0.25, 0.7). Size the panel in scale to wrap those two
(roughly (1, 0.9) @ the frame's centre) with the yellow `Accent` on its right edge. It does **not**
get the desktop (0.88, 0.58) numbers — those were authored for a 0.21 × 0.82 frame.

With the XP bar and level out (D5), the 0.29-wide `PlayerFrame` only has to fit the portrait, the
health bar, the name and `ModernPlayerPanel`, all at their frozen rects.

### 5.2 Proof — once, at the end, automated

The builder proves the result; the owner does not iterate. Runtime-resolved values are proven the
same way as authored ones: **measure before the restyle, measure after, assert equal.**

1. Before touching `HunterGuiMobile`, at each preset below, record with one `execute_luau`: the
   absolute rects of the five cluster buttons, the three tile `MainFrame`s, `WeaponFrame`,
   `PlayerFrame`, `Canvas`; the FIRE-to-intro-tag-band clearance; the value `scaleAbilityRow`
   resolves to (1.00 on phones, ~0.82 on a 4:3 tablet).
2. After the restyle (step-5 zero-delta assertion already passed), re-run the same block at the
   same presets and assert every recorded number is **equal**, plus: no new panel extends past its
   parent; `AmmoCount` / `PlayerName` / the `Cooldown` labels `TextFits`; nothing off-screen; the
   three tiles do not overlap FIRE / SPRINT / JUMP rects (absolute px — both GUIs are in the same
   `None` inset space).
3. Presets: `samsung_galaxy_a06` (800 × 360, landscape), `iphone_XR` (landscape),
   `ipad_6th_generation`, `vga` (640 × 480 windowed) and `hd_1080`. `orientation` only on the
   phone/tablet entries. `set_device_simulator` then the assertion block, five rounds, one pass.
4. One `capture_device_matrix` at those presets for the owner to look at — the visual sign-off.
5. Mid-match hunter switch (`HunterSwitchClient`) rebuilds the HUD from the template — confirm the
   clone/rename contract still resolves every §3 name for all four hunters.
6. **One owner look on one phone, once**, at the end of Phase 3. If it needs a second look, the
   build broke the rule above and is fixed in the script and re-proven, not nudged by hand.
7. Owner sign-off on the visual **before** vault, graph or changelog work.

(The canvas shape does not change in this port. If a future redesign ever must change it,
`CANVAS_PER_JUMP` is re-derived from the new canvas and the 4:3 iPad row scale re-checked — out of
scope here.)

---

## 6. The other ten GUIs

### 6.1 `KilledByGui` → `KillCamClient` (D8)

`KillCamClient` currently builds `Container` (420 × 108 px, bottom-anchored above the combat
feed's base line) with three code-made labels: `Title` ("KILLED BY" / "YOU DIED", 18 px),
`KillerName` (32 px, `#FFE196`), `KillerTitle` (26 px cosmetic title from `TitleRenderer`). The
design card is `Canvas > KilledBy ("KILLED BY:") + PlayerName`, two labels, no title slot.

Port: author the card into a real `StarterGui.KillCamGui` template (there is none today — the
whole kill cam GUI is code-built, against UI_STYLE_GUIDE §1.2), keep `KillCamClient` in charge of
cloning, positioning (`FEED_BASE_Y_ATTRIBUTE`, `MIN_BLOCK_SCALE`), and the `KillerTitle` slot, and
have it fill the authored labels instead of constructing them. `DisplayOrder 9500` stays; register
the new template in UI_STYLE_GUIDE §7. Keep the "YOU DIED" fallback text.

### 6.2 `AnnouncerGui` → objective line (D9)

Home (D9): a new label in `EyeCandy.Canvas`, styled from the design's `AnnouncementText` (+ its
`UIShadow`), shown through the existing `AnnouncementEvent` bindable so it queues with the kill and
bounty cards instead of drawing over them. `AnnouncementController` already runs the Domination
touch test against the capture bar (its lines ~94–185, "the two are one layout") — the new line
joins that stack rather than adding a band.

Feed: `workspace.AttributeChanged` for `DomOwner_<letter>` (A/B/C), resolved through `TeamView`
for relative wording — the exact pattern `DominationAudioClient` uses (lines 53–121). Copy:
"YOUR TEAM IS NOW CONTROLLING A POINT" / "ENEMY TEAM IS NOW CONTROLLING A POINT"; the losing
side's line is the owner's wording call on the first draft. Gate on
`workspace.Gamemode == "domination"` and `RoundActive`. Emit from the client that already watches
the attribute (`DominationAudioClient`, or a sibling `DominationAnnounceClient` if the audio script
should stay single-purpose) by firing `AnnouncementEvent` — no server change.

`AnnouncerGui` itself is not imported. (Had it become its own ScreenGui it would have needed a
`DisplayOrder` from the registry and a `RoundClientController.SWEEP_EXEMPT_GUI_NAMES` entry — the
trap `DominationGui`, `MapVoteGui` and `TutorialGui` each hit.)

### 6.3 `BountyListGui` (D11) — property merge, keep the live script

Design deltas (apply to all three card holders; the live-only `UIGradient`/`UIShadow` on
`RewardAmountLabel` and the stroke gradients on `IconDisplay` stay):

| Element | Live | Design |
|---|---|---|
| `Canvas` | (0.34, 0.175) @ (0.5, 0 + 60 px) | (0.242, 0.168) @ (0.5, 0.021 + 60 px) — `BountyListClient` re-pins `Position` per gamemode (`CROWDED_TOP_BAND`) but never `Size`, so the width change is safe; the y-scale change is overridden by the client and can be dropped |
| `BountyName` | (1, 0.19) @ (0.5, 0.3) | (1, 0.135) @ (0.5, 0.125) |
| `RewardAmountLabel.UIStroke` | 0.03, `#CBCBCB`, T 0.82 | 0.075, `#5B5B5B`, T 0 — a fraction, scale it, never assign an absolute (stroke-thickness memory) |
| `IconDisplay.UICorner` | (1, 0) round | (0.05, 0) square |
| `IconDisplay.UIStroke` | `#FFAA00` | `#000000` |
| `IconDisplay.RingShadow` | T 0.5 | T 0.15 |
| `IconDisplay` **new** `UIShadow` | — | black, T 0.5, blur 20 px |
| `BountyStamp` | (0.9, 0.32) @ (0.5, 0.9), `#FFE2AA`, stroke `#461E00` | (0.9, 0.298) @ (0.5, 0.986), white, stroke `#565656` |

**This is the only touch-geometry change in the whole port** (the 0.34 → 0.242 canvas width and the
`BountyName` move, D11), on a GUI whose phone placement was an owner bug report on 2026-09-07. It
gets the §5.2 treatment, not a look: at `samsung_galaxy_a06`, `iphone_XR` and
`ipad_6th_generation`, in FFA, TDM and Domination (`workspace.Gamemode`), assert the three cards
fit the canvas, no card overlaps `RoundStatusGui.Container` or `DominationGui.Canvas`, and every
label `TextFits`. If the owner would rather keep touch geometry untouched everywhere, the
alternative is the "portrait style only" variant (square portrait, ring, shadow, stamp colours at
the current 0.34 canvas) — the restyle script carries it behind a flag.

### 6.4 `DominationGui` (D7) — confirmed: flat black, live gradients stay

`BackgroundShadow.ImageTransparency` 0 → 1 (three of them), `BackgroundBar` `#232323` → `#000000`
(two), `CapturePointClaimed.<pad>.Circle` white → black (three). The live-only `ProgressText` /
`BarFill` gradients and the capture-bar `UIStroke` are kept. Nothing else differs. Both places.

### 6.5 `RoundStatusGui` (D12)

Add `UICorner (0.15, 0)` to `TeamScoreRed`, `TeamScoreBlue`, `TeamAssignBanner`; on the two score
frames `BackgroundTransparency` 0.15 → 0, `UIStroke` `#262626` T 0.2 → `#000000` T 0,
`ScoreLabel.UIStroke` `#262626` → `#030303`. Keep `Visible = false` (the client shows them in team
modes).

### 6.6 Mobile buttons (D6) — module constants, both places

| Module | Constant(s) | Live | Design |
|---|---|---|---|
| `HunterMobileFireButton` | lines 216–217 | `Color3.fromRGB(200, 60, 50)`, T 0.35 | same red, T 0 |
| `HunterMobileJumpButton` | `BG`, `BG_TRANSPARENCY` | `#2D3741`, 0.5 | `#131415`, 0 |
| `HunterMobileReloadButton` | `BG`, `BG_TRANSPARENCY` | `#2D3741`, 0.5 | `#131415`, 0 |
| `HunterMobileSprintButton` | `INACTIVE_BG`, `INACTIVE_BG_TRANSPARENCY` (+ check `ACTIVE_BG`) | `#2D3741`, 0.5 | `#131415`, 0 |
| `VesperScopeController` / `VesperScopeGui` | authored face + strokes | `#282828`, 0.5, one 0.02 Border stroke | `#131415`, 0, 2 px Contextual ring T 0.45 + second 2 px ring — **note** 2 px here is an authored pixel stroke on a button that is resized by `HunterMobileClusterLayout`; prefer the fraction the other four use |

Also set the same values on the authored instances so an edit-mode screenshot matches. Do not touch
`Size`, `Position`, `UISizeConstraint`, `UIAspectRatioConstraint` or `Icon.Size` — the layout
module owns them (mobile-button-layout memory) and §5.1 freezes them. The SCOPE ring: express it as
the same fraction the other four buttons' strokes use, not the design's 2 px, so it scales with the
button on tablets.

---

## 7. Jump effect and landing bounce (owner request, 2026-09-13)

**What exists.** `LandingImpactClient` owns the gate (`Freefall` or `Jumping` → later `Landed`)
and on landing runs a camera kick plus `HunterHudShake.Play`: the HUD `Canvas` bobs down/up
(BOB 0.007 of the ScreenGui, 0.26 s, squared decay) and every cluster button dips to 0.96 on its
authored `BreatheScale` and settles Back/Out. So a landing bounce exists but was tuned to be nearly
subliminal (0.012 read as too loud in a playtest).

**Proposal.**

1. **Jump** — new `HunterHudShake.Jump(playerGui)`, called from `LandingImpactClient` when the
   state becomes `Jumping` (not `Freefall`: stepping off a ledge is not a jump). Motion: the three
   target groups below stretch to ~1.04 on their `ImpactScale` over ~0.12 s and settle Back/Out over
   ~0.2 s. **No canvas motion on takeoff** (D10) and no button motion — the thumb is on the button.
2. **Land** — keep `Play` as the base (canvas bob + button dip), add a squash on the same targets
   (`ImpactScale` 0.94 → Back/Out to 1) and let the owner raise `BOB` if the bounce should read
   louder. Bunny-hop restarts the motion rather than stacking (existing `activeId` pattern).
3. **Targets (D10)** — author `ImpactScale` UIScales, in both templates and Frostbite, on:
   `PlayerFrame.PlayerHunterFrame` (portrait + `ModernAccent`); `WeaponFrame` itself (so
   `ModernWeaponPanel`, `AmmoCount`, `BulletCounter` and `GunDisplayImage` move as one — they are
   siblings, not children of the panel); and the tile **holders** `AbilityFrame.1Ability`,
   `AbilityFrame.2Ability` and `UltimateFrame` — never `MainFrame`, which owns `BumpScale` (only one
   UIScale per object applies). Never `Canvas` (§5 rule).
   *Touch hazard:* `HunterMobileSprintButton` positions the ability row off measured tile and tag
   rects, and `HunterIntroTags` sizes tags off tile `AbsoluteSize` — both include ancestor UIScales,
   so a 6 % squash on the holders can make the row step or the tags flicker for ~0.3 s. Verify on a
   phone in the first playtest; if it steps, exclude the tile holders on touch (`TouchEnabled`
   branch) and keep them on desktop.
4. **Fortuna's double jump** — verify whether her air jump raises `Humanoid` `Jumping`; if not,
   `CardsClient` calls `Jump` itself (it already owns her touch-jump subscription).
5. **Constraints** — cluster button scales must stay inside the 0.38 s window before
   `TutorialClient` re-arms a cancelled breathe; positions of cluster buttons are never written
   (`HunterMobileClusterLayout` owns both axes). Absent HUD (kill cam, intermission) is a no-op.
6. **Tuning** — amplitudes are guesses; the owner tunes them in a live playtest
   (iterate-against-live-playtest memory). Record the final numbers in the module header, once.

Files: `HunterHudShake` (new `Jump`, second surface), `LandingImpactClient` (hook), both HUD
templates (five authored UIScales each), possibly `CardsClient`. Vault: `HunterHudShake.md`,
`LandingImpactClient.md`.

---

## 8. Order of work

| Phase | Work | Gate |
|---|---|---|
| 0 | Owner answers D1–D12 | — |
| 1 | Quick wins, each with a device matrix: §6.5 RoundStatus, §6.3 BountyList, §6.4 Domination flat-black, §6.6 button constants (both places) | screenshots at the four presets |
| 2 | §4 desktop HUD restyle on `ReworkedHunterGui.ScreenGui` (Redwater), paint-line constants | **owner sign-off on the visual** |
| 3 | §5 mobile twin on `HunterGuiMobile` | §4.7 step-5 zero-delta assertion passes; §5.2 before/after proof equal at five presets; one matrix; **one** owner phone look |
| 4 | §7 jump / land | live playtest tune |
| 5 | §6.1 KilledBy into the kill cam; §6.2 objective line in EyeCandy | owner wording sign-off |
| 6 | Frostbite: re-run the restyle script; `/mirror`; vault `.md` updates; `python update_redwater_canyon_graph.py`; UI_STYLE_GUIDE additions; `/changelog` by hand for the `execute_luau` edits; `/preflight`; publish all three places together | — |

Vault files that will need their "What it does" or Connections updated (all exist today):
`Hunters/Shared/HunterHudShake.md`, `HunterHudCooldown.md`, `HunterHudBump.md`, `UltimateReadyFX.md`,
`HunterIntroTags.md`, `HunterMobileSprintButton.md`; `StarterPlayerScripts/LandingImpactClient.md`,
`KillCamClient.md`, `HunterPortraitClient.md`, `Dust/HunterGuiClient.md`,
`Fortuna/CardsHunterGuiClient.md`, `Vesper/VesperHunterGuiClient.md`, `Bram/BramHunterGuiClient.md`;
`StarterGui/DominationGui/DominationClient.md`, `EyeCandy/AnnouncementController.md`,
`BountyListGui/BountyListClient.md`, `StarterPlayerScripts/DominationAudioClient.md` (gains the
`AnnouncementEvent` bindable connection if it emits the objective line). New `.md` only if a
genuinely new script appears (a `DominationAnnounceClient`). No wikilinks for structure-matching or
attribute reads.

UI_STYLE_GUIDE additions: the Modern palette as a token block in §2 (slate/yellow/pink/text) with
the rule for where it applies (match HUD, EyeCandy announcement, level card) and where it does not
(lobby panels stay brown/gold); D4's stroke exception in §10; `KillCamGui` and any new announcer
GUI in the §7 registry; a pointer from §5 to the §3 shape contract in this file.

---

## 9. Do-not-port list

- `Enabled` / `Visible` preview states on every design GUI (§1).
- `In-gameGui` ScreenGui properties: `DisplayOrder 20`, `DeviceSafeInsets`, `VisualStyle` /
  `ModernReworkVersion` attributes, the placeholder rig in the viewport, and
  `PlayerFrame.PersistentXPBar` / `PlayerLevel` (D5).
- `AnnouncerGui` as an instance — only its label style is copied into `EyeCandy.Canvas` (D9).
- The design's stale `StunnedGui`, `DominationGui` (unless D7), and mobile-button instance copies
  (`MobileHunterHudCompanion` attribute).
- The design place itself is never edited, published or mirrored (ui-design-place memory).
