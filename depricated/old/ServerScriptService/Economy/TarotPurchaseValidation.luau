local ReplicatedStorage = game:GetService("ReplicatedStorage")

local buyCardsEvent = ReplicatedStorage:WaitForChild("BuyCardsEvent")

local COST = 9.99
local MAX_BUYS = 50

-- track per player
local purchaseCounts = {}

buyCardsEvent.OnServerEvent:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local cash = leaderstats:FindFirstChild("Cash")
	if not cash then return end

	purchaseCounts[player] = purchaseCounts[player] or 0

	-- check stock
	if purchaseCounts[player] >= MAX_BUYS then
		return
	end

	-- check money
	if cash.Value < COST then
		return
	end

	-- deduct + increment
	cash.Value -= COST
	purchaseCounts[player] += 1

	-- your card logic here
end)

-- cleanup when player leaves
game.Players.PlayerRemoving:Connect(function(player)
	purchaseCounts[player] = nil
end)