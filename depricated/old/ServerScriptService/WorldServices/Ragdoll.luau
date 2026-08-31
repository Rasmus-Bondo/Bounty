local Ragdoll = {}
Ragdoll.__index = Ragdoll

local COLLIDABLE_PARTS = {
	Head = true,
	UpperTorso = true,
	LowerTorso = true,
	LeftUpperLeg = true,
	RightUpperLeg = true,
	LeftLowerLeg = true,
	RightLowerLeg = true,
	LeftFoot = true,
	RightFoot = true,
	LeftUpperArm = true,
	RightUpperArm = true,
	LeftLowerArm = true,
	RightLowerArm = true,
	LeftHand = true,
	RightHand = true,
}

local function setRagdollCollisions(character, enabled)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Name == "HumanoidRootPart" then
				obj.CanCollide = false
			else
				obj.CanCollide = enabled and COLLIDABLE_PARTS[obj.Name] == true
			end
		end
	end
end

local function createConstraintFromMotor(motor)
	if not motor.Part0 or not motor.Part1 then
		return nil
	end

	local attachment0 = Instance.new("Attachment")
	attachment0.Name = motor.Name .. "_RagdollAttachment0"
	attachment0.CFrame = motor.C0
	attachment0.Parent = motor.Part0

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = motor.Name .. "_RagdollAttachment1"
	attachment1.CFrame = motor.C1
	attachment1.Parent = motor.Part1

	local socket = Instance.new("BallSocketConstraint")
	socket.Name = motor.Name .. "_RagdollConstraint"
	socket.Attachment0 = attachment0
	socket.Attachment1 = attachment1
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true
	socket.UpperAngle = 35
	socket.TwistLowerAngle = -20
	socket.TwistUpperAngle = 20
	socket.MaxFrictionTorque = 10
	socket.Restitution = 0
	socket.Parent = motor.Parent

	return {
		motor = motor,
		attachment0 = attachment0,
		attachment1 = attachment1,
		socket = socket,
	}
end

function Ragdoll.new(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		error("Ragdoll.new: character has no Humanoid")
	end

	local self = setmetatable({}, Ragdoll)

	self.character = character
	self.humanoid = humanoid
	self.createdConstraints = {}
	self.enabled = false

	return self
end

function Ragdoll:enable()
	if self.enabled then
		return
	end

	self.enabled = true

	self.humanoid.BreakJointsOnDeath = false
	self.humanoid.RequiresNeck = false
	self.humanoid.AutoRotate = false
	self.humanoid.PlatformStand = true

	local rootPart = self.character:FindFirstChild("HumanoidRootPart")
	local lowerTorso = self.character:FindFirstChild("LowerTorso")
	local upperTorso = self.character:FindFirstChild("UpperTorso")
	local head = self.character:FindFirstChild("Head")

	if rootPart then
		rootPart.CanCollide = false
		rootPart.Massless = true
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end

	for _, obj in ipairs(self.character:GetDescendants()) do
		if obj:IsA("Motor6D") then
			local created = createConstraintFromMotor(obj)
			if created then
				obj.Enabled = false
				table.insert(self.createdConstraints, created)
			end
		end
	end

	setRagdollCollisions(self.character, true)

	if head and head:IsA("BasePart") then
		head.CanCollide = true
	end

	self.humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	local impulsePart = upperTorso or lowerTorso or head
	if impulsePart and impulsePart:IsA("BasePart") then
		local randomX = math.random(-8, 8)
		local randomZ = math.random(-8, 8)
		local push = Vector3.new(randomX, -4, randomZ) * impulsePart.AssemblyMass
		impulsePart:ApplyImpulse(push)

		local torque = Vector3.new(
			math.random(-8, 8),
			math.random(-4, 4),
			math.random(-8, 8)
		) * impulsePart.AssemblyMass
		impulsePart:ApplyAngularImpulse(torque)
	end
end

function Ragdoll:destroy()
	if self.createdConstraints then
		for _, item in ipairs(self.createdConstraints) do
			if item.socket then
				item.socket:Destroy()
			end
			if item.attachment0 then
				item.attachment0:Destroy()
			end
			if item.attachment1 then
				item.attachment1:Destroy()
			end
		end
	end

	self.character = nil
	self.humanoid = nil
	self.createdConstraints = nil
end

return Ragdoll