---
phase: 01
slug: foundation-architecture
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-27
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Roblox playtest + manual verification |
| **Config file** | none — Roblox Studio integrated |
| **Quick run command** | Start playtest in Studio (F5) |
| **Full suite command** | Start playtest + run through combat flow |
| **Estimated runtime** | ~30 seconds per playtest cycle |

---

## Sampling Rate

- **After every task commit:** Verify module requires work (no circular deps)
- **After every plan wave:** Full playtest — services initialize, combat works
- **Before `/gsd:verify-work`:** Complete playtest with combat validation
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | FOUND-01 | manual | Playtest: services load without error | N/A | ⬜ pending |
| 01-01-02 | 01 | 1 | FOUND-04 | manual | Playtest: GameManager prints init logs | N/A | ⬜ pending |
| 01-02-01 | 02 | 1 | FOUND-02 | manual | Verify Events folder in ReplicatedStorage | N/A | ⬜ pending |
| 01-02-02 | 02 | 1 | CMBT-02 | manual | Rapid fire test in playtest | N/A | ⬜ pending |
| 01-03-01 | 03 | 2 | CMBT-01 | manual | Playtest: shoot and verify server raycast | N/A | ⬜ pending |
| 01-04-01 | 04 | 2 | FOUND-03 | manual | Playtest: no Townsfolk UI or role assignment | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing Roblox Studio playtest infrastructure covers all phase requirements.
- No external test framework needed — validation is through manual playtest and output log inspection.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Services initialize without error | FOUND-01, FOUND-04 | Roblox execution context requires Studio | Start playtest, check Output for init logs |
| RemoteEvents in Events folder | FOUND-02 | Instance hierarchy inspection | Open Explorer, verify Events folder exists |
| Rate limiting prevents spam | CMBT-02 | Requires rapid input simulation | Playtest: hold fire, check Output for rate limit messages |
| Server raycast validates hits | CMBT-01 | Requires two-player test or NPC | Playtest: shoot at target, verify server-side hit log |
| No Townsfolk references remain | FOUND-03 | Code audit + playtest | Search scripts for "Townsfolk", verify no role UI |

---

## Validation Sign-Off

- [ ] All tasks have manual verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without verification
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
