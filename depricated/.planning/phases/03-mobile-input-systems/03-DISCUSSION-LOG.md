# Phase 3: Mobile & Input Systems - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-30
**Phase:** 03-mobile-input-systems
**Areas discussed:** Touch control layout, Virtual joystick approach, Performance targets, Sprint & stamina mechanics

---

## Touch Control Layout

### Question 1: Button Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Right side cluster (Recommended) | Shoot, reload, sprint, crouch buttons clustered on right side near thumb. Standard FPS mobile layout. Easy to reach without repositioning hand. | ✓ |
| Split layout | Movement actions (sprint/crouch) on left near joystick, combat actions (shoot/reload) on right. Reduces right-hand crowding but requires both thumbs to move. | |
| Bottom bar | All action buttons in a bottom toolbar. Clean layout but harder to reach during movement. | |

**User's choice:** Right side cluster (Recommended)

### Question 2: Action Button Design

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated button per action (Recommended) | Separate visible buttons for shoot, reload, sprint, crouch. Clear and discoverable, matches other FPS games. Requires ~200-250px of right-side screen space. | ✓ |
| Context-sensitive button | Single button that changes function (becomes 'reload' when empty, 'sprint' when moving). Saves space but less discoverable. | |
| Tap zones | Right side tap for shoot, swipe for reload, double-tap for sprint. Minimal UI but requires learning gestures. | |

**User's choice:** Dedicated button per action (Recommended)

### Question 3: Button Visibility

| Option | Description | Selected |
|--------|-------------|----------|
| Always visible | Buttons stay at 100% opacity always. Easier to find but uses more screen space. Good for new players. | ✓ |
| Fade to 30% when idle (Recommended) | Buttons fade to 30% opacity after 3 seconds of no touch input, return to full opacity on touch. Reduces clutter while keeping buttons visible. | |
| Auto-hide completely | Buttons disappear after idle period, reappear on screen tap. Maximum visibility for gameplay but buttons can be hard to find in combat. | |

**User's choice:** Always visible

### Question 4: Button Size

| Option | Description | Selected |
|--------|-------------|----------|
| Standard 50x50px (Recommended) | Meets 44px minimum touch target, comfortable for most hands. Standard mobile game button size. | ✓ |
| Large 70x70px | Easier to hit, better for younger players or smaller devices. Uses more screen space, may overlap with HUD elements. | |
| Compact 44x44px | Minimum recommended size. Maximizes screen space for gameplay but harder to hit accurately during combat. | |

**User's choice:** Standard 50x50px (Recommended)

---

## Virtual Joystick Approach

### Question 1: Joystick Implementation

| Option | Description | Selected |
|--------|-------------|----------|
| Roblox default (Recommended) | Built-in mobile joystick provided by Roblox. Free, maintained by Roblox, familiar to players. Limited customization but proven to work. | ✓ |
| Custom ThumbstickController | Build custom joystick using UserInputService.TouchEnabled detection. Full control over appearance and behavior but requires testing across devices. | |
| Hybrid approach | Roblox default for movement, custom overlay for visual styling. Best of both worlds but more complex. | |

**User's choice:** Roblox default (Recommended)

### Question 2: Joystick Position

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed bottom-left (Recommended) | Joystick always appears in bottom-left corner. Predictable, players know where to reach. May be awkward for left-handed players. | ✓ |
| Dynamic (appears at touch) | Joystick appears wherever player's thumb first touches left side of screen. Comfortable for any hand position but can appear in unexpected locations. | |
| You decide | Claude picks the approach that works best with Roblox's default joystick system. | |

**User's choice:** Fixed bottom-left (Recommended)

### Question 3: Joystick Sensitivity

| Option | Description | Selected |
|--------|-------------|----------|
| Standard Roblox defaults | Use Roblox's built-in joystick sensitivity without modification. Works for most games, familiar to Roblox players. | ✓ |
| Fast (higher sensitivity) | Increase sensitivity for faster movement response. Better for experienced FPS players but can feel twitchy for new players. | |
| User-adjustable in settings | Add sensitivity slider in settings menu. Best UX but requires building settings UI (Phase 4 or later). | |

**User's choice:** Standard Roblox defaults

### Question 4: Camera Control

| Option | Description | Selected |
|--------|-------------|----------|
| Right-side swipe (Recommended) | Swiping anywhere on right side of screen (outside action buttons) controls camera. Standard mobile FPS pattern. FirstPersonCamera already tracks mouse delta - extend to touch. | ✓ |
| Dedicated camera area | Specific region for camera control, rest of right side reserved for buttons. Prevents accidental camera movement but limits usable area. | |
| You decide | Claude picks based on how FirstPersonCamera is structured and button layout. | |

**User's choice:** Right-side swipe (Recommended)

---

## Performance Targets

### Question 1: Target Device Tier

| Option | Description | Selected |
|--------|-------------|----------|
| Mid-range devices (Recommended) | Target devices like iPhone 11, Samsung A-series from last 3 years. ~60% of Roblox mobile players. Balances quality and reach. | ✓ |
| Low-end devices | Target older/budget devices (iPhone 8, low-end Androids). Maximum reach but requires aggressive optimization, visual compromises. | |
| High-end devices | Target latest devices (iPhone 15+, flagship Androids). Best visuals but excludes many players. Good for premium experiences. | |

**User's choice:** Mid-range devices (Recommended)

### Question 2: Target Frame Rate

| Option | Description | Selected |
|--------|-------------|----------|
| 30 FPS stable | Conservative target, very achievable. Acceptable for most mobile games. Allows more visual features and particles. | |
| 45-60 FPS (Recommended) | Smooth FPS experience, matches most mobile shooters. Requires careful optimization but feels responsive. May need to reduce particle counts. | ✓ |
| 60 FPS locked | Premium feel, matches PC experience. Challenging on mid-range devices, requires aggressive LOD and effect culling. | |

**User's choice:** 45-60 FPS (Recommended)

### Question 3: Optimization Priority

| Option | Description | Selected |
|--------|-------------|----------|
| Visual fidelity | Keep particles, lighting, and effects but reduce view distance and player count. Game looks good but may feel empty in distance. | |
| Responsiveness (Recommended) | Reduce particles/effects but keep input latency low and frame time consistent. Gunplay feels snappy even if visuals are simplified. | ✓ |
| Player count | Support more simultaneous players but reduce per-player effects. Fuller matches but simpler visuals per player. | |

**User's choice:** Responsiveness (Recommended)

### Question 4: Particle Effects Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Adaptive quality (Recommended) | Detect device performance (via Stats.PerformanceStats) and reduce particle counts on lower-end devices. Best of both worlds. | ✓ |
| Simplified for all mobile | All mobile devices get reduced particles regardless of capability. Predictable performance, easier to test. | |
| You decide | Claude picks based on current particle usage (bullet tracers, impacts, muzzle flash) and performance budget. | |

**User's choice:** Adaptive quality (Recommended)

---

## Sprint & Stamina Mechanics

### Question 1: Sprint Control

| Option | Description | Selected |
|--------|-------------|----------|
| Hold to sprint (Recommended) | Player holds sprint button to run, releases to walk. Standard FPS control. Drains stamina while held. | ✓ |
| Toggle sprint | Tap sprint to start running, tap again to stop. Hands-free sprinting but can lead to accidental stamina depletion. | |
| Auto-sprint | Player sprints by default when moving forward, walks when moving other directions. Mobile-friendly but less control. | |

**User's choice:** Hold to sprint (Recommended)

### Question 2: Sprint Duration

| Option | Description | Selected |
|--------|-------------|----------|
| 5-7 seconds (Recommended) | Enough to cross open areas but requires tactical sprint timing. Balances mobility and stamina management. Common in tactical shooters. | ✓ |
| 3-4 seconds (short) | Very limited sprinting, encourages pacing and positioning. Stamina becomes a critical resource. May frustrate new players. | |
| 10+ seconds (long) | Generous sprint duration, stamina rarely a concern. More forgiving for new players but reduces tactical depth. | |

**User's choice:** 5-7 seconds (Recommended)

### Question 3: Stamina Recovery

| Option | Description | Selected |
|--------|-------------|----------|
| Gradual regen after delay (Recommended) | 2-second delay after stopping sprint, then regenerates over 3-4 seconds. Standard FPS pattern. Rewards timing and positioning. | ✓ |
| Immediate regen | Stamina starts recovering immediately when sprint released. More forgiving but less strategic depth. | |
| Only when standing still | Stamina only recovers when not moving. Forces players to find cover to recover. More tactical but may feel restrictive. | |

**User's choice:** Gradual regen after delay (Recommended)

### Question 4: Stamina Display

| Option | Description | Selected |
|--------|-------------|----------|
| Small stamina bar (Recommended) | Thin bar near health/XP bars (bottom of screen). Visible but not intrusive. Matches existing HealthDisplayGui pattern. | ✓ |
| No UI, audio cues only | Heavy breathing when low on stamina, no visual bar. Cleaner screen but less clear feedback. | |
| Icon that flashes when low | Small stamina icon that only appears/flashes when stamina is below 25%. Minimal UI clutter but easy to miss. | |

**User's choice:** Small stamina bar (Recommended)

---

## Claude's Discretion

- Crouch mechanics implementation (MOV-02) — specific speed reduction and hitbox approach
- Mobile UI scaling specifics — UISizeConstraint/UIAspectRatioConstraint values
- Input detection strategy details — UserInputService.TouchEnabled usage pattern

## Deferred Ideas

None — all discussion stayed within Phase 3 scope
