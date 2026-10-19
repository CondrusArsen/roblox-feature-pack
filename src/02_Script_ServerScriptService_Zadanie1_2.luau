--2)[сложно]мы хотим чтобы если игрок 2 секунды стоит на платформе его телепортировало на SpawnLocation



local Players = game:GetService("Players")

local toleranceY = 6



local counters = {}
local onPlatform = {}
local platform = workspace.zadanie1.platform

local minX = math.floor(platform.Position.X - platform.Size.X/2)-1
local maxX = math.floor(platform.Position.X + platform.Size.X/2)+1
local minZ = math.floor(platform.Position.Z - platform.Size.Z/2)-1
local maxZ = math.floor(platform.Position.Z + platform.Size.Z/2)+1

local points

local textLabel = workspace.zadanie1.SurfaceGui.Frame.TextLabel2

platform.Touched:Connect(function(hit)
	local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
	if plr and not onPlatform[plr] then
		onPlatform[plr] = true
		
		
		if counters[plr] then
			counters[plr] = counters[plr] + 1
			textLabel.Text = "touches: " .. counters[plr]
		else
			counters[plr] = 1
		end
		
		local points1 = counters[plr]
		task.delay(2, function()
			local points2 = counters[plr]
			if onPlatform[plr] and points1 == points2 then
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local spawn = workspace:FindFirstChild("SpawnLocation")
					hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
					onPlatform[plr] = false
				end
			end
		end)
		
	end
end)




platform.TouchEnded:Connect(function(hit)
    local plr = Players:GetPlayerFromCharacter(hit.Parent)
    if not (plr and onPlatform[plr]) then return end

    task.delay(0.12, function()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local pos = hrp.Position
        
        local outsideRect = (pos.X < minX) or (pos.X > maxX) or (pos.Z < minZ) or (pos.Z > maxZ)
		local yFar = math.abs(pos.Y - platform.Position.Y) > (platform.Size.Y/2 + toleranceY)

		if outsideRect or yFar then
			
            onPlatform[plr] = false
        end
    end)
end)