--!strict
-- Unit tests for the pure shared modules. Run with: lune run tests/run

local CheckpointCycle = require("../src/shared/CheckpointCycle")
local PressurePlate = require("../src/shared/PressurePlate")
local RateLimiter = require("../src/shared/RateLimiter")
local Retry = require("../src/shared/Retry")

local failures = 0
local passed = 0

local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failures += 1
		print("FAIL " .. name .. ": " .. tostring(err))
	end
end

local function equal(actual: any, expected: any, message: string?)
	if actual ~= expected then
		error(
			string.format("%s: expected %s, got %s", message or "value", tostring(expected), tostring(actual)),
			2
		)
	end
end

-- Task 1 ------------------------------------------------------------------

test("plate counts one touch per visit", function()
	local state = PressurePlate.newState()
	local touched = PressurePlate.step(state, true, 0, 2, 5)
	equal(touched, true, "first frame on plate")
	for t = 1, 10 do
		touched = PressurePlate.step(state, true, t * 0.1, 2, 5)
		equal(touched, false, "still on plate")
	end
	PressurePlate.step(state, false, 1.1, 2, 5)
	touched = PressurePlate.step(state, true, 1.2, 2, 5)
	equal(touched, true, "second visit")
	equal(state.touches, 2, "touches")
end)

test("plate teleports after standing for 2 seconds, once per visit", function()
	local state = PressurePlate.newState()
	local _, action = PressurePlate.step(state, true, 0, 2, 5)
	equal(action, nil)
	_, action = PressurePlate.step(state, true, 1.9, 2, 5)
	equal(action, nil)
	_, action = PressurePlate.step(state, true, 2.0, 2, 5)
	equal(action, "teleport")
	_, action = PressurePlate.step(state, true, 5.0, 2, 5)
	equal(action, nil, "no repeat while still inside")
end)

test("leaving early cancels the teleport", function()
	local state = PressurePlate.newState()
	PressurePlate.step(state, true, 0, 2, 5)
	PressurePlate.step(state, false, 1, 2, 5)
	local _, action = PressurePlate.step(state, true, 1.5, 2, 5)
	equal(action, nil)
	_, action = PressurePlate.step(state, true, 3.0, 2, 5)
	equal(action, nil, "timer restarted on re-entry")
	_, action = PressurePlate.step(state, true, 3.5, 2, 5)
	equal(action, "teleport")
end)

test("every 5th trigger kills instead of teleporting", function()
	local state = PressurePlate.newState()
	local actions = {}
	local now = 0
	for _ = 1, 10 do
		PressurePlate.step(state, true, now, 2, 5)
		local _, action = PressurePlate.step(state, true, now + 2, 2, 5)
		table.insert(actions, action)
		PressurePlate.step(state, false, now + 2.1, 2, 5)
		now += 3
	end
	for i, action in actions do
		equal(action, if i % 5 == 0 then "kill" else "teleport", "trigger " .. i)
	end
end)

test("plate bounds use padding and height tolerance", function()
	equal(PressurePlate.contains(0, 3, 0, 17, 1, 12, 1, 12), true, "standing in the middle")
	equal(PressurePlate.contains(9.4, 3, 0, 17, 1, 12, 1, 12), true, "within edge padding")
	equal(PressurePlate.contains(9.6, 3, 0, 17, 1, 12, 1, 12), false, "outside edge padding")
	equal(PressurePlate.contains(0, 12, 0, 17, 1, 12, 1, 12), true, "jumping")
	equal(PressurePlate.contains(0, 13, 0, 17, 1, 12, 1, 12), false, "too high")
	equal(PressurePlate.contains(0, -1, 0, 17, 1, 12, 1, 12), false, "below the plate")
end)

-- Task 2 ------------------------------------------------------------------

test("rate limiter allows a burst then refills over time", function()
	local limiter = RateLimiter.new(3, 2)
	equal(limiter:tryConsume("a", 0), true)
	equal(limiter:tryConsume("a", 0), true)
	equal(limiter:tryConsume("a", 0), true)
	equal(limiter:tryConsume("a", 0), false, "burst exhausted")
	equal(limiter:tryConsume("b", 0), true, "keys are independent")
	equal(limiter:tryConsume("a", 0.4), false, "0.8 tokens is not enough")
	equal(limiter:tryConsume("a", 0.5), true, "1 token after 0.5 s")
	equal(limiter:tryConsume("a", 100), true)
	equal(limiter:tryConsume("a", 100), true)
	equal(limiter:tryConsume("a", 100), true)
	equal(limiter:tryConsume("a", 100), false, "refill is capped at capacity")
end)

test("rate limiter caps an autoclicker at the refill rate", function()
	local limiter = RateLimiter.new(10, 8)
	local accepted = 0
	for i = 0, 999 do
		if limiter:tryConsume("p", i / 100) then -- 100 requests per second for 10 s
			accepted += 1
		end
	end
	assert(accepted <= 10 + 8 * 10 + 1, "accepted " .. accepted)
	assert(accepted >= 8 * 10, "accepted " .. accepted)
end)

test("retry returns the first success and backs off between attempts", function()
	local waits = {}
	local calls = 0
	local ok, result = Retry.call(
		function()
			calls += 1
			if calls < 3 then
				error("throttled")
			end
			return 42
		end,
		3,
		1,
		function(seconds)
			table.insert(waits, seconds)
		end
	)
	equal(ok, true)
	equal(result, 42)
	equal(#waits, 2)
	equal(waits[1], 1)
	equal(waits[2], 2)
end)

test("retry gives up after the last attempt", function()
	local calls = 0
	local ok, result = Retry.call(function(): number
		calls += 1
		error("down")
	end, 3, 1, function() end)
	equal(ok, false)
	equal(calls, 3)
	assert(string.find(tostring(result), "down"), "error message kept")
end)

-- Task 3 ------------------------------------------------------------------

test("checkpoints: previous one hides, all reappear when one is left", function()
	local state = CheckpointCycle.newState()
	equal(CheckpointCycle.activate(state, 1, 3), true)
	equal(CheckpointCycle.encodeHidden(state), "")
	equal(CheckpointCycle.activate(state, 1, 3), false, "same checkpoint again")
	equal(CheckpointCycle.activate(state, 2, 3), true)
	equal(CheckpointCycle.encodeHidden(state), "1")
	equal(CheckpointCycle.activate(state, 1, 3), false, "hidden checkpoint cannot be used")
	equal(CheckpointCycle.activate(state, 3, 3), true)
	equal(CheckpointCycle.encodeHidden(state), "", "only #3 was left, so everything is visible again")
	equal(state.current, 3)
end)

test("checkpoint state is independent per player", function()
	local a = CheckpointCycle.newState()
	local b = CheckpointCycle.newState()
	CheckpointCycle.activate(a, 1, 7)
	CheckpointCycle.activate(a, 2, 7)
	equal(CheckpointCycle.isAvailable(b, 1), true)
	equal(CheckpointCycle.isAvailable(a, 1), false)
end)

test("hidden set round-trips through the attribute string", function()
	local state = CheckpointCycle.newState()
	state.hidden = { [5] = true, [2] = true, [11] = true }
	local encoded = CheckpointCycle.encodeHidden(state)
	equal(encoded, "2,5,11")
	local decoded = CheckpointCycle.decodeHidden(encoded)
	equal(decoded[2] and decoded[5] and decoded[11], true)
	equal(decoded[3], nil)
	equal(next(CheckpointCycle.decodeHidden("")), nil)
end)

print(string.format("%d passed, %d failed", passed, failures))
if failures > 0 then
	error("tests failed")
end
