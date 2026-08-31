local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(game.ServerScriptService.Shared.Config)

local FootstepService = {}

local footstepTemplate
local FOOTSTEP_SIZE = Vector3.new(1.5, 0.08, 1.5)
local FOOT_Y_OFFSET = 0.02

local function tweenDecalTransparency(decal, targetTransparency, duration)
	local tween = TweenService:Create(
		decal,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = targetTransparency}
	)
	tween:Play()
	return tween
end

local function createFootstep(character, footPart)
	if not footPart then return end

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayOrigin = footPart.Position + Vector3.new(0, 1, 0)
	local rayDirection = Vector3.new(0, -4, 0)

	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if not result then return end
	if result.Material ~= Enum.Material.Sand then return end

	local footstep = footstepTemplate:Clone()
	footstep.Anchored = true
	footstep.CanCollide = false
	footstep.Size = FOOTSTEP_SIZE
	footstep.Transparency = 1

	local footLook = footPart.CFrame.LookVector
	local flatLook = Vector3.new(footLook.X, 0, footLook.Z)

	if flatLook.Magnitude == 0 then
		flatLook = Vector3.new(0, 0, -1)
	end

	local pos = result.Position + Vector3.new(0, FOOT_Y_OFFSET, 0)

	footstep.CFrame = CFrame.lookAt(pos, pos + flatLook)
	footstep.Parent = workspace

	local decal = footstep:FindFirstChildOfClass("Decal")
	if decal then
		decal.Transparency = 1
	end

	local sandStepSound = footstep:FindFirstChild("SandStep")
	if sandStepSound and sandStepSound:IsA("Sound") then
		sandStepSound.PlaybackSpeed = math.random(Config.FOOTSTEP_MIN_PITCH * 100, Config.FOOTSTEP_MAX_PITCH * 100) / 100
		sandStepSound.Volume = math.random(Config.FOOTSTEP_MIN_VOLUME * 100, Config.FOOTSTEP_MAX_VOLUME * 100) / 100
		sandStepSound:Play()
	end

	task.spawn(function()
		if decal then
			tweenDecalTransparency(decal, 0, Config.FOOTSTEP_FADE_IN_TIME)
			task.wait(Config.FOOTSTEP_FADE_IN_TIME + Config.FOOTSTEP_VISIBLE_TIME)

			local fadeOutTween = tweenDecalTransparency(decal, 1, Config.FOOTSTEP_FADE_OUT_TIME)
			fadeOutTween.Completed:Wait()
		else
			task.wait(Config.FOOTSTEP_FADE_IN_TIME + Config.FOOTSTEP_VISIBLE_TIME + Config.FOOTSTEP_FADE_OUT_TIME)
		end

		if footstep and footstep.Parent then
			footstep:Destroy()
		end
	end)
end

function FootstepService.Initialize()
	footstepTemplate = ReplicatedStorage:WaitForChild("Footstep")

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			local leftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
			local rightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")

			local useLeft = true
			local stepCooldown = 0

			local connection
			connection = RunService.Heartbeat:Connect(function(dt)
				if not character.Parent then
					if connection then
						connection:Disconnect()
					end
					return
				end

				stepCooldown -= dt

				local isMoving = humanoid.MoveDirection.Magnitude > 0.1
				if not isMoving then return end
				if humanoid.FloorMaterial ~= Enum.Material.Sand then return end
				if stepCooldown > 0 then return end

				if useLeft then
					createFootstep(character, leftFoot)
				else
					createFootstep(character, rightFoot)
				end

				useLeft = not useLeft
				stepCooldown = Config.FOOTSTEP_INTERVAL
			end)
		end)
	end)
end

return FootstepService