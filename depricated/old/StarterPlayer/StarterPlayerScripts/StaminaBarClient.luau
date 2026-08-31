local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local healthGui = playerGui:WaitForChild("HealthDisplayGui")
local canvas = healthGui:WaitForChild("Canvas")
local staminaBar = canvas:WaitForChild("StaminaBar")
local fill = staminaBar:WaitForChild("Fill")

local displayedStamina = 100
local MAX_STAMINA = 100
local LERP_SPEED = 10 -- interpolation speed factor

RunService.RenderStepped:Connect(function(dt)
	local targetStamina = player:GetAttribute("Stamina") or MAX_STAMINA
	-- Smooth interpolation to avoid jerky updates from network replication
	displayedStamina = displayedStamina + (targetStamina - displayedStamina) * math.min(1, dt * LERP_SPEED)
	fill.Size = UDim2.new(math.clamp(displayedStamina / MAX_STAMINA, 0, 1), 0, 1, 0)
end)