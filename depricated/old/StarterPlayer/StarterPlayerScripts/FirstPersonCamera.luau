local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

local roundActiveValue = ReplicatedStorage:WaitForChild("RoundActive")

local Character, Humanoid, HumanoidPart, Head, Animator
local UpperTorso, RightShoulder
local EquippedTool
local OriginalToolGrip
local CurrentArmTransform = CFrame.new()
local ToolAnimationIds = {}

local cameraEnabled = false

local CamPos, TargetCamPos = Camera.CFrame.Position, Camera.CFrame.Position
local AngleX, TargetAngleX = 0, 0
local AngleY, TargetAngleY = 0, 0

local CanToggleMouse = {allowed = true; activationkey = Enum.KeyCode.C}
local CanViewBody = true
local Sensitivity = 0.1
local Smoothness = 0.05
local FieldOfView = 80
local PlayerHeadOffset = CFrame.new(0, 0.7, 0)

local Running = true
local FreeMouse = false
local DefaultFOV = FieldOfView
local EasingTime = 0.1

local ArmPitchStrength = 1.0
local ArmLerpSpeed = 0.25
local ToolPitchStrength = 1.0

-- R15 right shoulder tuning
local BaseLift = math.rad(-95)      -- lifts arm away from torso
local BaseForward = math.rad(-10)   -- pushes arm slightly forward
local BaseYaw = math.rad(8)         -- slight outward turn

local function Lerp(a, b, t)
	return a * (1 - t) + (b * t)
end

local function isAlive()
	return Humanoid and Humanoid.Health > 0
end

local function isInGameMode()
	local role = Player:GetAttribute("Role")
	return roundActiveValue.Value == true and (role == "Bandit" or role == "Townsfolk")
end

local function shouldEnableCamera()
	return Character and Humanoid and HumanoidPart and Head and isAlive() and isInGameMode()
end

local function getEquippedTool()
	if not Character then
		return nil
	end

	for _, child in ipairs(Character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end

	return nil
end

local function cacheToolGrip(tool)
	if tool ~= EquippedTool then
		EquippedTool = tool
		OriginalToolGrip = tool and tool.Grip or nil
	end
end

local function resetToolGrip()
	if EquippedTool and EquippedTool.Parent and OriginalToolGrip then
		EquippedTool.Grip = OriginalToolGrip
	end
end

local function cacheToolAnimationIds()
	ToolAnimationIds = {}

	local animate = Character and Character:FindFirstChild("Animate")
	if not animate then
		return
	end

	for _, folderName in ipairs({"toolnone", "toolslash", "toollunge"}) do
		local folder = animate:FindFirstChild(folderName)
		if folder then
			for _, obj in ipairs(folder:GetDescendants()) do
				if obj:IsA("Animation") and obj.AnimationId ~= "" then
					ToolAnimationIds[obj.AnimationId] = true
				end
			end
		end
	end
end

local function stopToolHoldAnimations()
	if not Animator then
		return
	end

	for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
		local anim = track.Animation
		if anim and ToolAnimationIds[anim.AnimationId] then
			track:Stop(0.05)
		end
	end
end

local function resetRightArm()
	if RightShoulder then
		RightShoulder.Transform = CFrame.new()
	end
	CurrentArmTransform = CFrame.new()
end

local function setBodyVisibleForNormalCamera()
	if not Character then
		return
	end

	for _, part in ipairs(Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 0
		elseif part:IsA("Decal") then
			part.LocalTransparencyModifier = 0
		end
	end

	resetRightArm()
	resetToolGrip()
end

local function updateCharacterVisibility()
	if not Character then
		return
	end

	for _, part in ipairs(Character:GetDescendants()) do
		if CanViewBody then
			if part:IsA("BasePart") then
				if part.Name == "Head" then
					part.LocalTransparencyModifier = 1
					part.CanCollide = false
				else
					part.LocalTransparencyModifier = 0
				end
			elseif part:IsA("Decal") and part.Parent == Head then
				part.LocalTransparencyModifier = 1
			end
		else
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 1
				part.CanCollide = false
			elseif part:IsA("Decal") then
				part.LocalTransparencyModifier = 1
			end
		end

		if part:IsA("Accessory") or part:IsA("Hat") then
			local handle = part:FindFirstChild("Handle")
			if handle then
				handle.LocalTransparencyModifier = 1
				handle.CanCollide = false
			end
		end
	end
end

local function disableFirstPersonCamera()
	cameraEnabled = false
	Camera.CameraType = Enum.CameraType.Custom
	-- Re-attach to current character's humanoid for default camera
	if Character then
		local hum = Character:FindFirstChildOfClass("Humanoid")
		if hum then
			Camera.CameraSubject = hum
		end
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	Player.CameraMode = Enum.CameraMode.Classic  -- Enable classic camera (zoomable)
	Player.CameraMaxZoomDistance = 128  -- Ensure zoom is enabled
	Player.CameraMinZoomDistance = 0.5
	setBodyVisibleForNormalCamera()
	FieldOfView = DefaultFOV
end

local function enableFirstPersonCamera()
	if not Character or not Humanoid or not HumanoidPart or not Head then
		return
	end

	cameraEnabled = true
	Camera.CameraType = Enum.CameraType.Scriptable
	FreeMouse = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	CamPos = Head.Position
	TargetCamPos = Head.Position
end

local function refreshCameraState()
	if shouldEnableCamera() then
		enableFirstPersonCamera()
	else
		disableFirstPersonCamera()
	end
end

UserInputService.InputChanged:Connect(function(InputObject)
	if not cameraEnabled then
		return
	end

	if InputObject.UserInputType == Enum.UserInputType.MouseMovement or InputObject.UserInputType == Enum.UserInputType.Touch then
		local Delta = Vector2.new(
			InputObject.Delta.x / Sensitivity,
			InputObject.Delta.y / Sensitivity
		) * Smoothness

		local X = TargetAngleX - Delta.y
		TargetAngleX = math.clamp(X, -80, 80)
		TargetAngleY = (TargetAngleY - Delta.x) % 360
	end
end)

UserInputService.InputBegan:Connect(function(InputObject)
	if InputObject.UserInputType == Enum.UserInputType.Keyboard then
		if InputObject.KeyCode == CanToggleMouse.activationkey and CanToggleMouse.allowed and cameraEnabled then
			FreeMouse = not FreeMouse
		end
	end
end)

local function setupCharacter(Char)
	if not Char or not Char:IsDescendantOf(game) then return end
	Character = Char
	Humanoid = Character:WaitForChild("Humanoid", 10)
	HumanoidPart = Character:WaitForChild("HumanoidRootPart", 10)
	Head = Character:WaitForChild("Head", 10)
	if not Humanoid or not HumanoidPart or not Head then return end
	Animator = Humanoid:FindFirstChildOfClass("Animator") or Humanoid:WaitForChild("Animator", 10)

	UpperTorso = Character:FindFirstChild("UpperTorso")
	RightShoulder = nil
	EquippedTool = nil
	OriginalToolGrip = nil
	CurrentArmTransform = CFrame.new()

	if UpperTorso then
		RightShoulder = UpperTorso:FindFirstChild("RightShoulder")
	end

	cacheToolAnimationIds()

	Character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			cacheToolGrip(child)
		end
	end)

	Character.ChildRemoved:Connect(function(child)
		if child == EquippedTool then
			resetToolGrip()
			EquippedTool = nil
			OriginalToolGrip = nil
		end
	end)

	local existingTool = getEquippedTool()
	if existingTool then
		cacheToolGrip(existingTool)
	end

	Humanoid.Died:Connect(function()
		refreshCameraState()
	end)

	refreshCameraState()
end

if Player.Character then
	setupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(setupCharacter)
Player:GetAttributeChangedSignal("Role"):Connect(refreshCameraState)
roundActiveValue:GetPropertyChangedSignal("Value"):Connect(refreshCameraState)

RunService.RenderStepped:Connect(function()
	if not cameraEnabled then
		return
	end

	if not Character or not Humanoid or not HumanoidPart or not Head then
		disableFirstPersonCamera()
		return
	end

	if not shouldEnableCamera() then
		disableFirstPersonCamera()
		return
	end

	updateCharacterVisibility()

	CamPos = CamPos + (TargetCamPos - CamPos) * 0.28
	AngleX = AngleX + (TargetAngleX - AngleX) * 0.35

	local Dist = TargetAngleY - AngleY
	if math.abs(Dist) > 180 then
		Dist = Dist - math.sign(Dist) * 360
	end
	AngleY = (AngleY + Dist * 0.35) % 360

	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.CFrame = CFrame.new(Head.Position)
		* CFrame.Angles(0, math.rad(AngleY), 0)
		* CFrame.Angles(math.rad(AngleX), 0, 0)
		* PlayerHeadOffset

	HumanoidPart.CFrame = CFrame.new(HumanoidPart.Position) * CFrame.Angles(0, math.rad(AngleY), 0)

	stopToolHoldAnimations()

	if RightShoulder then
		local pitch = math.rad(AngleX) * ArmPitchStrength

		-- For R15 right shoulder, roll usually lifts/aims the arm more reliably than X pitch.
		local basePose =
			CFrame.Angles(BaseForward, BaseYaw, 0)
			* CFrame.Angles(0, 0, BaseLift)

		local aimPose = CFrame.Angles(0, 0, -pitch)

		local targetTransform = basePose * aimPose
		CurrentArmTransform = CurrentArmTransform:Lerp(targetTransform, ArmLerpSpeed)
		RightShoulder.Transform = CurrentArmTransform
	end

	local tool = getEquippedTool()
	if tool then
		if tool ~= EquippedTool then
			cacheToolGrip(tool)
		end

		if OriginalToolGrip then
			local pitch = math.rad(AngleX) * ToolPitchStrength
			tool.Grip = OriginalToolGrip * CFrame.Angles(-pitch, 0, 0)
		end
	else
		if EquippedTool then
			resetToolGrip()
			EquippedTool = nil
			OriginalToolGrip = nil
		end
	end

	if (Camera.Focus.Position - Camera.CFrame.Position).Magnitude < 1 then
		Running = false
	else
		Running = true
		UserInputService.MouseBehavior = FreeMouse and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
	end

	if not CanToggleMouse.allowed then
		FreeMouse = false
	end

	FieldOfView = Lerp(FieldOfView, DefaultFOV, EasingTime)
	Camera.FieldOfView = FieldOfView
end)