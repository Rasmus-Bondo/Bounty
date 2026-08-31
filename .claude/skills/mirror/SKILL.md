---
name: mirror
description: Compare and reconcile the shared code trees across the connected Roblox places - the 19 universe-wide modules across all three, and the full gamemode codebase between Redwater Canyon and Frostbite Claim. Reports drift by default; writes only when told to. Use before a publish, after editing anything shared, or whenever asked to check or fix mirror drift.
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
| `/mirror universe` | Compare the **universe** tier: the 19 shared modules across **all three** places. This is what `/preflight` Step 1 runs. |
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

Paste the block below into `execute_luau` (`target: "edit"`) once per place, changing **only** the
two knobs on the first two lines. Compare the outputs **line by line**; the rows are sorted and
line-aligned by construction, so equal files sit on equal lines.

Each row is `path · scripts · instances · sourceBytes · fold`. **The fold is the gate** — the counts
are there to tell you *how* something drifted once the fold has told you *that* it did.
`811c9dc5` is the fold of an empty set: a root showing it is present but empty, not absent.

```lua
-- ============================ MIRROR WALKER ============================
local TIER   = "match"   -- "match" = Redwater <-> Frostbite (full trees) | "universe" = all 3 places (shared modules)
local PREFIX = ""        -- "" = top level. Else a displayed path, e.g. "ReplicatedStorage.Hunters", to expand one level deeper.
-- =======================================================================

local PRIME = 16777619
local function hashStr(s, h)
	h = h or 2166136261
	local n, i = #s, 1
	while i <= n do
		local j = if i + 3999 < n then i + 3999 else n
		local b = { string.byte(s, i, j) }
		for k = 1, #b do
			local x = bit32.bxor(h, b[k])
			local lo = x % 65536
			h = ((lo * PRIME) % 4294967296 + (((x - lo) / 65536 * PRIME) % 65536) * 65536) % 4294967296
		end
		i = j + 1
	end
	return h
end

local SP  = game:GetService("StarterPlayer")
local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

-- ALLOWLIST of synced roots (spec §7.1). Workspace / Terrain / Lighting / MaterialService /
-- ServerStorage are absent by construction and never denylisted (spec §12).
-- Root labels must not contain "." -- the label is one path segment.
local ROOTS
if TIER == "match" then
	ROOTS = {
		{ "ServerScriptService", SSS },
		{ "ReplicatedStorage", RS },
		{ "ReplicatedFirst", game:GetService("ReplicatedFirst") },
		{ "StarterGui", game:GetService("StarterGui") },
		{ "StarterPlayerScripts", SP:FindFirstChild("StarterPlayerScripts") },
		{ "StarterCharacterScripts", SP:FindFirstChild("StarterCharacterScripts") },
		{ "StarterPlayer/Folder", SP:FindFirstChild("Folder") },
		{ "SoundService", game:GetService("SoundService") },
		{ "TextChatService", game:GetService("TextChatService") },
	}
else
	-- The 19 universe modules, each addressed by its FULL path rather than a bare name.
	--
	-- These moved once already: on 2026-08-21 a preflight found twelve of them had been
	-- restructured out of the ReplicatedStorage root into RS.Config / RS.Modules, and the
	-- stale list did not fail -- it PASSED. An unresolved name folds as <MISSING>, which is
	-- the SAME string in every place, so all three printed an identical TOTAL while only
	-- 7 of 19 modules were actually being compared. A gate that goes green when it cannot
	-- find the thing it guards is worse than no gate. Hence two rules here:
	--   1. full paths, so a move breaks resolution loudly instead of quietly;
	--   2. the unresolved count is printed SEPARATELY from the fold (see below) -- never
	--      trust matching TOTALs without also reading "resolved N of N".
	ROOTS = {}
	local function add(label, base, ...)
		local inst = base
		for _, seg in ipairs({ ... }) do
			inst = inst and inst:FindFirstChild(seg)
		end
		table.insert(ROOTS, { label, inst })
	end
	for _, n in ipairs({
		"GameEnvironment", "MapCatalog", "GamemodeConfig", "BattlePassConfig", "BoostConfig",
		"EmoteConfig", "QuestConfig", "TitlesConfig", "DailyRewardConfig", "FriendBonusConfig",
		"TitleStyles",
	}) do add("RS/Config/" .. n, RS, "Config", n) end
	add("RS/Modules/TitleRenderer", RS, "Modules", "TitleRenderer")
	add("RS/Modules/AnimationLoader", RS, "Modules", "AnimationLoader")
	add("SSS/PlayerServices/Wallet", SSS, "PlayerServices", "Wallet")
	add("SSS/PlayerServices/TesterGrantService", SSS, "PlayerServices", "TesterGrantService")
	add("SSS/PlayerServices/Telemetry", SSS, "PlayerServices", "Telemetry")
	add("SSS/PlayerServices/ProfileService", SSS, "PlayerServices", "ProfileService")
	add("SSS/SoftShutdown", SSS, "SoftShutdown")
	add("SPS/VersionTagController", SP, "StarterPlayerScripts", "VersionTagController")
	add("SPS/TelemetryClient", SP, "StarterPlayerScripts", "TelemetryClient")
end

-- Map-specific instances living inside a synced root: never compared (spec §7.2/§7.3).
-- This key is a DISPLAYED path and must track the live tree. It read "ReplicatedStorage.MapConfig"
-- until 2026-08-21, by which point MapConfig had moved under RS.Config -- so it matched nothing and
-- the match tier compared the one file that is SUPPOSED to differ per place, reporting permanent
-- false drift in ReplicatedStorage. Same stale-path root cause as the universe list above, failing
-- the opposite way round.
local EXCLUDE = { ["ReplicatedStorage.Config.MapConfig"] = true }

-- One entry per instance. The key folds path + class, plus size + source hash for script
-- containers -- so an edit, a rename, a reclass and a missing GUI child all move the fold.
local entries = {}
local function visit(inst, segs)
	local path = table.concat(segs, ".")
	if EXCLUDE[path] then return end
	local key, isScript, bytes = path .. "|" .. inst.ClassName, false, 0
	if inst:IsA("LuaSourceContainer") then
		local src = inst.Source
		isScript, bytes = true, #src
		key = key .. "|" .. bytes .. "|" .. string.format("%08x", hashStr(src))
	end
	table.insert(entries, { segs = segs, path = path, key = key, isScript = isScript, bytes = bytes })
	for _, c in ipairs(inst:GetChildren()) do
		local child = table.clone(segs)
		table.insert(child, c.Name)
		visit(c, child)
	end
end
for _, r in ipairs(ROOTS) do
	if r[2] then
		if r[2]:IsA("LuaSourceContainer") then
			visit(r[2], { r[1] })                    -- universe tier: the root IS the module
		else
			for _, c in ipairs(r[2]:GetChildren()) do visit(c, { r[1], c.Name }) end
		end
	else
		table.insert(entries, { segs = { r[1] }, path = r[1], key = r[1] .. "|<MISSING>", isScript = false, bytes = 0 })
	end
end

local depth = 1
if PREFIX ~= "" then
	for _ in string.gmatch(PREFIX, "%.") do depth += 1 end
	depth += 1
end
local groups, order = {}, {}
local function group(name)
	local g = groups[name]
	if not g then
		g = { keys = {}, scripts = 0, insts = 0, bytes = 0 }
		groups[name] = g
		table.insert(order, name)
	end
	return g
end
-- Seed a row per root so an EMPTY root still prints. Without this a root with no children emits
-- no line at all, and the drift shows up as an absent row rather than a differing one -- exactly
-- the kind of miss a gate is supposed to make impossible.
if PREFIX == "" then
	for _, r in ipairs(ROOTS) do group(r[1]) end
end
for _, e in ipairs(entries) do
	if PREFIX == "" or e.path == PREFIX or string.sub(e.path, 1, #PREFIX + 1) == PREFIX .. "." then
		local g = group(table.concat(e.segs, ".", 1, math.min(depth, #e.segs)))
		table.insert(g.keys, e.key)
		g.insts += 1
		g.bytes += e.bytes
		if e.isScript then g.scripts += 1 end
	end
end
table.sort(order)

local allKeys, tS, tI, tB = {}, 0, 0, 0
for _, name in ipairs(order) do
	local g = groups[name]
	table.sort(g.keys)
	local h = 2166136261
	for _, k in ipairs(g.keys) do h = hashStr(k, h) end
	print(string.format("%-46s %4d %5d %8d  %08x", name, g.scripts, g.insts, g.bytes, h))
	for _, k in ipairs(g.keys) do table.insert(allKeys, k) end
	tS += g.scripts; tI += g.insts; tB += g.bytes
end
table.sort(allKeys)
local th = 2166136261
for _, k in ipairs(allKeys) do th = hashStr(k, th) end
print(string.format("%-46s %4d %5d %8d  %08x", "TOTAL", tS, tI, tB, th))

-- Resolution is reported SEPARATELY from the fold, because an unresolved root folds to the
-- literal "<MISSING>" -- identical in every place -- and therefore cannot be caught by comparing
-- TOTALs. Read this line first; matching folds mean nothing for a root that was never found.
local unresolved = {}
for _, r in ipairs(ROOTS) do
	if not r[2] then table.insert(unresolved, r[1]) end
end
print(string.format("resolved %d of %d roots", #ROOTS - #unresolved, #ROOTS))
for _, label in ipairs(unresolved) do
	print("  !! UNRESOLVED: " .. label .. "  -- path is stale or the instance is gone; FIX BEFORE TRUSTING THE FOLD")
end
```

**The gate is two lines, not one: `resolved N of N` AND a matching `TOTAL` fold.** When both agree
across every place the tier is in sync and there is nothing to eyeball row by row.

**A matching `TOTAL` on its own proves nothing.** An unresolved root folds to the literal
`<MISSING>`, which is the same in every place, so a stale path produces three identical TOTALs and a
green gate over modules nobody compared. Read `resolved N of N` first, every time — if it is short,
the fold below it is answering a smaller question than you asked. Any `!! UNRESOLVED` line means fix
the path list and re-run; it is never a "that module is legitimately absent" result, because every
module on this list is required in all three places.

---

## Step 2 — Drill down

For each row whose fold differs, re-run with `PREFIX` set to that row's path. `depth` follows the
prefix automatically, so each run descends exactly one level. Repeat until you reach individual
scripts, where the row's `bytes` and fold identify the file.

The rollup is self-consistent: a subtree's `TOTAL` at depth *n+1* equals its row at depth *n*. If it
does not, the walker was edited — not the code.

---

## Step 3 — Reconcile

**Name the direction before touching anything, and get the user to confirm it.**

| Tier | Canonical |
|---|---|
| match (Redwater ↔ Frostbite) | **Redwater Canyon.** Frostbite is downstream and carries no code of its own. |
| universe (19 modules) | **Neither.** A mismatch here is a real conflict — whoever edited last is the only one who knows which side is right. Ask; do not guess from timestamps. |

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
