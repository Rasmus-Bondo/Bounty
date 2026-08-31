local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local CollisionService = {}

local function onDescendantAdded(descendant)
	if descendant:IsA("BasePart") then
		descendant.CollisionGroup = "Characters"
	end
end

local function onCharacterAdded(character)
	for _, descendant in pairs(character:GetDescendants()) do
		onDescendantAdded(descendant)
	end
	character.DescendantAdded:Connect(onDescendantAdded)
end

function CollisionService.Initialize()
	PhysicsService:RegisterCollisionGroup("Characters")
	PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(onCharacterAdded)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			onCharacterAdded(player.Character)
		end

		player.CharacterAdded:Connect(onCharacterAdded)
	end
end

return CollisionService