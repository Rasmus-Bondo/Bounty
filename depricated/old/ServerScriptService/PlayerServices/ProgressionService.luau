local Players = game:GetService("Players")

local Config = require(game.ServerScriptService.Shared.Config)

local ProgressionService = {}

-- Services (set in Initialize)
local DataService
local State
local LobbyService
local requestStats
local statsResponse
local timeRewardTracker = {} -- [userId] = lastRewardedAliveTime

-- Internal helper: Check and handle level-up
local function checkLevelUp(player, data)
	local newLevel = math.floor(data.XP / Config.XP_PER_LEVEL) + 1
	
	if newLevel > data.Level then
		data.Level = newLevel
		if levelUpEvent then
			levelUpEvent:FireClient(player, newLevel)
		end
		print("[Progression] " .. player.Name .. " leveled up to Level " .. newLevel .. "!")
	end
	
	return newLevel
end

-- Award kill: XP + Cash + check level-up
function ProgressionService.awardKill(player)
	local data = DataService.getPlayerData(player)
	if not data then return end
	
	-- Add rewards
	data.XP = data.XP + Config.XP_PER_KILL
	data.Cash = data.Cash + Config.CASH_PER_KILL
	
	-- Increment session + lifetime kill count
	DataService.incrementSessionStat(player, "Kills", 1)
	
	-- Check level-up
	checkLevelUp(player, data)
	
	-- Update leaderstats
	DataService.updateLeaderstats(player)
	
	print("[Progression] " .. player.Name .. " earned " .. Config.XP_PER_KILL .. " XP + $" .. Config.CASH_PER_KILL .. " for kill")
end

-- Award death: increment session death counter
function ProgressionService.awardDeath(player)
	DataService.incrementSessionStat(player, "Deaths", 1)
end

-- Award round completion: XP + Cash + check level-up
function ProgressionService.awardRoundCompletion(player)
	local data = DataService.getPlayerData(player)
	if not data then return end
	
	-- Add rewards
	data.XP = data.XP + Config.ROUND_BONUS_XP
	data.Cash = data.Cash + Config.ROUND_BONUS_CASH
	
	-- Check level-up
	checkLevelUp(player, data)
	
	-- Update leaderstats
	DataService.updateLeaderstats(player)
	
	print("[Progression] " .. player.Name .. " earned " .. Config.ROUND_BONUS_XP .. " XP + $" .. Config.ROUND_BONUS_CASH .. " for round completion")
end

-- Initialize: Set up time-based reward loop
function ProgressionService.Initialize()
	print("[ProgressionService] Initializing...")
	
	-- Get service references
	DataService = require(script.Parent.DataService)
	State = require(game.ServerScriptService.Shared.State)
	LobbyService = require(game.ServerScriptService.RoundSystem.LobbyService)
	
	-- Get RemoteEvents from ProgressionEvents folder
	local progressionEvents = game.ReplicatedStorage.Events:WaitForChild("ProgressionEvents", 10)
	if progressionEvents then
		levelUpEvent = progressionEvents:WaitForChild("LevelUp", 5)
		requestStats = progressionEvents:WaitForChild("RequestStats", 5)
		statsResponse = progressionEvents:WaitForChild("StatsResponse", 5)
	end
	
	-- Handle stats requests from clients
	if requestStats and statsResponse then
		requestStats.OnServerEvent:Connect(function(player)
			local data = DataService.getPlayerData(player)
			local sessionData = DataService.getSessionData(player)
			if data and sessionData then
				-- Merge persistent data with session data
				local completeData = {}
				for k, v in pairs(data) do
					completeData[k] = v
				end
				completeData.SessionKills = sessionData.Kills
				completeData.SessionDeaths = sessionData.Deaths
				completeData.TimeAlive = sessionData.TimeAlive
				completeData.TimeDead = sessionData.TimeDead
				
				statsResponse:FireClient(player, completeData)
			end
		end)
	end
	task.spawn(function()
		while true do
			task.wait(10)
			if not State.roundActive then continue end
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local humanoid = character and character:FindFirstChild("Humanoid")
				if LobbyService.isOptedIn(player) and humanoid and humanoid.Health > 0 then
					local sessionData = DataService.getSessionData(player)
					if sessionData then
						local userId = player.UserId
						if not timeRewardTracker[userId] then
							timeRewardTracker[userId] = 0
						end
						local aliveTime = sessionData.TimeAlive
					if aliveTime - timeRewardTracker[userId] >= Config.TIME_REWARD_INTERVAL then
							timeRewardTracker[userId] = aliveTime
							local data = DataService.getPlayerData(player)
							if data then
								data.XP = data.XP + Config.TIME_REWARD_XP
								data.Cash = data.Cash + Config.TIME_REWARD_CASH
								checkLevelUp(player, data)
								DataService.updateLeaderstats(player)
								print("[Progression] " .. player.Name .. " earned " .. Config.TIME_REWARD_XP .. " XP + $" .. Config.TIME_REWARD_CASH .. " for time reward")
							end
						end
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		timeRewardTracker[player.UserId] = nil
	end)
	
	print("[ProgressionService] Initialized")
end

return ProgressionService