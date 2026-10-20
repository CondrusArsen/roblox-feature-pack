--!strict
-- Task 1 (client): shows the local player's own touch counter on the sign.
-- The server never writes this label, so every player sees their own number.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local sign = workspace:WaitForChild(Config.Task1.MapPart)
local label = sign:WaitForChild("SurfaceGui"):WaitForChild("Frame"):WaitForChild("TextLabel2") :: TextLabel

local function render()
	local touches = player:GetAttribute(Config.Attributes.PlateTouches)
	label.Text = string.format("touches: %d", if typeof(touches) == "number" then touches else 0)
end

player:GetAttributeChangedSignal(Config.Attributes.PlateTouches):Connect(render)
render()
