--!strict
-- Pure per-player checkpoint rules for Task 3:
-- activating a new checkpoint hides the previous one; once only the current
-- checkpoint is left visible, every checkpoint becomes visible again.

local CheckpointCycle = {}

export type State = {
	current: number?,
	hidden: { [number]: boolean },
}

function CheckpointCycle.newState(): State
	return { current = nil, hidden = {} }
end

function CheckpointCycle.isAvailable(state: State, id: number): boolean
	return id ~= state.current and not state.hidden[id]
end

-- Returns true if the state changed.
function CheckpointCycle.activate(state: State, id: number, total: number): boolean
	if not CheckpointCycle.isAvailable(state, id) then
		return false
	end

	local previous = state.current
	if previous ~= nil then
		state.hidden[previous] = true
	end
	state.current = id

	local hiddenCount = 0
	for _ in state.hidden do
		hiddenCount += 1
	end
	if total - hiddenCount <= 1 then
		state.hidden = {}
	end
	return true
end

-- Encodes hidden ids as a sorted comma-separated string, so it fits in a player attribute.
function CheckpointCycle.encodeHidden(state: State): string
	local ids = {}
	for id in state.hidden do
		table.insert(ids, id)
	end
	table.sort(ids)
	local parts = {}
	for _, id in ids do
		table.insert(parts, tostring(id))
	end
	return table.concat(parts, ",")
end

function CheckpointCycle.decodeHidden(encoded: string): { [number]: boolean }
	local hidden = {}
	for token in string.gmatch(encoded, "%d+") do
		local id = tonumber(token)
		if id ~= nil then
			hidden[id] = true
		end
	end
	return hidden
end

return CheckpointCycle
