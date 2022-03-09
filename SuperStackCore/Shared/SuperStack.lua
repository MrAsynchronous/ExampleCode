-- SuperStack
-- Brandon Wilcox
-- 12/01/2021

--[=[
	@class SuperStack

	The core driver of the SuperStack platform.  This module is responsible for building a charge of
	lazy-loaded modules.

	Modules are aggregated by the StackBootstrapper.

	* Written by Brandon Wilcox, DevTech
]=]

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local SuperStack = {}
SuperStack.__index = SuperStack

--[=[
	@private

	Constructs a new SuperStack object.  This is called internally and should not be called outside
	of this instance!

	@return SuperStack
]=]
function SuperStack.new()
	local self = setmetatable({}, SuperStack)

	self.Version = "1.5.1"

	self._ModulesBeingLoaded = {}
	self._Packages = {}
	self._Modules = {}

	print(string.format(
		"SuperStack v%s is running on the %s!",
		self.Version,
		if (RunService:IsServer()) then "server" else "client"
	))

	return self
end

--[=[
	Returns a module that shares the moduleName argument.  If ignoreNilModule is passed,
	any error thrown in the process will be surpressed.  If the module is not found in
	the cache, a deep search of the package containers is performed.  If the module is
	found, the module is started and initialized if needed.

	@param moduleName String
	@param ignoreNilModule? boolean
	@return module: table | nil
]=]
function SuperStack:GetModule(moduleName: string, ignoreNilModule: boolean | nil): any
	local module: ModuleScript = self._Modules[moduleName]

	-- Return module if it exists
	if (module) then
		return require(module)
	end

	-- If module isn't found, attempt to traverse all packages
	local module: ModuleScript = self:_FindModule(moduleName)

	-- If module still doens't exist, handle
	if (not module) then
		if (ignoreNilModule) then
			return
		end

		return warn(string.format("Module %s does not exist!", moduleName))
	end

	-- Require module
	local data: table = require(module)

	-- Soft check if methods exist
	local indexSuccess, hasStackMethods = pcall(function()
		return (data.Start or data.Initialize)
	end)

	-- Return early if package doens't need to be initialized
	if (typeof(data) ~= "table" or (not indexSuccess or (indexSuccess and not hasStackMethods))) then
		self._Modules[moduleName] = module

		return data
	end

	-- If module is already being loaded, wait until it's loaded
	if (table.find(self._ModulesBeingLoaded, module)) then
		repeat task.wait() until (not table.find(self._ModulesBeingLoaded, module))

		return data
	end

	-- Mark module as being loaded
	table.insert(self._ModulesBeingLoaded, module)

	-- Start and initialize the module
	self:_InitializeModule(moduleName, data)
	self:_StartModule(moduleName, data)

	-- Cache module
	self._Modules[moduleName] = module

	-- Remote module loading mark
	table.remove(self._ModulesBeingLoaded, table.find(self._ModulesBeingLoaded, module))

	return data
end

--[=[
	Returns a package that shares the packageName argument. If ignoreNilPackage
	is passed, any errors thrown in the process will be surpressed.

	@param packageName String
	@param ignoreNilPackage? boolean
	@return package: Instance
]=]
function SuperStack:GetPackage(packageName: string, ignoreNilPackage: boolean | nil): Instance | nil
	local package = self._Packages[packageName]

	if (not package) then
		if (ignoreNilPackage) then
			return
		end

		return warn(string.format("Package %s does not exist!", packageName))
	end

	return package
end

--[=[
	@private

	Performs a deep search on all package containers in an attempt to find a module
	that shares the moduleName argument.

	@param moduleName string
	@return moduleName: Instance | nil
]=]
function SuperStack:_FindModule(moduleName: string): Instance | nil
	local moduleContainers = {
		script.Parent:FindFirstChild("Packages")
	}

	-- Add Server container if running on server
	if (RunService:IsServer()) then
		table.insert(
			moduleContainers,
			ServerScriptService:FindFirstChild("SuperStack", true).Packages
		)
	end

	-- Iterate through all containers to try and find module
	for _, container in pairs(moduleContainers) do
		
		-- Iterate through all descendants
		for _, child in pairs(container:GetDescendants()) do
			if (not child:IsA("ModuleScript")) then continue end

			-- Break out early and return module
			if (child.Name == moduleName) then
				return child
			end
		end
	end

	return nil
end

--[=[
	@private

	Initializes the module passed.

	@param moduleName string
	@param module table
	@return nil
]=]
function SuperStack:_InitializeModule(moduleName: string, module: table): nil
	if (not module.Initialize) then return end

	local success, err = pcall(function()
		return module:Initialize()
	end)

	-- Warn error
	if (not success) then
		warn(string.format("Couldn't initialize module %s: %s", moduleName, err))
	end
end

--[=[
	@private

	Starts the module passed.

	@param moduleName string
	@param module table
	@return nil
]=]
function SuperStack:_StartModule(moduleName: string, module: table): nil
	if (not module.Start) then return end

	local success, err = pcall(function()
		return module:Start()
	end)

	-- Warn error
	if (not success) then
		warn(string.format("Couldn't start module %s: %s", moduleName, err))
	end
end

local Singleton = SuperStack.new()
return Singleton