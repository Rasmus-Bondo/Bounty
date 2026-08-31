-- RagdollService: Server-authoritative ragdoll system
-- Cross-client consistency: all ragdoll creation, constraints, and physics run server-side.
-- Corpses are server-owned Models in workspace.Corpses — physics replicates to all clients automatically.
-- No client-side ragdoll code needed; attribute sync (ShouldRagdoll, RagdollForce) is server-to-server only.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ragdoll = require(script.Parent.Ragdoll)

local RagdollService = {}

local corpseFolder
local roundActiveValue

local function hideCharacterModel(character)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Transparency = 1
			obj.CanCollide = false
		elseif obj:IsA("Decal") then
			obj.Transparency = 1
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
			obj.Enabled = false
		end
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(0, -500, 0)
	end
end

local function applyStoredShotImpulse(player, corpse)
	local x = player:GetAttribute("RagdollForceX")
	local y = player:GetAttribute("RagdollForceY")
	local z = player:GetAttribute("RagdollForceZ")

	if x == nil or y == nil or z == nil then
		return
	end

	local direction = Vector3.new(x, y, z)
	if direction.Magnitude <= 0 then
		return
	end

	direction = direction.Unit

	local impulsePart =
		corpse:FindFirstChild("UpperTorso")
		or corpse:FindFirstChild("LowerTorso")
		or corpse:FindFirstChild("Head")
		or corpse:FindFirstChild("HumanoidRootPart")

	if impulsePart and impulsePart:IsA("BasePart") then
		local push = (direction * 35 + Vector3.new(0, 8, 0)) * impulsePart.AssemblyMass
		impulsePart:ApplyImpulse(push)
	end
end

local function prepareCorpseModel(corpse)
	for _, obj in ipairs(corpse:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") then
			obj:Destroy()
		elseif obj:IsA("Tool") then
			obj:Destroy()
		elseif obj:IsA("Humanoid") then
			obj.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			obj.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			obj.NameDisplayDistance = 0
			obj.BreakJointsOnDeath = false
			obj.RequiresNeck = false
		end
	end
end

local function cloneCorpseFromCharacter(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return nil
	end

	local oldArchivable = character.Archivable
	character.Archivable = true

	local success, corpse = pcall(function()
		return character:Clone()
	end)

	character.Archivable = oldArchivable

	if not success or not corpse then
		warn("Failed to clone corpse for", character.Name)
		return nil
	end

	corpse.Name = character.Name .. "_Corpse"
	prepareCorpseModel(corpse)
	corpse.Parent = corpseFolder
	corpse:PivotTo(character:GetPivot())

	local corpseRoot = corpse:FindFirstChild("HumanoidRootPart")
	if corpseRoot then
		corpseRoot.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity
		corpseRoot.AssemblyAngularVelocity = rootPart.AssemblyAngularVelocity
	end

	return corpse
end

local function clearStoredForce(player)
	player:SetAttribute("RagdollForceX", nil)
	player:SetAttribute("RagdollForceY", nil)
	player:SetAttribute("RagdollForceZ", nil)
end

local function setupCharacter(player, character)
	player:SetAttribute("ShouldRagdoll", false)
	clearStoredForce(player)

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.BreakJointsOnDeath = false

	humanoid.Died:Connect(function()
		local shouldRagdoll = player:GetAttribute("ShouldRagdoll") == true
		player:SetAttribute("ShouldRagdoll", false)

		if shouldRagdoll then
			local corpse = cloneCorpseFromCharacter(character)

			hideCharacterModel(character)

			if corpse then
				local ragdoll = Ragdoll.new(corpse)
				ragdoll:enable()

				task.defer(function()
					applyStoredShotImpulse(player, corpse)
					clearStoredForce(player)
				end)
			else
				clearStoredForce(player)
			end
		else
			clearStoredForce(player)
		end

		-- Respawn is handled by RoundController (with countdown delay + invuln)
		-- Do NOT call LoadCharacter() here to avoid double-respawn
	end)
end

function RagdollService.Initialize()
	roundActiveValue = ReplicatedStorage:WaitForChild("RoundActive")

	corpseFolder = Workspace:FindFirstChild("Corpses")
	if not corpseFolder then
		corpseFolder = Instance.new("Folder")
		corpseFolder.Name = "Corpses"
		corpseFolder.Parent = Workspace
	end

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("ShouldRagdoll", false)
		clearStoredForce(player)

		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("ShouldRagdoll", false)
		clearStoredForce(player)

		if player.Character then
			setupCharacter(player, player.Character)
		end

		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
	end
end

return RagdollService