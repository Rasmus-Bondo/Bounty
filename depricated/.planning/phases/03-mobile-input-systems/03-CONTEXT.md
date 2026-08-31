# Phase 3: Mobile & Input Systems - Context

**Gathered:** 2026-03-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Cross-platform input handling and mobile optimization — implement touch controls with virtual joystick and action buttons, add sprint/crouch/stamina mechanics, ensure UI scales correctly across mobile devices, and optimize performance for mid-range mobile devices targeting 45-60 FPS.

Requirements: MOBI-01, MOBI-02, MOBI-03, MOV-01, MOV-02, MOV-03

</domain>

<decisions>
## Implementation Decisions

### Touch Control Layout
- **D-01:** Right side cluster placement — Shoot, reload, sprint, and crouch buttons clustered on right side of screen near thumb. Standard mobile FPS layout that's easy to reach without repositioning hand.
- **D-02:** Dedicated button per action — Separate visible buttons for each action (shoot, reload, sprint, crouch). Clear and discoverable, matches other FPS games. Requires ~200-250px of right-side screen space.
- **D-03:** Always visible buttons — Buttons stay at 100% opacity always. No fading or auto-hide. Prioritizes discoverability and ease of access over screen real estate.
- **D-04:** Standard 50x50px button size — Meets 44px minimum touch target recommendation from CLAUDE.md, comfortable for most hands. Standard mobile game button size.

### Virtual Joystick
- **D-05:** Roblox default joystick — Use Roblox's built-in mobile joystick. Free, maintained by Roblox, familiar to players. No custom ThumbstickController needed.
- **D-06:** Fixed bottom-left position — Joystick always appears in bottom-left corner. Predictable location players can rely on.
- **D-07:** Standard Roblox default sensitivity — Use Roblox's built-in joystick sensitivity without modification. Works for most games, familiar to Roblox players.
- **D-08:** Right-side swipe for camera — Swiping anywhere on right side of screen (outside action buttons) controls camera. Standard mobile FPS pattern. FirstPersonCamera already tracks input delta — extend to touch input.

### Performance Targets
- **D-09:** Mid-range device optimization — Target devices like iPhone 11, Samsung A-series from last 3 years. ~60% of Roblox mobile players. Balances quality and reach.
- **D-10:** 45-60 FPS target — Aim for smooth FPS experience on mid-range mobile. Matches most mobile shooters, feels responsive. May need to reduce particle counts compared to PC.
- **D-11:** Prioritize responsiveness — Reduce particles/effects if needed but keep input latency low and frame time consistent. Gunplay feels snappy even if visuals are simplified. Core value: "Gunplay feels satisfying."
- **D-12:** Adaptive particle quality — Detect device performance (via Stats.PerformanceStats) and reduce particle counts on lower-end devices. Allows best visuals on capable devices while maintaining performance on weaker ones.

### Sprint & Stamina Mechanics
- **D-13:** Hold to sprint — Player holds sprint button to run, releases to walk. Standard FPS control. Drains stamina while held.
- **D-14:** 5-7 seconds continuous sprint — Full stamina bar allows 5-7 seconds of sprinting. Enough to cross open areas but requires tactical timing. Balances mobility and stamina management.
- **D-15:** Gradual regen after delay — 2-second delay after stopping sprint, then stamina regenerates over 3-4 seconds. Standard FPS pattern. Rewards timing and positioning.
- **D-16:** Small stamina bar display — Thin bar near health/XP bars at bottom of screen. Visible but not intrusive. Should match existing HealthDisplayGui.Canvas bar pattern.

### Crouch Mechanics (MOV-02)
- **Implementation at Claude's discretion** — Crouch button in right-side cluster, reduces WalkSpeed and character height. Specific speed reduction (e.g., 50% of normal walk speed) and hitbox reduction approach determined during planning.

### Mobile UI Scaling (MOBI-02)
- **Implementation at Claude's discretion** — Add UISizeConstraint, UIAspectRatioConstraint to ensure UI elements scale correctly on different screen sizes. Test at multiple aspect ratios (16:9, 19.5:9, 4:3) per CLAUDE.md recommendations. Specific constraint values determined during implementation.

### Input Detection Strategy
- **Implementation at Claude's discretion** — Use UserInputService.TouchEnabled to detect mobile vs PC. Platform-specific UI adjustments (show touch buttons only on mobile). ContextActionService recommended by CLAUDE.md for touch button creation with automatic touch support.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Documents
- `.planning/PROJECT.md` — Project vision, mobile-first constraint, 72% of Roblox players on mobile
- `.planning/REQUIREMENTS.md` — MOBI-01, MOBI-02, MOBI-03, MOV-01, MOV-02, MOV-03 requirements for this phase
- `.planning/ROADMAP.md` — Phase 3 goals and success criteria
- `CLAUDE.md` — Input Handling section (UserInputService + ContextActionService pattern), Mobile section (touch targets, scaling, performance), Performance constraints

### Prior Phase Context
- `.planning/phases/01-foundation-architecture/01-CONTEXT.md` — Service ModuleScript architecture pattern
- `.planning/phases/02-combat-audio-polish/02-CONTEXT.md` — Performance considerations from audio/particle system

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **FirstPersonCamera** (game.StarterPlayer.StarterPlayerScripts.FirstPersonCamera): Already uses UserInputService (line 2) for mouse input. Currently tracks mouse delta for camera control — can be extended to handle touch input.
- **HealthDisplayGui.Canvas** (game.StarterGui.HealthDisplayGui.Canvas): Existing bottom-screen bar layout with HealthBar, XpBarDisplay. Pattern to follow for stamina bar placement.
- **StarterGui ScreenGuis**: 7 existing ScreenGuis (RoundStartGui, GameplayGui, RevolverGui, CurrencyGui, XPGui, InGameLeaderboard, HealthDisplayGui). None currently use UISizeConstraint or UIAspectRatioConstraint — need to add responsive scaling.

### Established Patterns
- **UserInputService usage**: FirstPersonCamera uses `UserInputService.InputChanged` for mouse tracking. Extend this pattern to detect TouchEnabled and handle touch input.
- **Service ModuleScript pattern**: From Phase 1 — create MovementService or InputService as ModuleScript under ServerScriptService.RoundSystem.Modules for sprint/crouch/stamina logic.
- **Attribute-based state**: Player state tracked via attributes (Phase 1 pattern) — use for stamina values.

### Integration Points
- **FirstPersonCamera**: Main camera script — add touch input handling for camera swipe, integrate with right-side touch detection
- **StarterGui**: Add new MobileControlsGui ScreenGui with action buttons (shoot, reload, sprint, crouch). Only visible when UserInputService.TouchEnabled is true.
- **HealthDisplayGui.Canvas**: Add stamina bar as new Frame sibling to existing bars
- **ServerScriptService.RoundSystem.Modules**: Create new MovementService for sprint/crouch/stamina server-side logic
- **Humanoid.WalkSpeed**: Modified by sprint (increase) and crouch (decrease) states

### Current Limitations
- No ContextActionService usage yet — CLAUDE.md recommends this for touch buttons with automatic touch support
- No touch control UI exists — need to create from scratch
- No UI scaling constraints — all UI is fixed size, won't adapt to different mobile screens
- No performance profiling or adaptive quality system — need to implement device detection

</code_context>

<specifics>
## Specific Ideas

- Stamina bar should be placed in HealthDisplayGui.Canvas near existing bars (HealthBar at Canvas.HealthBar, XPBar at Canvas.XpBarDisplay) for visual consistency
- Right-side button cluster should avoid overlapping with RevolverGui.Canvas (revolver wheel and bullet indicators at bottom-right) and CurrencyGui.Canvas (top-right)
- FirstPersonCamera's existing input handling (lines 1-50) shows UserInputService pattern — extend with TouchEnabled detection and touch input handling for camera swipe
- CLAUDE.md Input Handling section explicitly recommends ContextActionService for touch buttons: "BindAction with touch button support built in"
- Mobile-first constraint from PROJECT.md: "Large portion of Roblox players are on mobile — UI and controls must work well on touchscreens"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-mobile-input-systems*
*Context gathered: 2026-03-30*
