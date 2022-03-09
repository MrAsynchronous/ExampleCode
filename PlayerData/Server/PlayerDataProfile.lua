-- PlayerDataProfile
-- MrAsync
-- 02/11/2022


local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local RunService = game:GetService("RunService")

local PlayerDataConfig = SuperStack:GetModule("PlayerDataConfig")
local NetworkService = SuperStack:GetModule("NetworkService")
local SchedulerService = SuperStack:GetModule("SchedulerService")
local Promise = SuperStack:GetModule("Promise")
local Signal = SuperStack:GetModule("Signal")
local Table = SuperStack:GetModule("Table")
local Maid = SuperStack:GetModule("Maid")

local PlayerDataProfile = {}
PlayerDataProfile.__index = PlayerDataProfile

function PlayerDataProfile.new(player: Player, cloudData: {[string]: any}, 
		datastore: GlobalDataStore, keyMergeCallbacks: {[string]: (any) -> any}
	)

	local self = setmetatable({}, PlayerDataProfile)
	self._maid = Maid.new()
	
	self.Player = player

	self.DataChanged = Signal.new()
	self._maid:GiveTask(self.DataChanged)

	self._CloudData = cloudData
	self._MutableData = Table.deepCopy(cloudData)
	self._Datastore = datastore
	self._KeyMergeCallbacks = keyMergeCallbacks

	self._Saving = false

	-- Setup data replication
	self.DataChanged:Connect(function(key, newValue, oldValue)
		if (table.find(PlayerDataConfig.DataReplicationIgnoreList, key)) then
			return
		end

		NetworkService:FireClient(
			"PlayerDataGateway",
			player,
			"DataChanged",
			{
				Key = key,
				NewValue = newValue,
				OldValue = oldValue
			}
		)
	end)

	-- Add autosave task
	SchedulerService:AddTask(
		string.format("Autosave:%s", player.Name), PlayerDataConfig.AutosaveFrequency, function()

			self:Save():catch(function(err)
				warn(string.format("Couldn't autosave data for %s! %s", self.Player.Name, err))
			end)

		end
	)

	return self
end

function PlayerDataProfile:Save(useSetAsync: boolean?)
	return Promise.new(function(resolve, reject)
		local success = self:_Save(0, useSetAsync)

		if (not success) then
			return reject()
		else
			return resolve()
		end
	end)
end

function PlayerDataProfile:GetData(key: string, defaultValue: any?): any
	local data = self._MutableData[key]

	-- Set default value
	if (not data and defaultValue) then
		self._MutableData[key] = defaultValue

		return defaultValue
	end

	return data
end

function PlayerDataProfile:SetData(key: string, value: any, ignoreType: boolean?): boolean
	local data = self:GetData(key)

	-- Compare types
	if ((typeof(data) ~= typeof(value)) and (not ignoreType)) then
		return false
	end

	-- Fire signal that data changed
	if (data ~= value) then
		self.DataChanged:Fire(key, value, data)
	end

	-- Set value
	self._MutableData[key] = value

	return true
end

function PlayerDataProfile:UpdateData(key: string, mutator: (any) -> any): any
	local success, response = pcall(mutator, self:GetData(key))

	-- Handle error
	if (not success) then
		return warn(string.format("Couldn't call mutator on %s!", key, tostring(response)))
	end

	-- Update data
	local success = self:SetData(key, response)
	if (not success) then
		return warn("Coudln't update %s!", key)
	end

	-- Return new data
	return self:GetData(key)
end

function PlayerDataProfile:GetMutableData()
	return Table.deepCopy(self._MutableData)
end

function PlayerDataProfile:GetCloudData()
	return Table.deepCopy(self._CloudData)
end

function PlayerDataProfile:SetCloudData(newCloudData: {[string]: any})
	self._CloudData = Table.deepCopy(newCloudData)
end

function PlayerDataProfile:SetNextSaveTime(newTime)
	self._NextAutosave = newTime
end

function PlayerDataProfile:_Save(retries: number | nil, useSetAsync: boolean?)
	if ((self._Saving and (retries == 0) ) or self.Player == nil) then return true end
	self._Saving = true

	local success, response = pcall(function()
		-- Set or Update depending on argumebt
		if (useSetAsync) then
			return self._Datastore:SetAsync(tostring(self.Player.UserId), self:GetMutableData())
		else
			return self._Datastore:UpdateAsync(tostring(self.Player.UserId), function(cloudData: {[string]: any})
				if (cloudData == nil) then
					return self:GetMutableData()
				end
	
				-- Fetch mutable data
				local mutableData = self:GetMutableData()
	
				-- Update keys
				for key, value in pairs(mutableData) do
					local mergeCallback = self._KeyMergeCallbacks[key]
	
					-- If merge callback exists, call it and pass proper data
					if (mergeCallback) then
						local success, newData = pcall(mergeCallback, self.Player, cloudData, mutableData)

						-- Set to newData if the method was a success
						if (success) then
							cloudData[key] = newData
						end
					else
						cloudData[key] = value
					end
				end
	
				return cloudData
			end)
		end
	end)

	if (not success) then
		if (retries + 1 > PlayerDataConfig.MaxRetries) then
			self._Saving = false

			return false
		end

		task.wait(PlayerDataConfig.RetryDelay)

		return self:_Save(retries + 1, useSetAsync)
	end

	-- Update cloudData
	self:SetCloudData(response)
	self._Saving = false

	return true
end

function PlayerDataProfile:Destroy()
	SchedulerService:RemoveTask(string.format("Autosave:%s", self.Player.Name))

	self._maid:Destroy()
end

return PlayerDataProfile