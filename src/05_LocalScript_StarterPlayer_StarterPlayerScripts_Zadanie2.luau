local plr = game.Players.LocalPlayer
local counter
local KillEvent = game.ReplicatedStorage:WaitForChild("KillEvent")
local ClickEvent = game.ReplicatedStorage:WaitForChild("ClickEvent")
local StoreEvent = game.ReplicatedStorage:WaitForChild("StoreEvent")

StoreEvent.OnClientEvent:Connect(function(clicks)
	counter = clicks
	print(clicks)
	
end)


local function setupGui()
	local button = plr.PlayerGui:WaitForChild("Zadanie2").Frame.TextButton
	local label = plr.PlayerGui.Zadanie2.Frame.TextLabel
	label.Text = "presses: "..counter
	button.Activated:Connect(function()
	counter += 1
	label.Text = "presses: "..counter
	ClickEvent:FireServer(counter)
	if counter % 20 == 0 then
			KillEvent:FireServer()
	end 
end)
end

setupGui()

plr.CharacterAdded:Connect(function()
	task.wait(0.5)
	setupGui()
end)


---Оставил подсчет кликов у клиента, так как это было в заготовке кода. Правильнее подсчитывать все же на сервере