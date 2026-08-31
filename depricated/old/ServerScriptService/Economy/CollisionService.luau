local ReplicatedStorage = game:GetService("ReplicatedStorage")

local buyCardsEvent = ReplicatedStorage:WaitForChild("BuyCardsEvent")

buyCardsEvent.OnServerEvent:Connect(function(player)
	-- put your money/check logic here if needed

	-- only tell this one player to show cards
	buyCardsEvent:FireClient(player)
end)