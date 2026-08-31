---
tags: [client, localscript, fx, bram]
path: game.StarterPlayer.StarterPlayerScripts.BramWorldFXClient
type: LocalScript
lines: 387
---

# BramWorldFXClient

Ungated Bram world-FX + victim-pin client — runs for EVERY player regardless of hero (same placement convention as `FortunaCardsWorldVisibilityClient`). Exists because victims and bystanders of Bram's abilities are usually playing other heroes, whose clients never load the hero-gated `GrudgekeeperClient`.

## What it does
1. **Breach Charge pin-follow on the local player**: character physics are client-owned, so when [[BreachChargeService]] pins the local player it sends a directed `BreachChargeFX` `"Pin"` message (Bram's character + a carry-offset CFrame); this script then locks the victim's HumanoidRootPart just ahead of Bram every Heartbeat (`CFrame.lookAt(bramRoot.CFrame * offset ...)`, velocity zeroed) — following Bram locally with no per-frame server traffic (same "follow a moving anchor" idea as Vesper's grapple pull). The offset carries a **lane** component so two carried players don't share one point. Each frame the carry point is **clamped to clear space** by [[BreachCarryGeometry]]`.clampToClearSpace`, a spherecast (`CarryCastRadius` 1.5) from Bram's position stopping just short of anything solid — a centre ray is not enough against the map's lattice cover, where it reports "clear" on ~6% of headings that a body would collide with. That was a fourth hand-copy of the same cast, with its own `1.5` / `0.1` literals, until 2026-08-05; sharing it means this prediction and the server's authoritative write can no longer disagree about where "clear" is. The carry *point* is still built from the server's offset rather than the module's `carryPoint`, because this client does not know its own lane.

**This loop is no longer authoritative.** As of the 2026-08-01 fix the server takes network ownership of a player victim for the carry, so what happens here is client-side *prediction* against the server's write rather than the source of truth. It was promoted to prediction precisely because it could not be trusted as truth: a player owns their own character, so this loop was silently overriding the server's correctly-clamped position every frame, and under `StreamingEnabled` it cannot clamp against geometry the client has not loaded at all. The clamp is kept here as belt-and-braces for the frames before the ownership handoff lands. Ends on the `"Unpin"` message (or a 4s safety cap), which is now **bare — it only stops the follow loop**. Until 2026-08-05 a wall-slam release carried a safe position + charge forward as args 2-3 and this handler seated the victim there, behind a push-back-only guard measured against this client's own root position. **That was removed because the guard failed routinely and took the whole reseat with it** — the reported symptom being a slammed player left short of the wall while bots landed flush. It was reading the *lagging* copy: the server has owned and driven carried players since 2026-08-01, so the premise it was written under — "only this client knows the victim's true position" — had inverted, and the comment asserting it was never revisited. `_unpin` also hands ownership back *before* firing the remote, so the guard ran mid-flip. [[BreachChargeService]]`._resolveSlam` now writes the settle server-side while it still holds ownership, by the same call the bot branch uses, so both victim types land on the identical point. Nothing is applied here any more, and the arguments should not be reintroduced — two appliers is what let the reseat go missing silently. Bots are dragged server-side; the server keeps `KnockbackGraceUntil` fresh so MovementChecker ignores the drag
2. **Grab + slam flashes** for everyone: a `"Grab"` broadcast pops an expanding ForceField sphere at a newly-pinned victim; a `"Slam"` broadcast pops a larger one at the wall impact point
3. **Shrapnel Shell VFX** for everyone: shell tracer via [[laserBeamEffect]] (skipped for the caster, who drew a local one in `GrudgekeeperClient`) + two expanding rings sized to the real 5.4/12.2 stud radii — victims see why they got slowed
4. Waits for the server-created `Hunters/Bram/Remotes` folder (30s timeout, warns + disables on failure)
5. Bot Bram casts render through this same script — [[BotCombat]] fires the authored remotes rather than duplicating the FX, so a bot's shell and charge look identical to a player's
6. **Last Call public tell** (added 2026-07-26, recoloured 2026-08-05): mounts `BramLastCallHighlight` on every Bram player's character for the ultimate's duration — the same Highlight (`12,12,15` fill at 0.5, `240,245,255` outline, Occluded depth) that `playBramUltimateStart` in `BotVisualClient` builds for bot Brams, so a real Bram's 50% damage-reduction window no longer reads as bullets simply not registering. **Keep the two property sets in sync.** The colour sits deliberately outside Bram's ember palette: it shipped amber (`214,106,42` fill at 0.55, `255,170,90` outline) and players read an ulting Bram as the bounty target, because `BountyService.applyHighlight` is also an amber wash over a whole character. Black body plus a bright rim separates by **value** rather than hue, which survives distance and the orange canyon behind him. The script's own `EMBER_COLOR`/`FLASH_COLOR` constants belong to the Shrapnel Shell FX (impact spheres + projectile trail) and are no longer used by the ult — the dedicated `LAST_CALL_FILL_COLOR`/`LAST_CALL_OUTLINE_COLOR` constants exist so a future tidy-up cannot re-couple the two. Unlike the bot path there is no broadcast: `LastCallModule` only notifies the caster, so this watches the character's replicated `UltimateActive` attribute instead. Being state rather than an event, it needs no safety-net expiry and covers late joiners and streamed-in characters. `UltimateActive` is set by every hunter's ultimate, so the `SelectedHunter == "Bram"` check is what keeps the tell off Dust/Fortuna/Vesper — and a mid-match hunter switch drops it

## Dependencies
- **Requires:** [[laserBeamEffect]] (from `ReplicatedStorage.Hunters.Dust.Modules`), [[BreachCarryGeometry]] (from `ReplicatedStorage.Hunters.Bram.Config`)
- **Required by:** Nobody (self-running LocalScript)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `BreachChargeFX` | ← Server | [[BreachChargeService]] sends `Pin`/`Unpin` (directed carry-lock) + `Grab`/`Slam` (broadcast flashes) |
| `BreachChargeFX` | ← Server | [[BotCombat]] sends the same messages for a **bot** Bram's simplified single-victim charge |
| `ShrapnelShellFX` | ← Server | [[ShrapnelShellService]] broadcasts shooter, shell line, explosion point + radii |
| `ShrapnelShellFX` | ← Server | [[BotCombat]] broadcasts a bot Bram's shell; the handler ignores its shooter argument, so the bot Model is passed where a Player would be |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[laserBeamEffect]] | `(startPos, endPos)` | Shell tracer for non-casters |
