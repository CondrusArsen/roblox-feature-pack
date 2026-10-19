--3)[невозможно] мы хотим чтобы каждый 5 раз когда игрока телепортирует на SpawnLocation его не телепортировало а убивало


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

local teleportScore = {}

platform.Touched:Connect(function(hit)
	local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
	if plr and not onPlatform[plr] and plr.Character.Humanoid.Health ~= 0 then
		onPlatform[plr] = true
		
		
		if counters[plr] then
			counters[plr] = counters[plr] + 1
			textLabel.Text = "touches: " .. counters[plr]
		else
			counters[plr] = 1
			textLabel.Text = "touches: " .. counters[plr]
		end
		
		local points1 = counters[plr]
		task.delay(2, function()
			local points2 = counters[plr]
			if not teleportScore[plr] then
				teleportScore[plr] = 1
			end
			if onPlatform[plr] and points1 == points2 then
				if teleportScore[plr] % 5 == 0 then
					local char = plr.Character
					local hum = char and char:FindFirstChild("Humanoid")
					if hum then
						hum.Health = 0
						teleportScore[plr] += 1
						onPlatform[plr] = false
					end
				else
					local char = plr.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if hrp then
						local spawn = workspace:FindFirstChild("SpawnLocation")
						hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
						onPlatform[plr] = false
						teleportScore[plr] += 1
					end
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

Players.PlayerRemoving:Connect(function(plr)
	counters[plr] = nil
	onPlatform[plr] = nil
	teleportScore[plr] = nil
end)