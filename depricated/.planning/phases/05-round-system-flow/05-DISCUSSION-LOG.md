# Phase 5: Round System & Flow - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-01
**Phase:** 5-round-system-flow
**Areas discussed:** Lobby opt-in flow, Mid-match join behavior, Post-game stat display, Invulnerability details

---

## Lobby opt-in flow

### Question 1: How should players join from the lobby?

| Option | Description | Selected |
|--------|-------------|----------|
| Button to join (recommended) | Players click/tap a "Join Round" button to opt in. Clear choice, mobile-friendly. Button appears in lobby, hidden during active round. | ✓ |
| Auto-join after timer | Players automatically join next round after 10 seconds in lobby. Faster onboarding, but less player agency. | |
| Proximity trigger | Walk through a portal/zone to join queue. Immersive but requires map design and may confuse new players. | |

**User's choice:** Button to join (recommended)

---

### Question 2: Can players leave the round queue once they've opted in?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, with Leave button (recommended) | Button changes to "Leave Queue" after joining. Players can change their mind before round starts. More flexible. | ✓ |
| No, locked in | Once opted in, they're committed until round starts. Simpler logic, but less forgiving for accidental clicks. | |
| Auto-leave on death | Players return to lobby queue after dying, must re-opt to respawn. Adds friction but lets players take breaks. | |

**User's choice:** Yes, with Leave button (recommended)

---

### Question 3: Should lobby players be able to spectate the ongoing round?

| Option | Description | Selected |
|--------|-------------|----------|
| No spectating (recommended) | Lobby players stay in lobby area. Simpler, no camera logic needed. Players join when they're ready. | ✓ |
| Free-fly spectate camera | Lobby players can fly around and watch the fight. Engaging but complex camera system and potential for ghosting/cheating. | |
| Fixed camera positions | Lobby players view from preset cameras in the map. Safer than free-fly but still adds complexity. | |

**User's choice:** No spectating (recommended)

---

### Question 4: What info should lobby players see about the current round?

| Option | Description | Selected |
|--------|-------------|----------|
| Timer + player count (recommended) | Show round time remaining and # of active players. Helps players decide when to join. | ✓ |
| Full round HUD | Same HUD as active players (kills, status, timer). More info but clutters lobby experience. | |
| Minimal — just Join button | No round info shown. Clean lobby UI, but players don't know what they're joining into. | |

**User's choice:** Timer + player count (recommended)

---

### Question 5: Where should the Join/Leave Round button appear?

| Option | Description | Selected |
|--------|-------------|----------|
| Center screen (recommended) | Large button in middle of screen. Highly visible, easy to tap on mobile. Standard lobby pattern. | ✓ |
| Bottom-center | Near other UI elements (health bar area). Consistent placement but might overlap existing UI. | |
| Top-center | Near round status display. Groups related info but less thumb-friendly on mobile. | |

**User's choice:** Center screen (recommended)

---

## Mid-match join behavior

### Question 1: When does a player spawn after clicking Join Round?

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate spawn (recommended) | Player teleports to round spawn right away. Fast, gets them in the action. Existing hookCharacter() logic already does this. | ✓ |
| Wait for next respawn wave | Players spawn in groups every 15-30 seconds. More balanced but adds waiting. | |
| Wait for next death | Player spawns when someone dies. Unpredictable timing, could wait a long time. | |

**User's choice:** Immediate spawn (recommended)

---

### Question 2: Should the first spawn (joining mid-match) have invulnerability?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, same as respawn (recommended) | First spawn gets same ~10s invuln as regular respawns. Consistent, gives new joiners a chance to orient. | ✓ |
| Yes, but longer duration | First spawn gets extra invuln time (e.g., 15s). Helps new joiners learn the map but may be exploitable. | |
| No invulnerability | First spawn is vulnerable immediately. Harsh but fair — they chose to join mid-match. | |

**User's choice:** Yes, same as respawn (recommended)

---

### Question 3: What happens when a player dies during the round?

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-respawn with invuln (recommended) | Player automatically respawns after 3-5 seconds with invulnerability. Keeps action flowing, standard FPS pattern. | ✓ |
| Return to lobby, must re-join | Player goes back to lobby and must click Join again. More deliberate but adds friction. | |
| Spectate until next wave | Player watches others until next respawn wave (15-30s intervals). More tactical but longer downtime. | |

**User's choice:** Auto-respawn with invuln (recommended)

---

### Question 4: How long should the auto-respawn delay be after death?

| Option | Description | Selected |
|--------|-------------|----------|
| 3 seconds (recommended) | Quick return to action. Standard for fast-paced FPS. Brief enough to not frustrate players. | ✓ |
| 5 seconds | Slightly longer breather. Gives killers time to loot/reposition. More deliberate pace. | |
| Variable (3-8s) | Delay increases with consecutive deaths to discourage rushing. Complex but adds tactical depth. | |

**User's choice:** 3 seconds (recommended)

---

## Post-game stat display

### Question 1: What should the post-game stat board display?

| Option | Description | Selected |
|--------|-------------|----------|
| Leaderboard + personal (recommended) | Top 5 players (kills, deaths) + your own stats highlighted. Shows winners and your performance. Most common FPS pattern. | ✓ |
| Full leaderboard only | All players ranked by kills. Competitive but less personal focus. May be long list if many players. | |
| Personal stats focus | Just your round stats (kills, deaths, XP earned, cash earned). Private, less comparison pressure. | |

**User's choice:** Leaderboard + personal (recommended)

---

### Question 2: How long should the intermission (with stat display) last?

| Option | Description | Selected |
|--------|-------------|----------|
| 10 seconds (recommended) | Enough time to review stats and take a quick break. Currently set to 5s in Config — would double it. | ✓ |
| 15 seconds | More breathing room between rounds. Better for strategy discussion but slows overall pace. | |
| Keep 5 seconds | Fast transition, minimal downtime. May be too quick to read stats but keeps action flowing. | |

**User's choice:** 10 seconds (recommended)

---

### Question 3: What details should each leaderboard entry show?

| Option | Description | Selected |
|--------|-------------|----------|
| Kills + Deaths + K/D (recommended) | Rank, player name, kills, deaths, K/D ratio. Standard FPS leaderboard format. All data already tracked in State.playerKills. | ✓ |
| Just kills | Rank, player name, kill count. Simple, focuses on winner metric. Less context about performance. | |
| Extended stats | Kills, deaths, K/D, XP earned, cash earned, accuracy. Comprehensive but cluttered on mobile. | |

**User's choice:** Kills + Deaths + K/D (recommended)

---

### Question 4: How should the post-game stat board be presented?

| Option | Description | Selected |
|--------|-------------|----------|
| Center overlay (recommended) | Full-screen semi-transparent panel in center. Familiar pattern, works well on mobile. Matches stat menu from Phase 4. | ✓ |
| Top banner | Horizontal list across top of screen. Less obtrusive but harder to read on mobile. | |
| Side panel | Vertical list on left or right side. Less screen coverage but awkward aspect ratio on phones. | |

**User's choice:** Center overlay (recommended)

---

## Invulnerability details

### Question 1: How long should spawn invulnerability last?

| Option | Description | Selected |
|--------|-------------|----------|
| 10 seconds (recommended) | Matches requirement RND-06 (~10 seconds). Enough time to orient and find cover. Standard FPS spawn protection. | ✓ |
| 8 seconds | Slightly shorter. Enough to escape spawn but less forgiving. Faster-paced gameplay. | |
| 12 seconds | Extra cushion for mobile players with slower movement. More forgiving but may be exploited for positioning. | |

**User's choice:** 10 seconds (recommended)

---

### Question 2: How should invulnerable players appear?

| Option | Description | Selected |
|--------|-------------|----------|
| Flickering transparent (recommended) | Character rapidly blinks between visible and semi-transparent. Requirement RND-06 mentions this. Classic spawn protection visual. | ✓ |
| Constant glow/aura | Character has colored outline or particle aura. Always visible, no blinking. Clear but may obscure character details. | |
| Solid transparency | Character stays at constant 50% transparency. Simple but less attention-grabbing than flicker. | |

**User's choice:** Flickering transparent (recommended)

---

### Question 3: Should the flicker pattern change over time?

| Option | Description | Selected |
|--------|-------------|----------|
| Accelerating fade (recommended) | Flicker speeds up in final 3 seconds as warning. Gives player clear signal that protection is ending. Common FPS pattern. | ✓ |
| Constant rate | Flickering stays same speed throughout 10 seconds. Simpler logic but no end warning. | |
| Fade out gradually | Character becomes more opaque over time until fully visible. Smooth transition but less obvious. | |

**User's choice:** Accelerating fade (recommended)

---

### Question 4: Can players end invulnerability early by taking action?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, on firing gun (recommended) | Invuln ends when player shoots. Prevents camping/exploit, lets aggressive players engage faster. Standard FPS rule. | ✓ |
| Yes, on any action | Invuln ends on shooting, reloading, sprinting, crouching. Very strict, may feel punishing. | |
| No early cancel | Invuln always lasts full 10 seconds regardless of actions. Simple but exploitable for positioning. | |

**User's choice:** Yes, on firing gun (recommended)

---

### Question 5: How transparent should invulnerable players be during flicker?

| Option | Description | Selected |
|--------|-------------|----------|
| 50% transparent (recommended) | Character alternates between solid and half-transparent. Clearly visible but obviously different. Good mobile visibility. | ✓ |
| 75% transparent | More ghostly appearance. Very obvious but character is harder to see (affects gameplay readability). | |
| 25% transparent | Subtle effect. Character mostly solid with slight flicker. Less obtrusive but may be missed on small screens. | |

**User's choice:** 50% transparent (recommended)

---

## Claude's Discretion

Areas where user indicated Claude should decide during planning/implementation:
- Flicker timing exact values (frequency, acceleration curve)
- Death screen UI during 3-second respawn delay
- Lobby button styling details (colors, fonts, animations)
- Post-game stat tiebreaker logic
- Sound effects for spawn/despawn/invuln-end
- Opt-in state persistence across rounds
- Invulnerability visual implementation approach

---

## Deferred Ideas

None — all discussion remained within phase scope
