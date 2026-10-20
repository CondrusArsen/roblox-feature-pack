--!strict
-- Task 2: GUI click counter with saves.
--   1. The client only sends "I clicked" (no payload). The server owns the count.
--   2. Requests are rate-limited per player; every 20th accepted click kills the player.
--   3. The count is loaded with retries, saved with UpdateAsync on leave, on autosave and on shutdown.
-- The count is replicated through a player attribute, so the GUI can read the current value at any
-- time and there is no race between the GUI starting and the first data response.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local Retry = require(Shared:WaitForChild("Retry"))

local settings = Config.Task2
local clickRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClickRequest") :: RemoteEvent

type Session = {
	clicks: number,
	loaded: boolean,
	-- False when loading failed: saving would overwrite real data with 0.
	canSave: boolean,
	dirty: boolean,
}

local sessions: { [Player]: Session } = {}
local limiter = RateLimiter.new(settings.BurstSize, settings.RefillPerSecond)

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(settings.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[Task2] DataStore unavailable, clicks will not persist:", result)
	end
end

local function keyFor(player: Player): string
	-- Same key format the original version produced (numeric UserId), so old saves still load.
	return tostring(player.UserId)
end

local function yield(seconds: number)
	task.wait(seconds)
end

-- Number of UpdateAsync calls in flight; BindToClose waits for them.
local activeSaves = 0

local function load(player: Player)
	local session: Session = { clicks = 0, loaded = false, canSave = false, dirty = false }
	sessions[player] = session

	local dataStore = store
	if dataStore then
		local ok, result = Retry.call(function()
			return dataStore:GetAsync(keyFor(player))
		end, settings.SaveAttempts, settings.RetryDelaySeconds, yield)

		if ok then
			if typeof(result) == "number" and result >= 0 then
				session.clicks = math.floor(result)
			end
			session.canSave = true
		else
			warn("[Task2] Failed to load clicks for", player.Name, result)
		end
	end

	if sessions[player] ~= session then
		return -- player left while loading
	end
	session.loaded = true
	player:SetAttribute(Config.Attributes.Clicks, session.clicks)
end

local function save(player: Player, session: Session)
	local dataStore = store
	if dataStore == nil or not session.canSave or not session.dirty then
		return
	end

	local clicks = session.clicks
	activeSaves += 1
	local ok, result = Retry.call(function()
		return dataStore:UpdateAsync(keyFor(player), function(stored: any)
			-- Clicks only grow; never let a stale session overwrite a higher stored value.
			if typeof(stored) == "number" and stored > clicks then
				return nil
			end
			return clicks
		end)
	end, settings.SaveAttempts, settings.RetryDelaySeconds, yield)
	activeSaves -= 1

	if ok then
		if session.clicks == clicks then
			session.dirty = false
		end
	else
		warn("[Task2] Failed to save clicks for", player.Name, result)
	end
end

clickRequest.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if session == nil or not session.loaded then
		return
	end
	if not limiter:tryConsume(player, os.clock()) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return
	end

	session.clicks += 1
	session.dirty = true
	player:SetAttribute(Config.Attributes.Clicks, session.clicks)

	if session.clicks % settings.KillEveryNthClick == 0 then
		humanoid.Health = 0
	end
end)

Players.PlayerAdded:Connect(load)
for _, player in Players:GetPlayers() do
	task.spawn(load, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	local session = sessions[player]
	sessions[player] = nil
	limiter:forget(player)
	if session then
		save(player, session)
	end
end)

task.spawn(function()
	while true do
		task.wait(settings.AutosaveSeconds)
		for player, session in sessions do
			task.spawn(save, player, session)
		end
	end
end)

game:BindToClose(function()
	for player, session in sessions do
		task.spawn(save, player, session)
	end

	-- Also covers saves started by PlayerRemoving during shutdown. Roblox allows ~30 s here.
	local deadline = os.clock() + 25
	repeat
		task.wait(0.1)
	until activeSaves == 0 or os.clock() > deadline
end)
