-- PlayerDataClient
-- MrAsync
-- 02/15/2022


local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local NetworkClient = SuperStack:GetModule("NetworkClient")
local Signal = SuperStack:GetModule("Signal")

local PlayerDataClient = {}
PlayerDataClient.__index = PlayerDataClient

function PlayerDataClient.new()
	local self = setmetatable({}, PlayerDataClient)

	self._Signals = {}
	self._Data = {}
	
	return self
end

function PlayerDataClient:GetData(key: string): any
	return self._Data[key]
end

function PlayerDataClient:OnDataChanged(key: string): RBXScriptSignal | nil
	local signal = self._Signals[key]
	if (not signal) then return end

	return signal
end

function PlayerDataClient:Initialize()
	
	NetworkClient:OnClientEvent("PlayerDataGateway", function(route, data)
		if (route == "DataSchema") then
			self._Data = data

			for key, _ in pairs(data) do
				self._Signals[key] = Signal.new()
			end
		elseif (route == "DataChanged") then
			self._Data[data.Key] = data.NewValue

			local signal = self._Signals[data.Key]
			if (not signal) then return end

			signal:Fire(data.NewValue, data.OldValue)
		end
	end)

	NetworkClient:FireServer("PlayerDataGateway")
end

local Singleton = PlayerDataClient.new()
return Singleton