-- PreflightGates  (ServerStorage.PreflightGates in Bounty, Redwater Canyon and Frostbite Claim)
--
-- TOOLING, NOT GAME CODE. Nothing requires this module and it never runs in a live server:
-- ServerStorage does not replicate, no script names it, and no mirror root walks ServerStorage.
-- It exists so /preflight and /mirror run their gates with a one-line execute_luau instead of
-- retyping the Luau every run. Retyping cost 47K characters in the Hotfix 3.2 preflight (a
-- quarter of that run's output) because the mirror walker alone was pasted nine times.
--
-- Always load it with loadstring, never require -- the plugin's require cache is stale -- and pass
-- the caller's print, or the output never reaches execute_luau (see PRINT below):
--
--   loadstring(game.ServerStorage.PreflightGates.Source)().run(print)                  -- every gate
--   loadstring(game.ServerStorage.PreflightGates.Source)().mirror("match", "", print)  -- /mirror
--   loadstring(game.ServerStorage.PreflightGates.Source)().clips("Dust.Weapon", print) -- clip drill-down
--
-- CANONICAL SOURCE: .claude/skills/preflight/PreflightGates.luau in the docs repo. Install into
-- the places from PreflightGates.rbxm beside it (import_rbxm), never by retyping. run() prints a
-- gates=<hash> of the installed copy, and all three places must agree on it.
--
-- NO BACKSLASHES ANYWHERE IN THIS FILE, comments included. set_script_source rewrites the
-- backslash-n, backslash-t and backslash-quote escapes in transit, so a copy installed that way
-- would silently differ from the one in git -- and a rewritten one in a comment splits the line.
-- Use string.char when a control character is needed (see NL below).

local Gates = {}

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SP = game:GetService("StarterPlayer")

local NL = string.char(10)

-- execute_luau captures only its own chunk's print. A loadstring-ed chunk's print lands in Studio's
-- Output window and the tool returns nothing at all (found installing this), so every printing
-- function takes `print` as its last argument, falling back to this one.
local PRINT = print

--------------------------------------------------------------------------------------------------
-- Expected values. A deliberate tuning change updates these, in the same pass as the tuning.
--------------------------------------------------------------------------------------------------

local HUNTERS = { "Dust", "Fortuna", "Vesper", "Bram" }

-- The three bot-fill knobs are only correct relative to each other: MaxBots is
-- DesiredRoundParticipants - 1 (a solo player's fill), and a MaxBots below that silently re-shrinks
-- the quiet games the fill exists to populate. 8/10 until 2026-08-18, when the "more fighters per
-- game" pass took the target to 14 (visitor cap 10 -> 14, matchmaking ceilings to 11/12/2). Change
-- all three together or the gate fails on a correct config.
local BOT_EXPECT = { DesiredRoundParticipants = 14, MaxBots = 13, MinBots = 4 }

local ROUND_EXPECT = { ROUND_TIME = 360, ZONE_PHASE_DURATION = 80 }

-- HunterViewmodelContract.Report() lines that are known and accepted, keyed on the text before
-- " -- " (the advice half). A WARN or NOTE not listed here prints as NEW and turns the verdict to
-- JUDGE: read it, and either fix the art or add it here with a reason. FAIL lines are never
-- standing -- a FAIL is something Normalize cannot repair at runtime.
local STANDING = {
	-- Deliberate since 2026-08-29. BackupPrestigeCard is inert because every resolver type-checks
	-- IsA("Model"); PrestigeCard's world twin is mapped explicitly by CardsWorldVisualServer's
	-- TemplateResolver; the ViewmodelAnimations drop-zones are read by nothing until Phase 2.
	["NOTE: Bram ViewmodelAnimations holds 1 clip(s) no manifest entry names (Ability)"] = true,
	["NOTE: Fortuna Viewmodel.Skins.BackupPrestigeCard is a Folder, not a Model"] = true,
	["NOTE: Fortuna skin 'PrestigeCard': no Weapon.WorldModel.Skins entry of the same name"] = true,
	["NOTE: Vesper ViewmodelAnimations holds 2 clip(s) no manifest entry names (BasicShootReload, Run)"] = true,

	-- The four Lava gun skins: art parked in Redwater's viewmodel Skins folders, unwired (no catalog
	-- entry, no script names them, Redwater only), accepted as-is at Hotfix 3.2. These lines are
	-- standing ONLY while the skins are unwired. Delete this block in the same pass that wires them:
	-- wiring is exactly when "weapon model is named 'Lava'" and the stale rig clips reach players.
	["WARN: Bram skin 'MoltenGrudgekeeper': weapon model is named 'Lava', the default's is 'Shotgun'"] = true,
	["WARN: Bram skin 'MoltenGrudgekeeper' rig clip 'Shoot' is rbxassetid://78350631756950 where the manifest resolves rbxassetid://93041883597128"] = true,
	["WARN: Bram skin 'MoltenGrudgekeeper' rig clip 'ShrapnelShoot' is rbxassetid://82623093683842 where the manifest resolves rbxassetid://137350091876899"] = true,
	["WARN: Bram skin 'MoltenGrudgekeeper' rig clip 'Idle' is rbxassetid://101746142745601 where the manifest resolves rbxassetid://89197463725718"] = true,
	["WARN: Bram skin 'MoltenGrudgekeeper' rig clip 'Reload' is rbxassetid://103611548117911 where the manifest resolves rbxassetid://117768481236234"] = true,
	["WARN: Dust skin 'CinderSix-Shooter': weapon model is named 'Lava', the default's is 'Default'"] = true,
	["WARN: Dust skin 'CinderSix-Shooter' rig clip 'Shoot' is rbxassetid://130199779842197 where the manifest resolves rbxassetid://86496527884983"] = true,
	["WARN: Dust skin 'CinderSix-Shooter' rig clip 'Fanning' is rbxassetid://99602723302117 where the manifest resolves rbxassetid://127934175230422"] = true,
	["WARN: Dust skin 'CinderSix-Shooter' rig clip 'Reload' is rbxassetid://116854322871556 where the manifest resolves rbxassetid://98518914454467"] = true,
	["WARN: Fortuna skin 'InfernoHand' rig clip 'Ultimate' is rbxassetid://119957724727533 where the manifest resolves rbxassetid://89361073908392"] = true,
	["WARN: Vesper skin 'EmberpiecerRifle': weapon model is named 'Lava', the default's is 'Sniper'"] = true,
	["WARN: Vesper skin 'EmberpiecerRifle' rig clip 'Shoot' is rbxassetid://100006793489131 where the manifest resolves rbxassetid://84860686696858"] = true,
	["WARN: Vesper skin 'EmberpiecerRifle' rig clip 'Reload' is rbxassetid://116410602734293 where the manifest resolves rbxassetid://73583544224104"] = true,
	["NOTE: Bram skin 'MoltenGrudgekeeper': no Weapon.WorldModel.Skins entry of the same name"] = true,
	["NOTE: Dust skin 'CinderSix-Shooter': no Weapon.WorldModel.Skins entry of the same name"] = true,
	["NOTE: Fortuna skin 'InfernoHand': no Weapon.WorldModel.Skins entry of the same name"] = true,
	["NOTE: Vesper skin 'EmberpiecerRifle': no Weapon.WorldModel.Skins entry of the same name"] = true,
}

--------------------------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------------------------

local PRIME = 16777619
local FNV_BASIS = 2166136261

-- FNV-1a, verified against the standard vectors (a -> e40c292c, hello -> 4f9f2cab). The multiply
-- is split into 16-bit halves because h * 16777619 exceeds 2^53 and loses low bits. Keep it exactly
-- as it is: every fold quoted in a published release entry was produced by this function.
local function hashStr(s, h)
	h = h or FNV_BASIS
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
Gates.hash = hashStr

local function hex(h)
	return string.format("%08x", h)
end

local function find(base, ...)
	local inst = base
	for _, seg in ipairs({ ... }) do
		inst = inst and inst:FindFirstChild(seg)
	end
	return inst
end

-- loadstring + pcall, never require (stale cache). Returns the module's value, or nil + reason.
local function loadModule(inst, label)
	if not inst then
		return nil, label .. " not found"
	end
	local fn, err = loadstring(inst.Source)
	if not fn then
		return nil, label .. " parse: " .. tostring(err)
	end
	local ok, res = pcall(fn)
	if not ok then
		return nil, label .. " exec: " .. tostring(res)
	end
	return res
end

--------------------------------------------------------------------------------------------------
-- Mirror walker (the /mirror skill's, moved here so it has one home)
--------------------------------------------------------------------------------------------------

-- ALLOWLIST of synced roots (FROSTBITE_CLAIM_SPEC.md 7.1). Workspace / Terrain / Lighting /
-- MaterialService / ServerStorage are absent by construction, never denylisted: a walker that
-- visited services indiscriminately would flatten Frostbite's art on its first reconcile.
-- Root labels must not contain "." -- the label is one path segment.
local function rootsFor(tier)
	if tier == "match" then
		return {
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
	elseif tier == "universe" then
		-- The 21 universe modules, each by its FULL path rather than a bare name. On 2026-08-21 a
		-- preflight found twelve of them had moved out of the ReplicatedStorage root into RS.Config
		-- / RS.Modules, and the stale list did not fail -- it PASSED: an unresolved name folds as
		-- <MISSING>, the same string in every place, so three identical TOTALs covered 7 of 19
		-- modules. Hence full paths (a move breaks loudly) and the separate "resolved N of N" count.
		-- A new mirrored module is added HERE, in the same pass that starts mirroring it.
		local roots = {}
		local function add(label, base, ...)
			table.insert(roots, { label, find(base, ...) })
		end
		for _, n in ipairs({
			"GameEnvironment", "MapCatalog", "GamemodeConfig", "BattlePassConfig", "BoostConfig",
			"EmoteConfig", "QuestConfig", "TitlesConfig", "DailyRewardConfig", "FriendBonusConfig",
			"TitleStyles", "BountyPlusConfig",
		}) do
			add("RS/Config/" .. n, RS, "Config", n)
		end
		add("RS/Modules/TitleRenderer", RS, "Modules", "TitleRenderer")
		add("RS/Modules/AnimationLoader", RS, "Modules", "AnimationLoader")
		add("SSS/PlayerServices/Wallet", SSS, "PlayerServices", "Wallet")
		add("SSS/PlayerServices/TesterGrantService", SSS, "PlayerServices", "TesterGrantService")
		add("SSS/PlayerServices/Telemetry", SSS, "PlayerServices", "Telemetry")
		add("SSS/PlayerServices/ProfileService", SSS, "PlayerServices", "ProfileService")
		add("SSS/SoftShutdown", SSS, "SoftShutdown")
		add("SPS/VersionTagController", SP, "StarterPlayerScripts", "VersionTagController")
		add("SPS/TelemetryClient", SP, "StarterPlayerScripts", "TelemetryClient")
		return roots
	end
	error("tier must be 'match' or 'universe', got " .. tostring(tier))
end

-- Map-specific instances inside a synced root: never compared (spec 7.2/7.3). A DISPLAYED path, so
-- it must track the live tree -- it read "ReplicatedStorage.MapConfig" until 2026-08-21, matched
-- nothing, and reported permanent false drift on the one file that is SUPPOSED to differ.
local EXCLUDE = { ["ReplicatedStorage.Config.MapConfig"] = true }

-- Returns rows, total, rootCount, unresolved. Each row: name, scripts, insts, bytes, fold, sfold.
-- One key per instance folds path + class, plus size + source hash for scripts, so an edit, a
-- rename, a reclass and a missing GUI child all move `fold`. `sfold` folds the script keys only,
-- which separates "the code agrees" from non-script drift (unwired art, a stray Frame).
-- `prefix` is a displayed path to expand one level deeper; "" is the top level. A subtree's TOTAL
-- at depth n+1 equals its row at depth n -- if not, this function was edited, not the code.
-- 811c9dc5 is the fold of an empty set: a root showing it is present but empty, not absent.
function Gates.walk(tier, prefix)
	prefix = prefix or ""
	local roots = rootsFor(tier)
	local entries = {}

	local function visit(inst, segs)
		local path = table.concat(segs, ".")
		if EXCLUDE[path] then
			return
		end
		local key, isScript, bytes = path .. "|" .. inst.ClassName, false, 0
		if inst:IsA("LuaSourceContainer") then
			local src = inst.Source
			isScript, bytes = true, #src
			key = key .. "|" .. bytes .. "|" .. hex(hashStr(src))
		end
		table.insert(entries, { segs = segs, path = path, key = key, isScript = isScript, bytes = bytes })
		for _, c in ipairs(inst:GetChildren()) do
			local child = table.clone(segs)
			table.insert(child, c.Name)
			visit(c, child)
		end
	end

	for _, r in ipairs(roots) do
		if r[2] then
			if r[2]:IsA("LuaSourceContainer") then
				visit(r[2], { r[1] }) -- universe tier: the root IS the module
			else
				for _, c in ipairs(r[2]:GetChildren()) do
					visit(c, { r[1], c.Name })
				end
			end
		else
			table.insert(entries, { segs = { r[1] }, path = r[1], key = r[1] .. "|<MISSING>", isScript = false, bytes = 0 })
		end
	end

	local depth = 1
	if prefix ~= "" then
		for _ in string.gmatch(prefix, "%.") do
			depth += 1
		end
		depth += 1
	end

	local groups, order = {}, {}
	local function group(name)
		local g = groups[name]
		if not g then
			g = { keys = {}, skeys = {}, scripts = 0, insts = 0, bytes = 0 }
			groups[name] = g
			table.insert(order, name)
		end
		return g
	end
	-- Seed a row per root so an EMPTY root still prints, rather than showing up as an absent row.
	if prefix == "" then
		for _, r in ipairs(roots) do
			group(r[1])
		end
	end
	for _, e in ipairs(entries) do
		if prefix == "" or e.path == prefix or string.sub(e.path, 1, #prefix + 1) == prefix .. "." then
			local g = group(table.concat(e.segs, ".", 1, math.min(depth, #e.segs)))
			table.insert(g.keys, e.key)
			g.insts += 1
			g.bytes += e.bytes
			if e.isScript then
				g.scripts += 1
				table.insert(g.skeys, e.key)
			end
		end
	end
	table.sort(order)

	local function fold(keys)
		table.sort(keys)
		local h = FNV_BASIS
		for _, k in ipairs(keys) do
			h = hashStr(k, h)
		end
		return h
	end

	local rows, allKeys, allScriptKeys = {}, {}, {}
	local total = { name = "TOTAL", scripts = 0, insts = 0, bytes = 0 }
	for _, name in ipairs(order) do
		local g = groups[name]
		table.insert(rows, {
			name = name, scripts = g.scripts, insts = g.insts, bytes = g.bytes,
			fold = fold(g.keys), sfold = fold(g.skeys),
		})
		for _, k in ipairs(g.keys) do
			table.insert(allKeys, k)
		end
		for _, k in ipairs(g.skeys) do
			table.insert(allScriptKeys, k)
		end
		total.scripts += g.scripts
		total.insts += g.insts
		total.bytes += g.bytes
	end
	total.fold = fold(allKeys)
	total.sfold = fold(allScriptKeys)

	local unresolved = {}
	for _, r in ipairs(roots) do
		if not r[2] then
			table.insert(unresolved, r[1])
		end
	end
	return rows, total, #roots, unresolved
end

local function fmtRow(r)
	return string.format("%-46s %4d %5d %8d  %s  s=%s", r.name, r.scripts, r.insts, r.bytes, hex(r.fold), hex(r.sfold))
end

-- Prints `path  scripts  instances  sourceBytes  fold  s=scriptsFold`, sorted and line-aligned by
-- construction, then TOTAL and the resolution count. The gate is BOTH lines: a matching TOTAL over
-- an unresolved root proves nothing, because <MISSING> folds identically everywhere.
function Gates.mirror(tier, prefix, print)
	print = print or PRINT
	local rows, total, n, unresolved = Gates.walk(tier or "match", prefix)
	for _, r in ipairs(rows) do
		print(fmtRow(r))
	end
	print(fmtRow(total))
	print(string.format("resolved %d of %d roots", n - #unresolved, n))
	for _, label in ipairs(unresolved) do
		print("  !! UNRESOLVED: " .. label .. "  -- path is stale or the instance is gone; FIX BEFORE TRUSTING THE FOLD")
	end
end

--------------------------------------------------------------------------------------------------
-- Individual gates
--------------------------------------------------------------------------------------------------

-- Every script in the place, not just the ones a release touched: the sweep costs about a second,
-- and it also catches edits made through execute_luau or by hand, which the capture hook never sees.
local SWEEP_SERVICES = {
	"Workspace", "ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage",
	"StarterGui", "StarterPack", "StarterPlayer", "Lighting", "SoundService", "Teams",
	"TextChatService", "Chat",
}

function Gates.syntax()
	local count, fails = 0, {}
	for _, svcName in ipairs(SWEEP_SERVICES) do
		local ok, svc = pcall(game.GetService, game, svcName)
		if ok and svc then
			for _, d in ipairs(svc:GetDescendants()) do
				if d:IsA("LuaSourceContainer") then
					count += 1
					local fn, err = loadstring(d.Source)
					if not fn then
						table.insert(fails, d:GetFullName() .. " :: " .. tostring(err))
					end
				end
			end
		end
	end
	return count, fails
end

-- Returns fails, okSummary. Catches tuning edits that publish silently: a match with one hunter
-- type, no bots, or debug output. Enabled and Debug are the two that cost most and announce
-- themselves least -- Enabled=false ships an empty canyon to a solo player with no error, because
-- a disabled bot system is a legitimate configuration; Debug=true ships the debug draw to every
-- player and buries the server-log warnings the rest of the release depends on. Both get flipped
-- by hand while testing, in the Properties pane, where the capture hook cannot see them.
function Gates.botConfig()
	local cfg, err = loadModule(find(SSS, "Bots", "BotConfig"), "BotConfig")
	if not cfg then
		return { err }
	end
	local errs = {}
	-- Identity-compared, not truthiness-compared: Enabled=nil is falsy and would pass a
	-- `not cfg.Enabled` test by accident, while Debug="false" (a string) is truthy.
	if cfg.Enabled ~= true then
		table.insert(errs, "Enabled=" .. tostring(cfg.Enabled) .. " (" .. typeof(cfg.Enabled) .. "), expected boolean true -- bots would not spawn at all")
	end
	if cfg.Debug ~= false then
		table.insert(errs, "Debug=" .. tostring(cfg.Debug) .. " (" .. typeof(cfg.Debug) .. "), expected boolean false -- debug output would ship to live players")
	end
	local enabled = {}
	for _, h in ipairs(cfg.EnabledHunters or {}) do
		enabled[h] = true
	end
	local weights = {}
	for _, h in ipairs(HUNTERS) do
		if not enabled[h] then
			table.insert(errs, h .. " missing from EnabledHunters")
		end
		local w = (cfg.HunterWeights or {})[h]
		if type(w) ~= "number" or w <= 0 then
			table.insert(errs, h .. " weight=" .. tostring(w))
		end
		table.insert(weights, h .. "=" .. tostring(w))
	end
	if #(cfg.EnabledHunters or {}) ~= #HUNTERS then
		table.insert(errs, "#EnabledHunters=" .. #(cfg.EnabledHunters or {}) .. ", expected " .. #HUNTERS)
	end
	for _, k in ipairs({ "DesiredRoundParticipants", "MaxBots", "MinBots" }) do
		if cfg[k] ~= BOT_EXPECT[k] then
			table.insert(errs, k .. "=" .. tostring(cfg[k]) .. ", expected " .. BOT_EXPECT[k])
		end
	end
	return errs, string.format("weights %s  fill %s/%s/%s", table.concat(weights, " "),
		tostring(cfg.DesiredRoundParticipants), tostring(cfg.MaxBots), tostring(cfg.MinBots))
end

function Gates.roundConfig()
	local cfg, err = loadModule(find(SSS, "RoundSystem", "Config"), "RoundSystem.Config")
	if not cfg then
		return { err }
	end
	local errs, got = {}, {}
	for _, k in ipairs({ "ROUND_TIME", "ZONE_PHASE_DURATION" }) do
		if cfg[k] ~= ROUND_EXPECT[k] then
			table.insert(errs, k .. "=" .. tostring(cfg[k]) .. ", expected " .. ROUND_EXPECT[k])
		end
		table.insert(got, k .. "=" .. tostring(cfg[k]))
	end
	return errs, table.concat(got, " ")
end

-- The weapon-skin contract, plus clip parity. A gun skin forks the whole first-person rig, so adding
-- one can rename the weapon model, drop a clip or park a Folder in Skins without any error -- Icefang
-- shipped with two of those at once. Returns { fails, new, standing, summary, clips, clipInstances }.
--
-- Clip parity exists because Report() runs inside one place and passes a rig whose clips are merely
-- STALE: Frostbite's Icefang sat on the superseded July clips for three weeks (fixed 2026-08-27), and
-- the count read 609 in both places the whole time -- the drift moved the char figure by 1 and the
-- sum by 3,727,187. So the cross-place comparison is on the manifest TOTAL's SUM, never the count.
-- TOTAL-INSTANCES folds the rig Animation instances no loader has read since 2026-08-29; they are the
-- Phase 1 revert path, so a difference there is read-and-judge, not a stop.
function Gates.contract()
	local out = { fails = {}, new = {}, standing = 0, summary = "?", clips = "?", clipInstances = "?" }
	local mod, err = loadModule(find(RS, "Hunters", "Shared", "HunterViewmodelContract"), "HunterViewmodelContract")
	if not mod then
		table.insert(out.fails, err)
		return out
	end
	local ok, lines = pcall(mod.Report)
	if not ok then
		table.insert(out.fails, "Report() threw: " .. tostring(lines))
		lines = {}
	end
	for _, line in ipairs(lines) do
		local kind = string.sub(line, 1, 5)
		local head = string.match(line, "^(.-) %-%- ") or line
		if kind == "FAIL:" then
			table.insert(out.fails, line)
		elseif kind == "WARN:" or kind == "NOTE:" then
			if STANDING[head] then
				out.standing += 1
			else
				table.insert(out.new, line)
			end
		elseif string.sub(line, 1, 2) == "--" then
			out.summary = (string.gsub(line, "^%-%-%s*", ""))
		else
			table.insert(out.new, line) -- an unrecognised line shape is surfaced, never swallowed
		end
	end
	local okC, clipLines = pcall(mod.ClipManifest)
	if not okC then
		table.insert(out.fails, "ClipManifest() threw: " .. tostring(clipLines))
		return out
	end
	for _, l in ipairs(clipLines) do
		if string.sub(l, 1, 16) == "TOTAL-INSTANCES " then
			out.clipInstances = string.sub(l, 17)
		elseif string.sub(l, 1, 6) == "TOTAL " then
			out.clips = string.sub(l, 7)
		end
	end
	return out
end

-- One row per clip for a group named in ClipManifest's per-group rows, e.g. "Dust.Weapon".
function Gates.clips(groupName, print)
	print = print or PRINT
	local mod, err = loadModule(find(RS, "Hunters", "Shared", "HunterViewmodelContract"), "HunterViewmodelContract")
	if not mod then
		print("FAIL: " .. err)
		return
	end
	for _, line in ipairs(mod.ClipManifest(groupName)) do
		print(line)
	end
end

-- Reads the version line out of GameEnvironment's SOURCE rather than executing the module, so a
-- stale require cache cannot answer and nothing it requires can hang the call. Returns the version,
-- the line number and the exact line text (the old_string for the Step 6 bump).
function Gates.version()
	local ge = find(RS, "Config", "GameEnvironment")
	if not ge then
		return nil
	end
	local n = 0
	for line in string.gmatch(ge.Source .. NL, "(.-)" .. NL) do
		n += 1
		local v = string.match(line, '^GameEnvironment%.version%s*=%s*"([^"]*)"')
		if v then
			return v, n, line
		end
	end
	return nil
end

--------------------------------------------------------------------------------------------------
-- run(): every gate for this place, one call
--------------------------------------------------------------------------------------------------

-- VERDICT is local to this place: PASS, JUDGE (read the NEW lines and decide) or FAIL (stop).
-- The cross-place half is the COMPARE line -- universe= and gates= must be identical in all three
-- places, clips= in both match places. Nothing in one place can see another, so that comparison is
-- the caller's, and it is the whole of it.
function Gates.run(print)
	print = print or PRINT
	local verdict, why = "PASS", {}
	local function fail(msg)
		verdict = "FAIL"
		table.insert(why, msg)
	end
	local function judge(msg)
		if verdict == "PASS" then
			verdict = "JUDGE"
		end
		table.insert(why, msg)
	end

	-- Role comes from the tree, not a PlaceId (never hardcode one). It is printed, so a place that
	-- lost its Hunters folder shows up as role=lobby instead of quietly skipping the match gates.
	local isMatch = find(RS, "Hunters") ~= nil
	local selfInst = find(game:GetService("ServerStorage"), "PreflightGates")
	local gatesHash = if selfInst then hex(hashStr(selfInst.Source)) else "NOT-INSTALLED"
	print(string.format("PREFLIGHT PlaceId %d  role=%s  gates=%s", game.PlaceId,
		if isMatch then "match" else "lobby", gatesHash))

	local _, total, rootCount, unresolved = Gates.walk("universe", "")
	print(string.format("UNIVERSE resolved %d of %d  %d scripts  %d B  fold=%s", rootCount - #unresolved,
		rootCount, total.scripts, total.bytes, hex(total.fold)))
	for _, label in ipairs(unresolved) do
		print("  !! UNRESOLVED: " .. label)
	end
	if #unresolved > 0 then
		fail("universe roots unresolved")
	end

	local count, syntaxFails = Gates.syntax()
	print(string.format("SYNTAX %d scripts, %d fail", count, #syntaxFails))
	for _, f in ipairs(syntaxFails) do
		print("  FAIL: " .. f)
	end
	if #syntaxFails > 0 then
		fail("syntax")
	end

	local clips = "n/a"
	if isMatch then
		local botErrs, botInfo = Gates.botConfig()
		print("BOTCONFIG " .. (if #botErrs == 0 then "ok  " .. botInfo else "FAIL"))
		for _, e in ipairs(botErrs) do
			print("  FAIL: " .. e)
		end
		if #botErrs > 0 then
			fail("BotConfig")
		end

		local roundErrs, roundInfo = Gates.roundConfig()
		print("ROUNDCONFIG " .. (if #roundErrs == 0 then "ok  " .. roundInfo else "FAIL"))
		for _, e in ipairs(roundErrs) do
			print("  FAIL: " .. e)
		end
		if #roundErrs > 0 then
			fail("RoundSystem.Config")
		end

		local c = Gates.contract()
		print(string.format("CONTRACT %s  (%d standing, %d new)", c.summary, c.standing, #c.new))
		for _, l in ipairs(c.fails) do
			print("  FAIL: " .. l)
		end
		for _, l in ipairs(c.new) do
			print("  NEW: " .. l)
		end
		if #c.fails > 0 then
			fail("contract")
		elseif #c.new > 0 then
			judge("contract has NEW lines")
		end
		print("CLIPS " .. c.clips)
		print("CLIPS-INSTANCES " .. c.clipInstances .. "  (read-and-judge across places)")
		clips = string.match(c.clips, "sum=(%d+)") or "?"
		if clips == "?" then
			fail("clip TOTAL missing")
		end
	end

	local v, ln, text = Gates.version()
	if v then
		print(string.format("VERSION %s  (GameEnvironment line %d: %s)", v, ln, text))
	else
		print("VERSION not found")
		fail("GameEnvironment.version line not found")
	end

	print("VERDICT " .. verdict .. (if #why > 0 then "  -- " .. table.concat(why, "; ") else ""))
	print(string.format("COMPARE universe=%s clips=%s gates=%s", hex(total.fold), clips, gatesHash))
	return verdict
end

return Gates
