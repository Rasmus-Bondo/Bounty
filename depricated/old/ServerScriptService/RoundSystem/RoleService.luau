local Players = game:GetService("Players")

local RoleService = {}

function RoleService.clearRoles()
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("Role", nil)
	end
end

function RoleService.setAllBandits()
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("Role", "Bandit")
	end
end

function RoleService.eliminatePlayer(player)
	if not player then return end
	if player:GetAttribute("Role") ~= "Bandit" then return end

	player:SetAttribute("Role", "Eliminated")
	-- Respawn is handled by RoundController's Died handler (with countdown delay + invuln)
	-- Do NOT call LoadCharacter() here to avoid double-respawn
end

return RoleService