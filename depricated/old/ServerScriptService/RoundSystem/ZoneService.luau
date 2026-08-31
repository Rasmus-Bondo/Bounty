local ZoneService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game.ServerScriptService.Shared.Config)
local State = require(game.ServerScriptService.Shared.State)
local LobbyService = require(script.Parent.LobbyService)

local currentPhase = 0
local phaseStartTime = 0
local zoneActive = false
local randomCenterOffset = 0
local damageConnection = nil
local damageAccumulator = 0

local PHASE_NAMES = { "Exploration", "Pressure", "Event", "Final" }
local fireEffects = {}
local lastPhaseChangeTime = 0

function ZoneService.Initialize()
	print("[ZoneService] Initialized")
end

function ZoneService.startZone(randomSeed)
	zoneActive = true
	currentPhase = 1
	phaseStartTime = tick()
	damageAccumulator = 0

	local rng = Random.new(randomSeed or tick())
	randomCenterOffset = rng:NextNumber(-Config.ZONE_CENTER_RANDOM_RANGE, Config.ZONE_CENTER_RANDOM_RANGE)

	workspace:SetAttribute("ZonePhase", 1)
	workspace:SetAttribute("ZonePhaseName", PHASE_NAMES[1])

	if damageConnection then
		damageConnection:Disconnect()
	end

	damageConnection = RunService.Heartbeat:Connect(function(dt)
		if not zoneActive then return end

		local elapsed = tick() - phaseStartTime
		local newPhase = math.min(math.floor(elapsed / Config.ZONE_PHASE_DURATION) + 1, 4)

		if newPhase ~= currentPhase then
			currentPhase = newPhase
			workspace:SetAttribute("ZonePhase", currentPhase)
			workspace:SetAttribute("ZonePhaseName", PHASE_NAMES[currentPhase] or "Final")
			if currentPhase == 2 then
				ZoneService._createFireEffects()
			end
			lastPhaseChangeTime = tick()
			print("[ZoneService] Phase " .. currentPhase .. ": " .. (PHASE_NAMES[currentPhase] or "Final"))
		end

		local phaseTimeLeft = Config.ZONE_PHASE_DURATION - (elapsed % Config.ZONE_PHASE_DURATION)
		if currentPhase >= 4 then
			phaseTimeLeft = math.max(0, Config.ROUND_TIME - elapsed)
		end
		workspace:SetAttribute("ZonePhaseTimeLeft", math.ceil(phaseTimeLeft))

		if currentPhase >= 2 then
			ZoneService._updateFirePositions()

			damageAccumulator = damageAccumulator + dt
			if damageAccumulator >= Config.ZONE_DAMAGE_INTERVAL then
				damageAccumulator = damageAccumulator - Config.ZONE_DAMAGE_INTERVAL
				ZoneService._applyZoneDamage()
			end
		end
	end)

	print("[ZoneService] Zone started — center offset: " .. string.format("%.1f", randomCenterOffset))
end

function ZoneService._getZoneBounds()
	local fullRange = Config.ZONE_END_Z - Config.ZONE_START_Z
	local center = (Config.ZONE_START_Z + Config.ZONE_END_Z) / 2 + randomCenterOffset

	-- Phase 1: full map, no shrinking
	if currentPhase <= 1 then
		return center - fullRange / 2, center + fullRange / 2
	end

	-- Previous and target fractions per phase: 100% -> 75% -> 50% -> 25%
	local prevFraction = 1.0 - 0.25 * (currentPhase - 2)
	local targetFraction = 1.0 - 0.25 * (currentPhase - 1)

	-- Move during first half of phase, hold during second half
	local halfPhase = Config.ZONE_PHASE_DURATION / 2
	local phaseElapsed = tick() - lastPhaseChangeTime
	local t = math.clamp(phaseElapsed / halfPhase, 0, 1)

	local fraction = prevFraction + (targetFraction - prevFraction) * t
	local halfSpan = (fullRange * fraction) / 2

	return center - halfSpan, center + halfSpan
end

function ZoneService._applyZoneDamage()
	if not State.roundActive then return end

	local damagePerTick = Config.ZONE_DAMAGE_PER_SEC * Config.ZONE_DAMAGE_INTERVAL

	for _, player in pairs(Players:GetPlayers()) do
		if LobbyService.isOptedIn(player) then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					if not ZoneService.isPlayerInSafeZone(player) then
						if humanoid.Health - damagePerTick <= 0 then
							player:SetAttribute("ShouldRagdoll", true)
						end
						humanoid:TakeDamage(damagePerTick)
					end
				end
			end
		end
	end
end

function ZoneService.isPlayerInSafeZone(player)
	if not zoneActive then return true end
	if currentPhase <= 1 then return true end

	local character = player.Character
	if not character then return true end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return true end

	local posZ = rootPart.Position.Z

	-- Use actual fire wall positions so damage matches the visual
	if #fireEffects >= 2 then
		local southZ = fireEffects[1].Position.Z
		local northZ = fireEffects[2].Position.Z
		return posZ >= southZ and posZ <= northZ
	end

	local minZ, maxZ = ZoneService._getZoneBounds()
	return posZ >= minZ and posZ <= maxZ
end

function ZoneService.getCurrentPhase()
	return currentPhase
end

function ZoneService.getPhaseName()
	return PHASE_NAMES[currentPhase] or "None"
end

function ZoneService.isPositionInSafeZone(zPos)
	if not zoneActive or currentPhase <= 1 then return true end
	local minZ, maxZ = ZoneService._getZoneBounds()
	return zPos >= minZ and zPos <= maxZ
end

function ZoneService._createFireEffects()
	for _, effect in pairs(fireEffects) do
		effect:Destroy()
	end
	fireEffects = {}

	if not zoneActive or currentPhase == 0 then return end

	-- Spawn walls at full map edges so they move inward visually
	local mapSouth = Config.ZONE_START_Z - 50
	local mapNorth = Config.ZONE_END_Z + 50
	local function createFireWall(name, zPos)
		local wall = Instance.new("Part")
		wall.Name = name
		wall.Size = Vector3.new(800, 50, 20)
		wall.Position = Vector3.new(0, 25, zPos)
		wall.Anchored = true
		wall.CanCollide = false
		wall.CanQuery = false
		wall.Transparency = 0.6
		wall.Color = Color3.fromRGB(120, 60, 20)
		wall.Material = Enum.Material.Neon
		wall.Parent = workspace

		-- Main fire layer
		local fire = Instance.new("ParticleEmitter")
		fire.Texture = "rbxasset://textures/particles/fire_main.dds"
		fire.Rate = 200
		fire.Lifetime = NumberRange.new(1, 3)
		fire.Speed = NumberRange.new(5, 15)
		fire.SpreadAngle = Vector2.new(30, 30)
		fire.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 80)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 120, 20)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(200, 50, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 20, 0)),
		})
		fire.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 8),
			NumberSequenceKeypoint.new(0.3, 15),
			NumberSequenceKeypoint.new(0.7, 12),
			NumberSequenceKeypoint.new(1, 4),
		})
		fire.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		fire.LightEmission = 0.9
		fire.LightInfluence = 0.1
		fire.Parent = wall

		-- Thick dust/smoke layer for density
		local dust = Instance.new("ParticleEmitter")
		dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
		dust.Rate = 150
		dust.Lifetime = NumberRange.new(2, 5)
		dust.Speed = NumberRange.new(2, 8)
		dust.SpreadAngle = Vector2.new(40, 40)
		dust.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 120, 50)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 80, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 40, 10)),
		})
		dust.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 10),
			NumberSequenceKeypoint.new(0.5, 25),
			NumberSequenceKeypoint.new(1, 15),
		})
		dust.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		})
		dust.LightEmission = 0.3
		dust.LightInfluence = 0.5
		dust.Rotation = NumberRange.new(0, 360)
		dust.RotSpeed = NumberRange.new(-30, 30)
		dust.Parent = wall

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 120, 0)
		light.Brightness = 4
		light.Range = 60
		light.Parent = wall

		table.insert(fireEffects, wall)
	end

	createFireWall("ZoneFire_South", mapSouth)
	createFireWall("ZoneFire_North", mapNorth)
end

function ZoneService._updateFirePositions()
	if #fireEffects < 2 then return end

	local minZ, maxZ = ZoneService._getZoneBounds()

	fireEffects[1].Position = Vector3.new(0, 25, minZ)
	fireEffects[2].Position = Vector3.new(0, 25, maxZ)
end

function ZoneService.resetZone()
	zoneActive = false
	currentPhase = 0
	randomCenterOffset = 0
	damageAccumulator = 0

	if damageConnection then
		damageConnection:Disconnect()
		damageConnection = nil
	end

	for _, effect in pairs(fireEffects) do
		effect:Destroy()
	end
	fireEffects = {}

	workspace:SetAttribute("ZonePhase", 0)
	workspace:SetAttribute("ZonePhaseName", "")
	workspace:SetAttribute("ZonePhaseTimeLeft", 0)

	print("[ZoneService] Zone reset")
end

return ZoneService