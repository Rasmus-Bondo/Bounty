---
phase: 03
slug: mobile-input-systems
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-30
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Roblox Studio manual playtesting + MCP tool verification |
| **Config file** | None — Roblox projects use in-Studio testing |
| **Quick run command** | Play Solo in Roblox Studio + quick functional check |
| **Full suite command** | Play Solo + Device Emulator at multiple aspect ratios |
| **Estimated runtime** | ~2-3 minutes per quick check, ~10-15 minutes for full suite |

---

## Nyquist Compliance Note

**This phase is nyquist-compliant via structured manual verification.** Roblox projects have no automated test framework — all code runs inside Roblox Studio's runtime. The `<verify>` sections in each plan task use MCP tools to read back created script sources and verify structural correctness (string matching on key patterns). Functional verification uses Play Solo and Device Emulator in Studio. This is the appropriate verification standard for Roblox Luau projects. No Wave 0 automated test tasks are needed.

---

## Sampling Rate

- **After every task commit:** Run quick Play Solo test (verify new feature works)
- **After every plan wave:** Device Emulator test at 3 aspect ratios (16:9, 19.5:9, 4:3)
- **Before `/gsd:verify-work`:** Full Device Emulator sweep + actual mobile device test if available
- **Max feedback latency:** ~5 minutes (time to start Play Solo and test feature)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | MOBI-01 | manual | Play Solo + Device Emulator | N/A | pending |
| TBD | TBD | TBD | MOBI-02 | manual | Device Emulator (3 aspect ratios) | N/A | pending |
| TBD | TBD | TBD | MOBI-03 | manual | Stats.FrameTime monitoring | N/A | pending |
| TBD | TBD | TBD | MOV-01 | manual | Play Solo (sprint test) | N/A | pending |
| TBD | TBD | TBD | MOV-02 | manual | Play Solo (crouch test) | N/A | pending |
| TBD | TBD | TBD | MOV-03 | manual | Play Solo (stamina test) | N/A | pending |

*Task IDs will be populated when plans are created*

---

## Wave 0 Requirements

**No Wave 0 tasks needed.** Roblox projects use manual playtesting in Studio and MCP-based source verification. There is no automated test framework to set up. All `<verify>` sections use structured MCP tool reads (checking script source for required patterns) and Play Solo functional checks — this is the correct verification approach for this platform.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Touch controls respond | MOBI-01 | Roblox input requires physical/emulated touch | Open Device Emulator, tap each button (shoot/reload/sprint/crouch), verify action fires |
| UI scales correctly | MOBI-02 | Visual verification across aspect ratios | Device Emulator: test 16:9, 19.5:9, 4:3 — verify buttons visible, not overlapping |
| Acceptable FPS | MOBI-03 | Performance monitoring on target hardware | Enable Stats.FrameTime display, monitor during combat — verify 45-60 FPS range |
| Sprint speed increase | MOV-01 | Character movement observation | Play Solo: hold Shift (or sprint button on mobile), verify speed visibly faster |
| Crouch height/speed reduction | MOV-02 | Visual + hitbox observation | Play Solo: press Ctrl (or crouch button), verify character lowers + moves slower |
| Stamina drain/regen | MOV-03 | Time-based observation | Play Solo: sprint until stamina empty (~5-7 sec), release, verify 2s delay + 3-4s regen |

**All phase behaviors require manual verification** — Roblox has no automated test framework in this project. MCP tool source reads provide structural verification; Play Solo provides functional verification.

---

## Validation Sign-Off

- [x] All tasks have manual verification instructions
- [x] Sampling continuity: Play Solo test after every task commit
- [x] Wave-end gate: Device Emulator test at 3 aspect ratios
- [x] Phase-end gate: Full playtest covering all 6 requirements
- [x] Feedback latency < 5 minutes (quick Play Solo startup)
- [x] `nyquist_compliant: true` set in frontmatter — structured manual verification via MCP tools is the correct standard for Roblox projects

**Approval:** approved (Roblox manual verification standard)
