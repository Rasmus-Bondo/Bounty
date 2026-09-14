---
name: mirror
description: Compare and reconcile the shared code trees across the connected Roblox places - the 21 universe-wide modules across all three, and the full gamemode codebase between Redwater Canyon and Frostbite Claim. Reports drift by default; writes only when told to. Use before a publish, after editing anything shared, or whenever asked to check or fix mirror drift.
---

# Mirror

The scripted mirror sync from `FROSTBITE_CLAIM_SPEC.md` §7 (Option B). It answers one question —
**do the shared trees match?** — and can push the answer one way when they do not.

Read `FROSTBITE_CLAIM_SPEC.md` §7 for *why* this exists and why Packages were rejected. This file is
only *how to run it*.

**Default is read-only.** `/mirror` reports. `/mirror apply …` writes, and only after you have
named a direction and the user has agreed to it.

## Arguments

| Invocation | Does |
|---|---|
| `/mirror` | Compare the **match** tier: Redwater ↔ Frostbite, whole shared codebase. Top-level rollup. |
| `/mirror universe` | Compare the **universe** tier: the 21 shared modules across **all three** places. This is what `/preflight` Step 1 runs. |
| `/mirror <path>` | Drill one level into a drifted subtree, e.g. `/mirror ReplicatedStorage.Hunters`. |
| `/mirror apply <path>` | Reconcile the scripts under `<path>`. Requires a stated direction. |

---

## Step 0 — Resolve the places

Run `get_connected_instances` and match on `placeName`. **Never hardcode a PlaceId** — same rule as
`GameEnvironment` (`CLAUDE.md`, Environments). Every call below needs an explicit `instance_id`,
because more than one place is connected and the tool will not guess.

Pass the `instanceId` field **verbatim, including its `place:` prefix**. A bare id is rejected with
`unrecognized_instance_id`, which is at least loud.

If a place needed for the requested tier is not connected, **stop and say which one**. A one-sided
run proves nothing and reads like a pass.

---

## Step 1 — Run the walker in each place

The walker lives in Studio, in `ServerStorage.PreflightGates` (canonical source and install recipe:
`.claude/skills/preflight/PreflightGates.luau` and that skill's "Changing the gate module"). **Never
paste a walker** — send one line per place, all places in **one message**:

```lua
loadstring(game.ServerStorage.PreflightGates.Source)().mirror("match", "", print)      -- /mirror
loadstring(game.ServerStorage.PreflightGates.Source)().mirror("universe", "", print)   -- /mirror universe
loadstring(game.ServerStorage.PreflightGates.Source)().mirror("match", "ReplicatedStorage.Hunters", print)  -- drill-down
```

Always `loadstring`, never `require` — the plugin's require cache is stale — and always pass `print`:
`execute_luau` captures only its own chunk's `print`, so without it the walk returns nothing. If the module is missing,
`import_rbxm` `.claude/skills/preflight/PreflightGates.rbxm` into `game.ServerStorage` first.

Compare the outputs **line by line**; rows are sorted and line-aligned by construction, so equal files
sit on equal lines. Each row is `path · scripts · instances · sourceBytes · fold · s=scriptsFold`.
**The fold is the gate** — the counts say *how* something drifted once the fold has said *that* it did.
`s=` folds the script entries only, so it separates "the code agrees" from non-script drift such as
unwired art or a stray Frame. `811c9dc5` is the fold of an empty set: a root showing it is present but
empty, not absent. The module's `rootsFor` holds the allowlisted roots and the 21 universe modules, and
its comments carry why each is there.

**The gate is two lines, not one: `resolved N of N` AND a matching `TOTAL` fold.** An unresolved root
folds to the literal `<MISSING>`, identical in every place, so a stale path produces matching TOTALs
over modules nobody compared. Read `resolved N of N` first. Any `!! UNRESOLVED` line means fix the path
list in the module and re-run — never "that module is legitimately absent", because every module on the
list is required in all three places.

---

## Step 2 — Drill down

For each row whose fold differs, re-run with that row's path as the second argument. The depth follows
the prefix automatically, so each run descends exactly one level. Repeat until you reach individual
scripts, where the row's `bytes` and fold identify the file.

The rollup is self-consistent: a subtree's `TOTAL` at depth *n+1* equals its row at depth *n*. If it
does not, the walker was edited — not the code.

---

## Step 3 — Reconcile

**Name the direction before touching anything, and get the user to confirm it.**

| Tier | Canonical |
|---|---|
| match (Redwater ↔ Frostbite) | **Redwater Canyon.** Frostbite is downstream and carries no code of its own. |
| universe (21 modules) | **Neither.** A mismatch here is a real conflict — whoever edited last is the only one who knows which side is right. Ask; do not guess from timestamps. |

> **Repair with `.rbxm`, never with `set_script_source`.** Measured while building this skill:
> `set_script_source` **interprets** `\n`, `\r` and `\t` inside the source text, so pushing a script
> whose string literals contain them writes a *different file* than the one you read
> (`reference_mcp_source_newline_escapes`). `export_rbxm` → `import_rbxm` is binary and round-trips
> `ProfileService` — 83,513 bytes, the heaviest escape carrier in the codebase — byte-identical,
> with `ClassName` preserved. It also creates missing scripts and whole subtrees in one operation,
> so it subsumes `create_object` + `set_script_source` entirely.

1. `export_rbxm` the drifted paths from the **canonical** place into the scratchpad. It takes a
   list, so a whole drifted subtree is one call.
2. `import_rbxm` into a **staging folder** in the target (e.g. `ServerScriptService.ZZ_MirrorStaging`,
   created with `create_object`).
3. **Fold the staged copy and compare it to canonical before destroying anything.** This is the
   round-trip check; nothing else catches a bad write.
4. Swap: delete the stale instance, reparent the staged one (`execute_luau`, `inst.Parent = …`),
   delete the staging folder.
5. **Re-run Step 1** scoped to that parent. The folds must now agree.

Importing straight over the target skips steps 2–4 and is fine for bulk work — `import_rbxm` is
wrapped in `ChangeHistoryService`, so one Ctrl+Z reverses it — but it destroys the old copy before
you have verified the new one. Stage when the target holds the only copy of anything.

> **`.rbxm` silently drops two things. Both were caught by the fold, not by the import.**
>
> **1. Instance references whose target is outside the exported set.** Measured: 92
> `Sound.SoundGroup` references pointing at `SoundService` came back `nil`. This is a *serialize*-time
> loss, not a resolve-time one — re-importing into the source place, where the target definitely
> exists, still gave `nil`, so **no import order fixes it**. Either export the referrers and their
> targets in one call, or reapply the property afterwards and verify by count.
>
> **2. Some `Weld` instances, even with valid intra-set `Part0`/`Part1`.** Measured: 3 of 6
> `AccessoryWeld`s under `ReplicatedStorage.Characters` vanished — every other class of 6,274
> instances survived. The three that dropped welded to `LeftFoot`/`RightFoot`/`UpperTorso`; the
> three that survived welded to `LowerTorso`. No error, no warning. Fix is to recreate them with
> `Instance.new("Weld")` and copy `C0`/`C1` across at full precision (`%.17g`) — they stick once
> created directly.
>
> The general lesson: **`instance_count` in the import result counts top-level instances only.** It
> said 35 while the subtree was three short. Only the fold catches this.

**A script present only in the target** is not automatically garbage. Report it and ask. Deleting is
the one action here that destroys work no other copy holds.

---

## Step 4 — Non-script drift is detect-only

The fold covers every instance's path and class, so a missing `Frame`, a renamed `ScreenGui` or a
reclassed child all show up. It deliberately does **not** compare properties — a colour or a size
change reads as no drift. Authored GUI is compared **structurally, not visually**.

Repair is the same `.rbxm` swap as Step 3; there is just no finer-grained option than replacing the
tree. That is also the tool for the one-time Frostbite bring-up (spec §7, Phase 4 step 4), which is
*not* this skill's job: pushing the ~9 roots as `.rbxm` beats 273 script writes, and it never moves
terrain.

---

## What this must never touch

`Workspace`, `Terrain`, `Lighting`, `MaterialService`, `ServerStorage`, and
`ReplicatedStorage.MapConfig`. They are per-place by design (spec §7.2) and are absent from the
allowlist rather than filtered out of a full walk — a mirror that walked services indiscriminately
would flatten Frostbite's art on its first run.

`ReplicatedStorage.MapConfig` is the one exclusion inside a synced root, and it is why `MapConfig`
is a root-level sibling instead of `RoundSystem.MapConfig` (spec §7.3).

## Notes carried from building this

- **No dev twins exist yet.** Spec §7 argues the mirror is safe because it only ever runs between
  dev places. Until those exist, `apply` writes into a *live* place's edit session. Nothing reaches
  players until the user publishes, so the risk equals any hand edit — but the "dev-only accident"
  safety net is not there yet. Say so when proposing an `apply`.
- **`SoundService`'s three SoundGroups are in the allowlist and spec §7.1 omits them.** Redwater has
  `SFX` / `HitSound` / `Music`; Frostbite has none. Every Sound must carry a group (`CLAUDE.md`,
  Audio), and the settings sliders multiply into them, so a Frostbite without them escapes all four
  sliders — silently.
- **`TextChatService` already matches** across all three places (fold `b317e447`) — Roblox defaults,
  never edited. It stays in the allowlist so an edit to one place shows up.
- **`StarterPlayer.Folder`** holds three `StarterCharacter` rigs and 3 scripts. It is map-agnostic
  and synced. It is parked storage, not live config — a `StarterCharacter` only applies as a direct
  child of `StarterPlayer`.
- The walker's FNV-1a is verified against the standard vectors (`a` → `e40c292c`,
  `hello` → `4f9f2cab`). It splits the multiply into 16-bit halves because the obvious
  `h * 16777619` exceeds 2^53 and loses low bits.
- **The escape hazard is narrow but real: 2 of 269 synced scripts** carry `\n`/`\r`/`\t` escapes,
  the heaviest being `ProfileService` (6). A mangled `\n` inside a short string literal happens to
  fail loudly — `Malformed string; did you forget to finish it?` — because Lua forbids a raw newline
  there. A mangled `\t` does **not**: it becomes a real tab, compiles, and means the same thing.
  Do not let the loud case talk you into trusting the mechanism.
- **Drift detection was tested, not assumed.** An equal-length source edit, a rename with identical
  source, a removed non-script instance and a `ModuleScript`→`Script` reclass were each folded and
  each moved the hash; restoring the tree returned it to the exact baseline.
