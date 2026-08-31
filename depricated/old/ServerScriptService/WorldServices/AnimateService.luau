local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local AnimateService = {}

local defaultAnimate
local DEFAULT_R15_IDS = {
	idle = {
		"rbxassetid://507766666",
		"rbxassetid://507766951",
	},
	walk = "rbxassetid://507777826",
	run = "rbxassetid://507767714",
	jump = "rbxassetid://507765000",
	fall = "rbxassetid://507767968",
	climb = "rbxassetid://507765644",
	swim = "rbxassetid://507784897",
	swimidle = "rbxassetid://507785072",
}

local function hasCustom(anim)
	return anim and anim:IsA("Animation") and anim.AnimationId ~= ""
end

local function fixAnimate(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end

	local animate = character:FindFirstChild("Animate")

	if not animate or not animate:IsA("LocalScript") then
		if animate then animate:Destroy() end
		animate = defaultAnimate:Clone()
		animate.Name = "Animate"
		animate.Parent = character
	end

	local idle = animate:FindFirstChild("idle") or Instance.new("Folder")
	idle.Name = "idle"
	idle.Parent = animate

	local function ensureAnim(parent, name, id)
		local anim = parent:FindFirstChild(name)

		if not anim or not anim:IsA("Animation") then
			if anim then anim:Destroy() end
			anim = Instance.new("Animation")
			anim.Name = name
			anim.Parent = parent
		end

		if not hasCustom(anim) then
			anim.AnimationId = id
		end
	end

	ensureAnim(idle, "Animation1", DEFAULT_R15_IDS.idle[1])
	ensureAnim(idle, "Animation2", DEFAULT_R15_IDS.idle[2])

	ensureAnim(animate, "walk", DEFAULT_R15_IDS.walk)
	ensureAnim(animate, "run", DEFAULT_R15_IDS.run)
	ensureAnim(animate, "jump", DEFAULT_R15_IDS.jump)
	ensureAnim(animate, "fall", DEFAULT_R15_IDS.fall)
	ensureAnim(animate, "climb", DEFAULT_R15_IDS.climb)
	ensureAnim(animate, "swim", DEFAULT_R15_IDS.swim)
	ensureAnim(animate, "swimidle", DEFAULT_R15_IDS.swimidle)
end

local function protectCharacter(character)
	fixAnimate(character)

	task.delay(0.5, function()
		if character.Parent then
			fixAnimate(character)
		end
	end)

	task.delay(1, function()
		if character.Parent then
			fixAnimate(character)
		end
	end)

	character.ChildAdded:Connect(function(child)
		if child.Name == "Animate" then
			task.wait(0.1)
			fixAnimate(character)
		end
	end)
end

local function onPlayer(player)
	player.CharacterAdded:Connect(protectCharacter)

	if player.Character then
		protectCharacter(player.Character)
	end
end

function AnimateService.Initialize()
	defaultAnimate = ServerStorage:WaitForChild("DefaultR15Animate")

	Players.PlayerAdded:Connect(onPlayer)

	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
end

return AnimateService