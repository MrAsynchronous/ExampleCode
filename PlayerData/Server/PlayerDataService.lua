-- PlayerDataService
-- MrAsync
-- 02/01/2022

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)
local Players = game:GetService('Players')

local DataStoreService = game:GetService("DataStoreService")

local PlayerDataConfig = SuperStack:GetModule("PlayerDataConfig")
local PlayerProfile = SuperStack:GetModule("PlayerDataProfile")
local NetworkService = SuperStack:GetModule("NetworkService")
local PlayerService = SuperStack:GetModule("PlayerService")
local PlayerCache = SuperStack:GetModule("PlayerCache")
local Promise = SuperStack:GetModule("Promise")
local Signal = SuperStack:GetModule("Signal")
local Table = SuperStack:GetModule("Table")

local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService

function PlayerDataService.new()
	local self = setmetatable({}, PlayerDataService)

	self.PlayerProfileAdded = Signal.new()
	self.PlayerProfileRemoved = Signal.new()

	self._DataStore = DataStoreService:GetDataStore(PlayerDataConfig.DataStoreKey)
	self._PlayerProfiles = {}
	self._PlayerCaches = {}
	self._PlayersSaving = {}
	self._GameIsClosing = false

	self._KeyMergeCallbacks = {}

	return self
end

function PlayerDataService:GetPlayerProfile(player: Player)
	local profile = self._PlayerProfiles[player]
	
	while (not profile) do
		task.wait()

		profile = self._PlayerProfiles[player]
	end

	return profile
end

function PlayerDataService:FetchUserData(user: Player | number, ignoreNil: boolean?): any
	return Promise.new(function(resolve, reject)
		local player = if (typeof(user) == "number") then {UserId = user} else user

		local success, response, wasNil = self:_FetchUserData(player, 0, ignoreNil)
		
		if (not success) then
			return reject(response)
		end
		
		return resolve(response, wasNil)
	end)
end

function PlayerDataService:UpdateUserData(user: Player | number, callback: (any) -> any): any
	return Promise.new(function(resolve, reject)
		local player = if (typeof(user) == "number") then {UserId = user} else user

		local newData = self._DataStore:UpdateAsync(tostring(player.UserId), function(currentData)
			local success, newData = pcall(callback, currentData)

			if ((not success) or (newData == nil)) then
				reject(newData)

				return currentData
			end

			return newData
		end)

		return resolve(newData)
	end)
end

function PlayerDataService:SetCacheValue(player: Player, key: string, value: any): nil
	local cacheProfile = self:GetPlayerCache(player)
	if (not cacheProfile) then return end
		
	return cacheProfile:SetCacheValue(key, value)
end

function PlayerDataService:GetCacheValue(player: Player, key: string, defaultValue: any?): any
	local cacheProfile = self:GetPlayerCache(player)
	if (not cacheProfile) then return end

	return cacheProfile:GetCacheValue(key, defaultValue)
end

function PlayerDataService:UpdateCacheValue(player: Player, key: string, callback: (any) -> any): nil
	local cacheProfile = self:GetPlayerCache(player)
	if (not cacheProfile) then return end

	local success, response = pcall(callback, cacheProfile:GetCacheValue(key))

	if (success) then
		cacheProfile:SetCacheValue(key, response)
	end

	return
end

function PlayerDataService:RemoveCacheValue(player: Player, key: string): any
	local cacheProfile = self:GetPlayerCache(player)
	if (not cacheProfile) then return end

	return cacheProfile:RemoveCacheValue(key)
end

function PlayerDataService:GetPlayerCache(player: Player): any
	return self._PlayerCaches[player]
end

function PlayerDataService:SetKeyMergeCallback(key: string, callback: (any) -> any)
	assert(key and typeof(key) == "string", "Invalid key!")
	assert(callback and typeof(callback) == "function", "Invalid calback!")

	self._KeyMergeCallbacks[key] = callback
end

function PlayerDataService:Initialize()
	NetworkService:RegisterEvent("PlayerDataGateway", function(player)
		local profile = self:GetPlayerProfile(player)
		local clientSafeData = {}

		-- Only clone non-hidden data
		for key, value in pairs(profile:GetMutableData()) do
			if (table.find(PlayerDataConfig.DataReplicationIgnoreList, key)) then
				continue
			end

			clientSafeData[key] = value
		end

		-- Ping pong back to client
		NetworkService:FireClient(
			"PlayerDataGateway",
			player,
			"DataSchema",
			clientSafeData
		)
	end)

	-- Fetch userdata when player joins
	PlayerService.PlayerAdded:Connect(function(player)
		local cache = PlayerCache.new(player)
		self._PlayerCaches[player] = cache

		-- Fetch user data
		self:FetchUserData(player):andThen(function(cloudData, wasNil)
			-- Create and store new profile
			local profile = PlayerProfile.new(player, cloudData, self._DataStore, self._KeyMergeCallbacks)
			self._PlayerProfiles[player] = profile

			-- Update total visits
			profile:UpdateData("TotalVisits", function(totalVisits)
				return totalVisits + 1
			end)

			-- Save immediately
			if (wasNil) then
				profile:Save(true)
			end

			-- Send signal to listeners
			self.PlayerProfileAdded:Fire(profile)
		end):catch(function(err)
			return warn(err)
		end):await()
	end)

	-- Cleanup PlayerProfile when player leaves
	PlayerService.PlayerRemoving:Connect(function(player)

		-- Grab profile
		local profile = self:GetPlayerProfile(player)
		if (not profile) then return end

		-- Save user data
		profile:Save():finally(function()
			self._PlayerProfiles[player] = nil
			self._PlayerCaches[player] = nil
			profile:Destroy()

			self.PlayerProfileRemoved:Fire(player)
		end):await()
	end)

	game:BindToClose(function()
		local promiseStack = {
			Promise.new(function(resolve, reject)
				task.wait(2)

				return resolve()
			end)
		}

		for _, player in pairs(Players:GetPlayers()) do
			local profile = self:GetPlayerProfile(player)
			if (not profile) then continue end
		
			table.insert(promiseStack, profile:Save())
		end

		Promise.all(promiseStack):await()
	end)
end

function PlayerDataService:_FetchUserData(player: Player, retries: number, ignoreNil: boolean?): any
	-- Query DataBase
	local success, response = pcall(function()
		return self._DataStore:GetAsync(tostring(player.UserId))
	end)

	-- Handle error
	if (not success) then
		if (retries + 1 > PlayerDataConfig.MaxRetries) then
			return false, response
		end

		task.wait(PlayerDataConfig.RetryDelay)

		return self:_FetchUserData(player, retries + 1)
	end

	if (response == nil and (not ignoreNil)) then
		return true, Table.deepCopy(PlayerDataConfig.DataSchema), true
	end

	return true, self:_ReconcileUserData(response)
end

function PlayerDataService:_ReconcileUserData(userData: {[string]: any}): {[string]: any} | nil
	if (not userData) then return end

	for service, sheet in pairs(Table.deepCopy(PlayerDataConfig.DataSchema)) do
		if (userData[service] == nil) then
			userData[service] = sheet

			continue
		end

		if (typeof(sheet) ~= "table") then continue end

		for key, value in pairs(sheet) do
			if (userData[service][key] ~= nil) then continue end
				
			userData[service][key] = value
		end
	end

	userData.SchemaVersion = PlayerDataConfig.DataSchema.SchemaVersion

	return userData
end

local Singleton = PlayerDataService.new()
return Singleton