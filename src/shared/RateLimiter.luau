--!strict
-- Per-key token bucket. The caller passes the current time, which keeps the module testable.

local RateLimiter = {}
RateLimiter.__index = RateLimiter

type Bucket = { tokens: number, updatedAt: number }

export type RateLimiter = typeof(setmetatable(
	{} :: { capacity: number, refillPerSecond: number, buckets: { [any]: Bucket } },
	RateLimiter
))

function RateLimiter.new(capacity: number, refillPerSecond: number): RateLimiter
	return setmetatable({
		capacity = capacity,
		refillPerSecond = refillPerSecond,
		buckets = {},
	}, RateLimiter)
end

function RateLimiter.tryConsume(self: RateLimiter, key: any, now: number): boolean
	local bucket = self.buckets[key]
	if bucket == nil then
		bucket = { tokens = self.capacity, updatedAt = now }
		self.buckets[key] = bucket
	end

	local elapsed = math.max(0, now - bucket.updatedAt)
	bucket.tokens = math.min(self.capacity, bucket.tokens + elapsed * self.refillPerSecond)
	bucket.updatedAt = now

	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

function RateLimiter.forget(self: RateLimiter, key: any)
	self.buckets[key] = nil
end

return RateLimiter
