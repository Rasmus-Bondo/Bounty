# Animation fetch guard — build spec

**Raised by:** 2026-08-07 Studio 2-client playtest. Log showed
`Failed to load animation with sanitized ID rbxassetid://123958453269998 (x2)`
and Dust's world revolver hold pose was missing.

## Diagnosis (settled — do not re-investigate)

The asset is fine. `GetProductInfo(123958453269998)` → `ShootRevolverServer`, AssetTypeId 24,
creator Outlaw Syndicate `647193849`, identical to `game.CreatorId`. Both that clip and the hold
clip `85888566430136` fetch successfully via `KeyframeSequenceProvider:GetKeyframeSequenceAsync`.
The URL in the error carries `serverplaceid=0` and the `(x2)` matches the two clients — a
transient CDN fetch failure, not a broken id or a permissions problem.

**The real bug is that the existing guards cannot detect it.** `Animator:LoadAnimation` returns a
track immediately *without* downloading the clip; the fetch resolves asynchronously afterwards. So
`pcall(function() return animator:LoadAnimation(anim) end)` returns `success = true` and a valid
track for a clip that never arrives. Consequences:

- The failure is silent — no warning anywhere.
- Retry loops that test a `playXxx()` helper's return value **exit on pass 1 on a false success**
  and never retry. This is what left Dust in his default pose.

`ContentProvider:PreloadAsync(instances, callback)` blocks until the fetch resolves and reports a
real `Enum.AssetFetchStatus`. Verified empirically: valid ids → `Success`, `rbxassetid://1` →
`Failure`. This is the only mechanism that distinguishes the two cases. Nowhere in either place
was `AssetFetchStatus` checked before this work (0 grep matches).

## The module — DONE, do not rewrite

`ReplicatedStorage.Modules.AnimationLoader` — **created in BOTH places, verbatim mirror**,
5113 bytes, checksum `2085980525`, compiles clean in both.

```lua
AnimationLoader.load(animator, animationId, opts) -> track, status   -- BLOCKS, authoritative
AnimationLoader.loadCached(animator, animationId, opts) -> track, status -- never yields
AnimationLoader.prewarm({ ids })                                     -- fire-and-forget warm
AnimationLoader.isRetryable(status) -> boolean
AnimationLoader.getStatus(animationId) -> Enum.AssetFetchStatus?
```

`opts = { Priority = Enum.AnimationPriority.*, Looped = boolean, Name = string }` — the module
sets all three on the track, so callers should delete their own `track.Name/.Priority/.Looped`
assignments. `track` is nil unless `status == Success`. Statuses are cached per id, so the yield
is paid once per clip per session.

### Two hazards that must be respected at every call site

1. **`load()` yields.** Anything that can be superseded while parked — a newer character, a newer
   menu build, a mid-match hunter switch — must re-check its own token/state *after* the call.
   `ViewportRigAnimationClient:189` (Bounty) already documents this trap for its build token.
2. **Never `load()` on a per-shot path.** Use `loadCached`. `HunterWorldModel:PlayOneShot` fires on
   every revolver shot; a blocking preload there would stall combat.

## Status

### Done and compile-verified
| Script | Place | Change |
|---|---|---|
| `ReplicatedStorage.Modules.AnimationLoader` | both | new module, mirrored |
| `ReplicatedStorage.Hunters.Shared.HunterWorldModel` | Redwater | `_loadTrack` → `AnimationLoader.load` + returns status; `_playIdle` propagates status; `EnsureIdle` warns on exhaustion; `PlayOneShot` → `loadCached`. 0 raw `LoadAnimation` left. Covers **Fortuna + Vesper + Bram** world guns. |
| `StarterPlayerScripts.Dust.WorldRevolverAimIdleClient` | Redwater | `load` + post-yield re-check + `prewarm` at script start |

### Done — Redwater (2026-08-07, compile-verified)
| Script | Change |
|---|---|
| `StarterPlayerScripts.FortunaCardsWorldIdleClient` | `load` + token snapshot re-checked after the yield + `prewarm` at script start. The retry loop now actually retries. |
| `StarterPlayerScripts.BramWorldIdleClient` | `load` + token/`isBramPlayer` re-check + `prewarm`. **No new retry loop was needed** — the existing 0.35s watchdog was already shaped like one and only ever ran once because the false success made it believe the pose had settled. Warn is throttled to one line per character per 10s (weak-keyed table) because the watchdog would otherwise warn ~3×/s on a dead clip. |
| `StarterPlayerScripts.HunterPortraitClient` | `load` + `model.Parent` / humanoid re-check + `prewarm`. Call site moved to `task.spawn` — `updatePortrait` runs in a loop over every ScreenGui. |
| `ServerScriptService.Bots.BotController` | The one private helper now calls **`loadCached`**, not `load`: it runs inside `BotController.new`, and `BotService` has already parented the rig into Workspace, so a blocking fetch would park a visible bot at its spawn point before the post-construction `PivotTo`. A module-level `task.spawn` prewarm resolves every bot clip at **server start** (all four hunters × Idle/Shooting/Scope/Unequip/Charging, the `BotAnimate` sets, and the static ids), so by the first round the cache is authoritative. Fortuna's double-jump id lives on the config table and is prewarmed at the top of `.new`. |

### Done — Bounty (2026-08-07, compile-verified)
| Script | Change |
|---|---|
| `StarterPlayerScripts.LobbySpawn` | `load` + `humanoid.Parent` re-check; bulk `prewarm` of all five lobby idles at script start. Safe to yield only because the caller already wraps it in `task.defer`. |
| `StarterPlayerScripts.CollectionClient.PreviewModel` | `load` + `model.Parent` re-check + `prewarm`. **Cannot be spawned** — `create` returns the track for `destroy` to pair with — so the prewarm is what keeps the yield off the interactive path. |
| `StarterPlayerScripts.CollectionClient.ViewportIcon` | `load` + `model.Parent` re-check + `prewarm`; `render` calls `playIdle` via `task.spawn`. |
| `StarterPlayerScripts.BattlePassClient` | `load` + `rig.Parent` re-check; bulk `prewarm` of every queued emote clip immediately before the serial render loop, so N cards cost one round-trip. Drain was already inside a `task.spawn`. |
| `StarterGui.CollectionGui.CollectionGuiController.Viewport` | `playIdle` → `load` (one shared clip, prewarmed at module load) + `model.Parent` re-check. `playEmoteAnim` → **`loadCached`**: a different id per tile means there is no single clip to warm, and blocking would stall the EMOTES tab one round-trip per emote. |
| `StarterGui.ReworkReworkedBuyMenu.EmoteBuyController` | `load` inside a `task.spawn` (the function is void) + `rig.Parent` re-check; bulk `prewarm` before the card build loop, read from the authored `Emotes` values folder so the ids match exactly what `loadPreview` asks for. Script-strip and camera framing stay synchronous so a rig's own scripts die before they can start an idle. |
| `StarterGui.ReworkReworkedBuyMenu.HuntersBuyController` | `load` + `model.Parent` re-check + `prewarm` at script start. |

### Deliberately NOT changed (one-shot action clips — a dropped frame is invisible and self-corrects)
`RevolverViewModel`, `RevolverReload`, `HighNoonGunFX`, `RevolverDashService`,
`Bram.GrudgekeeperClient`, `Fortuna.CardsClient`, `Workspace.WorkingChest`, `ChestController`.

### Already preloaded before this work — leave alone
`VesperViewModelAnimationClient`, `SunspikeClient`, `VictoryShowcaseClient` (Redwater);
`FeaturedSequence`, `BattlePassRigAnimationClient`, `ViewportRigAnimationClient`,
`TradingPostController` (Bounty). Note these preload but discard the status, so they fix the
*timing* case only. Upgrading them to check status is optional follow-up, not in scope.

## The client half — DONE (2026-08-07)

`HunterWorldModel` and `BotController` are **server-side**. Their tracks replicate as an id and
each client fetches independently, so the server-side guard protects the server's own load (a real
failure — if the server can't fetch, nobody sees it) but **cannot fix a client's fetch failure**,
which is what the original log showed: the error appeared `(x2)`, once per connected client, never
on the server. The same holds for a clip played by another *player's* client — a character's
network owner plays the track and it reaches everyone else as an id.

**`StarterPlayerScripts.WorldAnimationPrewarmClient`** (Redwater, new, 206 lines, compiles) closes
it. Ungated and at the **root**, because what it warms is what you see on *other* people — every
viewer needs it whatever their own hunter is, and `HunterClientLoader` would disable it inside a
hunter folder.

| Tier | Ids | When | Source |
|---|---|---|---|
| 1 | **12** hunter world-gun clips | script start | Dust's 2 as string literals; every `Animation` child of `Hunters.Fortuna.Cards.WorldAnimations`, `Hunters.Vesper.WorldModel`, `Grudgekeeper.WorldModel` |
| 2 | **48** bot clips | local character exists **+ 3s cushion** | the 3 static ids from `BotController` + every `Animation` **descendant** of `BotAnimate.Animate` |

- **Retry and report:** anything short of `Success` is re-prewarmed at 5s and 15s, then **warned
  once at 45s naming the ids**. `resolve()` only short-circuits on a cached `Success`, so a previous
  `Failure` genuinely refetches.
- **Tier 2 is deferred and that is free.** Prewarming never makes a clip play — a replicated track
  fetches on its own the moment it arrives — so nothing downstream depends on the timing. The
  cushion exists only so ~50 fetches don't contend with map streaming and the viewmodel at join.
- **`GetChildren` for the hunter folders, `GetDescendants` for `BotAnimate`.** Vesper's `WorldModel`
  also holds the `Sniper` model; the stock Animate layout nests each `Animation` one level inside a
  named `StringValue`, and `idle` alone holds two. This makes tier 2 a superset of `BotController`'s
  own prewarm, which takes only `FindFirstChildWhichIsA` per set.
- **Bots need this for the same reason players do:** `BotVisualClient` renders a bot from a clone
  whose Motor6Ds are copied off the server rig each frame (`pair.Visual.Transform =
  pair.Source.Transform`), and that server rig is animated on this client by this client's own
  Animator.
- **Dust's ids are a fourth copy.** `Hunters.Dust.WorldAnimations` is authored **empty**, so his hold
  and shoot ids are string literals in `RevolverWorldModelServer`, `WorldRevolverAimIdleClient`,
  `BotController.getWorldAnimationId` and now here. Change one, change all four. (`WorldRevolverAim-
  IdleClient` already prewarmed the hold — but it returns early unless the local player *is* Dust,
  so it warmed the clip on the one client that never needed to fetch it.)

**Verified:** compiles; all 12 tier-1 ids resolve `Success` through `AnimationLoader` in edit mode;
graph edge is `worldanimationprewarmclient → animationloader` and nothing else.

## Post-implementation checklist

- [x] `loadstring(script.Source)` compile-check every edited script — all 11 report `COMPILES`.
- [x] Re-verify the mirror: **5113 bytes / fnv `795ebe54` in both places**, confirmed via preflight's own Step 1 snippet with the new row in it (all 17 rows match).
- [x] **`AnimationLoader` added to the mirrored-module list** — 17th entry, updated in all **four** files `CONVENTIONS.md` names as needing to move together (`CLAUDE.md`, `changelog/CONVENTIONS.md`, `.claude/skills/preflight/SKILL.md`, `.claude/skills/changelog/SKILL.md`) plus the two "16 mirrored modules" pointers in `CHANGELOG.md`. Preflight's row is `{"AnimationLoader", RS.Modules}` — note the container is `RS.Modules`, not `RS`.
- [x] Vault `.md` created in both vaults; Connections updated in all 13 caller files.
- [x] `python update_redwater_canyon_graph.py` and `python update_bounty_graph.py` run.
- [x] Edges verified: 6 in Redwater, 7 in Bounty, **all `_src: <caller>` → `_tgt: animationloader`**, and zero `_src: animationloader`.
- [x] Changelog entry appended to `changelog/UNRELEASED.md` (anchored Edit); the cumulative **Shared modules** line flipped from "none yet" to the new mirror; residual gap logged in `OPEN-ITEMS.md`. Session capture retired to `consumed/`.
- [ ] **Both places publish together** — the mirror makes a half-publish a live drift bug. Manual, in Studio.

### Trap found while doing the vault work — do not re-derive

Writing `**Required by:** [[Caller]]` in `AnimationLoader.md` **created backwards edges.** A wikilink
becomes an edge whose `_src` is the node of the *file it was written in*, so a "Required by" wikilink
points dependency → dependent. When the dependent's own file also declares the `require()`, the two
form a reciprocal pair and the graph keeps whichever it parsed first. Five of six kept the correct
direction; `HunterWorldModel` lost the race, and the graph asserted `animationloader → hunterworldmodel`
— reading as though this module required the hunter world model. A `--full` rebuild did not fix it,
because it was never a cache problem.

Fix: **`AnimationLoader.md`'s "Required by" list is plain text, not wikilinks.** Each caller declares
its own `require()`, which is the edge the graph needs; writing it on both sides only creates a race.
This applies to any module `.md` with many dependents.
