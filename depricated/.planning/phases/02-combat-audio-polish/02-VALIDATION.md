---
phase: 02
slug: combat-audio-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-29
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual playtesting + Roblox Studio debugging |
| **Config file** | None — Roblox Studio built-in |
| **Quick run command** | `Run in Studio (F5)` |
| **Full suite command** | `Multiplayer test (F7)` |
| **Estimated runtime** | ~60 seconds per manual pass |

---

## Sampling Rate

- **After every task commit:** Quick manual verification in Studio (F5)
- **After every plan wave:** Full multiplayer test session (F7)
- **Before `/gsd:verify-work`:** Complete playtesting session with all requirements
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | SND-01 | Manual audio | Fire weapon, verify positional audio | N/A | ⬜ pending |
| 02-01-02 | 01 | 1 | SND-02 | Manual audio | Shoot different materials, verify impact sounds | N/A | ⬜ pending |
| 02-01-03 | 01 | 1 | CMBT-03 | Manual visual | Fire at distant target, verify crosshair alignment | N/A | ⬜ pending |
| 02-02-01 | 02 | 1 | CMBT-04 | Manual feel | Rapid fire vs paced shots, verify recoil/spread | N/A | ⬜ pending |
| 02-02-02 | 02 | 1 | CMBT-05 | Manual visual | Shoot wood, brick, glass, sand, stone surfaces | N/A | ⬜ pending |
| 02-03-01 | 03 | 2 | VIEW-01 | Visual inspection | Equip weapon in 1st-person, verify arm position | N/A | ⬜ pending |
| 02-03-02 | 03 | 2 | VIEW-02 | Visual inspection | Observer mode, verify 3rd-person arm position | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — Roblox Studio provides all testing capabilities (F5 play, F7 multiplayer).

Manual testing protocols:
- [ ] Audio testing protocol — verify positional audio from multiple player perspectives
- [ ] Visual inspection checklist — arm positioning verification steps
- [ ] Recoil feel testing — standardized rapid-fire vs paced shot comparison
- [ ] Material impact verification — systematic testing of all 5 material types
- [ ] Crosshair alignment test — precision targeting at various distances

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Positional audio falloff | SND-01 | Audio spatialization requires human ears | Fire weapon, walk away, verify volume decreases |
| Material impact sounds | SND-02 | Material-specific audio requires human judgment | Shoot each material type, verify distinct sounds |
| Arm positioning 1P | VIEW-01 | Visual correctness requires human eye | Equip weapon, aim in all directions, check for dislocation |
| Arm positioning 3P | VIEW-02 | Visual correctness requires human eye | Observe other player aiming, check arm positions |
| Crosshair alignment | CMBT-03 | Targeting precision requires gameplay testing | Fire at distant target, verify bullet lands on crosshair |
| Recoil feel | CMBT-04 | "Heavy & deliberate" is a subjective quality | Rapid fire, verify camera kick feels weighty |
| Impact effects per material | CMBT-05 | Visual/audio distinction requires human judgment | Shoot all 5 materials, verify unique particles and sounds |

---

## Validation Sign-Off

- [ ] All tasks have manual verification protocols
- [ ] Sampling continuity: manual check after each task
- [ ] Wave 0 covers all testing protocols
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
