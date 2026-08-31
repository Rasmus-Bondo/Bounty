local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local events = game.ReplicatedStorage.Events.MovementEvents
local sprintEvent = events.SprintEvent
local crouchEvent = events.CrouchEvent

local Config = require(game.ServerScriptService.Shared.Config)

local MovementService = {}

local CROUCH_ANIMATION_ID = ""  -- Placeholder - set to your crouch animation asset ID

-- Track crouch animations per player
local crouchAnimations = {}

function MovementService.Initialize()
	-- Set initial attributes for all current players
	for _, player in Players:GetPlayers() do
		MovementService.initPlayer(player)
	end
	Players.PlayerAdded:Connect(MovementService.initPlayer)
	Players.PlayerRemoving:Connect(MovementService.cleanupPlayer)

	-- Bind RemoteEvent handlers
	sprintEvent.OnServerEvent:Connect(function(player, isSprinting)
		MovementService.handleSprint(player, isSprinting)
	end)
	crouchEvent.OnServerEvent:Connect(function(player, isCrouching)
		MovementService.handleCrouch(player, isCrouching)
	end)

	-- Heartbeat tick for stamina drain/regen
	RunService.Heartbeat:Connect(function(dt)
		MovementService.tickStamina(dt)
	end)
end

function MovementService.initPlayer(player)
	player:SetAttribute("Stamina", Config.MAX_STAMINA)
	player:SetAttribute("IsSprinting", false)
	player:SetAttribute("IsCrouching", false)
	player:SetAttribute("LastSprintStop", 0)
	
	-- Wait for character and load crouch animation
	player.CharacterAdded:Connect(function(character)
		MovementService.loadCrouchAnimation(player, character)
	end)
	
	if player.Character then
		MovementService.loadCrouchAnimation(player, player.Character)
	end
end

function MovementService.loadCrouchAnimation(player, character)
	-- Clean up old animation if exists
	if crouchAnimations[player] then
		crouchAnimations[player]:Stop()
		crouchAnimations[player]:Destroy()
		crouchAnimations[player] = nil
	end
	
	-- Load new crouch animation if ID is set
	if CROUCH_ANIMATION_ID ~= "" then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = humanoid
			end
			
			local crouchAnim = Instance.new("Animation")
			crouchAnim.AnimationId = CROUCH_ANIMATION_ID
			
			local animTrack = animator:LoadAnimation(crouchAnim)
			animTrack.Priority = Enum.AnimationPriority.Action
			animTrack.Looped = true
			
			crouchAnimations[player] = animTrack
		end
	end
end

function MovementService.cleanupPlayer(player)
	-- Clean up crouch animation
	if crouchAnimations[player] then
		crouchAnimations[player]:Stop()
		crouchAnimations[player]:Destroy()
		crouchAnimations[player] = nil
	end
end

function MovementService.handleSprint(player, isSprinting)
	-- Type-check isSprinting (must be boolean)
	if typeof(isSprinting) ~= "boolean" then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if isSprinting then
		local stamina = player:GetAttribute("Stamina") or 0
		if stamina <= 0 then return end -- Can't sprint with no stamina
		-- Cancel crouch if crouching
		if player:GetAttribute("IsCrouching") then
			MovementService.handleCrouch(player, false)
		end
		player:SetAttribute("IsSprinting", true)
		humanoid.WalkSpeed = Config.SPRINT_SPEED
	else
		player:SetAttribute("IsSprinting", false)
		player:SetAttribute("LastSprintStop", workspace:GetServerTimeNow())
		-- Restore to crouch or walk speed
		if player:GetAttribute("IsCrouching") then
			humanoid.WalkSpeed = Config.CROUCH_SPEED
		else
			humanoid.WalkSpeed = Config.WALK_SPEED
		end
	end
end

function MovementService.handleCrouch(player, isCrouching)
	if typeof(isCrouching) ~= "boolean" then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if isCrouching then
		-- Cancel sprint if sprinting
		if player:GetAttribute("IsSprinting") then
			MovementService.handleSprint(player, false)
		end
		player:SetAttribute("IsCrouching", true)
		humanoid.WalkSpeed = Config.CROUCH_SPEED
		humanoid.HipHeight = Config.CROUCH_HIP_HEIGHT
	else
		player:SetAttribute("IsCrouching", false)
		humanoid.HipHeight = Config.NORMAL_HIP_HEIGHT
		if player:GetAttribute("IsSprinting") then
			humanoid.WalkSpeed = Config.SPRINT_SPEED
		else
			humanoid.WalkSpeed = Config.WALK_SPEED
		end
	end
end

function MovementService.tickStamina(dt)
	for _, player in Players:GetPlayers() do
		local stamina = player:GetAttribute("Stamina") or Config.MAX_STAMINA
		local isSprinting = player:GetAttribute("IsSprinting")

		if isSprinting then
			stamina = math.max(0, stamina - Config.STAMINA_DRAIN_RATE * dt)
			if stamina <= 0 then
				-- Force stop sprint
				MovementService.handleSprint(player, false)
				stamina = 0
			end
		else
			local lastSprintStop = player:GetAttribute("LastSprintStop") or 0
			local now = workspace:GetServerTimeNow()
			if now - lastSprintStop >= Config.STAMINA_REGEN_DELAY then
				stamina = math.min(Config.MAX_STAMINA, stamina + Config.STAMINA_REGEN_RATE * dt)
			end
		end
		player:SetAttribute("Stamina", stamina)
	end
end

return MovementService