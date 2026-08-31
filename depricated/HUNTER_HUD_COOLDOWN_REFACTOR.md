# Hunter HUD cooldown — shared controller refactor

**Status:** ✅ **DONE AND VERIFIED 2026-08-06** — module built, all four hunters migrated, every
verification below run, and the human playtest signed off by the owner on desktop **and** mobile.
One nuance, not a blocker: the Last Call **pop** was added after the desktop playtest pass and is
covered by harness + mobile, so checklist item 5 carries a ⚠️ rather than a ✅.
· **Raised:** 2026-08-06 · **Place:** Redwater Canyon only

Two things landed that this spec did not originally call for, both recorded in place below: Bram's
Last Call now **pops** the refreshed tiles (owner request — resolves the contradiction between this
document's API block and its own Verification case 5), and `Destroy` was made throw-isolating per
tile. Kept as a record of what shipped, not as work to do.

Extract the duplicated skill-cooldown UI machinery out of the four hunter HUD clients into one
module, so a HUD change lands once instead of four times.

**This is a spec for a cold session.** It assumes no prior context beyond `CLAUDE.md`. Read the
whole thing before touching anything — the ordering in *Migration* is deliberate, and Dust is last
for a reason.

**Scope is the skill cooldown only.** The ultimate is explicitly *not* part of this; see *What must
NOT be unified*. Widening this to the ultimate is how a refactor turns into a gameplay change.

---

## Why

The hunters **do** share their UI. All four clone one authored `StarterGui.ReworkedHunterGui` and
rename the clone. What they do not share is the code that drives it: each hunter's HUD LocalScript
carries its own copy of the cooldown controller.

Measured on 2026-08-06 by normalising the skill names away and hashing the `setSkillReady` +
`startSkillCooldown` block:

| Hunter | Normalised block | Hash | Verdict |
|---|---|---|---|
| Fortuna | 1480 chars | `988023070` | — |
| Vesper | 1480 chars | `988023070` | **character-identical to Fortuna** |
| Bram | 1542 chars | `585756514` | Fortuna's code + one `cooldownTime <= 0` branch |
| Dust | 1572 chars | `266783882` | older variant, explicit-args signature |

The helpers are duplicated too. `getChargeSize` (hash `966405179`, 428 chars) and `setFrameSize`
(hash `619598145`, 113 chars) are **byte-identical** across Fortuna, Vesper and Bram, and absent in
Dust.

**Two concrete costs, both from 2026-08-06:**

1. **Adding the readiness bump was one shared module and four separate wirings.** `HunterHudBump`
   holds all the animation logic once, but the trigger point — "the ability just became ready" —
   exists four times, so it had to be threaded through four scripts by hand.
2. **A real bug was found while doing it, and had to be fixed four times.** `setSkillReady` cancelled
   the cooldown bar's tween but never retired the in-flight countdown *thread*. Respawn mid-cooldown
   and the stale thread keeps overwriting the restored `READY` label with a phantom countdown, then
   calls back into `setSkillReady` at expiry. The label flicker was latent for as long as the code has
   existed; the bump upgraded it to a visible phantom pop, which is how it was caught. **Fixed in all
   four on 2026-08-06** — four identical edits, which is this spec's argument in one line.

That second one is the pattern to watch. It is the same defect class as `feedback_fix_every_implementation`
in project memory: a note that exists to remind an agent to go looking for the other copies. This
refactor is the thing that retires the need for it here.

---

## What is ALREADY shared — do not redo it

This refactor is narrower than it first looks. Most of the surrounding layer is already unified:

| Concern | Shared via |
|---|---|
| The authored UI instances | one `StarterGui.ReworkedHunterGui` (`ScreenGui` desktop / `HunterGuiMobile` touch), cloned and renamed per hunter |
| Resolving the three tiles from a canvas | `HunterIntroTags:111` already walks `Canvas → AbilityFrame → 1Ability/2Ability → MainFrame` and `UltimateFrame → MainFrame` |
| Slot declaration and HUD order | `Manifest.Abilities.Slots` — ordered `Q, E, F`, with the comment *"Slot order is HUD order: 1Ability = Q, 2Ability = E, UltimateFrame = F"* |
| The readiness pop | `ReplicatedStorage.Hunters.Shared.HunterHudBump` |
| The ultimate charged glow | `ReplicatedStorage.Hunters.Shared.UltimateReadyFX` |
| Mobile ability buttons | `HunterMobileAbilityButton` — **verified fully decoupled**: it references none of `Cooldown`, `MainFrame`, `UIScale` or `setSkillReady` |
| Event plumbing | `HunterClientRuntime` + the manifest's `ClientEvents` |

**The duplication is exactly one layer: the cooldown controller.**

State is fully contained, too — a place-wide grep for `activeSkillTweens|cooldownVisuals|skillBumps|setFrameSize`
matches **only** the four HUD clients. Nothing external reads any of it, so the blast radius is those
four files.

---

## Inventory — line numbers current as of 2026-08-06

| Symbol | Dust `HunterGuiClient` (523) | Fortuna `CardsHunterGuiClient` (682) | Vesper `VesperHunterGuiClient` (1123) | Bram `BramHunterGuiClient` (801) |
|---|---|---|---|---|
| `activeSkillTweens` | 184 | 194 | 287 | 249 |
| `skillCooldownTokens` | 185 | 195 | 288 | 250 |
| `cooldownVisuals` | — *(none)* | 197 | 290 | 252 |
| `skillBumps` | 135 | — | — | — |
| `getChargeSize` | — | 215 | 308 | 270 |
| `setFrameSize` | — | 226 | 319 | 281 |
| `setSkillReady` | 336 | 398 | 491 | 453 |
| `startSkillCooldown` | 351 | 417 | 510 | 472 |
| `setUltimateCharge` | — *(in `HighNoonChargeUI`)* | 472 | 565 | 532 |

Skill keys per hunter — the shared module must not know these:

| Hunter | Slot 1 (Q) | Slot 2 (E) |
|---|---|---|
| Dust | `Skill1` | `Skill2` |
| Fortuna | `Recall` | `Ability1` |
| Vesper | `Grapple` | `Pinning` |
| Bram | `Breach` | `Shrapnel` |

### Divergences

1. **Bram alone has the zero-length branch** (`startSkillCooldown:483`): `if cooldownTime <= 0 then
   setSkillReady(skillName) return end`. **Decision: adopt it for all four.** A zero or negative
   cooldown should read ready immediately rather than build a zero-duration tween and flip on the next
   0.05s tick. This is the one intentional behaviour change in the migration; it is unreachable today
   for the other three, so it should be invisible.
2. **Dust has no `cooldownVisuals` table.** Its `setSkillReady(skillName, frameBorderCooldown,
   cooldownLabel, bump)` and `startSkillCooldown(skillName, frameBorderCooldown, cooldownLabel,
   cooldownTime)` take the frames as arguments, and its bumps live in a separate `skillBumps` table
   keyed by name. This is the older shape and the reason Dust migrates last.
3. **Dust names its size constants differently** — `SKILL_READY_SIZE` / `SKILL_COOLDOWN_START_SIZE`
   vs `ABILITY_READY_SIZE` / `ABILITY_START_SIZE`. **The values are identical**: `UDim2.new(1, 0, -1, 0)`
   and `UDim2.new(1, 0, 0, 0)`. No behaviour rides on the rename.
4. **Dust's countdown loop uses an `elapsed` local** where the others inline the subtraction. Cosmetic.

> The disabled `StarterPlayerScripts.FortunaCardsClient` carries a *third* pair of size constants
> (`UDim2.new(0.6, 0, -1.4, 0)`). It targets the **pre-rework** GUI and is `Enabled = false`. Ignore
> it; do not "reconcile" its values.

---

## What must NOT be unified

Getting this wrong turns a refactor into a gameplay change.

- **`setUltimateCharge`.** Three genuinely different functions, measured: Fortuna **38 lines**,
  Vesper **51**, Bram **49** — with three different early-return guards (`isReady`, `ultimateActive`,
  `isLastCallActive`). Dust does not have the function at all; its ultimate lives in
  `ReplicatedStorage.Revolver.Modules.HighNoonChargeUI`. **Leave all four alone.**
- **The ultimate's readiness edge and its `UltimateReadyFX` clears.** Each hunter clears the glow in
  its own places for its own reason (Bram in the `isLastCallActive` return *and*
  `startLastCallCountdown`; Vesper in the `ultimateActive` return *and* the activation handler). The
  ultimate's `HunterHudBump` call sits alongside those clears and stays hero-side with them.
- **Event wiring.** Each hunter's cooldown events are manifest-declared under different names
  (`BreachChargeCooldownStarted`, `GrappleCooldownStarted`, `RecallCooldownStarted`,
  `DashCooldownStarted`…). The module receives seconds; it never subscribes to anything.
- **Vesper's ultimate window countdown and ammo row**, and **Bram's Last Call countdown**. Both drive
  the ultimate tile's label and bar directly and are hero logic.
- **Mobile ability buttons.** Already shared and already decoupled. Do not route them through the new
  module to "tidy up".

---

## Target design

### Placement

`ReplicatedStorage.Hunters.Shared.HunterHudCooldown` — a new ModuleScript beside `HunterHudBump`
and `UltimateReadyFX`.

`Hunters.Shared` is correct here: `CLAUDE.md` scopes it to hero-agnostic code, and this is exactly
that. It must be in `ReplicatedStorage` because every caller is a LocalScript.

`Hunters.Shared` is **Redwater-only** and is *not* one of the 16 mirrored modules. Do not copy it to
Bounty.

### API

A controller object per HUD, created once, matching the `.new()` / `:Destroy()` shape the two
neighbouring modules already use. It owns the tile, the label, the bar tween, the token and the pop.

```lua
-- Names are given in HUD order: slot 1 = 1Ability = Q, slot 2 = 2Ability = E.
-- Resolves tiles off the canvas the way HunterIntroTags:111 does. Returns nil if
-- the shape is missing, which every call site must tolerate.
local cooldowns = HunterHudCooldown.new(canvas, { "Breach", "Shrapnel" })

-- Begin a cooldown: bar from full to empty over `seconds`, label counting down.
-- Retires any cooldown already running for that name. seconds <= 0 goes straight
-- to ready, and pops IF the tile was actually mid-cooldown.
--
-- (Shipped amendment, 2026-08-06: this section originally said "without a pop",
-- contradicting Verification case 5 below, which said the Last Call refresh should
-- pop. The checklist won -- on owner request -- because a refresh the player cannot
-- see is half the ultimate going unadvertised. The "was actually cooling" guard is
-- required, not cosmetic: AbilityCooldownsReduced re-fires a clamped 0 on every
-- landed blast during Last Call, so an unguarded pop strobes both tiles.)
cooldowns:Start(name, seconds)

-- Force the resting ready state: bar full, label blank, in-flight countdown
-- retired. Does NOT pop -- this is the respawn / initial-wiring path.
cooldowns:SetReady(name)

-- Retire every countdown and restore each tile's UIScale to its authored value.
cooldowns:Destroy()
```

**The pop is internal and is not a parameter.** `HunterHudCooldown` requires `HunterHudBump` and
fires it from exactly one place: the natural expiry of a countdown. That deletes the `bump` argument
threaded through all four scripts on 2026-08-06 and removes the standing chance of a caller passing
it from a restore path. Hero scripts stop requiring `HunterHudBump` for *skills*; they keep requiring
it for the **ultimate**, which stays hero-owned.

**Token retirement is internal.** `SetReady` and `Start` both retire the previous countdown. The
2026-08-06 bug becomes structurally unreachable rather than fixed in four places.

### What each HUD client keeps

Everything ultimate-related, its event wiring, its ammo and bullet UI, its mobile buttons, its
artwork overrides. `getChargeSize` and `setFrameSize` stay — the **ultimate** still uses them. Do not
delete them as "now unused" without checking; that is a real trap, since only the skill half of their
call sites goes away.

---

## Migration — in this order

Behaviour-preserving throughout, except the zero-length branch noted above.

1. **Create `HunterHudCooldown`** with the union of the existing behaviour: Bram's zero-length
   branch, the internal token retirement, the internal pop, and the identical
   `getChargeSize`/`setFrameSize` logic copied verbatim.
2. **Migrate Fortuna.** The simplest of the three modern clients — no ultimate-active state to reason
   about. Delete its `setSkillReady`, `startSkillCooldown`, `cooldownVisuals`, `activeSkillTweens`,
   `skillCooldownTokens` and the two `HunterHudBump.new(skill1/skill2)` calls. Keep the ultimate's
   bump and its `HunterHudBump` require.
3. **Migrate Vesper.** The same diff, character for character — the two blocks hash identically. If
   this diff is not the same as Fortuna's, something is wrong; stop and re-read.
4. **Migrate Bram.** Same again, minus the zero-length branch, which the module now owns.
5. **Migrate Dust — last.** Different signature, no visuals table, `skillBumps` table to delete,
   size constants under different names. Its two call sites pass frames that the module now resolves
   itself, so the call sites shrink rather than move.
6. **Verify** per *Verification*, then do the *Obligations*.

---

## Verification — ✅ all complete 2026-08-06

MCP playtesting is unavailable (`start_playtest` hangs the plugin), so this is compile + probe +
a human checklist.

- ✅ **Compile.** All five scripts via `loadstring(script.Source)`.
- ✅ **Token semantics.** Grew from four cases to eight; all pass. See the table below.
- ✅ **Visual parity.** New module vs the pre-refactor code side by side over a 3s cooldown:
  **max `Y.Scale` delta 0.00000 across 21 samples, zero label mismatches.**
- ✅ **Screenshot.** Both `ScreenGui` and `HunterGuiMobile` cloned into `CoreGui`, checked resting
  and mid-cooldown. Desktop geometry matches this document: 85px tile → 101px at peak in a 122px
  holder. (Measured aside: the **mobile** tile is 117px in a 131px holder, so 1.18 overflows its
  cell ~5% horizontally. Pre-existing `HunterHudBump` behaviour, untouched by this work.)
- ✅ **Human playtest**, owner, desktop and mobile — all six items below.

| # | Harness case | Expected | Result |
|---|---|---|---|
| 1 | respawn mid-cooldown | label `""`, 0 pops | ✅ |
| 2 | natural completion | label `""`, 1 pop | ✅ |
| 3 | retrigger mid-cooldown | 1 pop (newest only) | ✅ |
| 4 | `Destroy` mid-cooldown | countdown retired, `BumpScale` at authored 1 | ✅ |
| 5 | Last Call refresh while cooling | instant rest, 1 pop | ✅ |
| 6 | refresh on an already-ready tile | 0 pops | ✅ |
| 7 | six consecutive zeros | 1 pop, no strobe | ✅ |
| 8 | blast shaved to a real remaining time | counts down, 1 pop | ✅ |

Plus a fault-injection case for the throw-isolating `Destroy`: with **both** tiles' bumps throwing,
both countdowns still retire and the controller still clears. Under one shared `pcall` whichever
slot came second in `pairs()` kept counting.

**Human playtest** — two real players, all four hunters. ✅ **All six confirmed by the owner:**

1. ✅ Use each ability; bar drains, label counts down, tile pops once at expiry.
2. ✅ **Respawn mid-cooldown** — no phantom countdown, no phantom pop. This is the 2026-08-06 bug.
3. ✅ Retrigger an ability the instant it comes up — exactly one pop.
4. ✅ Switch hunters mid-cooldown — no leftover tile, no tile stuck mid-bump.
5. ⚠️ Bram's Last Call refreshes cooldowns — both tiles go ready **and pop**. *"Go ready" confirmed
   on desktop; the **pop** was added after that run, on owner request, and is so far confirmed by
   harness plus the mobile pass. Worth one deliberate desktop look.*
6. ✅ Mobile: all of the above on a phone, plus the ability buttons still fire.

> **Case 4 is weaker than it reads, and that is worth recording.** A swap destroys the outgoing
> hunter's GUI and the incoming one clones a fresh tree, so a leaked countdown has no instance in
> common with anything on screen — the failure is invisible in play and only the harness can see it.
> The old code "passed" it by accident (the stale thread wrote to a dead label and called `Play()` on
> a destroyed bump, which early-returns). Case 2 is the one that would actually show a regression.

---

## Traps

Tool and codebase traps that will otherwise cost a round-trip each:

- **`grep_scripts` matches literals by default.** Regex alternation silently returns 0 and looks like
  "no references". Pass `usePattern: true` for alternation, or one pattern per call.
- **The plugin `require` cache is stale.** Recompile with `loadstring(script.Source)`.
- **`set_script_source` eats `\n` escapes** and breaks Lua string literals — use a `[[long string]]`
  and verify with `loadstring`.
- **Never partially overwrite a script.** `Edit`/`edit_script_lines` for spot changes;
  `set_script_source` needs the whole file.
- **Two Studio places are connected.** Pass `instance_id` — Redwater is `place:98517073248449`.
- **`execute_luau` runs at PluginSecurity**, so an edit-mode probe can pass for things a shipped
  LocalScript cannot do.
- **`StarterGui.HunterGui.*` is a dead pre-rework tree.** It still exists, still carries the old
  `Ultimate > FrameBorder > SkillIcon` shape, and nothing clones it. Resolve against
  `ReworkedHunterGui` only.
- **`BumpScale` UIScales are authored instances**, one per tile in both GUI variants (six total).
  Per `CLAUDE.md`, do not create them in code — a code-built instance cannot be screenshot-verified.
- **Plugins stay bound to the edit DataModel during Play Solo**, and `CoreGui` is shared. A preview
  cloned into `CoreGui` will draw *on top of* a running playtest and doubles the HUD, which makes
  screenshots misleading. Check `RunService:IsEdit()` before trusting one.

---

## Obligations on completion

Per `CLAUDE.md`:

- **Vault.** New `LocalRedwaterCanyon/ReplicatedStorage/Hunters/Shared/HunterHudCooldown.md` on the
  standard template. Update the Dependencies/Connections of the four HUD client `.md` files — each
  gains a real `[[HunterHudCooldown]]` require edge and **loses** its `[[HunterHudBump]]` edge for
  the skill path (Fortuna, Vesper and Bram keep theirs for the ultimate; **Dust loses it entirely**,
  since Dust's ultimate bump lives in `HighNoonChargeUI`).
- **Graph.** `python update_redwater_canyon_graph.py` as a bare command, one per tool call. Then
  verify: `Grep "\"_src\": \"hunterhudcooldown\"" graphs/RedwaterCanyonGraph/graph.json -A 1`.
  Node ids are lowercased; `_src`/`_tgt` is the correct directed pair. A node-count **drop** blocks
  the write and still prints "Done" — pass `--force` if the count legitimately falls.
- **Mirroring.** `Hunters.Shared` is Redwater-only. Confirm the new module is not added to the
  16 mirrored modules, and that Bounty is untouched.
- **Changelog.** `/changelog` for the session's capture. Note that the 2026-08-06 phantom-countdown
  fix already shipped separately — this refactor makes it structural, it does not re-fix it.
