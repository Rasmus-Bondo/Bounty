local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "ZoneColorCorrection"
cc.Brightness = 0
cc.Contrast = 0
cc.Saturation = 0
cc.TintColor = Color3.fromRGB(255, 140, 40)
cc.Enabled = false
cc.Parent = Lighting

local blur = Instance.new("BlurEffect")
blur.Name = "ZoneBlur"
blur.Size = 0
blur.Enabled = false
blur.Parent = Lighting

local currentIntensity = 0
local TARGET_LERP_SPEED = 3

RunService.Heartbeat:Connect(function(dt)
	local phase = workspace:GetAttribute("ZonePhase") or 0
	if phase < 2 then
		if cc.Enabled then
			currentIntensity = 0
			cc.Enabled = false
			blur.Enabled = false
			blur.Size = 0
		end
		return
	end

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local southWall = workspace:FindFirstChild("ZoneFire_South")
	local northWall = workspace:FindFirstChild("ZoneFire_North")
	if not southWall or not northWall then return end

	local posZ = rootPart.Position.Z
	local southZ = southWall.Position.Z
	local northZ = northWall.Position.Z

	local targetIntensity = 0
	if posZ < southZ or posZ > northZ then
		-- How far outside the zone (in studs), clamped for effect scaling
		local dist
		if posZ < southZ then
			dist = southZ - posZ
		else
			dist = posZ - northZ
		end
		targetIntensity = math.clamp(dist / 40, 0, 1)
	end

	currentIntensity = currentIntensity + (targetIntensity - currentIntensity) * math.min(dt * TARGET_LERP_SPEED, 1)

	if currentIntensity > 0.01 then
		cc.Enabled = true
		blur.Enabled = true
		cc.Brightness = 0.08 * currentIntensity
		cc.Contrast = -0.15 * currentIntensity
		cc.Saturation = -0.6 * currentIntensity
		blur.Size = 6 * currentIntensity
	else
		currentIntensity = 0
		cc.Enabled = false
		blur.Enabled = false
		blur.Size = 0
	end
end)