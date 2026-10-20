--!strict
-- Task 1: pressure plate.
--   1. The touch counter increases once per visit, not while the player walks around on the plate.
--   2. Standing on the plate for 2 seconds teleports the player to SpawnLocation.
--   3. Every 5th teleport is replaced with the player's death.
--
-- Touched/TouchEnded fire once per body part and flicker while walking, so instead of relying on
-- them the server polls each character's root position against the plate bounds (in plate space).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PressurePlate = require(Shared:WaitForChild("PressurePlate"))

local settings = Config.Task1
local plate = workspace:WaitForChild(settings.MapPart):WaitForChild(settings.Plate) :: BasePart

local states: { [Player]: PressurePlate.State } = {}

local function isOnPlate(rootPart: BasePart): boolean
	local localPosition = plate.CFrame:PointToObjectSpace(rootPart.Position)
	local size = plate.Size
	return PressurePlate.contains(
		localPosition.X,
		localPosition.Y,
		localPosition.Z,
		size.X,
		size.Y,
		size.Z,
		settings.EdgePadding,
		settings.HeightTolerance
	)
end

local function teleportToSpawn(character: Model)
	local spawnLocation = workspace:FindFirstChild("SpawnLocation")
	if spawnLocation and spawnLocation:IsA("BasePart") then
		character:PivotTo(spawnLocation.CFrame + Vector3.new(0, settings.SpawnHeightOffset, 0))
	end
end

local function updatePlayer(player: Player, now: number)
	local state = states[player]
	if state == nil then
		state = PressurePlate.newState()
		states[player] = state
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	local inside = false
	if humanoid and humanoid.Health > 0 and rootPart and rootPart:IsA("BasePart") then
		inside = isOnPlate(rootPart)
	end

	local touched, action =
		PressurePlate.step(state, inside, now, settings.StandSeconds, settings.KillEveryNthTrigger)

	if touched then
		-- Per-player value; the client renders it on the sign (see Task1_PlateLabel.client).
		player:SetAttribute(Config.Attributes.PlateTouches, state.touches)
	end

	if action == "kill" and humanoid then
		humanoid.Health = 0
	elseif action == "teleport" and character then
		teleportToSpawn(character)
	end
end

local elapsed = 0
RunService.Heartbeat:Connect(function(deltaTime: number)
	elapsed += deltaTime
	if elapsed < settings.PollInterval then
		return
	end
	elapsed = 0

	local now = os.clock()
	for _, player in Players:GetPlayers() do
		updatePlayer(player, now)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	states[player] = nil
end)
