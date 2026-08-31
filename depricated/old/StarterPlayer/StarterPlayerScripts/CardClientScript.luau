local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local TarotEngine = ReplicatedStorage:WaitForChild("TarotEngine")
local CardController = require(TarotEngine:WaitForChild("CardController"))

local controller = CardController.new(player)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	controller:OnInputBegan(input)
end)

RunService.RenderStepped:Connect(function()
	controller:Update()
end)

controller:BindRemoteEvents()