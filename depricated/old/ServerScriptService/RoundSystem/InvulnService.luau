local InvulnService = {}

local Config = require(game.ServerScriptService.Shared.Config)

-- Track active invuln sessions with generation counter to prevent stale cleanup
local activeInvulns = {} -- {[player] = generation}
local healthConns = {} -- {[player] = RBXScriptConnection}
local invulnGeneration = {} -- {[player] = number}

function InvulnService.applyInvulnerability(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Bump generation so any old flicker loop knows it's stale
	local gen = (invulnGeneration[player] or 0) + 1
	invulnGeneration[player] = gen

	-- Set attribute FIRST so GunServer can check it
	player:SetAttribute("Invulnerable", true)
	activeInvulns[player] = gen

	-- Block ALL damage by reverting health changes while invulnerable
	if healthConns[player] then
		healthConns[player]:Disconnect()
	end
	local maxHP = humanoid.MaxHealth
	humanoid.Health = maxHP
	healthConns[player] = humanoid.HealthChanged:Connect(function(newHealth)
		if activeInvulns[player] and newHealth < maxHP then
			humanoid.Health = maxHP
		end
	end)

	-- Record original transparency for all visible parts (skip invisible ones like CollisionPart, HumanoidRootPart)

	-- Record original transparency for all visible parts (skip invisible ones like CollisionPart, HumanoidRootPart)
	local originalTransparency = {}
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			originalTransparency[part] = part.Transparency
		end
	end

	-- Server-side flicker loop (so all clients see it via Transparency replication)
	task.spawn(function()
		local startTime = tick()
		local duration = Config.INVULN_DURATION
		local warningStart = duration - Config.INVULN_WARNING_TIME

		while activeInvulns[player] == gen and player.Parent and character.Parent do
			local elapsed = tick() - startTime

			-- Auto-expire after duration
			if elapsed >= duration then
				break
			end

			-- Calculate flicker interval (per D-15: accelerating in final 3s)
			local interval
			if elapsed < warningStart then
				interval = Config.INVULN_FLICKER_BASE  -- 0.3s
			else
				local progress = (elapsed - warningStart) / Config.INVULN_WARNING_TIME
				interval = Config.INVULN_FLICKER_BASE - ((Config.INVULN_FLICKER_BASE - Config.INVULN_FLICKER_FAST) * math.min(progress, 1))
			end

			-- Set visible parts to 50% transparent
			for part in originalTransparency do
				if part.Parent then
					part.Transparency = 0.5
				end
			end
			task.wait(interval)

			-- Restore to original
			for part, orig in originalTransparency do
				if part.Parent then
					part.Transparency = orig
				end
			end
			task.wait(interval)
		end

		-- Clean up: restore original transparency
		if character.Parent then
			for part, orig in originalTransparency do
				if part.Parent then
					part.Transparency = orig
				end
			end
		end

		-- Only remove invuln if timer expired naturally (character still alive)
		-- If character was destroyed (respawn), new hookCharacter handles invuln state
		if character.Parent and invulnGeneration[player] == gen then
			InvulnService.removeInvulnerability(player)
		end
	end)

	print("[InvulnService] Applied invulnerability to " .. player.Name)
end

function InvulnService.removeInvulnerability(player)
	activeInvulns[player] = nil
	player:SetAttribute("Invulnerable", false)

	-- Disconnect health protection
	if healthConns[player] then
		healthConns[player]:Disconnect()
		healthConns[player] = nil
	end

	local character = player.Character
	if character then
		-- Restore visible parts to opaque (skip parts that should stay invisible)
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") and part.Transparency < 1 then
				part.Transparency = 0
			end
		end
	end
end

function InvulnService.isInvulnerable(player)
	return player:GetAttribute("Invulnerable") == true
end

-- Cleanup on disconnect
function InvulnService.Initialize()
	game.Players.PlayerRemoving:Connect(function(player)
		activeInvulns[player] = nil
		invulnGeneration[player] = nil
		if healthConns[player] then
			healthConns[player]:Disconnect()
			healthConns[player] = nil
		end
	end)
	print("[InvulnService] Initialized")
end

return InvulnService