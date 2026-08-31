local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local References = require(game.ServerScriptService.Shared.References)

local SpawnService = {}

function SpawnService.clearCorpses()
	local corpseFolder = Workspace:FindFirstChild("Corpses")
	if corpseFolder then
		corpseFolder:ClearAllChildren()
	end
end

function SpawnService.getCharacterRoot(character)
	if not character then return nil end
	return character:FindFirstChild("HumanoidRootPart")
end

function SpawnService.getHumanoid(character)
	if not character then return nil end
	return character:FindFirstChildOfClass("Humanoid")
end

function SpawnService.getSpawnParts(container)
	local valid = {}

	for _, obj in ipairs(container:GetChildren()) do
		if obj:IsA("BasePart") then
			table.insert(valid, obj)
		end
	end

	return valid
end

function SpawnService.shuffleArray(array)
	for i = #array, 2, -1 do
		local j = math.random(1, i)
		array[i], array[j] = array[j], array[i]
	end
end

function SpawnService.teleportPlayerToSpawn(player, spawnPart)
	if not player.Character then return end

	local root = SpawnService.getCharacterRoot(player.Character)
	local humanoid = SpawnService.getHumanoid(player.Character)

	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	root.CFrame = spawnPart.CFrame + Vector3.new(0, 4, 0)
end

function SpawnService.sendPlayerToLobby(player)
	local spawnParts = SpawnService.getSpawnParts(References.lobbySpawnsFolder)
	if #spawnParts == 0 then
		return
	end

	local spawnPart = spawnParts[math.random(1, #spawnParts)]
	SpawnService.teleportPlayerToSpawn(player, spawnPart)
end

function SpawnService.teleportPlayersToUniqueLobbySpawns(playersList)
	local spawnParts = SpawnService.getSpawnParts(References.lobbySpawnsFolder)
	if #spawnParts == 0 then
		warn("No BaseParts found in LobbySpawns.")
		return
	end

	SpawnService.shuffleArray(spawnParts)

	for index, player in ipairs(playersList) do
		local spawnPart = spawnParts[((index - 1) % #spawnParts) + 1]
		SpawnService.teleportPlayerToSpawn(player, spawnPart)
	end
end

function SpawnService.teleportAllToLobby()
	SpawnService.teleportPlayersToUniqueLobbySpawns(Players:GetPlayers())
end
function SpawnService.sendPlayerToRoundSpawn(player)
	local ZoneService = require(script.Parent.ZoneService)
	local spawnParts = SpawnService.getSpawnParts(References.townsfolkSpawnsFolder)
	if #spawnParts == 0 then
		return
	end
	-- Filter to spawns inside the safe zone
	local safeSpawns = {}
	for _, sp in ipairs(spawnParts) do
		if ZoneService.isPositionInSafeZone(sp.Position.Z) then
			table.insert(safeSpawns, sp)
		end
	end

	-- Use safe spawns if any exist, otherwise fall back to all spawns
	local pool = #safeSpawns > 0 and safeSpawns or spawnParts
	local spawnPart = pool[math.random(1, #pool)]
	SpawnService.teleportPlayerToSpawn(player, spawnPart)
end

function SpawnService.teleportPlayersToRound(banditPlayer)
	local townSpawns = SpawnService.getSpawnParts(References.townsfolkSpawnsFolder)
	if #townSpawns == 0 then
		warn("No BaseParts found in TownsfolkSpawns.")
		return
	end

	SpawnService.shuffleArray(townSpawns)
	local townIndex = 1

	for _, player in ipairs(Players:GetPlayers()) do
		if player == banditPlayer then
			if References.banditSpawnObject:IsA("BasePart") then
				SpawnService.teleportPlayerToSpawn(player, References.banditSpawnObject)
			elseif References.banditSpawnObject:IsA("Folder") then
				local banditSpawns = SpawnService.getSpawnParts(References.banditSpawnObject)
				if #banditSpawns > 0 then
					local chosenBanditSpawn = banditSpawns[math.random(1, #banditSpawns)]
					SpawnService.teleportPlayerToSpawn(player, chosenBanditSpawn)
				end
			end
		else
			local spawnPart = townSpawns[((townIndex - 1) % #townSpawns) + 1]
			townIndex += 1
			SpawnService.teleportPlayerToSpawn(player, spawnPart)
		end
	end
end

function SpawnService.ensureAllPlayersAlive()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and SpawnService.getHumanoid(character)

		if not character or not humanoid or humanoid.Health <= 0 then
			player:LoadCharacter()
		end
	end
end

return SpawnService