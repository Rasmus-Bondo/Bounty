--[[
	NEWGUI_PORT_RESTYLE.luau -- the "Bounty - UI Update" port as ONE idempotent execute_luau script.

	Spec: NEWGUI_PORT_SPEC.md (same folder). Ran against Redwater Canyon on 2026-09-13 and re-run
	against Frostbite Claim the same day -- the HUD folder is ~1,234 instances and does not fit
	through import_rbxm, so Frostbite is a re-run of this file, never an import.

	Prepend a config line before pasting the whole file into execute_luau:

		_G.NEWGUI_PORT_CONFIG = { part = "hud", template = "ScreenGui", profile = "desktop" }

	parts:
		"hud"        Restyle one HUD template. template = "ScreenGui" | "HunterGuiMobile",
		             profile = "desktop" | "mobile". On mobile the geometry of every EXISTING
		             instance is frozen and only paint changes -- enforced by the before/after
		             snapshot diff at the end, which errors with the offending path. On desktop
		             the spec 4.1-4.5 geometry is written and every write is listed as expected;
		             any other geometry delta still fails the build.
		"quickwins"  RoundStatusGui (D12), BountyListGui (D11), DominationGui (D7), the five mobile
		             button faces (D6 -- the authored instances; the module constants are script
		             edits made separately).
		"killcam"    Authors StarterGui.KillCamGuiTemplate.KillCamGui (D8).
		"eyecandy"   Adds EyeCandy.Canvas.ObjectiveAnnouncement (D9).
		"proof"      Clones the template into CoreGui at the CURRENT device-simulator preset,
		             measures rects / TextFits / containment, stores the geometry under
		             __NewGuiStaging.Proof.<template>.<preset> on the first run and asserts
		             equality on the next (spec 5.2). config.preset names the preset.
		"firstlook"  The owner's first-look fixes of 2026-09-13 (white skill fill with the two-layer
		             icon, mobile slab flush with the portrait, flat white STUNNED/PINNED
		             label). Run AFTER "hud"; needs no staging.
		"cleanup"    Deletes ReplicatedStorage.__NewGuiStaging and any proof harness.

	Everything except "cleanup" needs ReplicatedStorage.__NewGuiStaging, imported from
	backups/newgui-staging.rbxm (exported from the design place's NEWGUI subtrees -- cloned, not
	re-typed, per UI_STYLE_GUIDE 1.1).

	The changelog hook does not capture execute_luau, so the changelog entry for this file's
	edits is written by hand.
]]

local CONFIG = rawget(_G, "NEWGUI_PORT_CONFIG") or {}
local PART = CONFIG.part or "hud"
local TEMPLATE = CONFIG.template or "ScreenGui"
local PROFILE = CONFIG.profile or (TEMPLATE == "HunterGuiMobile" and "mobile" or "desktop")
-- D11 ships the full BountyList restyle. false = the "portrait style only" variant (square
-- portrait, ring, shadow, stamp colours at the current 0.34 canvas) if touch geometry must stay.
local BOUNTYLIST_FULL_RESTYLE = CONFIG.bountyListFullRestyle ~= false

local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local FONT_ID = "rbxassetid://12187376174"
local function font(weight, style)
	return Font.new(FONT_ID, weight, style or Enum.FontStyle.Normal)
end
local BOLD_ITALIC = font(Enum.FontWeight.Bold, Enum.FontStyle.Italic)

-- The Modern palette (UI_STYLE_GUIDE 2.6). Same yellow / pink the EyeCandy announcement uses.
local hex = Color3.fromHex
local SLATE_900 = hex("0E1118")
local SLATE_800 = hex("181C26")
local SLATE_700 = hex("252A36")
local TEXT = hex("E5E8EE")
local YELLOW = hex("F6E525")
local PINK = hex("F427BA") -- no longer on the skill tiles since the first look (fill WHITE, underline SLATE_900: firstLookFixes)
local ULT_CARD = hex("282614")
local HEALTH_BACK = hex("080A0F")
local VIEWPORT_BG = hex("1E2026")
local HEALTH_FULL = hex("FFFFFF")
local HEALTH_TRAIL = hex("BE3037")
local HEALTH_EMPTY = hex("343842")
local BUTTON_FACE = hex("131415")

local staging = ReplicatedStorage:FindFirstChild("__NewGuiStaging")
local function stagingItem(name)
	assert(staging, "ReplicatedStorage.__NewGuiStaging is missing -- import backups/newgui-staging.rbxm first")
	local item = staging:FindFirstChild(name)
	assert(item, "staging has no " .. name)
	return item
end

local report = {}
local function log(fmt, ...)
	table.insert(report, string.format(fmt, ...))
end

-- Clone a staging subtree into `parent` as `newName` unless one is already there (idempotent).
local function ensureClone(parent, stagingName, newName)
	newName = newName or stagingName
	local existing = parent:FindFirstChild(newName)
	if existing then
		return existing, false
	end
	local c = stagingItem(stagingName):Clone()
	c.Name = newName
	c.Parent = parent
	return c, true
end

local function removeChildren(parent, names)
	for _, n in ipairs(names) do
		local c = parent:FindFirstChild(n)
		while c do
			c:Destroy()
			c = parent:FindFirstChild(n)
		end
	end
end

local function set(inst, props)
	for k, v in pairs(props) do
		inst[k] = v
	end
end

-- ---------------------------------------------------------------------------------------------
-- Geometry snapshot (spec 4.7 step 0 / step 5)
-- ---------------------------------------------------------------------------------------------

local GEOMETRY = {
	GuiObject = { "Size", "Position", "AnchorPoint", "SizeConstraint", "AutomaticSize", "Rotation", "Visible" },
	UIAspectRatioConstraint = { "AspectRatio", "AspectType", "DominantAxis" },
	UISizeConstraint = { "MinSize", "MaxSize" },
	UIGridLayout = { "CellSize", "CellPadding", "FillDirection", "HorizontalAlignment", "VerticalAlignment", "SortOrder", "StartCorner" },
	UIListLayout = { "FillDirection", "HorizontalAlignment", "VerticalAlignment", "Padding", "SortOrder" },
	UIPadding = { "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" },
	UIScale = { "Scale" },
	UITextSizeConstraint = { "MinTextSize", "MaxTextSize" },
}

local function geometryProps(inst)
	if inst:IsA("GuiObject") then
		return GEOMETRY.GuiObject
	end
	return GEOMETRY[inst.ClassName]
end

-- Path relative to `root`, with a #n suffix on same-named siblings so the key is unique.
local function pathOf(inst, root)
	local segs = {}
	local cur = inst
	while cur and cur ~= root do
		local idx = 0
		for _, s in ipairs(cur.Parent:GetChildren()) do
			if s.Name == cur.Name then
				idx += 1
			end
			if s == cur then
				break
			end
		end
		table.insert(segs, 1, cur.Name .. (idx > 1 and ("#" .. idx) or ""))
		cur = cur.Parent
	end
	return table.concat(segs, "/")
end

local function snapshot(root)
	local snap = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:FindFirstAncestorWhichIsA("WorldModel") then
			continue
		end
		local props = geometryProps(d)
		if props then
			local parts = {}
			for _, p in ipairs(props) do
				table.insert(parts, p .. "=" .. tostring(d[p]))
			end
			snap[pathOf(d, root)] = table.concat(parts, " ")
		end
	end
	return snap
end

-- ---------------------------------------------------------------------------------------------
-- HUD
-- ---------------------------------------------------------------------------------------------

local function restyleHud()
	local folder = StarterGui:FindFirstChild("ReworkedHunterGui")
	assert(folder, "StarterGui.ReworkedHunterGui missing")
	local root = folder:FindFirstChild(TEMPLATE)
	assert(root, "ReworkedHunterGui." .. TEMPLATE .. " missing")
	local isMobile = PROFILE == "mobile"

	local before = snapshot(root)
	local expected = {} -- paths whose geometry is allowed to change (desktop only)
	local newInstances = {}

	local function note(inst)
		table.insert(newInstances, inst)
	end

	-- Geometry write: desktop only, and always recorded as expected. On mobile this is a no-op,
	-- which is the whole of the "touch geometry is frozen" rule.
	local function geo(inst, props)
		if isMobile then
			return
		end
		expected[pathOf(inst, root)] = true
		set(inst, props)
	end

	local canvas = root.Canvas
	local weapon = canvas.WeaponFrame
	local ability = canvas.AbilityFrame
	local ultimate = canvas.UltimateFrame
	local playerFrame = canvas.PlayerFrame

	-- 4.1 frame geometry (desktop)
	geo(canvas, { Size = UDim2.fromScale(1, 0.22), Position = UDim2.fromScale(0.5, 0.874) })
	geo(weapon, { Size = UDim2.fromScale(0.21, 0.82), Position = UDim2.fromScale(0.885, 0.52) })
	geo(ability, { Size = UDim2.fromScale(0.19, 0.82), Position = UDim2.fromScale(0.665, 0.49) })
	geo(ultimate, { Size = UDim2.fromScale(0.145, 0.82), Position = UDim2.fromScale(0.505, 0.49) })
	geo(playerFrame, { Size = UDim2.fromScale(0.33, 0.92), Position = UDim2.fromScale(0.165, 0.5) })
	-- Keep the live Horizontal grid; the design's Vertical/Center reads two-up only by accident.
	-- CellSize shrinks to make room for the padding: 0.5 + 0.5 + 0.015 overflows the row and a
	-- UIGridLayout wraps on ANY overflow (UI_STYLE_GUIDE 4.5) -- measured, tile E landed under
	-- tile Q at 1080p. 0.485 + 0.015 + 0.485 = 0.985 leaves the same sub-pixel margin the
	-- mobile grid (0.485 / 0.03) has run with since August.
	geo(ability.UIGridLayout, { CellSize = UDim2.fromScale(0.485, 1), CellPadding = UDim2.fromScale(0.015, 0) })

	-- 4.2 WeaponFrame
	local bulletCounter = weapon.BulletCounter
	geo(bulletCounter, { Size = UDim2.fromScale(0.4, 0.13), Position = UDim2.fromScale(0.7, 0.64) })
	for _, bullet in ipairs(bulletCounter:GetChildren()) do
		if bullet:IsA("ImageLabel") then
			removeChildren(bullet, { "UIGradient" })
			-- ImageTransparency stays 0: the four GUI clients write 0 (live) / 1 (spent) at
			-- runtime, so the design's 0.1 would only ever be seen in the template.
		end
	end
	local gun = weapon.GunDisplayImage
	geo(gun, { Size = UDim2.fromScale(0.45, 0.58), Position = UDim2.fromScale(0.28, 0.5) })
	set(gun, { ImageColor3 = TEXT, ImageTransparency = 0.06 })
	removeChildren(gun, { "UIGradient" })
	local ammo = weapon.AmmoCount
	geo(ammo, { Size = UDim2.fromScale(0.42, 0.29), Position = UDim2.fromScale(0.7, 0.4) })
	set(ammo, { TextColor3 = TEXT, FontFace = BOLD_ITALIC })
	removeChildren(ammo, { "UIGradient", "UIStroke" })
	-- The design's ZIndex 4 on the weapon content. ModernWeaponPanel is a LATER sibling at
	-- ZIndex 1, and under Sibling ordering an equal ZIndex draws in child order -- at 1 the
	-- slab painted over the ammo count and the gun (first desktop capture, 2026-09-13).
	set(bulletCounter, { ZIndex = 4 })
	for _, bullet in ipairs(bulletCounter:GetChildren()) do
		if bullet:IsA("ImageLabel") then
			set(bullet, { ZIndex = 4 })
		end
	end
	set(gun, { ZIndex = 4 })
	set(ammo, { ZIndex = 4 })
	if isMobile then
		-- The mobile WeaponFrame sits INSIDE the PlayerFrame's rect (ammo above the health bar,
		-- right of the portrait) and PlayerFrame is the later sibling, so the one slate panel
		-- lives in PlayerFrame and WeaponFrame is raised a step to draw over it. ZIndex is paint.
		set(weapon, { ZIndex = 2 })
	else
		local panel, created = ensureClone(weapon, "WeaponPanel", "ModernWeaponPanel")
		if created then
			note(panel)
			note(panel.Accent)
		end
	end

	-- 4.3 / 4.4 tiles
	local function restyleTile(mainFrame, isUlt)
		local background = mainFrame.Background
		set(background, {
			BackgroundColor3 = isUlt and ULT_CARD or SLATE_800,
			-- Mobile keeps its authored translucency (the 2026-08-15 mobile-card change); desktop
			-- takes the design's near-opaque card.
			BackgroundTransparency = isMobile and 0.45 or 0.08,
			ZIndex = 5,
		})
		local _, c1 = ensureClone(background, isUlt and "CardCornerUlt" or "CardCornerSkill", "ModernCorner")
		local _, c2 = ensureClone(background, isUlt and "CardGradientUlt" or "CardGradientSkill", "ModernGradient")
		if c1 then note(background.ModernCorner) end
		if c2 then note(background.ModernGradient) end
		-- D4: the gold rope goes. UltimateReadyFX tolerates the missing strokes (it lights the
		-- ReadyGlow layers instead) and VesperHunterGuiClient's stroke read is nil-tolerant.
		removeChildren(background, { "UIStroke", "InnerStroke", "ShadowStroke", "UIShadow" })

		-- D3: the coloured fill draws ABOVE the card so the drain is readable mid-fight.
		local bar = mainFrame.CooldownBar
		set(bar, {
			BackgroundColor3 = isUlt and YELLOW or PINK,
			BackgroundTransparency = isMobile and 0.45 or 0.12,
			ZIndex = 6,
		})
		local _, c3 = ensureClone(bar, "FillCorner", "ModernCorner")
		if c3 then note(bar.ModernCorner) end

		-- D2: the underline shows only while ready. HunterHudCooldown (skills) and
		-- UltimateReadyFX (ultimate) toggle Visible; authored hidden so a controller that has not
		-- run yet cannot advertise a readiness it has not asserted.
		local accent, c4 = ensureClone(mainFrame, isUlt and "ReadyAccentUlt" or "ReadyAccentSkill", "ModernReadyAccent")
		set(accent, { ZIndex = 7, Visible = false })
		if c4 then note(accent) end

		local icon = mainFrame.Ability
		geo(icon, {
			Size = UDim2.fromScale(isUlt and 0.72 or 0.68, isUlt and 0.72 or 0.68),
			Position = UDim2.fromScale(0.5, 0.46),
		})
		set(icon, { ImageColor3 = TEXT, ZIndex = 8 })

		local cooldownLabel = mainFrame:FindFirstChild("Cooldown")
		if cooldownLabel then
			set(cooldownLabel, { ZIndex = 9 })
		end

		local badge = mainFrame.CooldownFrame
		geo(badge, { Size = UDim2.fromScale(0.38, 0.3), Position = UDim2.fromScale(0.5, 0.94) })
		set(badge, { BackgroundColor3 = SLATE_900, BackgroundTransparency = 0, ZIndex = 10 })
		local _, c5 = ensureClone(badge, "BadgeCorner", "ModernCorner")
		if c5 then note(badge.ModernCorner) end
		removeChildren(badge, { "UIStroke", "ShadowStroke", "UIShadow" })
		set(badge.TextLabel, { TextColor3 = isUlt and YELLOW or TEXT, FontFace = BOLD_ITALIC })

		local glow = mainFrame:FindFirstChild("ReadyGlow")
		if glow then
			-- UltimateReadyFX gives ReadyGlow an opaque body while lit (the mask); with a rounded
			-- card above it, the mask needs the same corner or it shows as square shoulders.
			local _, c6 = ensureClone(glow, "CardCornerUlt", "ModernCorner")
			if c6 then note(glow.ModernCorner) end
		end
	end

	for _, holderName in ipairs({ "1Ability", "2Ability" }) do
		local mainFrame = ability[holderName].MainFrame
		geo(mainFrame, { Size = UDim2.fromScale(0.63, 0.63), Position = UDim2.fromScale(0.5, 0.47) })
		restyleTile(mainFrame, false)
	end
	do
		local mainFrame = ultimate.MainFrame
		geo(mainFrame, { Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.47) })
		restyleTile(mainFrame, true)
	end

	-- 4.5 PlayerFrame
	local healthBar = playerFrame.HealthBarFrame
	geo(healthBar, { Size = UDim2.fromScale(0.61, 0.22), Position = UDim2.fromScale(0.61, 0.44) })
	set(healthBar, { ZIndex = 20, ClipsDescendants = true })
	local LAYERS = {
		{ name = "HealthBar", layerZ = 23, barZ = 15, innerZ = 16, innerName = "HealthFrame", color = HEALTH_FULL, transparency = 0 },
		{ name = "DamageTrailBar", layerZ = 22, barZ = 12, innerZ = 13, innerName = "TrailFrame", color = HEALTH_TRAIL, transparency = 0.04 },
		{ name = "HealthBarEmpty", layerZ = 21, barZ = 9, innerZ = 10, innerName = "EmptyFrame", color = HEALTH_EMPTY, transparency = 0.24 },
	}
	for _, layer in ipairs(LAYERS) do
		local frame = healthBar[layer.name]
		set(frame, { ZIndex = layer.layerZ })
		for _, bar in ipairs(frame:GetChildren()) do
			if bar:IsA("Frame") and bar.Name:match("^%d+Bar$") then
				set(bar, { ZIndex = layer.barZ })
				local inner = bar:FindFirstChild(layer.innerName)
				if inner then
					-- SegmentedHealthManager overwrites these three colours at runtime from
					-- its own constants, which are changed to match in the same pass.
					set(inner, { ZIndex = layer.innerZ, BackgroundColor3 = layer.color, BackgroundTransparency = layer.transparency })
					local _, created = ensureClone(inner, "SegmentCorner", "ModernCorner")
					if created then note(inner.ModernCorner) end
				end
			end
		end
	end

	local healthBack = playerFrame.HealthBarFrameBackground
	geo(healthBack, { Size = UDim2.fromScale(0.61, 0.22), Position = UDim2.fromScale(0.61, 0.44) })
	set(healthBack, { BackgroundColor3 = HEALTH_BACK, BackgroundTransparency = 0.08, ZIndex = 5 })
	do
		local _, created = ensureClone(healthBack, "HealthBackCorner", "ModernCorner")
		if created then note(healthBack.ModernCorner) end
	end

	local portrait = playerFrame.PlayerHunterFrame
	geo(portrait, {
		Size = UDim2.fromScale(0.27, 0.88),
		Position = UDim2.fromScale(0.15, 0.5),
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
	})
	set(portrait, { BackgroundColor3 = SLATE_800, BackgroundTransparency = 1, ZIndex = 4 })
	removeChildren(portrait, { "InnerStroke", "ShadowStroke", "UIStroke", "UIShadow" })
	do
		local _, c1 = ensureClone(portrait, "PortraitCorner", "ModernCorner")
		if c1 then note(portrait.ModernCorner) end
		local accent, c2 = ensureClone(portrait, "PortraitAccent", "ModernAccent")
		if c2 then note(accent) end
	end
	local viewport = portrait.ViewportFrame
	geo(viewport, { Size = UDim2.fromScale(0.94, 0.94), Position = UDim2.fromScale(0.5, 0.5) })
	set(viewport, { BackgroundColor3 = VIEWPORT_BG, BackgroundTransparency = 0.08, ZIndex = 4 })
	do
		local _, created = ensureClone(viewport, "ViewportCorner", "ModernCorner")
		if created then note(viewport.ModernCorner) end
	end

	local nameLabel = playerFrame.PlayerName
	geo(nameLabel, { Size = UDim2.fromScale(0.43, 0.18), Position = UDim2.fromScale(0.53, 0.72) })
	set(nameLabel, { TextColor3 = TEXT, FontFace = BOLD_ITALIC, ZIndex = 4 })
	removeChildren(nameLabel, { "UIStroke" })
	-- The design keeps the white -> #585858 gradient the live label already has.

	do
		local panel, created = ensureClone(playerFrame, "PlayerPanel", "ModernPlayerPanel")
		if created then
			note(panel)
			if isMobile then
				-- Sized in scale of the frozen PlayerFrame to back the whole portrait-side stack
				-- (ammo + bullets, health bar, name -- measured at 800x360: x 0.25..1.0 of the
				-- frame, y 0.05..0.89). The desktop numbers were authored for a 0.33 x 0.92
				-- frame with the weapon panel elsewhere, and do not apply here.
				set(panel, { Size = UDim2.fromScale(0.75, 0.84), Position = UDim2.fromScale(0.625, 0.47) })
				-- The yellow edge accent the desktop weapon panel carries moves onto this one.
				local accent = stagingItem("WeaponPanel").Accent:Clone()
				accent.Parent = panel
				note(accent)
			end
		end
	end

	-- D10: the jump / landing impulse targets. UIScales at rest 1, authored so HunterHudShake
	-- never has to create one (only one UIScale per object applies). On AbilityFrame /
	-- UltimateFrame rather than the 1Ability / 2Ability holders: the holders are anchored
	-- (0, 0) under a grid, so a scale on them grows from the top-left corner and reads as a
	-- nudge; the containers are centre-anchored and stretch in place. Never MainFrame (owns
	-- BumpScale) and never Canvas (HunterHudShake bobs its Position).
	for _, target in ipairs({ weapon, ability, ultimate, portrait }) do
		if not target:FindFirstChild("ImpactScale") then
			local scale = Instance.new("UIScale")
			scale.Name = "ImpactScale"
			scale.Scale = 1
			scale.Parent = target
			note(scale)
		end
	end

	-- Step 5: nothing pre-existing moved except what desktop declared.
	local after = snapshot(root)
	local violations = {}
	for path, was in pairs(before) do
		local now = after[path]
		if now ~= nil and now ~= was and not expected[path] then
			table.insert(violations, path .. "\n    was " .. was .. "\n    now " .. now)
		end
	end
	if #violations > 0 then
		error("GEOMETRY MOVED on a frozen instance (" .. #violations .. "):\n  " .. table.concat(violations, "\n  "))
	end

	-- New instances are sized in Scale, px offsets only on the 3-4 px accent lines.
	for _, inst in ipairs(newInstances) do
		if inst:IsA("GuiObject") then
			local s = inst.Size
			local isAccentLine = inst.Name == "Accent" or inst.Name == "ModernAccent" or inst.Name == "ModernReadyAccent"
			local okX = s.X.Offset == 0 or (isAccentLine and math.abs(s.X.Offset) <= 4)
			local okY = s.Y.Offset == 0 or (isAccentLine and math.abs(s.Y.Offset) <= 4)
			if not (okX and okY) then
				error("new instance " .. inst:GetFullName() .. " is sized in pixels: " .. tostring(s))
			end
			-- Scale-sized inside its parent rect (position + size within 0..1, allowing the
			-- anchor). Absolute rects are checked in the proof part, where the GUI is laid out.
			local ax, ay = inst.AnchorPoint.X, inst.AnchorPoint.Y
			local left = inst.Position.X.Scale - s.X.Scale * ax
			local top = inst.Position.Y.Scale - s.Y.Scale * ay
			local right = left + s.X.Scale
			local bottom = top + s.Y.Scale
			if left < -0.001 or top < -0.001 or right > 1.001 or bottom > 1.001 then
				error("new instance " .. inst:GetFullName() .. " reaches past its parent: " .. left .. "," .. top .. " .. " .. right .. "," .. bottom)
			end
		end
	end

	-- The 3 shape contract.
	local mustExist = {
		"SegmentedHealthManager", "Canvas", "Canvas/WeaponFrame", "Canvas/WeaponFrame/BulletCounter/Bullet1",
		"Canvas/WeaponFrame/BulletCounter/Bullet6", "Canvas/WeaponFrame/GunDisplayImage", "Canvas/WeaponFrame/AmmoCount",
		"Canvas/AbilityFrame/1Ability/MainFrame/Background", "Canvas/AbilityFrame/1Ability/MainFrame/CooldownBar",
		"Canvas/AbilityFrame/1Ability/MainFrame/Cooldown", "Canvas/AbilityFrame/1Ability/MainFrame/CooldownFrame/TextLabel",
		"Canvas/AbilityFrame/1Ability/MainFrame/Ability", "Canvas/AbilityFrame/1Ability/MainFrame/BumpScale",
		"Canvas/AbilityFrame/1Ability/MainFrame/ResponsiveAspect",
		"Canvas/AbilityFrame/2Ability/MainFrame/Background", "Canvas/AbilityFrame/2Ability/MainFrame/CooldownBar",
		"Canvas/AbilityFrame/2Ability/MainFrame/Cooldown", "Canvas/AbilityFrame/2Ability/MainFrame/BumpScale",
		"Canvas/UltimateFrame/MainFrame/Background", "Canvas/UltimateFrame/MainFrame/CooldownBar",
		"Canvas/UltimateFrame/MainFrame/Cooldown", "Canvas/UltimateFrame/MainFrame/BumpScale",
		"Canvas/UltimateFrame/MainFrame/ReadyGlow/Layer01", "Canvas/UltimateFrame/MainFrame/ReadyGlow/Layer24",
		"Canvas/PlayerFrame/HealthBarFrame/HealthBar/20Bar/HealthFrame", "Canvas/PlayerFrame/HealthBarFrame/DamageTrailBar/20Bar/TrailFrame",
		"Canvas/PlayerFrame/HealthBarFrame/HealthBarEmpty/20Bar/EmptyFrame", "Canvas/PlayerFrame/PlayerHunterFrame/ViewportFrame/WorldModel",
		"Canvas/PlayerFrame/PlayerName", "Canvas/PlayerFrame/HealthBarFrameBackground", "Canvas/UIAspectRatioConstraint",
	}
	for _, rel in ipairs(mustExist) do
		local cur = root
		for seg in rel:gmatch("[^/]+") do
			cur = cur and cur:FindFirstChild(seg)
		end
		assert(cur, "contract instance missing after merge: " .. rel)
	end

	local expectedCount = 0
	for _ in pairs(expected) do
		expectedCount += 1
	end
	log("%s/%s: %d descendants, %d new instances, %d declared geometry writes, 0 frozen violations",
		TEMPLATE, PROFILE, #root:GetDescendants(), #newInstances, expectedCount)
end

-- ---------------------------------------------------------------------------------------------
-- Quick wins (spec 6.3 - 6.6)
-- ---------------------------------------------------------------------------------------------

local function restyleRoundStatus()
	local gui = StarterGui:FindFirstChild("RoundStatusGui")
	assert(gui, "RoundStatusGui missing")
	for _, name in ipairs({ "TeamScoreRed", "TeamScoreBlue", "TeamAssignBanner" }) do
		local frame = gui[name]
		ensureClone(frame, "ScoreCorner", "UICorner")
	end
	for _, name in ipairs({ "TeamScoreRed", "TeamScoreBlue" }) do
		local chip = gui[name]
		set(chip, { BackgroundTransparency = 0 })
		local stroke = chip:FindFirstChildOfClass("UIStroke")
		if stroke then
			set(stroke, { Color = hex("000000"), Transparency = 0 })
		end
		local labelStroke = chip.ScoreLabel:FindFirstChildOfClass("UIStroke")
		if labelStroke then
			set(labelStroke, { Color = hex("030303") })
		end
		-- Visible stays false; RoundStatusClient shows the chips in team modes.
	end
	log("RoundStatusGui: corners on 3 frames, opaque score plates")
end

local function restyleBountyList()
	local gui = StarterGui:FindFirstChild("BountyListGui")
	assert(gui, "BountyListGui missing")
	local canvas = gui.Canvas
	if BOUNTYLIST_FULL_RESTYLE then
		-- The one touch-geometry change in the port (D11). Position stays authored: the client
		-- re-pins Y per gamemode from AUTHORED_POSITION, and HEADROOM_SCALE in BountyListClient is
		-- re-derived from the new BountyName box in the same pass.
		set(canvas, { Size = UDim2.fromScale(0.241836, 0.168351) })
	end
	local holders = 0
	for _, slot in ipairs(canvas.BountyHolderFrame:GetChildren()) do
		if slot:IsA("Frame") then
			holders += 1
			local real = slot.RealFrame
			local name = real.BountyName
			if BOUNTYLIST_FULL_RESTYLE then
				set(name, { Size = UDim2.fromScale(1, 0.13516), Position = UDim2.fromScale(0.5, 0.124513) })
			end
			local reward = real.RewardAmountLabel
			local rewardStroke = reward:FindFirstChildOfClass("UIStroke")
			if rewardStroke then
				-- A fraction: scale the authored 0.03 to the design's 0.075, never assign a pixel value.
				if rewardStroke:GetAttribute("NewGuiScaled") ~= true then
					rewardStroke.Thickness = rewardStroke.Thickness * 2.5
					rewardStroke:SetAttribute("NewGuiScaled", true)
				end
				set(rewardStroke, { Color = hex("5B5B5B"), Transparency = 0 })
			end
			local icon = real.IconDisplay
			set(icon.UICorner, { CornerRadius = UDim.new(0.05, 0) })
			local ring = icon:FindFirstChildOfClass("UIStroke")
			if ring then
				set(ring, { Color = hex("000000") })
				-- Its gradient children (the gilded stroke gradient, 2026-08-29) stay.
			end
			local ringShadow = icon:FindFirstChild("RingShadow")
			if ringShadow then
				set(ringShadow, { Transparency = 0.15 })
			end
			ensureClone(icon, "BountyIconShadow", "UIShadow")
			local stamp = icon.BountyStamp
			set(stamp, {
				Size = UDim2.fromScale(0.9, 0.298469),
				Position = UDim2.fromScale(0.5, 0.986189),
				TextColor3 = hex("FFFFFF"),
			})
			local stampStroke = stamp:FindFirstChildOfClass("UIStroke")
			if stampStroke then
				set(stampStroke, { Color = hex("565656") })
			end
		end
	end
	log("BountyListGui: %d card holders restyled (%s)", holders, BOUNTYLIST_FULL_RESTYLE and "full D11" or "portrait-only variant")
end

local function restyleDomination()
	local gui = StarterGui:FindFirstChild("DominationGui")
	assert(gui, "DominationGui missing")
	local shadows, bars, circles = 0, 0, 0
	for _, d in ipairs(gui:GetDescendants()) do
		if d.Name == "BackgroundShadow" and d:IsA("ImageLabel") then
			d.ImageTransparency = 1
			shadows += 1
		elseif d.Name == "BackgroundBar" and d:IsA("Frame") and d:FindFirstAncestor("Canvas") then
			-- The two team bars only; the capture bar keeps its #232323 in the design too.
			d.BackgroundColor3 = hex("000000")
			bars += 1
		elseif d.Name == "Circle" and d:IsA("Frame") and d.Parent.Parent.Name == "CapturePointClaimed" then
			-- DominationClient reads this as the empty-track colour and hands it back after a
			-- full dial, so black is what the not-owned dial shows.
			d.BackgroundColor3 = hex("000000")
			circles += 1
		end
	end
	assert(shadows == 3 and bars == 2 and circles == 3, string.format("DominationGui shape changed: %d shadows %d bars %d circles", shadows, bars, circles))
	log("DominationGui: 3 shadows off, 2 bars + 3 pad circles black")
end

local function restyleMobileButtons()
	-- D6 -- the authored instances. The modules rewrite colour on the runtime-built fallback
	-- and on the sprint toggle, so their constants are edited separately.
	local FACES = {
		{ gui = "HunterFireGui", button = "MobileFireButton", color = nil, transparency = 0 },
		{ gui = "HunterJumpGui", button = "MobileJumpButton", color = BUTTON_FACE, transparency = 0 },
		{ gui = "HunterReloadGui", button = "MobileReloadButton", color = BUTTON_FACE, transparency = 0 },
		{ gui = "HunterSprintGui", button = "MobileSprintButton", color = BUTTON_FACE, transparency = 0 },
		{ gui = "VesperScopeGui", button = "MobileScopeButton", color = BUTTON_FACE, transparency = 0 },
	}
	for _, face in ipairs(FACES) do
		local gui = StarterGui:FindFirstChild(face.gui)
		assert(gui, face.gui .. " missing")
		local button = gui[face.button]
		if face.color then
			button.BackgroundColor3 = face.color
		end
		button.BackgroundTransparency = face.transparency
	end
	-- SCOPE gains the second (Border) ring the other four carry, cloned from JUMP so it is the
	-- same 0.02 fraction and scales with the button on tablets rather than the design's 2 px.
	local scope = StarterGui.VesperScopeGui.MobileScopeButton
	local hasBorder = false
	for _, c in ipairs(scope:GetChildren()) do
		if c:IsA("UIStroke") and c.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then
			hasBorder = true
		end
	end
	if not hasBorder then
		for _, c in ipairs(StarterGui.HunterJumpGui.MobileJumpButton:GetChildren()) do
			if c:IsA("UIStroke") and c.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then
				c:Clone().Parent = scope
				break
			end
		end
	end
	log("mobile buttons: 5 faces opaque, SCOPE has its Border ring")
end

-- ---------------------------------------------------------------------------------------------
-- Kill cam card (spec 6.1)
-- ---------------------------------------------------------------------------------------------

local function authorKillCam()
	-- A Folder wrapper, like ReworkedHunterGui: a top-level ScreenGui in StarterGui would be
	-- force-shown by RoundClientController's sweep ("unknown gui -> visible") on every respawn
	-- unless it were added to SWEEP_EXEMPT_GUI_NAMES; nested in a Folder it is invisible to the
	-- sweep and KillCamClient clones it into PlayerGui by name.
	local folder = StarterGui:FindFirstChild("KillCamGuiTemplate")
	if folder and folder:FindFirstChild("KillCamGui") then
		log("KillCamGuiTemplate already authored")
		return
	end
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "KillCamGuiTemplate"
		folder.Parent = StarterGui
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "KillCamGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 9500
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false

	-- The pixel block KillCamClient positions above the combat-feed base line, unchanged:
	-- 420 x 108 = "KILLED BY" 28 + name 46 + cosmetic title 30, bottom-anchored.
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.Position = UDim2.new(0.5, 0, 0.6, 0)
	container.Size = UDim2.fromOffset(420, 108)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = gui

	local design = stagingItem("KilledByCanvas")
	local title = design.KilledBy:Clone()
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0, 0)
	title.Position = UDim2.fromOffset(0, 0)
	title.Size = UDim2.new(1, 0, 0, 28)
	title.Text = "KILLED BY"
	title.Parent = container

	local name = design.PlayerName:Clone()
	name.Name = "KillerName"
	name.AnchorPoint = Vector2.new(0, 0)
	name.Position = UDim2.fromOffset(0, 30)
	name.Size = UDim2.new(1, 0, 0, 46)
	name.Text = "ONLYTWENTYCHARACTERS"
	name.Parent = container

	-- The killer's cosmetic title slot. TitleRenderer restyles it per title; empty and hidden
	-- for bots and killer-less deaths, but its 30 px stays reserved so the card never jumps.
	local cosmetic = name:Clone()
	cosmetic.Name = "KillerTitle"
	cosmetic.Position = UDim2.fromOffset(0, 78)
	cosmetic.Size = UDim2.new(1, 0, 0, 30)
	cosmetic.Text = ""
	cosmetic.Visible = false
	cosmetic.Parent = container

	local scale = Instance.new("UIScale")
	scale.Name = "MobileScale"
	scale.Scale = 1
	scale.Parent = container

	gui.Parent = folder
	log("KillCamGuiTemplate.KillCamGui authored (%d descendants)", #gui:GetDescendants())
end

-- ---------------------------------------------------------------------------------------------
-- Objective line (spec 6.2)
-- ---------------------------------------------------------------------------------------------

local function authorObjectiveLine()
	local gui = StarterGui:FindFirstChild("EyeCandy")
	assert(gui, "EyeCandy missing")
	local canvas = gui.Canvas
	local label, created = ensureClone(canvas, "ObjectiveText", "ObjectiveAnnouncement")
	if created then
		-- Same slot and size as MainAnnouncement: it is shown through the notice lane, which
		-- only ever runs when no beat is on screen, so the two never overlap.
		local main = canvas.MainAnnouncement
		label.Size = main.Size
		label.Position = main.Position
		label.AnchorPoint = main.AnchorPoint
		label.ZIndex = main.ZIndex
		label.Visible = false
		label.Text = "YOUR TEAM IS NOW CONTROLLING A POINT"
	end
	log("EyeCandy.Canvas.ObjectiveAnnouncement %s", created and "added" or "already present")
end

-- ---------------------------------------------------------------------------------------------
-- Proof (spec 5.2)
-- ---------------------------------------------------------------------------------------------

local PROOF_PREFIX = "__NewGuiProof"

local function destroyProofHarness()
	for _, c in ipairs(CoreGui:GetChildren()) do
		if c.Name:sub(1, #PROOF_PREFIX) == PROOF_PREFIX then
			c:Destroy()
		end
	end
end

local function rect(g)
	local p, s = g.AbsolutePosition, g.AbsoluteSize
	if p.X ~= p.X or s.X ~= s.X then
		return "NaN"
	end
	return string.format("%.1f,%.1f %.1fx%.1f", p.X, p.Y, s.X, s.Y)
end

local function proof()
	local preset = CONFIG.preset or "unknown"
	destroyProofHarness()
	local folder = StarterGui.ReworkedHunterGui
	local template = folder[TEMPLATE]
	local hud = template:Clone()
	hud.Name = PROOF_PREFIX .. "_" .. TEMPLATE
	for _, d in ipairs(hud:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	hud.Enabled = true
	hud.Parent = CoreGui
	local buttons = {}
	local CLUSTER = { "HunterFireGui", "HunterJumpGui", "HunterReloadGui", "HunterSprintGui", "VesperScopeGui" }
	if TEMPLATE == "HunterGuiMobile" then
		for _, name in ipairs(CLUSTER) do
			local src = StarterGui:FindFirstChild(name)
			if src then
				local c = src:Clone()
				c.Name = PROOF_PREFIX .. "_" .. name
				c.Enabled = true
				c.Parent = CoreGui
				buttons[name] = c:FindFirstChildWhichIsA("GuiButton")
			end
		end
	end
	task.wait(0.25)

	local canvas = hud.Canvas
	local weapon, ability, ultimate, playerFrame = canvas.WeaponFrame, canvas.AbilityFrame, canvas.UltimateFrame, canvas.PlayerFrame
	local tiles = {
		Q = ability["1Ability"].MainFrame,
		E = ability["2Ability"].MainFrame,
		F = ultimate.MainFrame,
	}

	-- Geometry that must be EQUAL before and after (mobile) -- every pre-existing frame.
	local geometry = {}
	local function g(name, inst)
		table.insert(geometry, name .. "=" .. rect(inst))
	end
	g("Canvas", canvas)
	g("WeaponFrame", weapon)
	g("AbilityFrame", ability)
	g("UltimateFrame", ultimate)
	g("PlayerFrame", playerFrame)
	g("TileQ", tiles.Q)
	g("TileE", tiles.E)
	g("TileF", tiles.F)
	g("HealthBarFrame", playerFrame.HealthBarFrame)
	g("Portrait", playerFrame.PlayerHunterFrame)
	g("PlayerName", playerFrame.PlayerName)
	g("AmmoCount", weapon.AmmoCount)
	g("BulletCounter", weapon.BulletCounter)
	g("GunDisplayImage", weapon.GunDisplayImage)
	for _, name in ipairs(CLUSTER) do
		if buttons[name] then
			g(name, buttons[name])
		end
	end
	local geometryText = table.concat(geometry, "\n")

	-- Checks that hold on both profiles.
	local problems = {}
	local vp = workspace.CurrentCamera.ViewportSize
	local function inside(child, parent, label)
		local cp, cs = child.AbsolutePosition, child.AbsoluteSize
		local pp, ps = parent.AbsolutePosition, parent.AbsoluteSize
		local slack = 0.75
		if cp.X < pp.X - slack or cp.Y < pp.Y - slack or cp.X + cs.X > pp.X + ps.X + slack or cp.Y + cs.Y > pp.Y + ps.Y + slack then
			table.insert(problems, label .. " reaches past its parent: " .. rect(child) .. " vs " .. rect(parent))
		end
	end
	local function fits(labelInst, label)
		if labelInst.Visible and not labelInst.TextFits then
			table.insert(problems, label .. " does not fit its box (" .. rect(labelInst) .. ")")
		end
	end
	local wp = weapon:FindFirstChild("ModernWeaponPanel")
	if wp then inside(wp, weapon, "ModernWeaponPanel") end
	local pp = playerFrame:FindFirstChild("ModernPlayerPanel")
	if pp then inside(pp, playerFrame, "ModernPlayerPanel") end
	local pa = playerFrame.PlayerHunterFrame:FindFirstChild("ModernAccent")
	if pa then inside(pa, playerFrame.PlayerHunterFrame, "ModernAccent") end
	for key, tile in pairs(tiles) do
		local accent = tile:FindFirstChild("ModernReadyAccent")
		if accent then inside(accent, tile, "ModernReadyAccent " .. key) end
		fits(tile.CooldownFrame.TextLabel, "keybind badge " .. key)
	end
	fits(weapon.AmmoCount, "AmmoCount")
	fits(playerFrame.PlayerName, "PlayerName")
	-- Off-screen.
	local cp, cs = canvas.AbsolutePosition, canvas.AbsoluteSize
	local guiPos, guiSize = hud.AbsolutePosition, hud.AbsoluteSize
	if cp.X < guiPos.X - 0.75 or cp.X + cs.X > guiPos.X + guiSize.X + 0.75 or cp.Y + cs.Y > guiPos.Y + guiSize.Y + 0.75 then
		table.insert(problems, "Canvas leaves the ScreenGui: " .. rect(canvas) .. " vs " .. rect(hud))
	end
	-- Tiles vs the touch cluster (authored positions; HunterMobileClusterLayout moves the buttons
	-- at runtime, so this is the conservative edit-mode reading).
	for _, name in ipairs({ "HunterFireGui", "HunterSprintGui", "HunterJumpGui" }) do
		local button = buttons[name]
		if button then
			local bp, bs = button.AbsolutePosition, button.AbsoluteSize
			for key, tile in pairs(tiles) do
				local tp, ts = tile.AbsolutePosition, tile.AbsoluteSize
				if tp.X < bp.X + bs.X and tp.X + ts.X > bp.X and tp.Y < bp.Y + bs.Y and tp.Y + ts.Y > bp.Y then
					table.insert(problems, "tile " .. key .. " overlaps " .. name .. " (authored rects)")
				end
			end
		end
	end
	-- First painted HUD pixel (what DominationClient / AnnouncementController dodge).
	local firstPainted = math.huge
	local firstName = "?"
	for _, d in ipairs(hud:GetDescendants()) do
		if d:IsA("GuiObject") and d.Visible and d.AbsoluteSize.Y > 0 and not d:FindFirstAncestorWhichIsA("WorldModel") then
			local painted = (d.BackgroundTransparency < 1)
				or (d:IsA("ImageLabel") and d.Image ~= "" and d.ImageTransparency < 1)
				or (d:IsA("TextLabel") and d.Text ~= "" and d.TextTransparency < 1)
				or d:IsA("ViewportFrame")
			-- A visible ancestor chain is required too.
			local shown = true
			local a = d.Parent
			while a and a ~= hud do
				if a:IsA("GuiObject") and not a.Visible then
					shown = false
					break
				end
				a = a.Parent
			end
			if painted and shown and d.AbsolutePosition.Y < firstPainted then
				firstPainted = d.AbsolutePosition.Y
				firstName = d.Name
			end
		end
	end

	-- Store or compare.
	local proofFolder = staging and staging:FindFirstChild("Proof")
	if staging and not proofFolder then
		proofFolder = Instance.new("Folder")
		proofFolder.Name = "Proof"
		proofFolder.Parent = staging
	end
	local key = TEMPLATE .. "." .. preset
	local stored = proofFolder and proofFolder:FindFirstChild(key)
	local verdict
	if stored then
		if stored.Value == geometryText then
			verdict = "EQUAL to the stored before-snapshot"
		else
			local diffs = {}
			local beforeLines = {}
			for line in stored.Value:gmatch("[^\n]+") do
				local k = line:match("^([^=]+)=")
				beforeLines[k] = line
			end
			for _, line in ipairs(geometry) do
				local k = line:match("^([^=]+)=")
				if beforeLines[k] ~= line then
					table.insert(diffs, "  " .. tostring(beforeLines[k]) .. "  ->  " .. line)
				end
			end
			verdict = "DIFFERS from the stored before-snapshot:\n" .. table.concat(diffs, "\n")
		end
	elseif proofFolder then
		local v = Instance.new("StringValue")
		v.Name = key
		v.Value = geometryText
		v.Parent = proofFolder
		verdict = "stored as the before-snapshot"
	else
		verdict = "no staging folder: nothing stored"
	end

	destroyProofHarness()

	log("[%s @ %s, viewport %dx%d] %s", TEMPLATE, preset, vp.X, vp.Y, verdict)
	log("first painted HUD pixel: y=%.1f (%.4f of viewport, %s); canvas top %.4f", firstPainted, firstPainted / vp.Y, firstName, cp.Y / vp.Y)
	if #problems > 0 then
		log("PROBLEMS (%d):\n  %s", #problems, table.concat(problems, "\n  "))
	else
		log("containment / TextFits / overlap: all clear")
	end
	if CONFIG.verbose then
		log(geometryText)
	end
end

-- First-look fixes (owner, 2026-09-13, after the build above). Idempotent; run AFTER "hud" in
-- each match place. Records what was changed by hand in Studio that day so a rebuild lands on
-- the signed-off state:
--   * skill tiles: a READY tile is the dark card with the light icon, as in the design place (the
--     fill is hidden at rest by HunterHudCooldown and authored hidden here). While LOADING a WHITE
--     fill rises, with a BLACK (SLATE_900) ready underline, drawn with a positive-height
--     CooldownBar anchored to the tile's bottom (HunterHudCooldown READY_SIZE is +1 since the
--     same day; a negative-height frame did not render mid-fill), ClipsDescendants on, and a
--     dark copy of the icon INSIDE the fill (CooldownBar.ModernFillContent.ModernAbilityOver,
--     mirrored off Ability.Image by HunterHudCooldown) so the glyph reads on both halves. The
--     countdown label stays single (it is authored rotated, and rotated descendants are not
--     clipped) and gets a dark text stroke instead.
--   * the mobile ModernPlayerPanel slab is flush with the portrait's top and bottom (0.76 tall
--     at y 0.5) so its corner no longer peeks out above the portrait.
--   * the STUNNED / PINNED label (StunnedGui.Canvas.TextLabel) is flat white: the gold fill
--     UIGradient and the UIStroke + its UIGradient are removed, as in the design place's copy
--     (added the same evening). StunnedController's setAlpha drives TextStrokeTransparency to 0,
--     so at runtime the label gets the legacy thin black outline the UIStroke used to hide.
--   * TOUCH GEOMETRY EXCEPTIONS, owner-approved: CooldownBar's AnchorPoint/Position/Size on the
--     two skill tiles (same resolved rect at rest), and the slab (a port-created instance).
-- The Vesper / Bram gun boxes and the Domination bounty placement live in their scripts.
local function firstLookFixes()
	local WHITE = Color3.fromRGB(255, 255, 255)
	local sg = game.StarterGui.ReworkedHunterGui
	for _, tname in ipairs({ "ScreenGui", "HunterGuiMobile" }) do
		local canvas = sg[tname].Canvas
		for _, holder in ipairs({ "1Ability", "2Ability" }) do
			local mf = canvas.AbilityFrame[holder].MainFrame
			local icon, label, bar = mf.Ability, mf.Cooldown, mf.CooldownBar
			local content = bar:FindFirstChild("ModernFillContent")
			if not content then
				content = Instance.new("Frame")
				content.Name = "ModernFillContent"
				content.BackgroundTransparency = 1
				content.BorderSizePixel = 0
				content.SizeConstraint = Enum.SizeConstraint.RelativeXX -- the bar's width never changes
				content.Size = UDim2.fromScale(1, 1)
				content.AnchorPoint = Vector2.new(0.5, 1)
				content.Position = UDim2.fromScale(0.5, 1)
				content.Parent = bar
				log("%s/%s: +ModernFillContent", tname, holder)
			end
			local iconOver = content:FindFirstChild("ModernAbilityOver")
			if not iconOver then
				iconOver = icon:Clone()
				iconOver.Name = "ModernAbilityOver"
				iconOver.Parent = content
				log("%s/%s: +ModernAbilityOver", tname, holder)
			end
			local stale = content:FindFirstChild("ModernCooldownOver")
			if stale then
				stale:Destroy()
			end
			bar.AnchorPoint = Vector2.new(0.5, 1)
			bar.Position = UDim2.fromScale(0.5, 1)
			bar.Size = UDim2.fromScale(1, 1)
			bar.BackgroundColor3 = WHITE
			bar.ClipsDescendants = true
			bar.Visible = false -- a loading indicator only; HunterHudCooldown shows it between Start and expiry
			mf.Background.ZIndex = 5
			icon.ZIndex = 6
			icon.ImageColor3 = TEXT
			bar.ZIndex = 8
			content.ZIndex = 1
			iconOver.ZIndex = 1
			iconOver.ImageColor3 = SLATE_900
			mf.ModernReadyAccent.ZIndex = 9
			mf.ModernReadyAccent.BackgroundColor3 = SLATE_900 -- black underline on the white tile (owner, second note)
			label.ZIndex = 10
			label.TextColor3 = TEXT
			label.TextStrokeColor3 = SLATE_900
			label.TextStrokeTransparency = 0.15
			mf.CooldownFrame.ZIndex = 11
		end
	end
	local slab = sg.HunterGuiMobile.Canvas.PlayerFrame:FindFirstChild("ModernPlayerPanel")
	if slab then
		slab.Size = UDim2.fromScale(0.75, 0.76)
		slab.Position = UDim2.fromScale(0.625, 0.5)
	end
	local stunLabel = game.StarterGui.StunnedGui.Canvas.TextLabel
	for _, child in ipairs(stunLabel:GetChildren()) do
		if child:IsA("UIStroke") or child:IsA("UIGradient") then
			child:Destroy()
			log("StunnedGui label: -%s", child.ClassName)
		end
	end
	log("first-look fixes applied")
end

-- ---------------------------------------------------------------------------------------------

if PART == "hud" then
	restyleHud()
elseif PART == "quickwins" then
	restyleRoundStatus()
	restyleBountyList()
	restyleDomination()
	restyleMobileButtons()
elseif PART == "killcam" then
	authorKillCam()
elseif PART == "eyecandy" then
	authorObjectiveLine()
elseif PART == "firstlook" then
	firstLookFixes()
elseif PART == "proof" then
	proof()
elseif PART == "cleanup" then
	destroyProofHarness()
	if staging then
		staging:Destroy()
	end
	log("staging + harness removed")
else
	error("unknown part " .. tostring(PART))
end

return table.concat(report, "\n")
