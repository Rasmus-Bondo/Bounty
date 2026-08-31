local Players = game:GetService("Players")

local References = require(game.ServerScriptService.Shared.References)

local BanditService = {}

function BanditService.removeBanditGunFromPlayer(player)
	if not player then return end

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		local tool = backpack:FindFirstChild("BanditGun")
		if tool then
			tool:Destroy()
		end
	end

	if player.Character then
		local equippedTool = player.Character:FindFirstChild("BanditGun")
		if equippedTool then
			equippedTool:Destroy()
		end
	end
end

function BanditService.removeBanditGunFromEveryone()
	for _, player in ipairs(Players:GetPlayers()) do
		BanditService.removeBanditGunFromPlayer(player)
	end
end

function BanditService.giveBanditGun(player)
	if not player then return end
	BanditService.removeBanditGunFromPlayer(player)

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	local newGun = References.banditGunTemplate:Clone()
	newGun.Parent = backpack

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:EquipTool(newGun)
		end
	end
end

function BanditService.giveGunToAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		BanditService.giveBanditGun(player)
	end
end

return BanditService