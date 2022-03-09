-- NetworkClient
-- Brandon Wilcox
-- 12/23/2021

--[=[
	@class NetworkClient
	@client

	Client component of the SuperStack Networking package.  This module contains several methods
	that streamline client -> server communication.

	* Written by Brandon Wilcox, DevTech
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local NetworkUtils = SuperStack:GetModule("NetworkUtils")
local Promise = SuperStack:GetModule("Promise")

local NetworkClient = {}
NetworkClient.__index = NetworkClient

--[=[
	@private

	Creates a new instance of the NetworkClient.
	
	:::caution
	This method is called internally and should not be called elsewhere.
	:::

	@return NetworkClient
]=]
function NetworkClient.new()
	local self = setmetatable({}, NetworkClient)

	self._Events = {}
	self._Functions = {}
	
	return self
end

--[=[
	Invokes the specified RemoteFunction and passes any arguments given.  Wraps the call
	in a promise and pcall to assure graceful failures.

	@param functionName string
	@param args? {<T>}
	@return Promise<T>
]=]
function NetworkClient:InvokeServer(functionName: string, ...): Promise
	local arguments = {...}

	return Promise.new(function(resolve, reject)
		local remoteFunction: RemoteFunction = NetworkUtils:GetFunction(self, functionName)
		
		local success, response = pcall(function()
			return remoteFunction:InvokeServer(table.unpack(arguments))
		end)

		-- Reject if something went wrong
		if (not success) then
			return reject(response)
		end

		-- Resolve if value is not a table
		if (typeof(response) ~= "table") then
			return resolve(response)
		end

		-- Check for error
		if (response.error or response.Error or response.IsErrorCode) then
			response.IsErrorCode = nil

			return reject(response)
		end

		return resolve(response)
	end)
end

--[=[
	Calls :FireServer() on the specified eventName.  Passes any arguments given
	to the server.

	:::caution
	This method will throw an error if the event with the specified eventName does not exist!
	:::

	@param eventName string
	@param args? {<T>}
	@return nil
]=]
function NetworkClient:FireServer(eventName: string, ...): nil
	local remoteEvent: RemoteEvent = NetworkUtils:GetEvent(self, eventName)

	return remoteEvent:FireServer(...)
end

--[=[
	Binds the specified callback to the OnClientEvent signal of the specified eventName.

	:::caution
	This method will throw an error if the event with the specified eventName does not exist!
	:::

	@param eventName string
	@param callback: (any) -> any
	@return nil
]=]
function NetworkClient:OnClientEvent(eventName: string, callback: (any) -> any): nil
	local remoteEvent: RemoteEvent = NetworkUtils:GetEvent(self, eventName)

	-- Connect callback to OnClientEvent
	remoteEvent.OnClientEvent:Connect(callback)
	
	return
end

local Singleton = NetworkClient.new()
return Singleton