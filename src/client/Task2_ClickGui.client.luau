--!strict
-- Task 2 (client): sends click intent and renders the server-owned count.
-- The GUI has ResetOnSpawn enabled, so it is re-bound every time a new copy appears in PlayerGui.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local clickRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClickRequest") :: RemoteEvent

local connections: { RBXScriptConnection } = {}

local function disconnectAll()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function render(label: TextLabel)
	local clicks = player:GetAttribute(Config.Attributes.Clicks)
	if typeof(clicks) == "number" then
		label.Text = string.format("presses: %d", clicks)
	else
		label.Text = "loading..."
	end
end

local function bind(gui: Instance)
	disconnectAll()

	local frame = gui:WaitForChild("Frame")
	local button = frame:WaitForChild("TextButton") :: TextButton
	local label = frame:WaitForChild("TextLabel") :: TextLabel

	render(label)
	table.insert(
		connections,
		player:GetAttributeChangedSignal(Config.Attributes.Clicks):Connect(function()
			render(label)
		end)
	)
	table.insert(
		connections,
		button.Activated:Connect(function()
			clickRequest:FireServer()
		end)
	)
end

playerGui.ChildAdded:Connect(function(child: Instance)
	if child.Name == Config.Task2.GuiName then
		bind(child)
	end
end)

local existing = playerGui:FindFirstChild(Config.Task2.GuiName)
if existing then
	bind(existing)
end
