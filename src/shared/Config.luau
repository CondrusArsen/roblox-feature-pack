--!strict
-- Tunable values, attribute names and map instance names shared by server and client.
-- Map names (zadanie1, "Zadanie 3", Zadanie4, Zadanie2) come from Testovoe.rbxl and are kept as-is.

local Config = {}

Config.Attributes = {
	PlateTouches = "PlateTouches",
	Clicks = "Clicks",
	HiddenCheckpoints = "HiddenCheckpoints",
	CheckpointId = "CheckpointId",
}

Config.Task1 = {
	MapPart = "zadanie1",
	Plate = "platform",
	StandSeconds = 2,
	KillEveryNthTrigger = 5,
	PollInterval = 0.1,
	-- Extra studs around the plate edges that still count as "on the plate".
	EdgePadding = 1,
	-- How far above the plate the root part may be (covers jumping in place).
	HeightTolerance = 12,
	SpawnHeightOffset = 5,
}

Config.Task2 = {
	GuiName = "Zadanie2",
	KillEveryNthClick = 20,
	DataStoreName = "ClickCounter_v1",
	SaveAttempts = 3,
	RetryDelaySeconds = 1,
	AutosaveSeconds = 60,
	-- Token bucket: short bursts up to BurstSize, sustained rate of RefillPerSecond clicks.
	BurstSize = 10,
	RefillPerSecond = 8,
}

Config.Task3 = {
	Folder = "Zadanie 3",
	CheckpointTag = "checkpoints",
	KillPartTag = "killparts",
	RespawnHeightOffset = 5,
}

Config.Task4 = {
	Folder = "Zadanie4",
	Mover = "mover",
	Spinner = "spiner",
	MoveSeconds = 2,
	SpinDegreesPerSecond = 36,
}

return Config
