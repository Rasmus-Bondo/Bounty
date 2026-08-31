local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Config = require(game.ServerScriptService.Shared.Config)

local DataService = {}

-- Constants
local playerStore = DataStoreService:GetDataStore("PlayerData_v1")
local MAX_RETRIES = 3

-- Default player data structure
local DEFAULT_DATA = {
	Cash = 0,
	Level = 1,
	XP = 0,
	LifetimeKills = 0,
	LifetimeDeaths = 0,
	TotalPlaytime = 0,
}

-- Server-side caches
local playerDataCache = {} -- [userId] = data table
local sessionTracker = {} -- [userId] = { Kills, Deaths, TimeAlive, TimeDead, JoinTime, LastAliveTime, IsAlive }
local savedPlayers = {} -- [userId] = true, prevents double-save in BindToClose
local timeTrackingConnections = {} -- [userId] = { diedConnection, spawnedConnection, heartbeatConnection }

-- RemoteEvents (initialized in Initialize)
local requestStatsEvent
-- Module references (initialized in Initialize)
local State
local LobbyService
local statsResponseEvent
local levelUpEvent

-- Safe DataStore get with retry
local function safeGet(key)
	for attempt = 1, MAX_RETRIES do
		local success, result = pcall(function()
			return playerStore:GetAsync(key)
		end)
		
		if success then
			return result
		else
			warn("[DataService] GetAsync failed (attempt " .. attempt .. "/" .. MAX_RETRIES .. "): " .. tostring(result))
			if attempt < MAX_RETRIES then
				task.wait(attempt * 2) -- Exponential backoff
			end
		end
	end
	
	warn("[DataService] GetAsync failed after " .. MAX_RETRIES .. " attempts for key: " .. key)
	return nil
end

-- Safe DataStore save
local function safeSave(player)
	local userId = player.UserId
	local data = playerDataCache[userId]
	local session = sessionTracker[userId]
	
	if not data or not session then
		return false
	end
	
	-- Update TotalPlaytime before saving
	data.TotalPlaytime = data.TotalPlaytime + (os.clock() - session.JoinTime)
	session.JoinTime = os.clock() -- Reset join time for next save
	
	local success, err = pcall(function()
		local encoded = HttpService:JSONEncode(data)
		playerStore:SetAsync(tostring(userId), encoded)
	end)
	
	if not success then
		warn("[DataService] SetAsync failed for " .. player.Name .. ": " .. tostring(err))
	end
	
	return success
end

-- Time tracking setup
local function setupTimeTracking(player)
	local userId = player.UserId
	local connections = {}
	
	-- Heartbeat connection to accumulate time every frame
	-- TimeAlive only counts during active rounds for opted-in players
	connections.heartbeat = RunService.Heartbeat:Connect(function(dt)
		local session = sessionTracker[userId]
		if not session then return end
		if session.IsAlive then
			if State and State.roundActive and LobbyService and LobbyService.isOptedIn(player) then
				session.TimeAlive = session.TimeAlive + dt
			end
		else
			session.TimeDead = session.TimeDead + dt
		end
	end)
	
	-- CharacterAdded: player just spawned, mark alive
	connections.characterAdded = player.CharacterAdded:Connect(function(character)
		local session = sessionTracker[userId]
		if not session then return end
		session.IsAlive = true
		
		-- Listen for death
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			if connections.died then connections.died:Disconnect() end
			connections.died = humanoid.Died:Connect(function()
				local s = sessionTracker[userId]
				if s then
					s.IsAlive = false
				end
			end)
		end
	end)
	
	-- If character already exists (race condition), set alive
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local session = sessionTracker[userId]
			if session then session.IsAlive = true end
		end
	end
	
	timeTrackingConnections[userId] = connections
end

-- Time tracking cleanup
local function cleanupTimeTracking(player)
	local connections = timeTrackingConnections[player.UserId]
	if connections then
		if connections.heartbeat then connections.heartbeat:Disconnect() end
		if connections.characterAdded then connections.characterAdded:Disconnect() end
		if connections.died then connections.died:Disconnect() end
	end
	timeTrackingConnections[player.UserId] = nil
end

-- Load player data from DataStore
function DataService.loadPlayerData(player)
	local userId = player.UserId
	local key = tostring(userId)
	
	-- Attempt to load from DataStore
	local loadedData = safeGet(key)
	local data
	
	if loadedData then
		-- Decode if string
		if type(loadedData) == "string" then
			local success, decoded = pcall(function()
				return HttpService:JSONDecode(loadedData)
			end)
			if success then
				loadedData = decoded
			end
		end
		
		-- Merge with defaults (handle schema additions)
		data = {}
		for key, defaultValue in pairs(DEFAULT_DATA) do
			data[key] = loadedData[key] ~= nil and loadedData[key] or defaultValue
		end
	else
		-- New player - deep copy defaults
		data = {}
		for key, value in pairs(DEFAULT_DATA) do
			data[key] = value
		end
	end
	
	-- Store in cache
	playerDataCache[userId] = data
	
	-- Initialize session tracker
	sessionTracker[userId] = {
		Kills = 0,
		Deaths = 0,
		TimeAlive = 0,
		TimeDead = 0,
		JoinTime = os.clock(),
		LastAliveTime = os.clock(),
		IsAlive = false,
	}
	
	-- Set initial player attributes for scoreboard
	player:SetAttribute("SessionKills", 0)
	player:SetAttribute("SessionDeaths", 0)
	
	return data
end

-- Get player data from cache
function DataService.getPlayerData(player)
	return playerDataCache[player.UserId]
end

-- Get session data
function DataService.getSessionData(player)
	return sessionTracker[player.UserId]
end

-- Increment session stat (and lifetime if applicable)
function DataService.incrementSessionStat(player, statName, amount)
	local userId = player.UserId
	local session = sessionTracker[userId]
	local data = playerDataCache[userId]
	
	if not session or not data then return end
	
	amount = amount or 1
	session[statName] = session[statName] + amount
	
	-- Update lifetime stats
	if statName == "Kills" then
		data.LifetimeKills = data.LifetimeKills + amount
	elseif statName == "Deaths" then
		data.LifetimeDeaths = data.LifetimeDeaths + amount
	end
	
	-- Set player attributes for client-readable scoreboard data
	player:SetAttribute("Session" .. statName, session[statName])
end

-- Update player's leaderstats from cache
function DataService.updateLeaderstats(player)
	local data = playerDataCache[player.UserId]
	if not data then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	local cash = leaderstats:FindFirstChild("Cash")
	local level = leaderstats:FindFirstChild("Level")
	
	if cash then cash.Value = data.Cash end
	if level then level.Value = data.Level end

	local playerStats = player:FindFirstChild("PlayerStats")
	if playerStats then
		local xp = playerStats:FindFirstChild("XP")
		if xp then xp.Value = data.XP end
	end
end

-- Initialize DataService
function DataService.Initialize()
	print("[DataService] Initializing...")
	
	-- Get module references for time tracking gates
	State = require(game.ServerScriptService.Shared.State)
	LobbyService = require(game.ServerScriptService.RoundSystem.LobbyService)
	-- Get RemoteEvents
	local progressionEvents = game.ReplicatedStorage.Events:WaitForChild("ProgressionEvents", 10)
	if progressionEvents then
		requestStatsEvent = progressionEvents:WaitForChild("RequestStats", 5)
		statsResponseEvent = progressionEvents:WaitForChild("StatsResponse", 5)
		levelUpEvent = progressionEvents:WaitForChild("LevelUp", 5)
	end
	
	-- PlayerAdded: load data, update leaderstats, setup time tracking
	Players.PlayerAdded:Connect(function(player)
		DataService.loadPlayerData(player)
		
		-- Wait for leaderstats to be created by LeaderstatService
		local leaderstats = player:WaitForChild("leaderstats", 10)
		if leaderstats then
			DataService.updateLeaderstats(player)
		end
		
		-- Setup time tracking
		setupTimeTracking(player)
	end)
	
	-- PlayerRemoving: cleanup, save data
	Players.PlayerRemoving:Connect(function(player)
		local userId = player.UserId
		
		-- Cleanup time tracking
		cleanupTimeTracking(player)
		
		-- Save data
		safeSave(player)
		savedPlayers[userId] = true
		
		-- Cleanup caches
		playerDataCache[userId] = nil
		sessionTracker[userId] = nil
	end)
	
	-- Auto-save loop: every 5 minutes
	task.spawn(function()
		while true do
			task.wait(Config.AUTO_SAVE_INTERVAL)
			local count = 0
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(function()
					if safeSave(player) then
						count += 1
					end
				end)
			end
			task.wait(1)
			print("[DataService] Auto-save complete: " .. count .. " player(s) saved")
		end
	end)
	
	-- BindToClose: save all players on server shutdown
	game:BindToClose(function()
		if RunService:IsStudio() then
			task.wait(1)
			return
		end
		
		local startTime = os.clock()
		local saveCount = 0
		local activePlayers = Players:GetPlayers()
		
		-- Parallel save all players not already saved
		for _, player in ipairs(activePlayers) do
			if not savedPlayers[player.UserId] then
				task.spawn(function()
					if safeSave(player) then
						saveCount = saveCount + 1
					end
				end)
			end
		end
		
		-- Wait for saves to complete or timeout
		local timeout = 25
		while os.clock() - startTime < timeout do
			task.wait(0.1)
		end
		
		local elapsed = os.clock() - startTime
		print("[DataService] BindToClose: saved " .. saveCount .. " players in " .. string.format("%.2f", elapsed) .. "s")
	end)
	
	-- RequestStats handler
	if requestStatsEvent then
		requestStatsEvent.OnServerEvent:Connect(function(player)
			local data = playerDataCache[player.UserId]
			local session = sessionTracker[player.UserId]
			if data and session and statsResponseEvent then
				local now = os.clock()
				local statsPayload = {
					-- Progression (also in leaderstats but sent for completeness)
					Cash = data.Cash,
					Level = data.Level,
					XP = data.XP,
					XPToNextLevel = Config.XP_PER_LEVEL - (data.XP % Config.XP_PER_LEVEL),
					-- Session
					SessionKills = session.Kills,
					SessionDeaths = session.Deaths,
					TimeAlive = session.TimeAlive,
					TimeDead = session.TimeDead,
					-- Lifetime
					LifetimeKills = data.LifetimeKills,
					LifetimeDeaths = data.LifetimeDeaths,
					TotalPlaytime = data.TotalPlaytime + (now - session.JoinTime),
				}
				statsResponseEvent:FireClient(player, statsPayload)
			end
		end)
	end
	
	print("[DataService] Initialized")
end

return DataService