-- NetworkServer
-- Brandon Wilcox
-- 12/23/2021

--[=[
	@class NetworkService
	@server
	
	Server component of the SuperStack Networking package.  This module contains several methods
	that streamline server -> client communication.

	* Written by Brandon Wilcox, DevTech
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local GetRemoteFunction = SuperStack:GetModule("GetRemoteFunction")
local GetRemoteEvent = SuperStack:GetModule("GetRemoteEvent")
local NetworkUtils = SuperStack:GetModule("NetworkUtils")

local NetworkService = {}
NetworkService.__index = NetworkService

--[=[
	@private

	Creates a new instance of the NetworkClient.
	
	:::caution
	This method is called internally and should not be called elsewhere.
	:::

	@return NetworkService
]=]
function NetworkService.new()
	local self = setmetatable({}, NetworkService)

	self._Events = {}
	self._Functions = {}

	self._FunctionsWithCallback = {}

	return self
end

--[=[
	Sets the OnServerInvoke callback of the specified function to the specified callback

	:::caution
	This method will throw errors in any of the following scenarios: invalid parameters,
	RemoteFunction with the given functionName does not exist.
	:::

	@param functionName string
	@param callback (any) -> any
	@return nil
]=]
function NetworkService:OnServerInvoke(functionName: string, callback: (any) -> any): nil
	assert(functionName, string.format("Expected functionName: string!  Got %s!", tostring(functionName)))
	assert(callback, string.format("Expected callback: Function! Got %s!", tostring(callback)))
	
	-- Fetch remote function
	local remoteFunction: RemoteFunction = NetworkUtils:GetFunction(self, functionName)

	-- Don't allow callback to be set again
	if (table.find(self._FunctionsWithCallback, functionName)) then
		return warn(string.format("RemoteFunction %s already has a callback!", functionName))
	end

	-- Mark remote as callback-positive
	table.insert(self._FunctionsWithCallback, functionName)
	
	-- Set the callback
	remoteFunction.OnServerInvoke = callback
	
	return
end

--[=[
	Connects the specified callback to the OnServerEvent signal of the specified event.

	@param eventName string
	@param callback (any) -> any
	@return nil
]=]
function NetworkService:OnServerEvent(eventName: string, callback: (any) -> any) : nil
	assert(eventName, string.format("Expected eventName: string!  Got %s!", tostring(eventName)))
	assert(callback, string.format("Expected callback: Function! Got %s!", tostring(callback)))
	
	-- Fetch remote event
	local remoteEvent: RemoteEvent = NetworkUtils:GetEvent(self, eventName)

	-- Connect listener
	remoteEvent.OnServerEvent:Connect(callback)

	return
end

--[=[
	Calls :FireClient() on the specified eventName.  Passes any arguments given
	to the client.

	@param eventName string
	@param player Player
	@param args? {<T>}
	@return nil
]=]
function NetworkService:FireClient(eventName: string, player: Player, ...): nil
	assert(eventName, string.format("Expected eventName: string!  Got %s!", tostring(eventName)))
	assert(player, string.format("Expected player: Player! Got %s!", tostring(player)))

	-- Fetch remote event
	local remoteEvent: RemoteEvent = NetworkUtils:GetEvent(self, eventName)

	-- Fire event
	remoteEvent:FireClient(player, ...)

	return
end

--[=[
	Calls :FireAllClients() on the specified eventName.  Passes any arguments given
	to the clients.

	@param eventName string
	@param args? {<T>}
	@return nil
]=]
function NetworkService:FireAllClients(eventName: string, ...): nil
	assert(eventName, string.format("Expected eventName: string!  Got %s!", tostring(eventName)))

	-- Fetch remote event
	local remoteEvent: RemoteEvent = NetworkUtils:GetEvent(self, eventName)

	-- Fire event
	remoteEvent:FireAllClients(...)

	return
end

--[=[
	Fires the specified eventName to all clients not found in the specified ignoreList.

	@param eventName string
	@param ignoreList {Player}
	@return nil
]=]
function NetworkService:FireAllClientsWithIgnoreList(eventName: string, ignorelist: {Player}, ...): nil
	assert(eventName, string.format("Expected eventName: string!  Got %s!", tostring(eventName)))
	assert(ignorelist, string.format("Expected ignorelist: {Player}! Got %s!", tostring(ignorelist)))

	-- Fetch remote event
	local remoteEvent: RemoteEvent = NetworkUtils:GetEvent(self, eventName)

	-- Iterate through all players, skipping those in the ignore list
	for _, player in pairs(Players:GetPlayers()) do
		if (table.find(ignorelist, player)) then continue end

		-- FireClient
		remoteEvent:FireClient(player, ...)
	end
end

--[=[
	Fires the specified eventName to all clients found in the specified whitelist.

	@param eventName string
	@param whitelist {Player}
	@return nil
]=]
function NetworkService:FireAllClientsWithWhitelist(eventName: string, whitelist: {Player}, ...): nil
	assert(eventName, string.format("Expected eventName: string!  Got %s!", tostring(eventName)))
	assert(whitelist, string.format("Expected whitelist: {Player}! Got %s!", tostring(whitelist)))

	-- Fetch remote event
	local remoteEvent: RemoteEvent = NetworkUtils:GetEvent(self, eventName)

	-- Iterate through all players
	for _, player in pairs(whitelist) do

		-- FireClient
		remoteEvent:FireClient(player, ...)
	end
end

--[=[
	Registers a remote event with the NetworkService.  Creates the Remote
	if it doesn't exist.  Caches the remote internally.

	:::caution
	This method is required to be called on all RemoteEvent names you intend to use.  This should
	be done in the Init or Start methods of your Service. If you try to call methods related
	to a EventName that was not registered, errors will be thrown.
	:::

	@param eventName string
	@param callback? (any) -> any
	@return RemoteEvent
]=]
function NetworkService:RegisterEvent(eventName: string, callback: (any) -> any?): RemoteEvent
	local remoteEvent = GetRemoteEvent(eventName)
	self._Events[eventName] = remoteEvent

	-- Bind callback if given
	if (callback) then
		self:OnServerEvent(eventName, callback)
	end

	return remoteEvent
end

--[=[
	Registers a remote function with the NetworkService.  Creates the Remote
	if it doesn't exist.  Caches the remote internally.

	:::caution
	This method is required to be called on all RemoteFunction names you intend to use.  This should
	be done in the Init or Start methods of your Service.  If you try to call methods related
	to a FunctionName that was not registered, errors will be thrown.
	:::

	@param functionName string
	@param callback? (any) -> any
	@return RemoteFunction
]=]
function NetworkService:RegisterFunction(functionName: string, callback: (any) -> any?): RemoteFunction
	local remoteFunction = GetRemoteFunction(functionName)
	self._Functions[functionName] = remoteFunction

	-- Set OnServerInvoke if given callback
	if (callback) then
		self:OnServerInvoke(functionName, callback)
	end

	return remoteFunction
end

local Singleton = NetworkService.new()
return Singleton