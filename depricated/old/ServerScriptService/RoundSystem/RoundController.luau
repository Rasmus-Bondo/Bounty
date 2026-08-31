local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSS = game.ServerScriptService

-- Shared
local Config = require(SSS.Shared.Config)
local State = require(SSS.Shared.State)
local References = require(SSS.Shared.References)

-- Round services (siblings)
local SpawnService = require(script.Parent.SpawnService)
local RoleService = require(script.Parent.RoleService)
local BanditService = require(script.Parent.BanditService)
local LobbyService = require(script.Parent.LobbyService)
local InvulnService = require(script.Parent.InvulnService)
local DestructibleService = require(script.Parent.DestructibleService)
local ZoneService = require(script.Parent.ZoneService)

-- Cross-folder
local ProgressionService = require(SSS.PlayerServices.ProgressionService)

local Events = game.ReplicatedStorage:WaitForChild("Events")
local PostGameStats = Events:WaitForChild("PostGameStats")
local RespawnCountdown = Events:WaitForChild("RespawnCountdown")

local RoundController = {}

function RoundController.resetRound()
	State:reset()
	References.roundActiveValue.Value = false

	RoleService.clearRoles()
	BanditService.removeBanditGunFromEveryone()
	SpawnService.clearCorpses()

	-- Reset map feature systems before respawn
	DestructibleService.resetDestructibles()
	ZoneService.resetZone()

	-- Reset death tracking (per RND-08)
	State.playerDeaths = {}

	-- Only reload opted-in players (prevents affecting lobby players who left mid-round)
	for _, player in ipairs(Players:GetPlayers()) do
		if LobbyService.isOptedIn(player) then
			player:LoadCharacter()
		end
	end

	task.wait(1.5)
	
	-- Only teleport opted-in players to lobby (prevents affecting players who left mid-round)
	for _, player in ipairs(Players:GetPlayers()) do
		if LobbyService.isOptedIn(player) then
			SpawnService.sendPlayerToLobby(player)
		end
	end
end

function RoundController.cancelRound()
	State.roundCancelled = true
	State.roundActive = false
	State.currentPhase = "Ended"
	References.roundActiveValue.Value = false
	References.roundStatus.Value = "Round cancelled!"
	References.roundTime.Value = 0
end

function RoundController.hookCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.MaxHealth = Config.PLAYER_MAX_HEALTH
	humanoid.Health = Config.PLAYER_MAX_HEALTH
	-- Set Role and invulnerability immediately so player is protected before deferred teleport
	if State.roundActive and not State.roundCancelled and LobbyService.isOptedIn(player) then
		player:SetAttribute("Role", "Bandit")
		player:SetAttribute("Invulnerable", true)
		humanoid.Health = humanoid.MaxHealth
	end

	humanoid.Died:Connect(function()
		-- Ignore stale characters (replaced by LoadCharacter)
		if player.Character ~= character then return end
		if not State.roundActive or State.roundCancelled then
			return
		end

		-- Track death in State.playerDeaths and progression stats
		State.playerDeaths[player] = (State.playerDeaths[player] or 0) + 1
		ProgressionService.awardDeath(player)

		-- Auto-respawn with delay (per D-07, D-08)
		if State.roundActive and LobbyService.isOptedIn(player) then
			-- Fire respawn countdown to client
			RespawnCountdown:FireClient(player, Config.RESPAWN_DELAY)

			task.delay(Config.RESPAWN_DELAY, function()
				-- Verify still valid before respawning
				if player.Parent and State.roundActive and LobbyService.isOptedIn(player) then
					player:LoadCharacter()
					-- CharacterAdded fires, hookCharacter handles spawn + invuln
				end
			end)
		end
	end)

	task.defer(function()
		-- Gate mid-round respawn with opt-in check (per D-05, RND-02)
		if State.roundActive and not State.roundCancelled and LobbyService.isOptedIn(player) then
			-- Wait for character to fully load before arming
			if not character:IsDescendantOf(workspace) then
				character.AncestryChanged:Wait()
			end
			local hum = character:WaitForChild("Humanoid", 5)
			if not hum or hum.Health <= 0 then return end
			player:WaitForChild("Backpack", 5)
			task.wait(0.1)

			-- During active round: spawn as armed Bandit at a round spawn (Role already set above)
			SpawnService.sendPlayerToRoundSpawn(player)
			BanditService.giveBanditGun(player)
			
			-- Apply invulnerability after spawn (per D-06)
			InvulnService.applyInvulnerability(player)
		else
			-- Not in round or not opted in: send to lobby in third person
			player:SetAttribute("Role", nil)  -- Clear any role (including "Eliminated")
			SpawnService.sendPlayerToLobby(player)
		end
	end)
end

function RoundController.connectPlayers()
	local connectedPlayers = {}

	local function setupPlayer(player)
		if connectedPlayers[player] then return end
		connectedPlayers[player] = true

		player.CharacterAdded:Connect(function(character)
			RoundController.hookCharacter(player, character)
		end)

		if player.Character then
			RoundController.hookCharacter(player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(setupPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
end

function RoundController.connectEvents()
	References.eliminatePlayerEvent.Event:Connect(function(eliminatedPlayer, killerPlayer)
		RoleService.eliminatePlayer(eliminatedPlayer)

		if killerPlayer and State.roundActive then
			State.playerKills[killerPlayer] = (State.playerKills[killerPlayer] or 0) + 1
		end
	end)
end

function RoundController.getWinner()
	local bestPlayer = nil
	local bestKills = 0

	for player, kills in pairs(State.playerKills) do
		if kills > bestKills then
			bestKills = kills
			bestPlayer = player
		end
	end

	return bestPlayer, bestKills
end

function RoundController.run()
	while true do
		-- Wait for enough opted-in players (per RND-01, RND-05)
		while LobbyService.getOptedInCount() < Config.MIN_PLAYERS do
			State:reset()
			References.roundActiveValue.Value = false
			RoleService.clearRoles()

		References.roundStatus.Value = "Waiting for players..."
		References.roundTime.Value = 0
		workspace:SetAttribute("RoundTimeLeft", 0)

			task.wait(1)
		end

		State.currentPhase = "Intermission"

		for i = Config.INTERMISSION_TIME, 1, -1 do
			State.roundActive = false
			State.roundStarting = false
			State.roundCancelled = false
			References.roundActiveValue.Value = false
			RoleService.clearRoles()

		References.roundStatus.Value = "Intermission"
		References.roundTime.Value = i
		workspace:SetAttribute("RoundTimeLeft", 0)

			task.wait(1)
		end

		-- Check again after intermission
		if LobbyService.getOptedInCount() < Config.MIN_PLAYERS then
			task.wait(1)
			continue
		end

		State.roundStarting = true
		State.roundActive = false
		State.roundCancelled = false
		State.playerKills = {}
		State.playerDeaths = {}
		RoleService.clearRoles()

		SpawnService.ensureAllPlayersAlive()
		task.wait(1)

		-- Give guns and spawn only opted-in players
		local optedPlayers = LobbyService.getOptedInPlayers()
		for _, player in ipairs(optedPlayers) do
			player:SetAttribute("Role", "Bandit")
			SpawnService.sendPlayerToRoundSpawn(player)
			BanditService.giveBanditGun(player)
			InvulnService.applyInvulnerability(player)
		end

		task.wait(0.5)

		State.roundStarting = false
		State.roundActive = true
		References.roundActiveValue.Value = true
		State.currentPhase = "Fight"

		local s = ReplicatedStorage.SFX.RoundStart:Clone()
		s.Parent = workspace
		s:Play()
		Debris:AddItem(s, s.TimeLength)

		-- Start zone shrinking system
		ZoneService.startZone(tick())
		for i = Config.ROUND_TIME, 1, -1 do
			if State.roundCancelled then
				break
			end
		References.roundStatus.Value = "Fight!"
		References.roundTime.Value = i
		workspace:SetAttribute("RoundTimeLeft", i)

			task.wait(1)
		end

		if State.roundCancelled then
			task.wait(3)
			RoundController.resetRound()
			task.wait(2)
			continue
		end

		State.currentPhase = "Ended"
		State.roundActive = false
		References.roundActiveValue.Value = false
		ZoneService.resetZone()

		-- Brief wait for final events to propagate
		task.wait(0.1)

		-- Award round completion to opted-in players
		for _, player in ipairs(LobbyService.getOptedInPlayers()) do
			ProgressionService.awardRoundCompletion(player)
		end

		-- Collect and broadcast post-game stats (per D-09, D-12, RND-04)
		local stats = {}
		for _, player in ipairs(game.Players:GetPlayers()) do
			if LobbyService.isOptedIn(player) then
				table.insert(stats, {
					name = player.DisplayName,
					kills = State.playerKills[player] or 0,
					deaths = State.playerDeaths[player] or 0,
				})
			end
		end
		-- Sort by kills descending, fewer deaths as tiebreaker
		table.sort(stats, function(a, b)
			if a.kills == b.kills then
				return a.deaths < b.deaths
			end
			return a.kills > b.kills
		end)

		-- Set winner text before firing stats (so client can read it)
		local winner, kills = RoundController.getWinner()
		if winner and kills > 0 then
			References.roundStatus.Value = winner.Name .. " wins with " .. kills .. " kills!"
		else
			References.roundStatus.Value = "Draw! Nobody got a kill!"
		end

		-- Send stats only to opted-in players
		for _, p in ipairs(LobbyService.getOptedInPlayers()) do
			PostGameStats:FireClient(p, stats)
		end

		References.roundTime.Value = 0

		task.wait(5)

		RoundController.resetRound()
		task.wait(2)
	end
end

return RoundController