# Phase 4: Progression & Persistence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-30
**Phase:** 04-progression-persistence
**Areas discussed:** Data persistence strategy, Save triggers & frequency, Reward formulas, Stat menu UI & access

---

## Data Persistence Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| ProfileService (Recommended) | Community library that wraps DataStore with session locking, automatic retry on failures, and prevents data duplication across servers. CLAUDE.md recommends this. Handles edge cases like player server-hopping. | |
| Raw DataStore API | Roblox's built-in DataStore service. More control but requires manual session locking, retry logic, and duplicate prevention. More code to maintain but no external dependency. | ✓ |

**User's choice:** Raw DataStore API
**Notes:** "Just use DataStore, this is a small game so we dont worry about session locking for now"

---

| Option | Description | Selected |
|--------|-------------|----------|
| Core stats only (Recommended) | Cash, Level, XP — the three persistent progression values. Stats like kills/deaths reset each session (tracked in-memory only). Keeps DataStore simple and small. | |
| Core stats + lifetime totals | Cash, Level, XP + lifetime kills, lifetime deaths, total playtime. Allows showing all-time stats in the stat menu. Slightly larger data footprint but still small. | |
| Everything including session stats | Core stats + lifetime totals + current session kills/deaths/time. Most comprehensive but session stats could just be tracked in-memory and don't need persistence. | ✓ |

**User's choice:** Everything including session stats

---

## Save Triggers & Frequency

| Option | Description | Selected |
|--------|-------------|----------|
| On disconnect only | Save when player leaves. Simplest approach, no auto-save overhead. Risk: data lost if server crashes before player leaves. | |
| Periodic auto-save + disconnect (Recommended) | Auto-save every 5-10 minutes + on disconnect. Balances data safety with DataStore rate limits. Standard for most Roblox games. | ✓ |
| On every change + disconnect | Save immediately after XP gain, cash change, level up, etc. Most data-safe but hits DataStore rate limits quickly in active gameplay. | |

**User's choice:** Periodic auto-save + disconnect (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Every 5 minutes (Recommended) | Balances data safety with rate limits. At most 12 saves per hour per player. Standard interval for Roblox games. | ✓ |
| Every 10 minutes | Less frequent, more conservative on rate limits. Lower data safety — up to 10 minutes of progress lost on crash. | |
| Every 2-3 minutes | More frequent, better data safety. Higher DataStore usage — 20-30 saves per hour per player. May hit rate limits in high-traffic games. | |

**User's choice:** Every 5 minutes (Recommended)

---

## Reward Formulas

| Option | Description | Selected |
|--------|-------------|----------|
| 100 XP per kill | Round number, easy math. 10 kills = 1000 XP. Standard FPS progression rate. | ✓ |
| 50 XP per kill | Slower progression, more kills needed to level up. Makes each level feel more earned. | |
| 150-200 XP per kill | Faster progression, players level up quicker. Good for shorter play sessions, keeps engagement high. | |

**User's choice:** 100 XP per kill
**Notes:** "100 XP per kill, but make this decision easy to change later"

---

| Option | Description | Selected |
|--------|-------------|----------|
| $10 per kill (Recommended) | Matches the 100 XP per kill — clean 1:10 ratio. Easy for players to understand and calculate earnings. | ✓ |
| $25 per kill | Higher cash rewards, faster economy. Players accumulate money quicker for future features (shop, upgrades). | |
| $5 per kill | Slower economy, makes cash feel more valuable. Good if cash will have significant purchasing power later. | |

**User's choice:** $10 per kill
**Notes:** "$10 per kill, but make it easy to change later"

---

| Option | Description | Selected |
|--------|-------------|----------|
| Linear (Recommended) | Each level requires the same XP (e.g., 1000 XP per level). Simple, predictable. Level 1→2 = 1000 XP, Level 2→3 = 1000 XP, etc. Easy for players to track progress. | ✓ |
| Exponential (gradual) | XP requirement increases each level (e.g., 1000, 1200, 1440...). Early levels fast, later levels slower. Keeps engagement high early, provides long-term goals. | |
| Exponential (steep) | XP requirement doubles or increases significantly (e.g., 1000, 2000, 4000...). Very fast early progression, very slow late game. Good for games with level caps. | |

**User's choice:** Linear (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| 1000 XP per level (Recommended) | 10 kills per level up. Fast progression, frequent rewards. Players level up roughly every 2-3 rounds of solid gameplay. | ✓ |
| 500 XP per level | 5 kills per level up. Very fast progression, players see levels increase frequently. Good for casual games with shorter sessions. | |
| 2000 XP per level | 20 kills per level up. Slower progression, makes each level feel more significant. Players level up every 5-7 rounds. | |

**User's choice:** 1000 XP per level (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Small completion bonus (Recommended) | 50 XP + $5 just for playing a full round. Rewards participation, keeps players engaged even during bad rounds. Small enough not to overshadow kill rewards. | ✓ |
| No completion bonus | Only kills reward XP/cash. Focuses rewards on skill/performance. Players with 0 kills get nothing. | |
| Scaled bonus by placement | Top 3 players get bonus XP/cash (winner gets most). Adds competitive incentive beyond just kills. | |

**User's choice:** Small completion bonus (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Unlimited levels | Players can level up forever (Level 1, 2, 3... 100, 101...). Simple, no cap logic needed. Players always have progression goals. | ✓ |
| Level cap at 50 | Stops at Level 50. Gives a clear endgame goal. After cap, players still earn cash but no more XP/levels. | |
| Level cap at 100 | Stops at Level 100. Higher goal, takes longer to reach. Provides long-term progression for dedicated players. | |

**User's choice:** Unlimited levels

---

**Additional requirement (free-text):** "There should be a money reward and xp reward every 2 minute the player is in an active game"

| Option | Description | Selected |
|--------|-------------|----------|
| 25 XP + $2.50 (1/4 of kill) | Modest time reward, doesn't overshadow kills. 8 minutes of playing = 1 kill worth of rewards. | ✓ |
| 50 XP + $5 (1/2 of kill) | Meaningful time reward. 4 minutes of playing = 1 kill worth of rewards. Keeps low-skill players engaged. | |
| 10 XP + $1 (1/10 of kill) | Small participation reward, heavily favors kills. 20 minutes = 1 kill worth. Primarily skill-based economy. | |

**User's choice:** 25 XP + $2.50 (1/4 of kill)

---

## Stat Menu UI & Access

| Option | Description | Selected |
|--------|-------------|----------|
| Tab key (PC) / button (mobile) (Recommended) | Standard FPS stat menu key. Tab on keyboard, dedicated stat button on mobile. Toggle open/close. Common pattern players expect. | ✓ |
| Always visible (minimal) | Stat info always shown in a corner or HUD element. No toggle needed. Simple but takes screen space. | |
| Hold key to view | Hold Tab (PC) or hold button (mobile) to view, release to hide. Quick peek at stats without toggling. Used in some battle royales. | |

**User's choice:** Tab key (PC) / button (mobile) (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Core progression only | Cash, Level, XP, XP to next level. Focuses on progression info. Clean and simple. | |
| Progression + session stats (Recommended) | Cash, Level, XP + current session kills, deaths, K/D ratio, time alive. Shows both long-term and current performance. | |
| Everything including lifetime | Progression + session + lifetime kills, lifetime deaths, total playtime. Comprehensive but lots of info to display. Requires saving lifetime stats to DataStore. | ✓ |

**User's choice:** Everything including lifetime

---

| Option | Description | Selected |
|--------|-------------|----------|
| Center overlay (Recommended) | Semi-transparent panel in center of screen. Standard menu placement. Blurs/dims game behind it. Easy to read, clear focus. | ✓ |
| Side panel (left or right) | Vertical panel on side of screen. Doesn't block center view. Good for games where you might check stats while still playing. | |
| Top-down overlay | Fills most of screen with dark background. Maximum space for stats. Full immersive menu experience. | |

**User's choice:** Center overlay (Recommended)

---

## Claude's Discretion

- DataStore error handling specifics — Retry count, retry delay, fallback behavior on repeated failures
- Stat menu styling — Colors, fonts, layout grid, transparency values
- K/D ratio display format — Decimal places, handling division by zero (0 deaths)
- Time display format — Minutes:seconds vs hours:minutes, or human-readable strings
- Level-up visual feedback — Particle effect, sound, screen flash, etc. (not blocking for functionality)
- Session stat reset — When session stats reset (on respawn, on round end, or never until disconnect)

## Deferred Ideas

None mentioned during discussion
