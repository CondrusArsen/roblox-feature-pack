local Players = game:GetService("Players")

local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("ClickCounter_v1")

local KillEvent = game.ReplicatedStorage:WaitForChild("KillEvent")
local ClickEvent = game.ReplicatedStorage:WaitForChild("ClickEvent")
local StoreEvent = game.ReplicatedStorage:WaitForChild("StoreEvent")

local clicks = {}


KillEvent.OnServerEvent:Connect(function(plr)
	local char = plr.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if hum then
		plr.PlayerGui:WaitForChild("Zadanie2").Enabled = false
		hum.Health = 0
	end
end)

ClickEvent.OnServerEvent:Connect(function(plr, clk)
	clicks[plr] = clk
end)

Players.PlayerAdded:Connect(function(plr)
	local success, data = pcall(function()
		return store:GetAsync(plr.UserId)
	end)
	if success and data then
		clicks[plr] = data
	else
		clicks[plr] = 0
	end
	StoreEvent:FireClient(plr, clicks[plr])
end)

Players.PlayerRemoving:Connect(function(plr)
	local success, err = pcall(function()
		store:SetAsync(plr.UserId, clicks[plr])
	end)
	if not success then
		warn("Failed to save data for", plr.Name, ":", err)
	end
	
end)