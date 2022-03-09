-- PlayerCache
-- MrAsync
-- 02/25/2022


local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local PlayerCache = {}
PlayerCache.__index = PlayerCache

function PlayerCache.new(player: Player)
	local self = setmetatable({}, PlayerCache)
	
	self._Player = player
	self._CacheValues = {}

	return self
end

function PlayerCache:SetCacheValue(key: string, value: any): nil
	assert(key and typeof(key) == "string", "Expected key: string!")
	assert(value ~= nil, "Expected value: any!")

	self._CacheValues[key] = value
end

function PlayerCache:GetCacheValue(key: string, defaultValue: any): any
	local cacheValue = self._CacheValues[key]
	if (cacheValue == nil and defaultValue ~= nil) then
		self:SetCacheValue(key, defaultValue)

		return self._CacheValues[key]
	end

	return cacheValue
end

function PlayerCache:RemoveCacheValue(key: string): any
	local cacheValue = self:GetCacheValue(key)

	self._CacheValues[key] = nil

	return cacheValue
end

return PlayerCache