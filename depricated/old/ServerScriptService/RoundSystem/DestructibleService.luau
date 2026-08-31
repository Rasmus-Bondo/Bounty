local DestructibleService = {}

local CollectionService = game:GetService("CollectionService")

local windows = {}
local originalTransparency = {}

function DestructibleService.Initialize()
	for _, part in pairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == "Window" then
			windows[part] = false
			originalTransparency[part] = part.Transparency
		end
	end
	print("[DestructibleService] Initialized — tracking " .. DestructibleService._countWindows() .. " windows")
end

function DestructibleService._countWindows()
	local count = 0
	for _ in pairs(windows) do
		count = count + 1
	end
	return count
end

function DestructibleService.breakWindow(windowPart)
	if not windowPart or windows[windowPart] == nil then return end
	if windows[windowPart] then return end

	windows[windowPart] = true
	windowPart.CanCollide = false
	windowPart.Transparency = 0.8

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://280667448"
	sound.Volume = 0.8
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = 200
	sound.Parent = windowPart
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	print("[DestructibleService] Window broken at " .. tostring(windowPart.Position))
end

function DestructibleService.isWindowDestroyed(windowPart)
	return windows[windowPart] or false
end

function DestructibleService.resetDestructibles()
	for windowPart, broken in pairs(windows) do
		if broken then
			windowPart.CanCollide = true
			windowPart.Transparency = originalTransparency[windowPart] or 0.3
		end
		windows[windowPart] = false
	end
	print("[DestructibleService] All windows reset")
end

return DestructibleService