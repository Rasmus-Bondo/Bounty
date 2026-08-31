# Phase 2: Combat & Audio Polish - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Make gunplay feel responsive and satisfying with proper audio feedback. Fix positional audio (gun sounds play from weapon, not server-wide), fix crosshair alignment, add weapon recoil with accuracy spread, fix arm positioning in 1st/3rd person, and expand bullet impact material system.

Requirements: SND-01, SND-02, VIEW-01, VIEW-02, CMBT-03, CMBT-04, CMBT-05

</domain>

<decisions>
## Implementation Decisions

### Crosshair
- **D-01:** Fix crosshair alignment only — the dot is currently at Y=0.475 but shots fire from viewport center (0.5, 0.5). Align the crosshair to match actual bullet trajectory.
- **D-02:** Do NOT change crosshair visual style — Aetria handles crosshair design. Phase 2 only fixes the positional alignment bug.

### Recoil
- **D-03:** Heavy & deliberate recoil — strong upward camera kick with slow recovery. Each shot should feel weighty like a big revolver. Rewards pacing shots over spam.
- **D-04:** Accuracy spread on rapid fire — consecutive shots get increasingly inaccurate (bullets deviate from crosshair). Spread resets when player pauses between shots. Rewards trigger discipline.

### Impact Materials
- **D-05:** Five material types with unique impact effects (particles + sounds):
  1. **Wood** (already implemented) — splinters + wood impact sound
  2. **Bricks** — dust/debris particles + brick chip sound
  3. **Glass** — glass shard particles + glass break/shatter sound
  4. **Sand/Ground** — small dust cloud + soft thud sound
  5. **Rocks/Stone** — stone chip particles + hard ricochet/chip sound
- **D-06:** Generic impact spark (already exists) remains the fallback for unmatched materials.

### Audio
- **D-07:** Client-predicted fire sound — shooter hears their gun immediately on click (played client-side). Other players hear the shot when server processes it (positional from MuzzleAttachment).
- **D-08:** Medium audio range — full volume within ~10 studs, fades to silent by ~200 studs. Uses InverseTapered RollOffMode on positional sounds.
- **D-09:** Reload sound also becomes positional — plays from the gun's position, not server-wide.
- **D-10:** Impact sounds play at hit location (already partially done for wood — extend to all material types).

### Arm Positioning (VIEW-01, VIEW-02)

### Claude's Discretion
- Arm positioning fixes in 1st-person and 3rd-person — IKControl system already exists in GunClient with configurable constants. Claude should tune the IK parameters, elbow pole positions, and aim target offsets to fix any visible arm dislocations or inverted bending. No user input needed on the technical approach.
- RollOff distance exact values — ~10 min / ~200 max as guidance, tune to feel right in the canyon map.
- Recoil exact values (kick angle, spread multiplier, recovery time) — tune to feel "heavy & deliberate" per D-03.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements fully captured in decisions above and the following project files:

### Project Documents
- `.planning/PROJECT.md` — Project vision, constraints, and key decisions
- `.planning/REQUIREMENTS.md` — Full v1 requirements (SND-01, SND-02, VIEW-01, VIEW-02, CMBT-03, CMBT-04, CMBT-05 are this phase)
- `.planning/ROADMAP.md` — Phase goals and success criteria
- `CLAUDE.md` — Technology stack recommendations including Audio section (RollOffMode, distances) and Combat section (raycasting, server validation)

### Prior Phase Context
- `.planning/phases/01-foundation-architecture/01-CONTEXT.md` — Phase 1 decisions (architecture patterns, RemoteEvent consolidation, service modules)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **GunServer `playSound()`** (line 119-124): Currently plays sounds from tool — needs refactoring to positional audio on MuzzleAttachment
- **GunServer `emitMuzzleFlash()`** (line 72-117): Already creates effects on MuzzleAttachment — good pattern to follow for positional audio
- **GunServer `emitWoodImpactEffects()`** (line 212-238): Wood impact pattern — extend this for other materials
- **GunServer `createImpactSpark()`** (line 172-210): Generic fallback impact — keep as default
- **GunClient IK system** (lines 218-291): Full IKControl setup with aim target, elbow pole, torso tilt — tune parameters to fix arm positioning
- **GunClient `playShootAnimation()`** (line 156-179): Existing shoot animation — add camera kick after this plays
- **RevolverGui > Crosshair**: Existing Frame at position {0.5, 0}, {0.475, 0} — needs Y repositioned to 0.5

### Established Patterns
- **Debris cleanup**: `Debris:AddItem()` used consistently for temporary VFX parts — continue this pattern
- **Template cloning**: Wood effects clone templates from ReplicatedStorage — use same pattern for new material effects
- **RemoteEvent actions**: GunRemote uses string-action pattern ("Fire", "Reload", "Ammo", etc.) — add new actions if needed for client-predicted audio
- **RenderStepped**: GunClient already runs per-frame updates — add recoil recovery here

### Integration Points
- **GunServer `fireShot()`** (line 352-467): Main fire logic — add recoil spread to server raycast direction
- **GunClient `Tool.Activated`** (line 483-498): Client fire handler — add client-predicted fire sound + camera kick here
- **ReplicatedStorage.SFX**: Sound templates stored here — add new impact sounds
- **ReplicatedStorage**: Add new particle templates for brick, glass, sand, stone impacts
- **Handle > MuzzleAttachment**: Already exists on BanditGun — parent positional sounds here

</code_context>

<specifics>
## Specific Ideas

- Crosshair alignment is specifically off because the Frame is at Y=0.475 but shots cast from viewport center — this is a concrete misalignment, not a design issue
- The AUDIO_BUG flag in STATE.md refers to server-wide sound playback — this is the primary audio fix
- Kill sound (`roundKillSound`) currently cloned to workspace — should also be made positional or kept as a UI feedback sound for the killer only

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-combat-audio-polish*
*Context gathered: 2026-03-29*
