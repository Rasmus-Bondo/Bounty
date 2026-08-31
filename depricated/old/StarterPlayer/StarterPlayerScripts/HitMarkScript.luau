local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gunGui = playerGui:WaitForChild("GunGui")
local canvas = gunGui:WaitForChild("Canvas")

local headshotSound = gunGui:WaitForChild("HeadshotSound")
local normalHitSound = gunGui:WaitForChild("NormalHitSound")

local bodyLayerSound = gunGui:FindFirstChild("BodyLayerSound")
local headshotLayerSound = gunGui:FindFirstChild("HeadshotLayerSound")

local crosshairDot = gunGui:WaitForChild("CrosshairDot")
local skullMark = gunGui:WaitForChild("SkullMark")
local skullMarkUpper = gunGui:WaitForChild("SkullMarkUpper")
local skullMarkLower = gunGui:WaitForChild("SkullMarkLower")

local flashFrame = canvas:WaitForChild("FlashFrame")

local triangle1 = canvas:WaitForChild("Triangle1")
local triangle2 = canvas:WaitForChild("Triangle2")
local triangle3 = canvas:WaitForChild("Triangle3")

local NORMAL_COLOR = Color3.fromRGB(255, 255, 255)
local HEADSHOT_COLOR = Color3.fromRGB(241, 121, 123)
local HEADSHOT_GLOW_COLOR = Color3.fromRGB(255, 175, 185)

local START_TRANSPARENCY = 0.35
local FLASH_TRANSPARENCY = 0
local END_TRANSPARENCY = 0.45

local REST_SIDE_FRACTION = 0.22
local HIT_SIDE_FRACTION = 0.50
local TOP_OFFSET_FIX = 1.2

local HITMARKER_SCALE = 0.65

local function scaleUDim2(ud, mult)
	return UDim2.new(
		ud.X.Scale * mult,
		math.floor(ud.X.Offset * mult),
		ud.Y.Scale * mult,
		math.floor(ud.Y.Offset * mult)
	)
end

local BASE_TRIANGLE_SIZE = scaleUDim2(UDim2.new(0.1, 0, 0.1, 0), HITMARKER_SCALE)
local STRETCHED_TRIANGLE_SIZE = scaleUDim2(UDim2.new(0.1, 0, 0.6, 0), HITMARKER_SCALE)
local HEADSHOT_STRETCH_SIZE = scaleUDim2(UDim2.new(0.1, 0, 0.7, 0), HITMARKER_SCALE)

local OUT_TIME = 0.07
local IN_TIME = 0.08
local HEADSHOT_HOLD_TIME = 0.12

local SHAKE_DURATION = 0.12
local SHAKE_INTENSITY = 0.005

local DOT_BASE_SIZE = scaleUDim2(UDim2.new(0.005, 0, 0.005, 0), HITMARKER_SCALE)
local DOT_HIT_SIZE = scaleUDim2(UDim2.new(0.007, 0, 0.007, 0), HITMARKER_SCALE)
local DOT_HEADSHOT_SIZE = scaleUDim2(UDim2.new(0.0085, 0, 0.0085, 0), HITMARKER_SCALE)

local FLASH_BASE_SIZE = scaleUDim2(UDim2.new(0.45, 0, 0.45, 0), HITMARKER_SCALE)
local FLASH_HIT_SIZE = scaleUDim2(UDim2.new(0.56, 0, 0.56, 0), HITMARKER_SCALE)
local FLASH_HEADSHOT_SIZE = scaleUDim2(UDim2.new(0.64, 0, 0.64, 0), HITMARKER_SCALE)

local STACK_MAX = 6
local STACK_DECAY_TIME = 0.55

local SKULL_BASE_SIZE = scaleUDim2(UDim2.new(0.07, 0, 0.07, 0), HITMARKER_SCALE)
local SKULL_EXPANDED_SIZE = scaleUDim2(UDim2.new(0.1, 0, 0.1, 0), HITMARKER_SCALE)
local SKULL_EXPAND_TIME = 0.19
local SKULL_HOLD_TIME = 0.14
local SKULL_SPLIT_TIME = 0.18

local KILL_SKULL_BODY_COLOR = Color3.fromRGB(255, 145, 145)
local KILL_SKULL_HEADSHOT_COLOR = Color3.fromRGB(255, 90, 110)
local KILL_SKULL_START_COLOR = Color3.fromRGB(255, 255, 255)

local currentHitRemoteConnection
local activeTweens = {}
local activeShakeId = 0
local activeDotTweenId = 0
local activeSkullId = 0

local hitStack = 0
local lastHitTime = 0

UserInputService.MouseIconEnabled = false

canvas.AnchorPoint = Vector2.new(0.5, 0.5)
canvas.Position = UDim2.new(0.5, 0, 0.5, 0)
canvas.Size = scaleUDim2(UDim2.new(0.1, 0, 0.1, 0), HITMARKER_SCALE)

crosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairDot.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairDot.Size = DOT_BASE_SIZE
crosshairDot.Visible = true
crosshairDot.ZIndex = 10
crosshairDot.BackgroundColor3 = NORMAL_COLOR
crosshairDot.BorderSizePixel = 0

flashFrame.AnchorPoint = Vector2.new(0.5, 0.5)
flashFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
flashFrame.Size = FLASH_BASE_SIZE
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel = 0
flashFrame.Visible = true

local function setupSkullImage(imageLabel)
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	imageLabel.Size = SKULL_BASE_SIZE
	imageLabel.ImageTransparency = 1
	imageLabel.Visible = false
end

setupSkullImage(skullMark)
setupSkullImage(skullMarkUpper)
setupSkullImage(skullMarkLower)

local function clearTweens()
	for _, tween in ipairs(activeTweens) do
		tween:Cancel()
	end
	table.clear(activeTweens)
end

local function updateHitStack()
	local now = tick()
	local elapsed = now - lastHitTime

	if elapsed > STACK_DECAY_TIME then
		hitStack = 0
	end

	hitStack = math.clamp(hitStack + 1, 1, STACK_MAX)
	lastHitTime = now
end

local function getStackAlpha()
	return (hitStack - 1) / math.max(STACK_MAX - 1, 1)
end

local function darkenColor(color, amount)
	return Color3.new(
		math.clamp(color.R * (1 - amount), 0, 1),
		math.clamp(color.G * (1 - amount), 0, 1),
		math.clamp(color.B * (1 - amount), 0, 1)
	)
end

local function playLayeredSound(isHeadshot)
	if isHeadshot then
		headshotSound:Stop()
		headshotSound.TimePosition = 0
		headshotSound.PlaybackSpeed = math.random(98, 102) / 100
		headshotSound:Play()

		if headshotLayerSound then
			headshotLayerSound:Stop()
			headshotLayerSound.TimePosition = 0
			headshotLayerSound.PlaybackSpeed = math.random(98, 103) / 100
			headshotLayerSound:Play()
		end
	else
		normalHitSound:Stop()
		normalHitSound.TimePosition = 0
		normalHitSound.PlaybackSpeed = math.random(96, 104) / 100
		normalHitSound:Play()

		if bodyLayerSound then
			bodyLayerSound:Stop()
			bodyLayerSound.TimePosition = 0
			bodyLayerSound.PlaybackSpeed = math.random(96, 104) / 100
			bodyLayerSound:Play()
		end
	end
end

local function pulseDot(isHeadshot)
	activeDotTweenId += 1
	local thisDotTweenId = activeDotTweenId

	local stackAlpha = getStackAlpha()
	local growSize = isHeadshot and DOT_HEADSHOT_SIZE or DOT_HIT_SIZE

	if stackAlpha > 0 then
		local extra = 0.0015 * stackAlpha * HITMARKER_SCALE
		growSize = UDim2.new(growSize.X.Scale + extra, 0, growSize.Y.Scale + extra, 0)
	end

	local growColor = isHeadshot and HEADSHOT_COLOR or NORMAL_COLOR
	crosshairDot.BackgroundColor3 = growColor

	local grow = TweenService:Create(
		crosshairDot,
		TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = growSize}
	)

	local shrink = TweenService:Create(
		crosshairDot,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Size = DOT_BASE_SIZE}
	)

	grow:Play()
	grow.Completed:Once(function()
		if thisDotTweenId ~= activeDotTweenId then
			return
		end

		shrink:Play()
		shrink.Completed:Once(function()
			if thisDotTweenId ~= activeDotTweenId then
				return
			end

			crosshairDot.BackgroundColor3 = NORMAL_COLOR
		end)
	end)
end

local function flashImpact(isHeadshot)
	local stackAlpha = getStackAlpha()

	local targetSize = isHeadshot and FLASH_HEADSHOT_SIZE or FLASH_HIT_SIZE
	local extraSize = 0.06 * stackAlpha * HITMARKER_SCALE
	targetSize = UDim2.new(targetSize.X.Scale + extraSize, 0, targetSize.Y.Scale + extraSize, 0)

	flashFrame.BackgroundColor3 = isHeadshot and HEADSHOT_COLOR or NORMAL_COLOR
	flashFrame.BackgroundTransparency = isHeadshot and 0.78 or 0.84
	flashFrame.Size = FLASH_BASE_SIZE

	local outTween = TweenService:Create(
		flashFrame,
		TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			BackgroundTransparency = 1,
			Size = targetSize
		}
	)

	outTween:Play()
end

local function getTrianglePositions(sideFraction)
	local absSize = canvas.AbsoluteSize
	local W = absSize.X
	local H = absSize.Y

	if W <= 0 or H <= 0 then
		return nil
	end

	local s = W * sideFraction
	local halfSpanX = (s / 2) / W
	local verticalOffset = ((math.sqrt(3) / 4) * s) / H

	return {
		top = UDim2.new(0.5, 0, 0.5 - (verticalOffset * TOP_OFFSET_FIX), 0),
		left = UDim2.new(0.5 - halfSpanX, 0, 0.5 + verticalOffset, 0),
		right = UDim2.new(0.5 + halfSpanX, 0, 0.5 + verticalOffset, 0),
	}
end

local function applyTriangleStyle()
	triangle1.AnchorPoint = Vector2.new(0.5, 0.5)
	triangle2.AnchorPoint = Vector2.new(0.5, 0.5)
	triangle3.AnchorPoint = Vector2.new(0.5, 0.5)

	triangle1.Rotation = 0
	triangle2.Rotation = -120
	triangle3.Rotation = 120

	triangle1.Size = BASE_TRIANGLE_SIZE
	triangle2.Size = BASE_TRIANGLE_SIZE
	triangle3.Size = BASE_TRIANGLE_SIZE
end

local function setPositions(sideFraction)
	local positions = getTrianglePositions(sideFraction)
	if not positions then
		return
	end

	triangle1.Position = positions.top
	triangle2.Position = positions.left
	triangle3.Position = positions.right
end

local function setColor(color)
	triangle1.ImageColor3 = color
	triangle2.ImageColor3 = color
	triangle3.ImageColor3 = color
end

local function setTransparency(value)
	triangle1.ImageTransparency = value
	triangle2.ImageTransparency = value
	triangle3.ImageTransparency = value
end

local function playScreenShake()
	activeShakeId += 1
	local thisShakeId = activeShakeId
	local startTime = tick()

	local connection
	connection = RunService.RenderStepped:Connect(function()
		if thisShakeId ~= activeShakeId then
			connection:Disconnect()
			return
		end

		local elapsed = tick() - startTime
		if elapsed > SHAKE_DURATION then
			connection:Disconnect()
			canvas.Position = UDim2.new(0.5, 0, 0.5, 0)
			return
		end

		local strength = SHAKE_INTENSITY * (1 - (elapsed / SHAKE_DURATION))
		local offsetX = (math.random() - 0.5) * 2 * strength
		local offsetY = (math.random() - 0.5) * 2 * strength

		canvas.Position = UDim2.new(0.5 + offsetX, 0, 0.5 + offsetY, 0)
	end)
end

local function showHeadshotGlow()
	local glowOut1 = TweenService:Create(
		triangle1,
		TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ImageColor3 = HEADSHOT_GLOW_COLOR}
	)

	local glowOut2 = TweenService:Create(
		triangle2,
		TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ImageColor3 = HEADSHOT_GLOW_COLOR}
	)

	local glowOut3 = TweenService:Create(
		triangle3,
		TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ImageColor3 = HEADSHOT_GLOW_COLOR}
	)

	glowOut1:Play()
	glowOut2:Play()
	glowOut3:Play()

	glowOut1.Completed:Once(function()
		local glowBack1 = TweenService:Create(
			triangle1,
			TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ImageColor3 = HEADSHOT_COLOR}
		)

		local glowBack2 = TweenService:Create(
			triangle2,
			TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ImageColor3 = HEADSHOT_COLOR}
		)

		local glowBack3 = TweenService:Create(
			triangle3,
			TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ImageColor3 = HEADSHOT_COLOR}
		)

		glowBack1:Play()
		glowBack2:Play()
		glowBack3:Play()
	end)
end

local function resetKillSkull()
	skullMark.Visible = false
	skullMarkUpper.Visible = false
	skullMarkLower.Visible = false

	skullMark.Position = UDim2.new(0.5, 0, 0.5, 0)
	skullMarkUpper.Position = UDim2.new(0.5, 0, 0.5, 0)
	skullMarkLower.Position = UDim2.new(0.5, 0, 0.5, 0)

	skullMark.Size = SKULL_BASE_SIZE
	skullMarkUpper.Size = SKULL_EXPANDED_SIZE
	skullMarkLower.Size = SKULL_EXPANDED_SIZE

	skullMark.ImageTransparency = 1
	skullMarkUpper.ImageTransparency = 1
	skullMarkLower.ImageTransparency = 1

	skullMark.ImageColor3 = KILL_SKULL_START_COLOR
	skullMarkUpper.ImageColor3 = KILL_SKULL_START_COLOR
	skullMarkLower.ImageColor3 = KILL_SKULL_START_COLOR
end

local function playKillSkull(isHeadshot)
	activeSkullId += 1
	local thisSkullId = activeSkullId

	resetKillSkull()

	local targetColor = isHeadshot and KILL_SKULL_HEADSHOT_COLOR or KILL_SKULL_BODY_COLOR
	local splitDarkColor = darkenColor(targetColor, 0.22)

	skullMark.Visible = true
	skullMark.Position = UDim2.new(0.5, 0, 0.5, 0)
	skullMark.Size = SKULL_BASE_SIZE
	skullMark.ImageTransparency = 0
	skullMark.ImageColor3 = KILL_SKULL_START_COLOR

	local expandTween = TweenService:Create(
		skullMark,
		TweenInfo.new(SKULL_EXPAND_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Size = SKULL_EXPANDED_SIZE,
			ImageColor3 = targetColor
		}
	)

	expandTween:Play()

	expandTween.Completed:Once(function()
		if thisSkullId ~= activeSkullId then
			resetKillSkull()
			return
		end

		task.delay(SKULL_HOLD_TIME, function()
			if thisSkullId ~= activeSkullId then
				resetKillSkull()
				return
			end

			skullMark.Visible = false

			skullMarkUpper.Visible = true
			skullMarkLower.Visible = true

			skullMarkUpper.Position = UDim2.new(0.5, 0, 0.5, 0)
			skullMarkLower.Position = UDim2.new(0.5, 0, 0.5, 0)

			skullMarkUpper.Size = SKULL_EXPANDED_SIZE
			skullMarkLower.Size = SKULL_EXPANDED_SIZE

			skullMarkUpper.ImageTransparency = 0
			skullMarkLower.ImageTransparency = 0

			skullMarkUpper.ImageColor3 = targetColor
			skullMarkLower.ImageColor3 = targetColor

			local upperTween = TweenService:Create(
				skullMarkUpper,
				TweenInfo.new(SKULL_SPLIT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = UDim2.new(0.5, math.floor(-18 * HITMARKER_SCALE), 0.5, math.floor(-22 * HITMARKER_SCALE)),
					ImageTransparency = 1,
					ImageColor3 = splitDarkColor
				}
			)

			local lowerTween = TweenService:Create(
				skullMarkLower,
				TweenInfo.new(SKULL_SPLIT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = UDim2.new(0.5, math.floor(18 * HITMARKER_SCALE), 0.5, math.floor(22 * HITMARKER_SCALE)),
					ImageTransparency = 1,
					ImageColor3 = splitDarkColor
				}
			)

			upperTween:Play()
			lowerTween:Play()

			lowerTween.Completed:Once(function()
				if thisSkullId ~= activeSkullId then
					resetKillSkull()
					return
				end

				resetKillSkull()
			end)
		end)
	end)
end

local function showHitmarker(isHeadshot, didKill)
	updateHitStack()
	clearTweens()

	canvas.Visible = true
	canvas.Position = UDim2.new(0.5, 0, 0.5, 0)

	local stackAlpha = getStackAlpha()
	local color = isHeadshot and HEADSHOT_COLOR or NORMAL_COLOR

	local stretchSize = isHeadshot and HEADSHOT_STRETCH_SIZE or STRETCHED_TRIANGLE_SIZE
	local extraStretch = 0.08 * stackAlpha * HITMARKER_SCALE
	stretchSize = UDim2.new(stretchSize.X.Scale, 0, stretchSize.Y.Scale + extraStretch, 0)

	local sideFraction = HIT_SIDE_FRACTION + (0.06 * stackAlpha * HITMARKER_SCALE)

	setColor(color)
	setTransparency(START_TRANSPARENCY)

	playLayeredSound(isHeadshot)
	pulseDot(isHeadshot)
	flashImpact(isHeadshot)

	if isHeadshot then
		playScreenShake()
		showHeadshotGlow()
	end

	if didKill then
		playKillSkull(isHeadshot)
	end

	applyTriangleStyle()
	setPositions(REST_SIDE_FRACTION)

	local hitPositions = getTrianglePositions(sideFraction)
	if not hitPositions then
		return
	end

	local t1Out = TweenService:Create(
		triangle1,
		TweenInfo.new(OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = hitPositions.top,
			Size = stretchSize,
			ImageTransparency = FLASH_TRANSPARENCY
		}
	)

	local t2Out = TweenService:Create(
		triangle2,
		TweenInfo.new(OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = hitPositions.left,
			Size = stretchSize,
			ImageTransparency = FLASH_TRANSPARENCY
		}
	)

	local t3Out = TweenService:Create(
		triangle3,
		TweenInfo.new(OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = hitPositions.right,
			Size = stretchSize,
			ImageTransparency = FLASH_TRANSPARENCY
		}
	)

	table.insert(activeTweens, t1Out)
	table.insert(activeTweens, t2Out)
	table.insert(activeTweens, t3Out)

	t1Out:Play()
	t2Out:Play()
	t3Out:Play()

	t1Out.Completed:Once(function()
		local function playReturnTween()
			local restPositions = getTrianglePositions(REST_SIDE_FRACTION)
			if not restPositions then
				canvas.Visible = false
				canvas.Position = UDim2.new(0.5, 0, 0.5, 0)
				return
			end

			local t1In = TweenService:Create(
				triangle1,
				TweenInfo.new(IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					Position = restPositions.top,
					Size = BASE_TRIANGLE_SIZE,
					ImageTransparency = END_TRANSPARENCY
				}
			)

			local t2In = TweenService:Create(
				triangle2,
				TweenInfo.new(IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					Position = restPositions.left,
					Size = BASE_TRIANGLE_SIZE,
					ImageTransparency = END_TRANSPARENCY
				}
			)

			local t3In = TweenService:Create(
				triangle3,
				TweenInfo.new(IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					Position = restPositions.right,
					Size = BASE_TRIANGLE_SIZE,
					ImageTransparency = END_TRANSPARENCY
				}
			)

			table.insert(activeTweens, t1In)
			table.insert(activeTweens, t2In)
			table.insert(activeTweens, t3In)

			t1In:Play()
			t2In:Play()
			t3In:Play()

			t1In.Completed:Once(function()
				canvas.Visible = false
				canvas.Position = UDim2.new(0.5, 0, 0.5, 0)
				setColor(NORMAL_COLOR)
				setTransparency(0)
			end)
		end

		if isHeadshot then
			task.delay(HEADSHOT_HOLD_TIME, playReturnTween)
		else
			playReturnTween()
		end
	end)
end

local function connectTool(tool)
	if currentHitRemoteConnection then
		currentHitRemoteConnection:Disconnect()
		currentHitRemoteConnection = nil
	end

	local hitConfirmRemote = tool:WaitForChild("HitConfirm")
	currentHitRemoteConnection = hitConfirmRemote.OnClientEvent:Connect(function(isHeadshot, didKill)
		showHitmarker(isHeadshot, didKill)
	end)
end

local function watchCharacter(character)
	local function checkChild(child)
		if child:IsA("Tool") and child:FindFirstChild("HitConfirm") then
			connectTool(child)
		end
	end

	for _, child in ipairs(character:GetChildren()) do
		checkChild(child)
	end

	character.ChildAdded:Connect(checkChild)
end

canvas.Visible = false
applyTriangleStyle()
setPositions(REST_SIDE_FRACTION)
setColor(NORMAL_COLOR)
setTransparency(0)

crosshairDot.Size = DOT_BASE_SIZE
crosshairDot.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairDot.Visible = true
crosshairDot.BackgroundColor3 = NORMAL_COLOR

resetKillSkull()

if player.Character then
	watchCharacter(player.Character)
end

player.CharacterAdded:Connect(watchCharacter)