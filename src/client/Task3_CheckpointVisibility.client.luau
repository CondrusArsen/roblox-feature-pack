--!strict
-- Task 3 (client): hides this player's used checkpoints locally.
-- Other players keep seeing their own set. Tagged parts are tracked through CollectionService
-- signals because the place uses streaming and parts can arrive after this script starts.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CheckpointCycle = require(Shared:WaitForChild("CheckpointCycle"))

local player = Players.LocalPlayer
local tag = Config.Task3.CheckpointTag
local idAttribute = Config.Attributes.CheckpointId
local hiddenAttribute = Config.Attributes.HiddenCheckpoints

local function hiddenSet(): { [number]: boolean }
	local encoded = player:GetAttribute(hiddenAttribute)
	return CheckpointCycle.decodeHidden(if typeof(encoded) == "string" then encoded else "")
end

local function apply(part: BasePart, hidden: { [number]: boolean })
	local id = part:GetAttribute(idAttribute)
	local isHidden = typeof(id) == "number" and hidden[id] == true
	part.LocalTransparencyModifier = if isHidden then 1 else 0
	part.CanCollide = not isHidden
	part.CanTouch = not isHidden
end

local function applyAll()
	local hidden = hiddenSet()
	for _, instance in CollectionService:GetTagged(tag) do
		if instance:IsA("BasePart") then
			apply(instance, hidden)
		end
	end
end

local function onCheckpointAdded(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	apply(instance, hiddenSet())
	-- The server assigns ids at startup; re-apply if the id arrives after the part.
	instance:GetAttributeChangedSignal(idAttribute):Connect(function()
		apply(instance, hiddenSet())
	end)
end

CollectionService:GetInstanceAddedSignal(tag):Connect(onCheckpointAdded)
for _, instance in CollectionService:GetTagged(tag) do
	onCheckpointAdded(instance)
end
player:GetAttributeChangedSignal(hiddenAttribute):Connect(applyAll)
