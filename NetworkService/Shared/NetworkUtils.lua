-- NetworkUtils
-- Brandon Wilcox
-- 12/23/2021

--[=[
	@class NetworkUtils

	A utility class for the SuperStack Networking package.  This holds various methods that the NetworkService
	and NetworkClient take advantage of.

	* Written by Brandon Wilcox, DevTech
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local GetRemoteFunction = SuperStack:GetModule("GetRemoteFunction")
local GetRemoteEvent = SuperStack:GetModule("GetRemoteEvent")

local NetworkUtils = {}

--[=[
	Searches for a function in a module

	:::caution
	This method may throw an error if a RemoteFunction with the specified name does
	not exist!
	:::

	@param module table
	@param functionName string
	@return RemoteFunction | nil
]=]
function NetworkUtils:GetFunction(module: table, functionName: string): RemoteFunction
	local remoteFunction = module._Functions[functionName]

	-- Overwrite on client
	if  (RunService:IsClient()) then
		remoteFunction = GetRemoteFunction(functionName)
	end

	-- Return cached function if it exists
	if (remoteFunction) then return remoteFunction end

	return error(string.format("RemoteFunction %s does not exist!", functionName))
end

--[=[
	Searches for an event in a module

	:::caution
	This method may throw an error if a RemoteEvent with the specified name does
	not exist!
	:::

	@param module table
	@param eventName string
	@return RemoteEvent | nil
]=]
function NetworkUtils:GetEvent(module: table, eventName: string): RemoteEvent
	local remoteEvent = module._Events[eventName]

	-- Overwrite on client
	if  (RunService:IsClient()) then
		remoteEvent = GetRemoteEvent(eventName)
	end

	-- Return cached function if it exists
	if (remoteEvent) then return remoteEvent end

	return error(string.format("RemoteFunction %s does not exist!", eventName))
end

return NetworkUtils