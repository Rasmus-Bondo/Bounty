local Players = game:GetService("Players")

local LeaderstatService = {}

local function setupPlayer(player)
	if not player:FindFirstChild("leaderstats") then
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local cash = Instance.new("NumberValue")
		cash.Name = "Cash"
		cash.Value = 0
		cash.Parent = leaderstats

		local level = Instance.new("NumberValue")
		level.Name = "Level"
		level.Value = 1
		level.Parent = leaderstats
	end

	if not player:FindFirstChild("PlayerStats") then
		local stats = Instance.new("Folder")
		stats.Name = "PlayerStats"
		stats.Parent = player

		local xp = Instance.new("NumberValue")
		xp.Name = "XP"
		xp.Value = 0
		xp.Parent = stats
	end
end

function LeaderstatService.Initialize()
	Players.PlayerAdded:Connect(setupPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
end

return LeaderstatService