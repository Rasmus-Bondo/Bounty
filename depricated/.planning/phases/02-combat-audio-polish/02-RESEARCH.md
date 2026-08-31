# Phase 2: Combat & Audio Polish - Research

**Researched:** 2026-03-29
**Domain:** Roblox audio systems, camera manipulation, IK controls, UI positioning
**Confidence:** HIGH

## Summary

Phase 2 focuses on making gunplay feel responsive and satisfying through proper audio feedback, visual improvements, and weapon positioning fixes. The technical domain involves Roblox's positional audio system with RollOffMode configuration, camera CFrame manipulation for recoil effects, IKControl tuning for weapon arm positioning, and material-specific particle effects for bullet impacts.

The existing codebase (from CONTEXT.md analysis) already has the foundational patterns: MuzzleAttachment positioning, debris cleanup systems, RemoteEvent architecture, and IK infrastructure. This phase primarily involves parameter tuning and extending existing patterns rather than architectural changes.

**Primary recommendation:** Leverage existing GunServer/GunClient infrastructure with positional Sound parenting to MuzzleAttachment, TweenService for camera recoil recovery, and material-specific ParticleEmitter templates.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Fix crosshair alignment only — the dot is currently at Y=0.475 but shots fire from viewport center (0.5, 0.5). Align the crosshair to match actual bullet trajectory.
- **D-02:** Do NOT change crosshair visual style — Aetria handles crosshair design. Phase 2 only fixes the positional alignment bug.
- **D-03:** Heavy & deliberate recoil — strong upward camera kick with slow recovery. Each shot should feel weighty like a big revolver. Rewards pacing shots over spam.
- **D-04:** Accuracy spread on rapid fire — consecutive shots get increasingly inaccurate (bullets deviate from crosshair). Spread resets when player pauses between shots. Rewards trigger discipline.
- **D-05:** Five material types with unique impact effects (particles + sounds): Wood (already implemented), Bricks (dust/debris + chip sound), Glass (shards + shatter), Sand/Ground (dust cloud + thud), Rocks/Stone (chips + ricochet).
- **D-06:** Generic impact spark (already exists) remains the fallback for unmatched materials.
- **D-07:** Client-predicted fire sound — shooter hears their gun immediately on click (played client-side). Other players hear the shot when server processes it (positional from MuzzleAttachment).
- **D-08:** Medium audio range — full volume within ~10 studs, fades to silent by ~200 studs. Uses InverseTapered RollOffMode on positional sounds.
- **D-09:** Reload sound also becomes positional — plays from the gun's position, not server-wide.
- **D-10:** Impact sounds play at hit location (already partially done for wood — extend to all material types).

### Claude's Discretion
- Arm positioning fixes in 1st-person and 3rd-person — IKControl system already exists in GunClient with configurable constants. Claude should tune the IK parameters, elbow pole positions, and aim target offsets to fix any visible arm dislocations or inverted bending. No user input needed on the technical approach.
- RollOff distance exact values — ~10 min / ~200 max as guidance, tune to feel right in the canyon map.
- Recoil exact values (kick angle, spread multiplier, recovery time) — tune to feel "heavy & deliberate" per D-03.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SND-01 | Gun fire and reload sounds play from the gun's position (positional audio), not server-wide | Roblox Sound.RollOffMode with InverseTapered, parent Sound to MuzzleAttachment |
| SND-02 | Impact sounds play at hit location with material-appropriate sound | Temporary Attachment creation at impact coordinates, material-specific Sound templates |
| VIEW-01 | Arm positioning fixed in first-person view — no dislocated/inverted bending | IKControl.Pole configuration prevents inverted bending, Weight property for smooth blending |
| VIEW-02 | Arm positioning correct in third-person view | Same IKControl system applies to both perspectives |
| CMBT-03 | Crosshair displayed on screen during gameplay | Frame.Position UDim2 alignment to screen center (0.5, 0.5) with proper AnchorPoint |
| CMBT-04 | Weapon recoil — camera kick and accuracy spread on fire, recovers over time | Camera.CFrame manipulation with TweenService recovery, server-side spread calculation |
| CMBT-05 | Bullet hit material system — per-material impact sounds and particle effects | Material-specific ParticleEmitter templates with different Texture, Rate, Speed properties |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Roblox Sound | Current | Positional audio with RollOffMode | Built-in spatial audio system with distance attenuation |
| TweenService | Current | Camera recoil recovery animations | Smooth interpolation with easing styles |
| IKControl | Current | Weapon arm positioning | Inverse kinematics for realistic limb positioning |
| ParticleEmitter | Current | Material impact effects | Built-in particle system for debris effects |
| Camera | Current | Recoil camera kick | Direct CFrame manipulation for immediate response |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Debris | Current | Temporary effect cleanup | Auto-cleanup for impact particles and sounds |
| Attachment | Current | Effect positioning | Precise 3D positioning for particles and audio |
| RunService | Current | Frame-based recoil updates | Real-time camera manipulation during recoil |
| UserInputService | Current | Recoil input detection | Client-side immediate response triggers |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| TweenService | Manual lerping with RunService | More control but requires custom easing implementation |
| IKControl | Manual limb positioning | Full control but complex bone math and unrealistic results |
| Sound.RollOffMode | Manual distance calculations | Custom implementation but no built-in Doppler effects |

**Installation:**
All components are built into Roblox Studio — no external package installation required.

**Version verification:** Roblox APIs are current as of Studio version. No version conflicts expected.

## Architecture Patterns

### Recommended Project Structure
```
ReplicatedStorage/
├── SFX/                  # Sound templates (fire, reload, impact sounds)
├── VFX/                  # ParticleEmitter templates (material impacts)
└── Events/               # RemoteEvent consolidation (existing)

ServerScriptService/
├── GameManager/
│   └── Modules/
│       ├── GunServer     # Main weapon logic (existing)
│       └── *Service      # Other game services (existing)

StarterGui/
└── RevolverGui/
    └── Crosshair        # UI Frame positioning (existing)

StarterPlayerScripts/
└── GunClient             # Client weapon handling (existing)
```

### Pattern 1: Positional Audio Setup
**What:** Parent Sound instances to gun's MuzzleAttachment with proper RollOff configuration
**When to use:** All weapon-related audio (fire, reload)
**Example:**
```lua
-- Source: Roblox Sound documentation + CLAUDE.md recommendations
local sound = ReplicatedStorage.SFX.GunFire:Clone()
sound.Parent = gun.Handle.MuzzleAttachment
sound.RollOffMode = Enum.RollOffMode.InverseTapered
sound.RollOffMinDistance = 10
sound.RollOffMaxDistance = 200
sound:Play()
```

### Pattern 2: Camera Recoil with Recovery
**What:** Immediate camera kick followed by smooth TweenService recovery
**When to use:** All weapon fire events
**Example:**
```lua
-- Source: Roblox Camera and TweenService documentation
local camera = workspace.CurrentCamera
local recoilCFrame = camera.CFrame * CFrame.Angles(math.rad(-recoilAngle), 0, 0)
camera.CFrame = recoilCFrame

local recoveryTween = TweenService:Create(
    camera,
    TweenInfo.new(recoveryTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {CFrame = originalCFrame}
)
recoveryTween:Play()
```

### Pattern 3: Material Impact Effects
**What:** Temporary Attachment creation with material-specific particles and sounds
**When to use:** All bullet hit events on different surface materials
**Example:**
```lua
-- Source: Roblox ParticleEmitter and Attachment documentation + existing wood pattern
local attachment = Instance.new("Attachment")
attachment.Parent = workspace
attachment.WorldPosition = hitPosition

local particles = ReplicatedStorage.VFX.BrickImpact:Clone()
particles.Parent = attachment
particles:Emit(20)

local sound = ReplicatedStorage.SFX.BrickImpact:Clone()
sound.Parent = attachment
sound:Play()

Debris:AddItem(attachment, 5)
```

### Pattern 4: IKControl Arm Positioning
**What:** Proper IK chain configuration with pole constraints
**When to use:** Weapon equip/aim state management
**Example:**
```lua
-- Source: Roblox IKControl documentation
ikControl.ChainRoot = character.UpperTorso
ikControl.EndEffector = character.RightHand
ikControl.Target = gun.Handle.GripAttachment
ikControl.Pole = elbowPoleAttachment -- Prevents inverted bending
ikControl.Weight = 1
ikControl.Enabled = true
```

### Anti-Patterns to Avoid
- **Server-wide audio:** Never parent sounds to workspace or game services — always use positional parenting
- **Missing pole constraints:** IKControl without Pole leads to inverted limb bending
- **Immediate recoil recovery:** Instant camera reset feels jarring — always use smooth recovery
- **Hardcoded material mapping:** Use extensible material detection system for future materials

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Audio distance falloff | Custom distance calculations | Sound.RollOffMode properties | Handles Doppler effects, performance optimized |
| Smooth animations | Manual lerping loops | TweenService | Built-in easing styles, automatic cleanup |
| Inverse kinematics | Manual bone positioning | IKControl objects | Complex bone math, joint constraints |
| Particle physics | Custom debris systems | ParticleEmitter templates | GPU-accelerated, collision detection |
| UI scaling | Manual resolution adjustments | UDim2 Scale components | Automatic responsiveness across devices |

**Key insight:** Roblox provides robust built-in systems for 3D audio, particle effects, and animation that handle edge cases (device performance, network synchronization, cleanup) better than custom implementations.

## Runtime State Inventory

> Phase 2 is enhancement-only (no renames/migrations) — this section is not applicable.

## Common Pitfalls

### Pitfall 1: Audio Parent Hierarchy Confusion
**What goes wrong:** Sounds don't play positionally despite RollOff configuration
**Why it happens:** Sound parented to tool/model instead of specific Part or Attachment
**How to avoid:** Always parent directly to MuzzleAttachment, never to tool root
**Warning signs:** All players hear sound at same volume regardless of distance

### Pitfall 2: IKControl Missing Pole Constraint
**What goes wrong:** Arms bend backward/inward with unnatural joint angles
**Why it happens:** IK solver has multiple solutions without pole guidance
**How to avoid:** Always set Pole property to attachment indicating elbow bend direction
**Warning signs:** Arms "flip" or twist during aim transitions

### Pitfall 3: Camera Recoil State Desync
**What goes wrong:** Camera gets stuck in recoiled position or stutters
**Why it happens:** Multiple overlapping recoil tweens or missing cleanup
**How to avoid:** Cancel previous tween before starting new one, store reference
**Warning signs:** Camera slowly drifts upward or doesn't return to center

### Pitfall 4: Impact Effect Memory Leaks
**What goes wrong:** Game performance degrades over time in combat areas
**Why it happens:** Temporary effects not cleaned up properly
**How to avoid:** Always use Debris:AddItem() for temporary particles/sounds
**Warning signs:** Part count in workspace increases continuously

### Pitfall 5: Crosshair Offset Calculation
**What goes wrong:** Crosshair appears centered but shots don't align
**Why it happens:** AnchorPoint not set when using center positioning
**How to avoid:** Set AnchorPoint to (0.5, 0.5) when positioning at screen center
**Warning signs:** Visual crosshair doesn't match actual bullet trajectory

## Code Examples

Verified patterns from official sources:

### Positional Sound Setup
```lua
-- Source: Roblox Sound documentation + CLAUDE.md Audio section
local fireSound = ReplicatedStorage.SFX.GunFire:Clone()
fireSound.Parent = gun.Handle.MuzzleAttachment
fireSound.RollOffMode = Enum.RollOffMode.InverseTapered
fireSound.RollOffMinDistance = 10  -- Full volume within 10 studs
fireSound.RollOffMaxDistance = 200 -- Silent beyond 200 studs
fireSound:Play()

-- Cleanup after sound finishes
Debris:AddItem(fireSound, fireSound.TimeLength)
```

### Camera Recoil with Recovery
```lua
-- Source: Roblox Camera and TweenService documentation
local camera = workspace.CurrentCamera
local originalCFrame = camera.CFrame
local recoilAngle = math.random(2, 5) -- Random upward kick

-- Immediate recoil kick
camera.CFrame = originalCFrame * CFrame.Angles(math.rad(-recoilAngle), 0, 0)

-- Smooth recovery
local recoveryInfo = TweenInfo.new(
    0.3, -- Recovery time
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)
local recoveryTween = TweenService:Create(camera, recoveryInfo, {CFrame = originalCFrame})
recoveryTween:Play()
```

### Material Impact Detection
```lua
-- Source: Existing wood pattern + ParticleEmitter documentation
local function getImpactEffect(material)
    local effectMap = {
        [Enum.Material.Wood] = "WoodImpact",
        [Enum.Material.Brick] = "BrickImpact",
        [Enum.Material.Glass] = "GlassImpact",
        [Enum.Material.Sand] = "SandImpact",
        [Enum.Material.Rock] = "StoneImpact"
    }
    return effectMap[material] or "GenericSpark"
end

local function createImpactEffect(hitPart, hitPosition)
    local effectName = getImpactEffect(hitPart.Material)
    local particles = ReplicatedStorage.VFX[effectName]:Clone()
    local sound = ReplicatedStorage.SFX[effectName]:Clone()

    local attachment = Instance.new("Attachment")
    attachment.Parent = workspace
    attachment.WorldPosition = hitPosition

    particles.Parent = attachment
    sound.Parent = attachment

    particles:Emit(math.random(15, 25))
    sound:Play()

    Debris:AddItem(attachment, 3)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Server-wide audio | Positional audio with RollOff | Roblox audio updates 2020+ | Better immersion, performance |
| Manual IK calculations | IKControl objects | IKControl release 2021 | Simplified arm positioning |
| Frame-by-frame tweening | TweenService | TweenService improvements 2019+ | Smoother animations, less code |
| Static crosshairs | Responsive UDim2 positioning | UDim2 enhancements | Multi-device support |

**Deprecated/outdated:**
- BodyPosition/BodyVelocity: Deprecated for VectorForce/LinearVelocity (not applicable to this phase)
- Mouse object: Deprecated for UserInputService (already handled in existing code)

## Open Questions

1. **Material Detection Edge Cases**
   - What we know: Basic material enum mapping works for standard parts
   - What's unclear: How to handle terrain, unions, or custom materials
   - Recommendation: Implement fallback to generic spark, add terrain material detection if needed

2. **Recoil Spread Server Validation**
   - What we know: Client predicts recoil for visual feedback
   - What's unclear: How server should apply spread to actual raycast without client input
   - Recommendation: Server tracks per-player fire rate for spread calculation independent of client

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Roblox Studio | All implementation | ✓ | Current | — |
| TweenService | Camera recoil | ✓ | Built-in | — |
| IKControl | Arm positioning | ✓ | Built-in | — |
| ParticleEmitter | Impact effects | ✓ | Built-in | — |

**Missing dependencies with no fallback:**
- None — all required systems are built into Roblox

**Missing dependencies with fallback:**
- None — all systems available

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual playtesting + Roblox Studio debugging |
| Config file | None — see Wave 0 |
| Quick run command | `Run in Studio (F5)` |
| Full suite command | `Multiplayer test (F7)` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SND-01 | Gun sounds positional from weapon | Manual audio test | Manual: Fire weapon, move around | ❌ Wave 0 |
| SND-02 | Impact sounds at hit location | Manual audio test | Manual: Shoot different materials | ❌ Wave 0 |
| VIEW-01 | Arms positioned correctly 1st-person | Visual inspection | Manual: Equip weapon, aim | ❌ Wave 0 |
| VIEW-02 | Arms positioned correctly 3rd-person | Visual inspection | Manual: Observer mode | ❌ Wave 0 |
| CMBT-03 | Crosshair aligned with shots | Manual targeting test | Manual: Shoot at distant target | ❌ Wave 0 |
| CMBT-04 | Recoil kick and recovery | Manual feel test | Manual: Rapid fire vs paced shots | ❌ Wave 0 |
| CMBT-05 | Material-specific impact effects | Visual/audio test | Manual: Shoot wood, brick, glass, sand, stone | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Quick manual verification in Studio
- **Per wave merge:** Full multiplayer test session
- **Phase gate:** Complete playtesting session with all requirements

### Wave 0 Gaps
- [ ] Audio testing protocol — verify positional audio from multiple player perspectives
- [ ] Visual inspection checklist — arm positioning verification steps
- [ ] Recoil feel testing — standardized rapid-fire vs paced shot comparison
- [ ] Material impact verification — systematic testing of all 5 material types
- [ ] Crosshair alignment test — precision targeting at various distances

## Sources

### Primary (HIGH confidence)
- [Roblox Sound Documentation](https://create.roblox.com/docs/reference/engine/classes/Sound) - RollOffMode, positional audio setup
- [Roblox IKControl Documentation](https://create.roblox.com/docs/reference/engine/classes/IKControl) - Arm positioning, pole constraints
- [Roblox Camera Documentation](https://create.roblox.com/docs/reference/engine/classes/Camera) - CFrame manipulation, recoil implementation
- [Roblox ParticleEmitter Documentation](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter) - Material impact effects
- [Roblox Attachment Documentation](https://create.roblox.com/docs/reference/engine/classes/Attachment) - Effect positioning
- [Roblox Frame Documentation](https://create.roblox.com/docs/reference/engine/classes/Frame) - UI positioning, crosshair alignment

### Secondary (MEDIUM confidence)
- CLAUDE.md Audio section - Distance recommendations and RollOffMode guidance
- CLAUDE.md Combat section - Server validation patterns
- 02-CONTEXT.md - Existing code patterns and integration points

### Tertiary (LOW confidence)
- None — all technical information verified through official documentation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All built-in Roblox systems with official documentation
- Architecture: HIGH - Extending existing proven patterns from Phase 1
- Pitfalls: MEDIUM - Based on common Roblox development issues and documentation warnings

**Research date:** 2026-03-29
**Valid until:** 2026-04-28 (30 days - Roblox APIs stable, patterns unlikely to change)