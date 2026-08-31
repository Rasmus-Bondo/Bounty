---
phase: 04
slug: progression-persistence
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-30
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Roblox Studio Playtest |
| **Config file** | none — manual playtest verification |
| **Quick run command** | Manual verification after each task |
| **Full suite command** | Full playtest session |
| **Estimated runtime** | ~60 seconds per check |

---

## Sampling Rate

- **After every task commit:** Manual verification of task acceptance criteria
- **After every plan wave:** Full playtest session testing all wave features
- **Before `/gsd:verify-work`:** Full conversational UAT must pass
- **Max feedback latency:** 60 seconds

---

## Nyquist Compliance Note

Roblox projects cannot use automated test frameworks in the traditional sense. All Roblox game logic runs inside the Roblox engine, which requires Studio playtest sessions for behavioral verification. This is an inherent platform constraint, not a gap in test coverage.

**Verification model:** Each task's `<verify>` section contains:
1. **Automated checks** via MCP tools: Verify code structure, script content, instance hierarchy (confirms artifacts exist and contain expected patterns)
2. **Manual behavioral checks** via Roblox Studio playtest: Verify runtime behavior (confirms features actually work)

Both are required for task completion. MCP automated checks run first (fast, structural), followed by manual playtest (behavioral, ~60s each). This two-layer approach provides Nyquist-equivalent coverage for the Roblox platform.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Check | Manual Check | Status |
|---------|------|------|-------------|-----------|-----------------|--------------|--------|
| 01-T1 | 01 | 1 | DATA-01, DATA-02 | MCP + playtest | Script content, instance hierarchy | Join/leave/rejoin data persistence, time tracking | pending |
| 01-T2 | 01 | 1 | DATA-01 | MCP + playtest | Script content | Leaderstats appear with Cash/Level/XP | pending |
| 02-T1 | 02 | 2 | PROG-01, PROG-02, PROG-03 | MCP + playtest | Script content, constants | Kill rewards, level-up, time rewards | pending |
| 02-T2 | 02 | 2 | PROG-01 | MCP + playtest | Script content | Kill awards XP+cash in 2-player test | pending |
| 03-T1 | 03 | 2 | STAT-01, STAT-02, STAT-03 | MCP + playtest | Instance hierarchy, script content | Tab toggle, stat display, scoreboard | pending |
| 03-T2 | 03 | 2 | STAT-01 | MCP + playtest | Instance hierarchy, script content | Mobile button toggle | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing Roblox Studio playtest infrastructure covers all phase requirements. No additional test framework setup needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| DataStore save/load | DATA-01, DATA-02 | Roblox DataStore requires live server | Join game, earn XP/cash, leave, rejoin, verify values persist |
| XP/cash rewards | PROG-01, PROG-03 | Real-time combat system | Kill player in 2-player test, verify XP/cash increase in leaderstats |
| Level progression | PROG-02 | Requires earning enough XP | Earn 1000+ XP, verify level increases from 1 to 2 |
| Stat menu display | STAT-01 | UI functionality | Press Tab (PC) or stat button (mobile), verify all stats display correctly |
| Auto-save timing | DATA-02 | Time-based behavior | Wait 5 minutes in game, verify save occurs without disconnect |
| BindToClose save | DATA-02 | Server shutdown scenario | Start 2+ player test server, stop server, check Output for "BindToClose: saved N players" completion log within 30s |
| Time alive/dead tracking | DATA-02 | Real-time accumulation | Play 30s alive, die, wait 10s dead -- open stat menu, verify TimeAlive > 0 and TimeDead > 0 |
| Scoreboard session stats | STAT-03 | Multi-player attributes | Start 2-player test, get kills, open scoreboard, verify kill counts for both players |

---

## Validation Sign-Off

- [x] All tasks have MCP automated verification (code structure) + manual playtest verification (behavior)
- [x] Sampling continuity: every task verified after commit
- [x] Wave 0 covers all requirements (existing Roblox playtest infrastructure)
- [x] No watch-mode flags (not applicable to Roblox)
- [x] Feedback latency < 60s per manual check
- [x] `nyquist_compliant: true` set in frontmatter
- [x] Nyquist compliance note documents platform-specific verification model

**Approval:** ready
