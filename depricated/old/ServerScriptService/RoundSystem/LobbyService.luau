local LobbyService = {}

local Players = game:GetService("Players")
local State = require(game.ServerScriptService.Shared.State)
local Config = require(game.ServerScriptService.Shared.Config)
local SpawnService = require(script.Parent.SpawnService)
local BanditService = require(script.Parent.BanditService)
local InvulnService = require(script.Parent.InvulnService)

function LobbyService.Initialize()
	-- Hook PlayerRemoving to clean up opt-in state (Pitfall 5)
	Players.PlayerRemoving:Connect(function(player)
		LobbyService.optOut(player)
	end)

	-- Listen for RoundEvent from clients
	local Events = game.ReplicatedStorage:WaitForChild("Events")
	local RoundEvent = Events:WaitForChild("RoundEvent")
	RoundEvent.OnServerEvent:Connect(function(player, action)
		if action == "JoinRound" then
			LobbyService.optIn(player)
		elseif action == "LeaveRound" then
			LobbyService.optOut(player)
		end
	end)

	print("[LobbyService] Initialized")
end

function LobbyService.optIn(player)
	player:SetAttribute("OptedIn", true)
	State.optedInPlayers[player] = true
	print("[LobbyService] " .. player.Name .. " opted in")

	-- If round is active, immediately spawn into round (per D-05)
	if State.roundActive then
		player:SetAttribute("Role", "Bandit")  -- Set Role for FirstPersonCamera
		SpawnService.sendPlayerToRoundSpawn(player)
		BanditService.giveBanditGun(player)
		InvulnService.applyInvulnerability(player)  -- Apply invulnerability for mid-match join
	end
end
function LobbyService.optOut(player)
	player:SetAttribute("OptedIn", false)
	State.optedInPlayers[player] = nil
	print("[LobbyService] " .. player.Name .. " opted out")
	
	-- If leaving during active round:
	if State.roundActive and player.Character then
		-- 1. Clear Role immediately (camera will disable)
		player:SetAttribute("Role", nil)
		
		-- 2. Remove gun explicitly
		BanditService.removeBanditGunFromPlayer(player)
		
		-- 3. Wait for camera to fully disable on client before reloading
		task.wait(0.2)
		
		-- 4. Reload character (hookCharacter will send to lobby)
		if player and player.Parent then
			player:LoadCharacter()
		end
	end
end
function LobbyService.isOptedIn(player)
	return player:GetAttribute("OptedIn") == true
end

function LobbyService.getOptedInPlayers()
	local opted = {}
	for player, _ in pairs(State.optedInPlayers) do
		if player.Parent then -- still connected
			table.insert(opted, player)
		end
	end
	return opted
end

function LobbyService.getOptedInCount()
	local count = 0
	for player, _ in pairs(State.optedInPlayers) do
		if player.Parent then
			count = count + 1
		end
	end
	return count
end

function LobbyService.resetAllOptIns()
	-- Do NOT reset opt-ins between rounds (per Claude's discretion: persist across rounds for fluid experience)
	-- Only called if explicitly needed
	for player, _ in pairs(State.optedInPlayers) do
		player:SetAttribute("OptedIn", false)
	end
	State.optedInPlayers = {}
end

return LobbyService