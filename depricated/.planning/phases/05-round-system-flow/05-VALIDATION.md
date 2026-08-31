---
phase: 5
slug: round-system-flow
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-01
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **Note:** This Roblox project uses manual Studio playtesting as the validation method. All verification is manual in-game testing.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual Roblox Studio playtesting (no automated Luau test framework) |
| **Config file** | None — Roblox Studio project |
| **Quick run command** | Play Solo in Roblox Studio (F5) |
| **Full suite command** | Play with 2+ local servers (Test > Start with 2 Players) |
| **Estimated runtime** | ~5-10 minutes (full 2-player test) |

---

## Sampling Rate

- **After every task commit:** Play Solo (F5) to verify basic functionality
- **After every plan wave:** 2-player server test to verify multiplayer interactions
- **Before `/gsd:verify-work`:** Full 2+ player test covering all 8 requirements
- **Max feedback latency:** 30 seconds (Studio launch + basic checks)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | RND-01, RND-06 | manual | Play Solo, verify opt-in and invuln | N/A (manual) | ⬜ pending |
| 05-01-02 | 01 | 1 | RND-07 | manual | Play Solo, verify invuln blocks damage | N/A (manual) | ⬜ pending |
| 05-02-01 | 02 | 2 | RND-02, RND-03, RND-05, RND-08 | manual | Play Solo, verify round lifecycle | N/A (manual) | ⬜ pending |
| 05-02-02 | 02 | 2 | RND-04 | manual | 2-player test, verify post-game stats | N/A (manual) | ⬜ pending |
| 05-03-01 | 03 | 2 | RND-01 | manual | Play Solo, verify lobby button UI | N/A (manual) | ⬜ pending |
| 05-03-02 | 03 | 2 | RND-04 | manual | Play Solo, verify post-game leaderboard | N/A (manual) | ⬜ pending |
| 05-04-01 | 04 | 3 | All | manual | 2-player test, wire RoundTimeLeft | N/A (manual) | ⬜ pending |
| 05-04-02 | 04 | 3 | All | human-verify | Full 2-player verification checkpoint | N/A (checkpoint) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — Roblox Studio playtesting is the established test method for this project. No automated test framework to set up.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Lobby opt-in button appears, clicking joins round | RND-01 | Roblox GUI behavior | Play Solo, verify button + spawn |
| Mid-match join spawns player into active round | RND-02 | Multiplayer behavior | Start 2-player test, join second player mid-round |
| 10-min round transitions to intermission | RND-03 | Time-based behavior | Set ROUND_TIME to 10 for quick test, verify transition |
| Post-game stat board shows during intermission | RND-04 | GUI + multiplayer | Complete a round, verify leaderboard overlay |
| New round auto-starts after intermission | RND-05 | Round state machine | Watch full intermission-to-round transition |
| Respawned player flickers for ~10s | RND-06 | Visual effect | Die and respawn, observe flicker visual |
| Invulnerable player cannot deal damage | RND-07 | Combat interaction | Shoot during invuln, verify no damage applied |
| Map resets between rounds | RND-08 | State management | End round, verify clean state (corpses cleared) |

**All phase behaviors require manual Roblox Studio verification.**

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (manual Studio testing documented in each task)
- [x] Sampling continuity: Every task has verification instructions
- [x] Wave 0 covers all MISSING references: N/A — no Wave 0 needed
- [x] No watch-mode flags: N/A for Roblox
- [x] Feedback latency < 30s: Studio launch is fast
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Manual testing approach approved 2026-04-01
