--!strict
-- Pure rules for Task 1. No Roblox APIs, so the module is unit-tested with Lune.

local PressurePlate = {}

export type State = {
	inside: boolean,
	armed: boolean,
	enteredAt: number,
	touches: number,
	triggers: number,
}

export type Action = "teleport" | "kill"

function PressurePlate.newState(): State
	return {
		inside = false,
		armed = false,
		enteredAt = 0,
		touches = 0,
		triggers = 0,
	}
end

-- `x`, `y`, `z` are the root part position in the plate's object space.
function PressurePlate.contains(
	x: number,
	y: number,
	z: number,
	sizeX: number,
	sizeY: number,
	sizeZ: number,
	edgePadding: number,
	heightTolerance: number
): boolean
	local insideX = math.abs(x) <= sizeX / 2 + edgePadding
	local insideZ = math.abs(z) <= sizeZ / 2 + edgePadding
	local insideY = y >= -sizeY / 2 and y <= sizeY / 2 + heightTolerance
	return insideX and insideZ and insideY
end

-- Advances one player's state. Returns whether the touch counter changed and the action to run.
function PressurePlate.step(
	state: State,
	inside: boolean,
	now: number,
	standSeconds: number,
	killEvery: number
): (boolean, Action?)
	if not inside then
		state.inside = false
		state.armed = false
		return false, nil
	end

	local touched = false
	if not state.inside then
		state.inside = true
		state.armed = true
		state.enteredAt = now
		state.touches += 1
		touched = true
	end

	if state.armed and now - state.enteredAt >= standSeconds then
		state.armed = false
		state.triggers += 1
		if state.triggers % killEvery == 0 then
			return touched, "kill"
		end
		return touched, "teleport"
	end

	return touched, nil
end

return PressurePlate
