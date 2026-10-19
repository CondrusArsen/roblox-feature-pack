local Players = game:GetService("Players")

local DeathPart = script.Parent.DeathPart


local checkpointsFolder = workspace:WaitForChild("Zadanie 3")
local spawn = workspace:FindFirstChild("SpawnLocation")         

local lastCheckpoint = {}


local function bindCheckpoint(part)

	part.Touched:Connect(function(hit)
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		if not plr then return end
		lastCheckpoint[plr] = part
	end)
end

for _, child in ipairs(checkpointsFolder:GetChildren()) do
	if child:IsA("BasePart") and child.Name == "Part" then
		bindCheckpoint(child)
	end
end


--checkpointsFolder.ChildAdded:Connect(bindCheckpoint)


local function moveToCheckpoint(plr, char)
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	local cp = lastCheckpoint[plr]
	local targetCFrame

	if cp then
		targetCFrame = CFrame.new(cp.Position + Vector3.new(0, (cp.Size.Y / 2) + 5, 0))
	elseif spawn then
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

Players.PlayerRemoving:Connect(function(plr)
	lastCheckpoint[plr] = nil
end)


DeathPart.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") then
		hit.Parent.Humanoid.Health = 0
	end
end)

