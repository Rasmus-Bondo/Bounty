local ReplicatedStorage = game:GetService("ReplicatedStorage")

local revolverFolder = ReplicatedStorage:WaitForChild("Revolver")
local remotesFolder = revolverFolder:WaitForChild("Remotes")
local replicateShotRemote = remotesFolder:WaitForChild("ReplicateShot")

local laserBeamEffect = require(revolverFolder:WaitForChild("laserBeamEffect"))

local function onReplicateShot(tool, origin, hitPosition)
	if not tool or not tool:IsDescendantOf(game) then
		return
	end

	local muzzlePart = tool:FindFirstChild("MuzzlePart")
	local startPosition = origin

	if muzzlePart then
		local muzzleAttachment = muzzlePart:FindFirstChild("MuzzleAttachment")
		if muzzleAttachment then
			startPosition = muzzleAttachment.WorldPosition

			local flashEmitter = muzzlePart:FindFirstChild("FlashEmitter")
			if flashEmitter and flashEmitter:IsA("ParticleEmitter") then
				flashEmitter:Emit(1)
			end
		end
	end

	laserBeamEffect(startPosition, hitPosition)
end

replicateShotRemote.OnClientEvent:Connect(onReplicateShot)