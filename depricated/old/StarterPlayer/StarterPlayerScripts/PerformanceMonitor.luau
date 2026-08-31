local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Quality tiers (per D-10: 45-60 FPS target)
local QUALITY_HIGH = "high"     -- 50+ FPS: full particles
local QUALITY_MEDIUM = "medium" -- 40-50 FPS: reduced particles
local QUALITY_LOW = "low"       -- <40 FPS: minimal particles

-- Particle multipliers per quality level
local QUALITY_MULTIPLIERS = {
	[QUALITY_HIGH] = 1.0,    -- 100% particle count
	[QUALITY_MEDIUM] = 0.5,  -- 50% particle count
	[QUALITY_LOW] = 0.25,    -- 25% particle count
}

-- Sampling config
local SAMPLE_INTERVAL = 5  -- seconds between quality checks
local HYSTERESIS_UP = 55   -- must sustain 55+ FPS to go up a tier (prevents oscillation)
local HYSTERESIS_DOWN = 38  -- must drop below 38 to go down (prevents oscillation)

local frameCount = 0
local elapsed = 0
local currentQuality = QUALITY_HIGH

-- Store quality as player attribute so other scripts can read it
player:SetAttribute("QualityLevel", currentQuality)
player:SetAttribute("ParticleMultiplier", 1.0)

RunService.RenderStepped:Connect(function(dt)
	frameCount += 1
	elapsed += dt

	if elapsed >= SAMPLE_INTERVAL then
		local avgFPS = frameCount / elapsed

		-- Apply hysteresis to prevent rapid oscillation between tiers
		local newQuality = currentQuality

		if currentQuality == QUALITY_HIGH then
			if avgFPS < HYSTERESIS_DOWN then
				newQuality = QUALITY_LOW
			elseif avgFPS < 45 then
				newQuality = QUALITY_MEDIUM
			end
		elseif currentQuality == QUALITY_MEDIUM then
			if avgFPS >= HYSTERESIS_UP then
				newQuality = QUALITY_HIGH
			elseif avgFPS < HYSTERESIS_DOWN then
				newQuality = QUALITY_LOW
			end
		elseif currentQuality == QUALITY_LOW then
			if avgFPS >= HYSTERESIS_UP then
				newQuality = QUALITY_HIGH
			elseif avgFPS >= 45 then
				newQuality = QUALITY_MEDIUM
			end
		end

		if newQuality ~= currentQuality then
			currentQuality = newQuality
			local multiplier = QUALITY_MULTIPLIERS[currentQuality]
			player:SetAttribute("QualityLevel", currentQuality)
			player:SetAttribute("ParticleMultiplier", multiplier)

			-- Apply to existing ParticleEmitters in workspace
			-- Reduce Rate on active particle emitters
			for _, desc in workspace:GetDescendants() do
				if desc:IsA("ParticleEmitter") and desc:GetAttribute("BaseRate") then
					desc.Rate = desc:GetAttribute("BaseRate") * multiplier
				end
			end
		end

		frameCount = 0
		elapsed = 0
	end
end)
