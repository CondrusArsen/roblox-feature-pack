--!strict
-- Calls `fn` in pcall up to `attempts` times with linear backoff.
-- `wait` is injected (task.wait in game, a stub in tests).

local Retry = {}

function Retry.call<T>(
	fn: () -> T,
	attempts: number,
	delaySeconds: number,
	wait: (number) -> ()
): (boolean, T | string)
	local lastError = "no attempts made"
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = tostring(result)
		if attempt < attempts then
			wait(delaySeconds * attempt)
		end
	end
	return false, lastError
end

return Retry
