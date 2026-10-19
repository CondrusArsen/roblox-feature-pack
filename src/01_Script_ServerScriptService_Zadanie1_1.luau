--1)[легко] мы хотим чтобы счетчик увеличивался каждый раз когда игрок заходит на плиту, и пока он там ходит счетчик увеличиваться не должен


local Players = game:GetService("Players")

local ToleranceY = 6

local counters = {}
local onPlatform = {}
local platform = workspace.zadanie1.platform

local minX = math.floor(platform.Position.X - platform.Size.X/2)-1
local maxX = math.floor(platform.Position.X + platform.Size.X/2)+1
local minZ = math.floor(platform.Position.Z - platform.Size.Z/2)-1
local maxZ = math.floor(platform.Position.Z + platform.Size.Z/2)+1



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
		local yFar = math.abs(pos.Y - platform.Position.Y) > (platform.Size.Y/2 + ToleranceY)

        if outsideRect or yFar then
            onPlatform[plr] = false
        end
    end)
end)