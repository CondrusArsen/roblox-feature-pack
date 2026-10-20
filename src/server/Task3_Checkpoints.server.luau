--!strict
-- Task 3: kill parts and checkpoints.
--   1. Parts tagged "killparts" (the red floor) kill on touch.
--   2. Parts tagged "checkpoints" save the player's respawn point.
--   3. Activating a new checkpoint hides the previous one; when only one is left, all reappear.
-- Checkpoint progress is per player: the server keeps each player's state and replicates the
-- hidden set through a player attribute; Task3_CheckpointVisibility.client hides parts locally.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CheckpointCycle = require(Shared:WaitForChild("CheckpointCycle"))

local settings = Config.Task3

local checkpointsById: { [number]: BasePart } = {}
local checkpointCount = 0
local states: { [Player]: CheckpointCycle.State } = {}

local function getAliveHumanoid(hit: BasePart): (Player?, Humanoid?)
	local character = hit.Parent
	if character == nil then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return nil, nil
	end
	return Players:GetPlayerFromCharacter(character), humanoid
end

local function getState(player: Player): CheckpointCycle.State
	local state = states[player]
	if state == nil then
		state = CheckpointCycle.newState()
		states[player] = state
	end
	return state
end

local function onCheckpointTouched(id: number, hit: BasePart)
	local player = getAliveHumanoid(hit)
	if player == nil then
		return
	end
	local state = getState(player)
	if CheckpointCycle.activate(state, id, checkpointCount) then
		player:SetAttribute(Config.Attributes.HiddenCheckpoints, CheckpointCycle.encodeHidden(state))
	end
end

local function onKillPartTouched(hit: BasePart)
	local _, humanoid = getAliveHumanoid(hit)
	if humanoid then
		humanoid.Health = 0
	end
end

-- Stable ids: sort by position so the order does not depend on GetTagged ordering.
local function registerCheckpoints()
	local parts: { BasePart } = {}
	for _, instance in CollectionService:GetTagged(settings.CheckpointTag) do
		if instance:IsA("BasePart") then
			table.insert(parts, instance)
		end
	end
	table.sort(parts, function(a: BasePart, b: BasePart)
		if a.Position.X ~= b.Position.X then
			return a.Position.X < b.Position.X
		end
		return a.Position.Z < b.Position.Z
	end)

	for id, part in parts do
		checkpointsById[id] = part
		part:SetAttribute(Config.Attributes.CheckpointId, id)
		part.Touched:Connect(function(hit: BasePart)
			onCheckpointTouched(id, hit)
		end)
	end
	checkpointCount = #parts
end

local function bindKillPart(instance: Instance)
	if instance:IsA("BasePart") then
		instance.Touched:Connect(onKillPartTouched)
	end
end

local function respawnAtCheckpoint(player: Player, character: Model)
	local state = states[player]
	local checkpoint = state and state.current and checkpointsById[state.current]
	if checkpoint == nil then
		return -- default SpawnLocation behaviour
	end

	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if rootPart == nil or character.Parent == nil then
		return
	end
	local target = checkpoint.Position
		+ Vector3.new(0, checkpoint.Size.Y / 2 + settings.RespawnHeightOffset, 0)
	-- Deferred so the default spawn placement does not override our position.
	task.defer(function()
		character:PivotTo(CFrame.new(target))
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		respawnAtCheckpoint(player, character)
	end)
end

registerCheckpoints()
for _, instance in CollectionService:GetTagged(settings.KillPartTag) do
	bindKillPart(instance)
end
CollectionService:GetInstanceAddedSignal(settings.KillPartTag):Connect(bindKillPart)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	states[player] = nil
end)
