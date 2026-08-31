local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local References = {}

References.lobbySpawnsFolder = Workspace:WaitForChild("LobbySpawns")
References.townsfolkSpawnsFolder = Workspace:WaitForChild("SpawnPoints")
References.banditSpawnObject = Workspace:WaitForChild("BanditSpawn")
References.banditGunTemplate = ServerStorage:WaitForChild("BanditGun")
References.eliminatePlayerEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("EliminatePlayer")

local roundStatus = ReplicatedStorage:FindFirstChild("RoundStatus")
if not roundStatus then
	roundStatus = Instance.new("StringValue")
	roundStatus.Name = "RoundStatus"
	roundStatus.Parent = ReplicatedStorage
end
References.roundStatus = roundStatus

local roundActiveValue = ReplicatedStorage:FindFirstChild("RoundActive")
if not roundActiveValue then
	roundActiveValue = Instance.new("BoolValue")
	roundActiveValue.Name = "RoundActive"
	roundActiveValue.Parent = ReplicatedStorage
end
References.roundActiveValue = roundActiveValue

local roundTime = ReplicatedStorage:FindFirstChild("RoundTime")
if not roundTime then
	roundTime = Instance.new("IntValue")
	roundTime.Name = "RoundTime"
	roundTime.Parent = ReplicatedStorage
end
References.roundTime = roundTime

return References