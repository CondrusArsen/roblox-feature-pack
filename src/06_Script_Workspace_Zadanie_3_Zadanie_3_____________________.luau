local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local TAG_NAME = "checkpoints"
local checkpoints = CollectionService:GetTagged(TAG_NAME)
local spawn = workspace:FindFirstChild("SpawnLocation")

--- 1)[сложно]мы хотим чтобы красная платформа убивала при наступании
local DeathPart = script.Parent:FindFirstChild("DeathPart")

if DeathPart and DeathPart:IsA("BasePart") then
	DeathPart.Touched:Connect(function(hit)
		local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = 0 end
	end)
end




local lastCheckpoint = {}

local function moveToCheckpoint(plr, char)
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	local cp = lastCheckpoint[plr]
	local targetCFrame
	if cp then
		targetCFrame = CFrame.new(cp.Position + Vector3.new(0, (cp.Size.Y/2) + 5, 0))
	elseif spawn and spawn:IsA("BasePart") then
		targetCFrame = spawn.CFrame + Vector3.new(0, 5, 0)
	else
		return
	end

	task.defer(function()
		hrp.CFrame = targetCFrame
	end)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		moveToCheckpoint(plr, char)
	end)
end)






local function hidePart(p)
	if not (p and p:IsA("BasePart")) then return end
	p.Transparency = 1
	p.CanCollide = false
	p.CanTouch = false
end

local function showPart(p)
	if not (p and p:IsA("BasePart")) then return end
	p.Transparency = 0
	p.CanCollide = true
	p.CanTouch = true
end

local function restoreAll()
	for _, p in ipairs(checkpoints) do
		showPart(p)
	end
end

local function visibleCountAndLast()
	local n = 0 
	for _, p in ipairs(checkpoints) do
		if p:IsA("BasePart") and p.CanTouch then
			n += 1
		end
	end
	return n
end

local function onCheckpointTouched(plr, part)
	local char = plr.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if lastCheckpoint[plr] ~= part and hum.Health ~= 0 then
		if lastCheckpoint[plr] then
			hidePart(lastCheckpoint[plr])
		end
		
		lastCheckpoint[plr] = part
		
		local count = visibleCountAndLast()
		if count == 1 then
			restoreAll()
		end
	end
end

for _, part in ipairs(checkpoints) do
	if part:IsA("BasePart") then
		part.Touched:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if not plr then return end
			onCheckpointTouched(plr, part)
		end)
	end
end

Players.PlayerRemoving:Connect(function(plr)
	lastCheckpoint[plr] = nil
end)

restoreAll()




