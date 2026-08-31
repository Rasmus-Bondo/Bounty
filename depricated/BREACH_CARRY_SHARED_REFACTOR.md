# Breach Carry — shared geometry refactor

**Status:** **IMPLEMENTED 2026-08-05** — unverified, unpublished · **Raised:** 2026-08-05 ·
**Place:** Redwater Canyon only

> **Migration complete.** Steps 1–6 all landed in one pass; the preconditions below were met first
> (#5, #6, #9 and #23 all read `VERIFIED`). What the migration actually found is recorded inline —
> see *Divergences found on the 2026-08-05 diff* under the wall test, which is the record step 4
> asks for. Four things worth knowing before touching this area again:
>
> - **The clamp had FOUR copies, not the two this spec inventoried.** `BramWorldFXClient:208`
>   inlined the same cast with its own `1.5` / `0.1`.
> - **`BreachChargeService` had a THIRD `slotLateral` call site** the inventory missed, in `_pin`,
>   building the object-space lane offset for the client's `"Pin"` message. That is why the module
>   exports `laneOffset` separately from `carryPoint`.
> - **Two live bugs were found in passing**, neither in this spec: the client wall test had been
>   running without `RespectCanCollide` for its entire life (its cached params are built first by
>   `isGroundedForBreach`, which does not set the flag), and the bot's slam settle wrote identity
>   rotation, snapping victims to face world +Z.
> - **`workspace.CHARGEPOINT` has been deleted** since Hotfix 3, so the recorded baselines at that
>   site cannot be reproduced. The A/B harness was broadened across the map instead: 10,944 wall-test
>   comparisons, zero mismatches.
>
> The *Related findings* section at the end is still **open work** and was deliberately not touched.

Extract the duplicated carry/wall/slam geometry behind Bram's Breach Charge into one module that
all four implementations call, so a fix lands once instead of three or four times.

**This is a spec for a cold session.** It assumes no prior context beyond `CLAUDE.md`. Read the
whole thing before touching anything — the ordering in *Migration* is load-bearing and the
behaviour fixes are deliberately quarantined to the last step.

**The Bram work is the deliverable.** A sweep of the other three hunters turned up the same defect
class elsewhere; those findings are recorded under *Related findings* near the end. They are
**separate work** and must not be folded into this migration — but they share a root cause and the
same blocking playtest, so they are kept together deliberately.

---

## Why

Bram's charge exists in four places. The *decision* layer legitimately differs between them; the
*geometry* layer does not, and has been hand-copied. Every bug in this area for the last week came
out of that split:

- Launch issue **#5** (cooldown start) had to be fixed in **three** implementations.
- Launch issue **#3** (High Noon death audio) was missing on the player path — **the bot had it
  right all along.**
- Launch issue **#21** (bot bounties) had no bot path at all.
- The open **`_slamPin`** bullet in `changelog/OPEN-ITEMS.md`: the slam settle was written for
  players, written again for bots, and the two disagree.

There is a note in project memory (`feedback_fix_every_implementation`) that exists purely to remind
an agent to ask "is there a bot version?" That note is a workaround for this architecture, not a
feature of it. This refactor is the thing that would retire it.

---

## Preconditions — do not start yet

**Wait until the current unverified backlog is published and playtested.** As of 2026-08-05 the
charge carries unverified fixes for launch issues **#5, #6, #9 and #23**, all sitting in Studio
unplayed. Refactoring underneath them makes any playtest regression unattributable — you will not
know whether you broke it or whether #23 was never right.

Start when `changelog/OPEN-ITEMS.md` shows those four as `VERIFIED`.

---

## The four implementations

| # | Script | Lines | Role |
|---|---|---|---|
| 1 | `ServerScriptService.Hunters.BramServer.BreachChargeService` | 793 | Player charge authority: carry loop, wall re-verify, slam resolution |
| 2 | `StarterPlayer.StarterPlayerScripts.Bram.GrudgekeeperClient` | ~1000 | Player input, steering, wall **detection** and report |
| 3 | `StarterPlayer.StarterPlayerScripts.BramWorldFXClient` | 387 | Victim-side pin FX; applies the slam reseat |
| 4 | `ServerScriptService.Bots.BotCombat` | 2087 | Bot charge, entirely server-driven |

---

## What is ALREADY shared — do not redo it

This refactor is narrower than it first looks. The foundations were unified deliberately and both
paths already agree:

| Concern | Shared via |
|---|---|
| All tuning values | `ReplicatedStorage.Hunters.Bram.Config.GrudgekeeperConfig` — both read `BramConfig.BreachCharge.Pin` |
| Stun | `HunterStatusEffects:ApplyStun` |
| Combat lockout | `HunterActionLock` — `BotCombat:1739` calls `ReleasePin` |
| WalkSpeed overrides | `HunterMovement` |
| Anti-cheat grace | `MovementGrace.HoldUntilLanded` — `BotCombat:1750` |
| Visual effects | Both fire the same authored `BreachChargeFX` remote |

**The duplication is exactly one layer: the geometry.**

---

## Inventory of duplicated logic

### 1. Wall test — three copies

| Copy | Signature | Returns |
|---|---|---|
| `BreachChargeService:_isWallAhead:414` | `(character, charge, rootPart, distance)` | `(boolean, wallPos)` |
| `BotCombat:_isWallAhead:1607` | `(origin, direction, distance, victimChar)` | `RaycastResult?` |
| `GrudgekeeperClient.detectBreachWall:799` | `(rootPart, chargeDir)` | `boolean` |

All three do the same thing: a centre ray **OR** a body-width spherecast, either qualifying counts;
a hit qualifies when it is collidable, not part of a character, and `|normal.Y| <= cos(55)`.

All three carry a comment saying they MUST match the other two. That comment is the smell this
refactor removes.

Constants, currently three hand-maintained copies that happen to agree:

| Constant | `BreachChargeService` | `BotCombat` | `GrudgekeeperClient` |
|---|---|---|---|
| max normal Y | `:41` = `cos(55)` | `:1540` = `cos(55)` | `:798` = `cos(55)` |
| cast radius | `:145` `WallCastRadius or 1.5` | `:1625` `WallCastRadius or 1.5` | `:841` `Pin.WallCastRadius or 1.5` |

**The stakes on this one are the highest in the refactor.** `GrudgekeeperClient` is what *reports*
a hit and `BreachChargeService` *re-verifies* it. A test the server does not share turns every
reported slam into a rejected "no wall" and a 15-damage whiff.

#### Divergences found on the 2026-08-05 diff (migration step 4)

Recorded before resolving, as the migration requires. The two headline constants — cast radius and
max normal Y — **do agree** across all three; so do ray-before-sphere order, `IgnoreWater` and
`RespectCanCollide`. Four things did not:

1. **The distance is a different config KEY on the client, not just a different value.** The client
   reads `BreachConfig.ChargeWallCheckDistance` (**5**); both servers read `Pin.WallCheckDistance`
   (**8**), and the re-verify uses `Pin.WallVerifyDistance` (18). This is the authority split working
   as designed — the client reports early and the server re-verifies generously — but two similarly
   named keys one table apart is a trap. **Resolved by the API:** `distance` is a parameter, so each
   caller keeps its own constant and the module never picks one.
2. **The character test is not the same test.** `BreachChargeService:454` and the client `:847` take
   `FindFirstAncestorOfClass("Model")` and ask whether *that* model has a Humanoid. `BotCombat` uses
   `getCharacterFromPart:154`, which walks **every** ancestor up to `workspace`. They differ when the
   nearest Model ancestor of the hit part is a nested non-character Model inside a character — a
   world-gun model parented into the rig, say: the walk-up correctly calls it a character, the other
   two call it a **wall** and grant a slam off a player's gun. Only reachable for a character not
   already in the caster's exclude list, so the client (which excludes every player character and
   `ArenaBots`) cannot hit it and **both server copies can**. **Adopted the walk-up version** for the
   shared module — it is the strictly-correct one, and it is the only place in steps 1–5 besides the
   clamp guard where behaviour moves.
3. **`BotCombat`'s exclude list is wider than either other copy's**, and nothing documents it.
   `_rayParams():363` also excludes the `VesperHookSpotsBot` and `WallMap` workspace folders, so a
   **bot** Bram cannot slam a victim into anything parented under them, where a player Bram can.
   Preserved exactly — the exclude list is caller-supplied and this is a bot-AI decision, not
   geometry — but it is a live behavioural difference between bot and player charges and belongs in
   *What must NOT be unified* rather than being quietly normalised.
4. **The clamp has FOUR copies, not two.** `BramWorldFXClient:208` inlines the same spherecast with
   the same shape and its own hardcoded `1.5` / `0.1` literals. The inventory below says two. It is
   migrated with the rest.

One more, on the carry point rather than the wall test: `BreachChargeService:388` builds it from the
**unflattened** root CFrame (`rootPart.CFrame * CFrame.new(lateral, 0, -CarryDistance)`) while
`BotCombat:1839` flattens (`Position + flatLook * CarryDistance`). Identical for an upright
HumanoidRootPart, which is every case here — a Humanoid keeps its root level and the charge drives
velocity, not CFrame — so this is latent rather than live. The module flattens, matching the bot and
matching what all three wall tests already do.

### 2. Clear-space clamp — two copies

- `BreachChargeService:_clampToClearSpace:337`
- `BotCombat:_clampCarryToClearSpace:1653` — its own comment says "Mirrors
  BreachChargeService._clampToClearSpace"

Constants agree today: radius `1.5` (`:44` / `:1543`), epsilon `0.1` (`:45` / `:1544`).

**One real behavioural divergence.** The bot copy has an extra guard at `:1676`:

```lua
if not result or getCharacterFromPart(result.Instance) then return candidate end
```

The player copy has no character test (`:357` is `if not result then return candidate end`). That
guard is a **vestige**: `BotCombat:1659-1664` documents a bug where the clamp was a no-op on every
frame because the cast hit the victim and the character guard returned the unclamped candidate. The
fix was to exclude the victim in `FilterDescendantsInstances` — but the guard was left in.

Consequence today: a *third-party* character standing between the bot and the carry point makes the
clamp a no-op for that frame.

**Decision: drop the character guard.** Both callers already exclude the caster and the victim; a
third character in the path should clamp, not be ignored.

### 3. Slam settle — two copies, three divergences

- `BreachChargeService._resolveSlam` → local `settleFor:521` — backs off the wall face by
  `SlamWallClearance` (**2**), applies the victim's lane offset, then clamps to clear space.
- `BotCombat:_slamPin:1788` — `wallResult.Position + wallResult.Normal * 3`.

Divergences:

1. **Hardcoded `3` vs the config's `2`.** `config` is already bound to `BramConfig.BreachCharge.Pin`
   at `BotCombat:1777`, so `config.SlamWallClearance` is in scope and simply unused. The config
   comment at `GrudgekeeperConfig:87` says outright: *"Do not raise this much — at 3 the victim
   visibly bounces off the wall instead of being slammed into it."*
   Hotfix 3 claims to have fixed this 3 → 2; that landed in `_resolveSlam`'s bot-victim branch. This
   literal was never touched.
2. **No lane offset** on the bot path. Harmless — see *What must NOT be unified*.
3. **Player victims are skipped entirely.** `BotCombat:1787` reads `if victimRoot and not pin.Player
   then`. A player slammed by a bot Bram falls through to `_releasePin`, which fires a bare
   `fx:FireClient(pin.Player, "Unpin")` at `:1757` with no position arguments — and the client's
   reseat block at `BramWorldFXClient:229` requires `typeof(a) == "Vector3" and typeof(b) ==
   "Vector3"`, so it is skipped. This is the open bullet in `OPEN-ITEMS.md`.

### 4. Lane offset

`slotLateral` is a file-local at `BreachChargeService:28`. The bot path has no lanes.

---

## Ownership — read this before designing anything

This is the part most likely to be got wrong, and it changed recently.

**During the carry, both paths are server-authoritative.** `BreachChargeService:_maintainPins:392-405`
takes ownership of player victims (`ensureCarryOwnership`) and the server drives them directly; the
victim's own client pin loop still runs but is now local prediction, not the source of truth.
`BotCombat` does the same via `ensureBreachOwnership` at `:1860`. So the old rule "you cannot move a
player from the server" does **not** apply inside the carry.

**At the slam, the two paths diverge for a real reason.** The player path routes the settle through
the victim's client (`_unpin` → `"Unpin"` with `safePos` + `faceFlat` → `BramWorldFXClient:229-237`).
The reason is at `_resolveSlam:576-582`: the settle must be a push **back** only, never a pull
forward — `WallVerifyDistance` is a generous 18, so a slam can be granted with the victim still short
of the wall, and yanking them onto it would be worse than the bug. That decision is measured along
`faceFlat`, which derives from **Bram's** root — and Bram's server HRP lags his client-owned one, so
the server cannot judge the distance itself.

**That reason does not apply to the bot path.** A bot's root *is* server-authoritative, no lag. So
the bot can evaluate the same past-the-plane test server-side and write directly — while it still
holds ownership, i.e. **before** `_releasePin` calls `releaseBreachOwnership` at `:1745`.

**Design consequence:** the shared module exposes the settle **computation** and the **past-the-plane
test** as pure functions. It does not apply anything. Each caller applies the result its own way —
player path via the remote, bot path via a direct write.

---

## Target design

### Placement

`ReplicatedStorage.Hunters.Bram.BreachCarryGeometry` — a new ModuleScript beside the existing
`Config` folder.

**Not `Hunters.Shared`.** `CLAUDE.md` scopes that folder to hero-agnostic code and this is
Bram-specific. It must live in `ReplicatedStorage` because two of its four callers are LocalScripts.

*(The clear-space clamp is arguably generic enough for `Hunters.Shared` — any displacement ability
could want it. Deliberately not generalised now: no second caller exists. Revisit if Vesper's
grapple or Fortuna's recall ever needs it.)*

### API

Stateless, no `self`, no instances retained. Every constant resolved from `GrudgekeeperConfig` at
call time — no module-local literals, since duplicated literals are the thing being deleted.

```lua
-- Ray OR body-width spherecast; a hit qualifies when collidable, non-character,
-- and |normal.Y| <= cos(55). Returns the RaycastResult, or nil.
BreachCarryGeometry.findWall(origin: Vector3, flatDir: Vector3, distance: number,
                             exclude: {Instance}) -> RaycastResult?

-- Never write a carried body into geometry: spherecast from a known-clear origin
-- toward the intended point and stop short of whatever is in the way.
BreachCarryGeometry.clampToClearSpace(fromPos: Vector3, candidate: Vector3,
                                      exclude: {Instance}) -> Vector3

-- Where a carried victim rides: CarryDistance ahead, offset into their own lane.
BreachCarryGeometry.carryPoint(chargerCF: CFrame, slot: number?) -> Vector3

-- Where a slammed victim is left: back off the wall FACE by SlamWallClearance,
-- into their lane, at their own Y. Does NOT clamp — the caller clamps, because
-- the exclude list differs between the carry and the release.
BreachCarryGeometry.settlePoint(wallPos: Vector3, faceFlat: Vector3,
                                victimY: number, slot: number?) -> Vector3

-- Push BACK only, never pull forward. True when the victim is past the safe plane.
BreachCarryGeometry.isPastPlane(victimPos: Vector3, settlePos: Vector3,
                                faceFlat: Vector3) -> boolean
```

`isPastPlane` is the dot product currently inlined at `BramWorldFXClient:232`. Sharing it is what
lets the bot path adopt the same push-back-only rule without re-deriving it.

---

## What must NOT be unified

Getting this wrong turns a refactor into a gameplay change.

- **Input / decision.** Player = keypress, camera steering, client cooldown meter. Bot = target
  selection, distance-scaled duration (0.45s–`Time`), `DashToward`. Genuinely different code.
- **Wall detection *authority*.** Player: client detects at `WallCheckDistance` and reports, server
  re-verifies at `WallVerifyDistance` (18). Bot: server detects directly. The module supplies the
  **test**, never the authority.
- **Single vs multi-victim carry.** A bot carries only the FIRST enemy it catches
  (`BotCombat:1841-1848`); a player carries several in lanes. **Do not "unify" the bot to
  multi-victim** — that is a balance change, not a refactor. `settlePoint` takes an optional `slot`
  defaulting to 1 precisely so the bot can ignore lanes.
- **Slam application.** Player via remote, bot via direct write. See *Ownership* above.
- **The #23 clash guards.** `_scanForPins` returning true on a clash, and the
  `ActiveCharges[player] ~= charge` bail that must remain the **first** statement in `_updateCharge`.
  Both are load-bearing and unrelated to geometry.

---

## Migration — in this order

**Steps 1–5 are strictly behaviour-preserving.** Step 6 is the only one that changes what a player
sees. Do not blend them; if you do, a playtest regression cannot be attributed.

1. **Create `BreachCarryGeometry`** with the union of the existing behaviour. Confirm every constant
   it needs exists in `GrudgekeeperConfig.BreachCharge.Pin` — `WallCastRadius` already does
   (`BotCombat:1625`); add `CarryCastRadius` (1.5) and `CarryCastEpsilon` (0.1) if absent, matching
   the current literals exactly.
2. **Migrate `BotCombat`.** Smallest, server-only, single-victim, no client contract. Delete
   `_isWallAhead`, `_clampCarryToClearSpace` and the local constants at `:1540-1544`. Keep the
   character guard **out** (see divergence 2).
3. **Migrate `BreachChargeService`.** Delete `_isWallAhead`, `_clampToClearSpace`, `slotLateral` and
   the constants at `:41-45`. Its `_isWallAhead` returns `(boolean, pos)` while the module returns a
   `RaycastResult` — adapt at the two call sites (`:690`, `:748`), do not change the module.
4. **Migrate `GrudgekeeperClient.detectBreachWall`.** Last, because it has the highest blast radius:
   a mismatch here whiffs every slam. Diff it against the two server copies first and record any
   divergence you find in this file before resolving it.
5. **Verify parity** (see below) with **no behaviour change yet**. This is the checkpoint — if the
   A/B harness is not clean, stop here.
6. **Only now, the behaviour fixes**, as a clearly separate change:
   - `BotCombat:_slamPin` — drop the `not pin.Player` gate; settle player victims too, guarded by
     `isPastPlane`, written directly **before** the `_releasePin` call at `:1795`.
   - `BotCombat:_slamPin` — the hardcoded `3` becomes `config.SlamWallClearance` (2), which
     `settlePoint` now supplies.
   - Optionally pass `safePos`/`faceFlat` through the bot's `"Unpin"` at `:1757` as a belt-and-braces
     second application. **Weigh it:** the direct write should be sufficient since the server holds
     ownership, and a redundant client write risks a visible double-correction. Prefer the direct
     write alone unless a playtest shows it losing.

---

## Verification

MCP playtesting is unavailable (`start_playtest` hangs the plugin), so this is probe + simulation +
a human checklist.

**Compile.** Every touched script via `loadstring(script.Source)`. Do **not** trust `require` —
the plugin's require cache holds the pre-edit copy (`feedback_plugin_require_cache`).

**Constant parity.** Assert the module's resolved values equal the old literals: cast radius `1.5`,
epsilon `0.1`, max normal Y `math.cos(math.rad(55))`. A drift here is silent.

**A/B harness — the core check.** Extract the old and new wall test, run both over ≥72 headings at
the two documented sites and assert **identical** results:

- the wooden lattice structure (1.4-stud beams, 0.6-stud panels)
- `workspace.CHARGEPOINT` — the corner that produced the original void deaths

Recorded baselines from Hotfix 3, usable as regression anchors: at the lattice, ray **43%** / sphere
**54%**; at CHARGEPOINT, ray **35%** / sphere **28%**; terrain −X face `|normal.Y|` **0.6502**
(ramp, no slam), `RockLarge` +Z face **0.0480** (wall, slam fires), terrain ground **0.7703** (ramp).

Do the same for the clamp over a spread of candidate points, including one with a third-party
character in the path — that case is *expected to differ* (divergence 2) and is the one intentional
behaviour change inside steps 1–5. Record it.

**Human playtest — needed regardless.** Two real players:

1. Player Bram slams a player into a wall — victim ends flush against it, not embedded, not bounced.
2. Player Bram slams a **bot** — same, and at 2 studs not 3.
3. **Bot** Bram slams a **player** — the new case. Victim seated against the wall rather than left
   floating short of it.
4. Bot Bram slams a bot.
5. Charge into the lattice cover and into `CHARGEPOINT` — the slam still fires where it used to.
6. A slam granted at long range must never *pull* the victim onto a wall they were clear of.
7. Multi-victim player carry still lanes correctly; nobody interpenetrates.

---

## Traps

Tool and codebase traps that will otherwise cost a round-trip each:

- **`grep_scripts` matches literals.** Regex alternation silently returns 0 results — `a|b` finds
  nothing and looks like "no references". One pattern per call.
- **The plugin `require` cache is stale.** Recompile with `loadstring(script.Source)` before
  trusting any module error.
- **`set_script_source` eats `\n` escapes** and breaks Lua string literals — use a `[[long string]]`
  and verify with `loadstring`.
- **Never partially overwrite a script.** `Edit` for spot changes; `set_script_source` needs the
  whole file.
- **Two Studio places are connected.** Pass `instance_id` — Redwater is `place:98517073248449`.
- **`execute_luau` runs at PluginSecurity**, so an edit-mode probe can pass for things a shipped
  LocalScript cannot do. Do not use it to "prove" a client-side write works.

---

## Related findings — same defect class, other hunters

Found during the 2026-08-05 sweep that produced this spec. **None of this belongs in the migration
above** — do not fold it in. It is recorded here because it shares the root cause (a bot
implementation that hand-copies a player-facing value instead of reading it) and the same blocking
playtest.

### A. Dust's bot block is the only one that hardcodes player tuning

Every other hunter's bot ability block reads its hunter's config:

| Hunter | Reads |
|---|---|
| Fortuna | `CardsConfig.Ability1.Range/.Cooldown/.CardsPerBurst/.Damage/.BurstDelay`, `CardsConfig.Recall.Cooldown`, `CardsConfig.Ability1.Dash.DashPeakSpeed` |
| Vesper | `VesperConfig.GrappleHook.Cooldown`, `VesperConfig.PinningRound.Cooldown` |
| Bram | `BramConfig.Basic.MaxRange`, `BramConfig.BreachCharge.*` |

**Dust (`BotCombat:1938-1957`) reads nothing:**

| Bot literal | Player's value | Status |
|---|---|---|
| `_ready("Dash", 4)` `:1938` | `RevolverConfig.Dash.Cooldown = 4` | agrees today, unlinked |
| `_ready("Fan", 8)` `:1941` | `RevolverConfig.Skill2.Cooldown = 8` (also `RevolverServerConfig.Combat.Skill2AbilityCooldown = 8`) | agrees today, unlinked |
| `task.wait(0.1)` `:1954` | `RevolverServerConfig.Combat.Skill2FireCooldown = 0.07` | **probable live drift — confirm first** |

The first two are this spec's `3`-vs-`SlamWallClearance` pattern exactly: correct today, silently
unlinked, so retuning Dust's dash or Fan moves players and not bots. That is precisely what made
launch issue **#5** a three-implementation fix.

**On the 0.1 vs 0.07 — confirm before changing it.** `Skill2FireCooldown` sits beside
`NormalFireCooldown = 0.4`, which *is* the real fire rate, and that parallel suggests 0.07 is the
player's genuine fan cadence and bots fan roughly 30% slower. Not traced: whether the client
actually paces at 0.07 or whether that value is only the server's validation floor. Establish which
before touching it — if it is a floor, the bot's 0.1 is correct and linking them would speed bots up
wrongly.

**Two things already checked and cleared — do not re-raise:**

- **The dash speed `58` at `:1940` is NOT a drift of the player's `DashPeakSpeed = 72`.**
  `BotController:DashToward:993` gives Dust bots a **WalkSpeed override** (`HunterMovement.SetBase`)
  along a pathfinding move, deliberately bounded by `MaxGroundHorizontalVelocity` (62) — a different
  mechanic from the player's velocity ramp (28 → 72 → 22 over 0.46s). `BotController:1042` states the
  62-exceeds-58 relationship outright. The number is legitimately its own.
- **`distance > 70` and the `16..95` fan band are bot AI decisions** with no player counterpart.
  Correctly bot-only; leave them as literals.

### B. Root cause of A — Dust has two config tables

Every other hunter has one config module. Dust has **two, with no `require` between them**:

| Module | Carries |
|---|---|
| `ReplicatedStorage.Revolver.Modules.RevolverConfig` | `Range 500`, `MaxAmmo 6`, `ReloadTime 1.5`, `Combat.FireCooldown 0.4`, `Skill2.Cooldown 8`, `Dash.Cooldown 4`, `Dash.DashPeakSpeed 72` |
| `ReplicatedStorage.Revolver.Modules.RevolverServer.RevolverServerConfig` | `Range 500`, `MaxAmmo 6`, `ReloadTime 1.5`, `Combat.NormalFireCooldown 0.4`, `Combat.Skill2AbilityCooldown 8`, `DashPeakSpeed 72` |

Independently declared, overlapping, hand-agreed. This is why the bot hardcodes: there is no single
obvious config to point at, so whoever wrote the block typed the numbers.

Dust is the only hunter still on the legacy `Revolver` path that predates the
`Hunters.<Name>.Config` convention — `Hunters.Dust.Config` contains only a `Manifest`. Consolidating
Dust onto the convention is the real fix for A, and is a larger job than A itself.

### C. Vesper bots never use their ultimate

`BotCombat:TryUltimate:1909` gates to Dust, Fortuna and Bram. There is no `_tryVesperUltimate`
anywhere in the place — **Starfall is player-only.**

**This needs an owner decision, not an implementer's.** It is not clear whether it is deliberate.
The evidence leaning toward oversight: this file comments its deliberate bot omissions heavily —
`_tryBreachCharge:1798-1801` explains why bots get a simplified charge, and the #23 write-up spells
out why bot Brams are excluded from the clash. Vesper's absence from the ultimate list carries no
comment at all.

Consequence if it is an oversight: a Vesper bot banks ultimate charge it can never spend, and on
bot-heavy servers one of four hunters never shows its ultimate.

---

## Obligations on completion

Per `CLAUDE.md`:

- **Vault.** New `LocalRedwaterCanyon/ReplicatedStorage/Hunters/Bram/BreachCarryGeometry.md` on the
  standard template. Update the Dependencies/Connections sections of `BreachChargeService.md`,
  `BotCombat.md`, `GrudgekeeperClient.md` and `BramWorldFXClient.md` — these gain a real
  `[[BreachCarryGeometry]]` require edge, which is a legitimate wikilink.
- **Graph.** `python update_redwater_canyon_graph.py` as a bare command, one per tool call. Then
  verify the edges landed:
  `Grep "\"_src\": \"breachcarrygeometry\"" graphs/RedwaterCanyonGraph/graph.json -A 1`
  Node ids are lowercased; `_src`/`_tgt` is the correct directed pair. Note that a node-count **drop**
  blocks the write and still prints "Done" — pass `--force` if the count legitimately falls.
- **Mirroring.** `GrudgekeeperConfig` is Redwater-only and is **not** one of the 16 mirrored modules.
  Confirm that still holds before editing it, and confirm the new module does not need mirroring
  (Bounty has no Bram combat code).
- **Changelog.** `/changelog` for this session's capture, then close the `_slamPin` bullet in
  `changelog/OPEN-ITEMS.md` in the same pass, noting the release.
