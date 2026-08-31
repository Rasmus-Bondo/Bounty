local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isMobile = UserInputService.TouchEnabled

-- Get RemoteEvents
local events = game.ReplicatedStorage:WaitForChild("Events")
local movementEvents = events:WaitForChild("MovementEvents")
local sprintEvent = movementEvents:WaitForChild("SprintEvent")
local crouchEvent = movementEvents:WaitForChild("CrouchEvent")
local gunRemote = events:WaitForChild("GunRemote")

-- State
local isCrouching = false

-- === KEYBOARD BINDINGS (all platforms) ===

-- Sprint: hold LeftShift
local function onSprintAction(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		sprintEvent:FireServer(true)
	elseif inputState == Enum.UserInputState.End then
		sprintEvent:FireServer(false)
	end
	return Enum.ContextActionResult.Sink
end

-- Crouch: toggle LeftControl
local function onCrouchAction(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		isCrouching = not isCrouching
		crouchEvent:FireServer(isCrouching)
	end
	return Enum.ContextActionResult.Sink
end

-- Bind keyboard actions (createTouchButton = false, we use custom GUI)
ContextActionService:BindAction("Sprint", onSprintAction, false, Enum.KeyCode.LeftShift)
ContextActionService:BindAction("Crouch", onCrouchAction, false, Enum.KeyCode.LeftControl)

-- === MOBILE TOUCH BUTTONS ===

if isMobile then
	local mobileGui = playerGui:WaitForChild("MobileControlsGui")
	mobileGui.Enabled = true

	local actionFrame = mobileGui:WaitForChild("ActionFrame")
	local shootBtn = actionFrame:WaitForChild("ShootButton")
	local reloadBtn = actionFrame:WaitForChild("ReloadButton")
	local sprintBtn = actionFrame:WaitForChild("SprintButton")
	local crouchBtn = actionFrame:WaitForChild("CrouchButton")

	-- Helper function to check if input is touch or mouse (for Device Emulator testing)
	local function isTouchOrMouse(inputType)
		return inputType == Enum.UserInputType.Touch or inputType == Enum.UserInputType.MouseButton1
	end

	-- Shoot button: fires the gun via Tool:Activate()
	shootBtn.MouseButton1Down:Connect(function()
		local character = player.Character
		if character then
			local tool = character:FindFirstChildOfClass("Tool")
			if tool then
				tool:Activate()
			end
		end
	end)

	-- Reload button: fires reload via GunRemote
	reloadBtn.MouseButton1Down:Connect(function()
		gunRemote:FireServer("Reload")
	end)

	-- Sprint button: hold to sprint
	sprintBtn.MouseButton1Down:Connect(function()
		sprintEvent:FireServer(true)
	end)
	sprintBtn.MouseButton1Up:Connect(function()
		sprintEvent:FireServer(false)
	end)

	-- Crouch button: toggle
	crouchBtn.MouseButton1Down:Connect(function()
		isCrouching = not isCrouching
		crouchEvent:FireServer(isCrouching)
	end)

	-- Stats button: toggle stat menu
	local statsBtn = actionFrame:WaitForChild("StatsButton")
	statsBtn.MouseButton1Down:Connect(function()
		-- Call the global toggle function from StatMenuScript
		if _G.ToggleStatMenu then
			_G.ToggleStatMenu()
		end
	end)
else
	-- PC: Hide mobile controls but still wire up stats button if it exists
	local mobileGui = playerGui:WaitForChild("MobileControlsGui")
	mobileGui.Enabled = false
	
	-- Wire up stats button for PC (visible in case of emulator testing)
	local actionFrame = mobileGui:FindFirstChild("ActionFrame")
	if actionFrame then
		local statsBtn = actionFrame:FindFirstChild("StatsButton")
		if statsBtn then
			statsBtn.MouseButton1Down:Connect(function()
				if _G.ToggleStatMenu then
					_G.ToggleStatMenu()
				end
			end)
		end
	end
end
