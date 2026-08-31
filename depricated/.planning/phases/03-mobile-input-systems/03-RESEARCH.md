# Phase 3: Mobile & Input Systems - Research

**Researched:** 2026-03-30
**Domain:** Cross-platform input handling, mobile optimization, movement mechanics (Roblox/Luau)
**Confidence:** HIGH

## Summary

Phase 3 implements touch controls, responsive UI scaling, mobile performance optimization, and sprint/crouch/stamina mechanics. The Roblox platform provides strong built-in support for all of these: ContextActionService creates touch buttons automatically, UISizeConstraint/UIAspectRatioConstraint handle responsive scaling, Stats service provides runtime performance metrics for adaptive quality, and Humanoid.WalkSpeed is the standard lever for sprint/crouch speed changes.

The critical architectural decision is splitting input concerns correctly: ContextActionService for action binding with automatic touch buttons (shoot, reload, sprint, crouch), Roblox's default thumbstick for movement (no custom code needed per D-05), and touch-swipe camera handling in the existing FirstPersonCamera script. Sprint/crouch/stamina must be server-authoritative to prevent exploits -- the client sends intent via RemoteEvents, the server validates and applies WalkSpeed changes.

**Primary recommendation:** Use ContextActionService.BindAction with createTouchButton=true for all action buttons, keep movement on Roblox's default joystick, implement sprint/crouch as a server-side MovementService following the established ModuleScript pattern, and use Stats.FrameTime for adaptive particle quality.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Right side cluster placement for touch buttons (shoot, reload, sprint, crouch)
- **D-02:** Dedicated visible button per action -- separate buttons, not gestures or combos
- **D-03:** Always visible buttons at 100% opacity, no fading or auto-hide
- **D-04:** Standard 50x50px button size (meets 44px minimum)
- **D-05:** Use Roblox default joystick for movement (no custom ThumbstickController)
- **D-06:** Fixed bottom-left joystick position
- **D-07:** Standard Roblox default joystick sensitivity
- **D-08:** Right-side swipe for camera control (outside action buttons)
- **D-09:** Target mid-range devices (iPhone 11, Samsung A-series last 3 years)
- **D-10:** 45-60 FPS target on mid-range mobile
- **D-11:** Prioritize input responsiveness over visual quality
- **D-12:** Adaptive particle quality using Stats.PerformanceStats
- **D-13:** Hold to sprint (drains stamina while held)
- **D-14:** 5-7 seconds continuous sprint at full stamina
- **D-15:** Gradual regen after 2-second delay, regenerates over 3-4 seconds
- **D-16:** Small stamina bar near health/XP bars, matching HealthDisplayGui.Canvas pattern

### Claude's Discretion
- Crouch implementation: button in right cluster, reduces WalkSpeed and character height. Speed reduction percentage and hitbox approach at discretion.
- Mobile UI scaling: UISizeConstraint and UIAspectRatioConstraint values and where to apply them.
- Input detection strategy: How to detect mobile vs PC, when to show/hide touch controls.

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOBI-01 | Touch controls -- virtual joystick for movement, dedicated buttons for shoot, reload, sprint, crouch | ContextActionService.BindAction with createTouchButton=true for actions; Roblox default joystick for movement (D-05) |
| MOBI-02 | UI scales correctly on all mobile screen sizes and aspect ratios | UISizeConstraint (MinSize/MaxSize in pixels), UIAspectRatioConstraint, GuiService.ViewportDisplaySize for detection |
| MOBI-03 | Game runs at acceptable frame rate on mid-range mobile devices | Stats.FrameTime for FPS monitoring, adaptive particle reduction, draw call awareness |
| MOV-01 | Player can sprint with increased speed via sprint key/button | Server-side MovementService modifying Humanoid.WalkSpeed, ContextActionService binding for sprint key + touch button |
| MOV-02 | Player can crouch with reduced speed and smaller hitbox | WalkSpeed reduction + HipHeight/CameraOffset adjustment or scale-based approach |
| MOV-03 | Stamina system -- sprinting drains stamina, regenerates when not sprinting | Server-authoritative stamina tracking via player attributes, client UI reads attribute for stamina bar |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Platform**: All code is Luau in Roblox Studio data model -- no filesystem writes
- **MCP Tools Required**: All code changes via mcp__robloxstudio__* tools (create_object, set_script_source, etc.)
- **No Git**: Code lives in Roblox Studio only; planning artifacts on disk but not committed
- **Input**: UserInputService + ContextActionService (CLAUDE.md recommended stack)
- **UI**: Traditional ScreenGui/Frame hierarchy, no Roact/React-lua
- **Touch targets**: Minimum 44x44 pixels per CLAUDE.md
- **Scaling**: UISizeConstraint, UIAspectRatioConstraint for responsive scaling
- **Mobile detection**: UserInputService.TouchEnabled
- **Combat authority**: Server validates all state changes (sprint/crouch included)
- **RemoteEvent pattern**: Fire-and-forget for client intent, server applies changes

## Standard Stack

### Core (Roblox Built-in Services)
| Service | Purpose | Why Standard |
|---------|---------|--------------|
| ContextActionService | Bind actions to input + auto-create touch buttons | CLAUDE.md recommended; BindAction with createTouchButton handles mobile automatically |
| UserInputService | Detect platform (TouchEnabled), raw input events for camera swipe | CLAUDE.md recommended; already used by FirstPersonCamera |
| GuiService | ViewportDisplaySize for screen size detection | Official way to detect display dimensions for responsive UI |
| Stats | FrameTime for FPS monitoring, adaptive quality decisions | Only reliable way to measure runtime performance |
| Humanoid | WalkSpeed for sprint/crouch, HipHeight/CameraOffset for crouch visual | Standard Roblox character movement API |

### Supporting (Existing Project Patterns)
| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| ModuleScript service (under RoundSystem.Modules) | Server-side MovementService for sprint/crouch/stamina | All server logic follows this established Phase 1 pattern |
| Player attributes | Store stamina value, sprint/crouch state per player | Phase 1 established attribute-based state pattern |
| RemoteEvent (via Events folder) | Client sends sprint/crouch intent, server applies | Phase 1 consolidated events pattern |
| ScreenGui + Frame hierarchy | MobileControlsGui for touch buttons, StaminaBar in HealthDisplayGui | CLAUDE.md UI approach |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ContextActionService touch buttons | Custom ImageButtons in ScreenGui | ContextActionService is simpler, auto-handles touch, but less visual control. Decision D-02/D-03 want always-visible dedicated buttons -- ContextActionService buttons may need customization via SetPosition/SetImage/GetButton OR custom ScreenGui buttons may be better for full layout control |
| Roblox default joystick | Custom thumbstick controller | D-05 locks this -- use default, no custom needed |
| HipHeight for crouch | BodyHeightScale value change | HipHeight is simpler, BodyHeightScale changes actual collision but requires AutomaticScalingEnabled |

## Architecture Patterns

### Recommended Structure (Roblox Instance Hierarchy)
```
game.ServerScriptService.RoundSystem.Modules
  MovementService (ModuleScript)     -- sprint/crouch/stamina server logic

game.ReplicatedStorage.Events
  MovementEvents (Folder)
    SprintEvent (RemoteEvent)        -- client -> server sprint toggle
    CrouchEvent (RemoteEvent)        -- client -> server crouch toggle

game.StarterGui
  MobileControlsGui (ScreenGui)      -- touch action buttons (mobile only)
    ActionFrame (Frame)              -- right-side container
      ShootButton (ImageButton)
      ReloadButton (ImageButton)
      SprintButton (ImageButton)
      CrouchButton (ImageButton)
  HealthDisplayGui.Canvas
    StaminaBar (Frame)               -- thin bar near health/XP bars

game.StarterPlayer.StarterPlayerScripts
  InputController (LocalScript)      -- binds all input, creates touch buttons
  FirstPersonCamera (LocalScript)    -- EXISTING: extend with touch swipe
```

### Pattern 1: ContextActionService Touch Buttons
**What:** Use BindAction to simultaneously bind keyboard keys and create touch buttons
**When to use:** For all game actions that need both keyboard and touch support
**Example:**
```lua
-- Source: Roblox ContextActionService official docs
local ContextActionService = game:GetService("ContextActionService")

local function onSprint(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        -- Fire sprint start to server
    elseif inputState == Enum.UserInputState.End then
        -- Fire sprint stop to server
    end
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("Sprint", onSprint, true, Enum.KeyCode.LeftShift)
-- Third param `true` auto-creates touch button on mobile

-- Customize the touch button
ContextActionService:SetPosition("Sprint", UDim2.new(1, -70, 1, -180))
ContextActionService:SetImage("Sprint", "rbxassetid://SPRINT_ICON_ID")
```

### Pattern 2: Custom Touch Button GUI (Preferred for This Project)
**What:** Create a dedicated ScreenGui with ImageButtons for full layout control
**When to use:** When you need always-visible buttons with precise positioning (D-03 requires 100% opacity always)
**Why preferred:** ContextActionService auto-created buttons are designed to appear in a standard frame and may not give full control over always-visible behavior and exact right-side cluster layout. Custom buttons give complete control.
**Example:**
```lua
-- LocalScript in StarterPlayerScripts or StarterGui
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled

if isMobile then
    local gui = playerGui:WaitForChild("MobileControlsGui")
    gui.Enabled = true

    local sprintBtn = gui.ActionFrame.SprintButton
    sprintBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            -- Fire sprint start
        end
    end)
    sprintBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            -- Fire sprint stop
        end
    end)
end
```

### Pattern 3: Server-Authoritative Movement State
**What:** Client sends intent, server validates and applies WalkSpeed changes
**When to use:** All movement state changes (sprint, crouch) to prevent exploits
**Example:**
```lua
-- MovementService (server ModuleScript)
local WALK_SPEED = 16
local SPRINT_SPEED = 24
local CROUCH_SPEED = 8

local function onSprintRequest(player, isSprinting)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local stamina = player:GetAttribute("Stamina") or 100
    if isSprinting and stamina > 0 then
        player:SetAttribute("IsSprinting", true)
        humanoid.WalkSpeed = SPRINT_SPEED
    else
        player:SetAttribute("IsSprinting", false)
        humanoid.WalkSpeed = WALK_SPEED
    end
end
```

### Pattern 4: Stamina Tick System
**What:** Server-side heartbeat loop drains/regenerates stamina via attributes
**When to use:** Continuous stamina drain during sprint, regen after delay
**Example:**
```lua
-- Inside MovementService, connected to RunService.Heartbeat
local MAX_STAMINA = 100
local DRAIN_RATE = 100 / 6  -- ~6 seconds to drain (D-14: 5-7 seconds)
local REGEN_RATE = 100 / 3.5  -- ~3.5 seconds to regen (D-15)
local REGEN_DELAY = 2  -- seconds after sprint stops (D-15)

RunService.Heartbeat:Connect(function(dt)
    for _, player in Players:GetPlayers() do
        local stamina = player:GetAttribute("Stamina") or MAX_STAMINA
        local isSprinting = player:GetAttribute("IsSprinting")
        local lastSprintStop = player:GetAttribute("LastSprintStop") or 0

        if isSprinting then
            stamina = math.max(0, stamina - DRAIN_RATE * dt)
            if stamina <= 0 then
                -- Force stop sprint
                stopSprint(player)
            end
        else
            local now = workspace:GetServerTimeNow()
            if now - lastSprintStop >= REGEN_DELAY then
                stamina = math.min(MAX_STAMINA, stamina + REGEN_RATE * dt)
            end
        end
        player:SetAttribute("Stamina", stamina)
    end
end)
```

### Pattern 5: Crouch with HipHeight + CameraOffset
**What:** Lower the character visually and adjust camera for crouch
**When to use:** Crouch toggle that affects movement speed and perceived height
**Recommendation (Claude's Discretion):**
```lua
-- Crouch: reduce WalkSpeed to 50% of normal, lower camera
local CROUCH_SPEED = 8  -- 50% of 16
local CROUCH_HIP_OFFSET = -1.5  -- lower character by 1.5 studs

-- Server applies:
humanoid.WalkSpeed = CROUCH_SPEED

-- Client applies (via attribute change listener):
humanoid.CameraOffset = Vector3.new(0, CROUCH_HIP_OFFSET, 0)
```
**Note on hitbox reduction:** True hitbox reduction in Roblox requires either (a) scaling BodyHeightScale which changes the actual collision geometry, or (b) accepting that crouch is cosmetic-only for hitbox. Recommendation: use BodyHeightScale reduction (e.g., 0.7) with AutomaticScalingEnabled for actual hitbox change, combined with CameraOffset so the first-person view matches. This is more honest than cosmetic-only crouch.

### Pattern 6: Adaptive Quality System
**What:** Monitor FPS via Stats.FrameTime and reduce particle counts on low-end devices
**When to use:** MOBI-03 performance optimization
**Example:**
```lua
-- Client LocalScript
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")

local SAMPLE_INTERVAL = 5  -- check every 5 seconds
local LOW_FPS_THRESHOLD = 40
local qualityLevel = "high"  -- "high", "medium", "low"

local frameCount = 0
local elapsed = 0

RunService.RenderStepped:Connect(function(dt)
    frameCount += 1
    elapsed += dt
    if elapsed >= SAMPLE_INTERVAL then
        local avgFPS = frameCount / elapsed
        if avgFPS < LOW_FPS_THRESHOLD then
            qualityLevel = "low"
        elseif avgFPS < 50 then
            qualityLevel = "medium"
        else
            qualityLevel = "high"
        end
        frameCount = 0
        elapsed = 0
    end
end)
```

### Anti-Patterns to Avoid
- **Client-authoritative WalkSpeed:** Never let the client set WalkSpeed directly -- exploiters will set it to 100. Server must own WalkSpeed changes.
- **Polling TouchEnabled every frame:** Check UserInputService.TouchEnabled once at startup or listen to LastInputTypeChanged. It does not change during a session.
- **Fixed-pixel UI without constraints:** UI elements without UISizeConstraint/UIAspectRatioConstraint will look wrong on different screen sizes. Always constrain.
- **Touch buttons overlapping game UI:** CONTEXT.md notes RevolverGui.Canvas is at bottom-right and CurrencyGui.Canvas is at top-right. Touch buttons must avoid these areas.
- **Stamina on client only:** Client-only stamina is trivially hackable. Server must track and enforce stamina values.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mobile joystick | Custom thumbstick controller | Roblox default joystick (D-05) | Maintained by Roblox, familiar to players, zero code |
| Touch button auto-creation | Manual platform detection + button toggle | ContextActionService createTouchButton OR custom ScreenGui with TouchEnabled check | Built-in platform detection |
| FPS measurement | Manual frame counting | Stats.FrameTime (1/FrameTime = FPS) | Engine-level accuracy, no overhead |
| Screen size detection | Camera.ViewportSize guessing | GuiService.ViewportDisplaySize | Official API, fires change signals |
| Input type detection | Checking multiple input properties | UserInputService.TouchEnabled + LastInputTypeChanged | Single source of truth |

## Common Pitfalls

### Pitfall 1: ContextActionService Button Positioning Conflicts
**What goes wrong:** Auto-created touch buttons from ContextActionService pile up in the default ContextButtonFrame, overlapping each other and existing UI.
**Why it happens:** ContextActionService places buttons in a vertical stack by default. Multiple bindings create stacked buttons.
**How to avoid:** Either (a) use SetPosition on each button to place them precisely in the right-side cluster, or (b) use custom ScreenGui buttons instead of ContextActionService auto-buttons. Given D-01 through D-04 requirements (right cluster, always visible, 50x50), custom buttons with ContextActionService for keyboard bindings (createTouchButton=false) may be cleaner.
**Warning signs:** Buttons appearing in wrong positions, overlapping the revolver UI.

### Pitfall 2: Sprint Desync Between Client and Server
**What goes wrong:** Player appears to sprint on their screen but server has normal speed, or vice versa.
**Why it happens:** Network latency between client input and server state change. Client may predict sprint visually while server hasn't confirmed.
**How to avoid:** Client predicts WalkSpeed change immediately for responsiveness (D-11), server confirms/corrects. Use attribute change listeners so client stays synced with server state.
**Warning signs:** Player rubber-banding when starting/stopping sprint.

### Pitfall 3: Crouch Not Affecting Raycasts
**What goes wrong:** Player crouches visually but enemy raycasts still hit at standing height.
**Why it happens:** CameraOffset is cosmetic only -- it does not move the actual character collision geometry. Raycasts hit the HumanoidRootPart which hasn't moved.
**How to avoid:** Use BodyHeightScale to actually shrink the character, or adjust HipHeight to lower the root part. CameraOffset alone is insufficient for gameplay-affecting crouch.
**Warning signs:** Players getting shot while crouched behind cover that should protect them.

### Pitfall 4: Stamina Bar Not Updating Smoothly
**What goes wrong:** Stamina bar jumps in steps instead of smooth drain/regen.
**Why it happens:** Attribute replication has network delay. If bar reads attribute directly, it updates at network tick rate, not render rate.
**How to avoid:** Client-side interpolation. Read the attribute value but tween/lerp the visual bar toward it every frame using RenderStepped.
**Warning signs:** Jerky stamina bar movement, especially on higher-latency connections.

### Pitfall 5: Touch Swipe Conflicts with UI Buttons
**What goes wrong:** Swiping to look around triggers button presses, or touching buttons causes camera movement.
**Why it happens:** Touch input events fire for both UI elements and the game world. Without proper input sinking, both respond.
**How to avoid:** Use GuiButton.InputBegan (which sinks the input) for buttons. For camera swipe, check that the touch did NOT start on a GUI element (use gameProcessedEvent parameter in UserInputService events).
**Warning signs:** Camera jumps when pressing buttons, buttons activating when swiping.

### Pitfall 6: UI Scaling Breaks on Notched Phones
**What goes wrong:** UI elements hidden behind notch/dynamic island on newer phones.
**Why it happens:** ScreenGui.IgnoreGuiInset = true removes the safe area inset. Without it, Roblox respects safe areas.
**How to avoid:** For full-screen backgrounds, use IgnoreGuiInset = true. For interactive elements (buttons, HUD), use IgnoreGuiInset = false (default) so Roblox keeps them in safe areas. MobileControlsGui should use IgnoreGuiInset = false.
**Warning signs:** Buttons unreachable on phones with notches or rounded corners.

## Code Examples

### Responsive UI Scaling with Constraints
```lua
-- Source: Roblox UIAspectRatioConstraint / UISizeConstraint docs
-- Apply to each action button in MobileControlsGui

-- Frame setup for a touch button
local button = Instance.new("ImageButton")
button.Size = UDim2.new(0, 50, 0, 50)  -- D-04: 50x50px base
button.AnchorPoint = Vector2.new(1, 1)
button.BackgroundTransparency = 0  -- D-03: always visible

-- Keep button square on all screens
local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = 1  -- 1:1 square
aspectRatio.Parent = button

-- Prevent button from getting too small on tiny screens
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(44, 44)  -- CLAUDE.md minimum
sizeConstraint.MaxSize = Vector2.new(70, 70)  -- cap on large screens
sizeConstraint.Parent = button
```

### Platform-Conditional UI Visibility
```lua
-- Source: Roblox UserInputService docs
local UserInputService = game:GetService("UserInputService")

local isMobile = UserInputService.TouchEnabled

-- Show touch controls only on mobile
local mobileGui = playerGui:WaitForChild("MobileControlsGui")
mobileGui.Enabled = isMobile

-- Keyboard bindings always active (ContextActionService handles both)
local ContextActionService = game:GetService("ContextActionService")
ContextActionService:BindAction("Sprint", onSprint, false, Enum.KeyCode.LeftShift)
ContextActionService:BindAction("Crouch", onCrouch, false, Enum.KeyCode.LeftControl)
-- createTouchButton = false because we use custom GUI buttons on mobile
```

### Stamina Bar UI (Client)
```lua
-- Source: Pattern matching HealthDisplayGui.Canvas from existing codebase
-- Reads Stamina attribute, interpolates visually

local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local staminaBar = healthDisplayGui.Canvas.StaminaBar  -- Frame
local staminaFill = staminaBar.Fill  -- inner Frame

local displayedStamina = 100

RunService.RenderStepped:Connect(function(dt)
    local targetStamina = player:GetAttribute("Stamina") or 100
    -- Smooth interpolation
    displayedStamina = displayedStamina + (targetStamina - displayedStamina) * math.min(1, dt * 10)
    staminaFill.Size = UDim2.new(displayedStamina / 100, 0, 1, 0)
end)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mouse object for input | UserInputService | Deprecated years ago | Mouse object should never be used (CLAUDE.md) |
| BodyVelocity for movement | VectorForce / LinearVelocity | Deprecated | Not relevant here (using Humanoid.WalkSpeed) |
| Camera.ViewportSize for screen detection | GuiService.ViewportDisplaySize | Recent addition | More reliable, includes display size enum |
| Manual touch detection | UserInputService.PreferredInput | Recent | Better cross-platform detection than individual flags |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Roblox Studio manual playtesting (no automated test framework in project) |
| Config file | None -- Roblox projects use in-Studio testing |
| Quick run command | Play Solo in Roblox Studio + Device Emulator |
| Full suite command | Playtest on actual mobile device or Studio Device Emulator |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MOBI-01 | Touch controls work -- joystick moves, buttons fire/reload/sprint/crouch | manual | Studio Device Emulator: test each button | N/A |
| MOBI-02 | UI scales on all screen sizes | manual | Studio Device Emulator: test 16:9, 19.5:9, 4:3 aspect ratios | N/A |
| MOBI-03 | Acceptable FPS on mid-range mobile | manual | Stats.FrameTime monitoring + real device test | N/A |
| MOV-01 | Sprint increases speed | manual | Play Solo: hold Shift, verify speed increase | N/A |
| MOV-02 | Crouch reduces speed + height | manual | Play Solo: press Ctrl, verify speed/height change | N/A |
| MOV-03 | Stamina drains during sprint, regens after delay | manual | Play Solo: sprint until empty, verify drain rate and regen timing | N/A |

### Sampling Rate
- **Per task:** Play Solo quick test in Studio
- **Per wave:** Device Emulator test at multiple aspect ratios
- **Phase gate:** Full playtest on actual mobile device if available, otherwise Device Emulator at 3 aspect ratios

### Wave 0 Gaps
None -- Roblox projects use manual playtesting. No test framework to set up.

## Open Questions

1. **ContextActionService vs Custom GUI for Touch Buttons**
   - What we know: ContextActionService auto-creates touch buttons (convenient), but they stack in a default frame. Custom ScreenGui gives full layout control.
   - What's unclear: Whether ContextActionService's SetPosition is reliable enough for precise right-side cluster layout, or if custom buttons are needed.
   - Recommendation: Use hybrid approach -- custom ScreenGui for visual buttons (full control over layout, opacity, size per D-01 through D-04), ContextActionService for keyboard bindings only (createTouchButton=false). Custom buttons fire the same RemoteEvents. This gives best of both worlds.

2. **Crouch Hitbox Implementation**
   - What we know: CameraOffset is cosmetic only. BodyHeightScale with AutomaticScalingEnabled changes actual collision. HipHeight lowers root part position.
   - What's unclear: Whether BodyHeightScale change causes visual glitches with the gun viewmodel/IK arms from Phase 2.
   - Recommendation: Start with HipHeight reduction (lowers entire character) + CameraOffset. If hitbox needs to actually shrink, add BodyHeightScale. Test for visual artifacts with IK system.

3. **Existing GUI Overlap Avoidance**
   - What we know: RevolverGui.Canvas is bottom-right (ammo wheel), CurrencyGui.Canvas is top-right.
   - What's unclear: Exact pixel positions of these elements without Studio access.
   - Recommendation: Executor must inspect existing GUI positions via MCP tools before placing touch buttons. Buttons should be in the right-center area, above the revolver UI and below currency UI.

## Sources

### Primary (HIGH confidence)
- Roblox ContextActionService docs -- BindAction, createTouchButton, SetPosition, SetImage, GetButton APIs
- Roblox UserInputService docs -- TouchEnabled, PreferredInput, InputBegan/Changed/Ended
- Roblox Humanoid docs -- WalkSpeed, HipHeight, CameraOffset, AutomaticScalingEnabled
- Roblox Stats docs -- FrameTime, RenderGPUFrameTime for performance monitoring
- Roblox UIAspectRatioConstraint docs -- AspectRatio, AspectType, DominantAxis
- Roblox UISizeConstraint docs -- MinSize, MaxSize pixel constraints
- Roblox GuiService docs -- ViewportDisplaySize for screen size detection
- Roblox StarterPlayer docs -- DevTouchMovementMode, CharacterWalkSpeed

### Secondary (MEDIUM confidence)
- Roblox mobile input docs -- device orientation, haptic feedback, touch gesture support
- Roblox performance optimization docs -- general FPS monitoring and optimization guidance

### Tertiary (LOW confidence)
- Crouch via BodyHeightScale approach -- documented API but untested with IK arms system; may need runtime validation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all APIs are core Roblox services, well-documented
- Architecture: HIGH -- follows established Phase 1 ModuleScript pattern, standard Roblox input/UI patterns
- Pitfalls: HIGH -- common Roblox mobile development issues documented across multiple sources
- Crouch hitbox: MEDIUM -- multiple approaches exist, interaction with Phase 2 IK system untested

**Research date:** 2026-03-30
**Valid until:** 2026-04-30 (Roblox APIs are stable, 30-day window is conservative)
