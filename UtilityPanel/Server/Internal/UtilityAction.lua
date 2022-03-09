-- UtilityAction
-- Brandon Wilcox
-- 12/30/2021

--[=[
	@class UtilityAction
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local UtilityAction = {}
UtilityAction.__index = UtilityAction

function UtilityAction.new(actionName: string, order: number, descriptor: {[string]: any}?)
	local self = setmetatable({}, UtilityAction)

	self.Name = actionName
	self._Guid = HttpService:GenerateGUID(false)
	self._Order = order

	self._Runner = function()
		warn(string.format("No runner set for action %s!", actionName))
	end

	self._Variables = {}
	self._VariableNames = {}

	-- Handle descriptor
	if (descriptor) then
		self:SetRunner(descriptor.Runner)

		-- Add variables to Action
		for _, descriptor in pairs(descriptor.Variables or {}) do
			self:AddVariable(descriptor.Name, descriptor.Type, descriptor.Data, descriptor.DefaultValue)
		end
	end
	
	return self
end

--[=[
	Adds a variable to the Action.  This is called internally when calling AddVariables.

	:::tip
	This can be called on the UtilityAction that's returned when calling AddAction() on a UtilityCategory.

	```lua
	local action = Category:AddAction(actionName, descriptor)
	action:AddVariable("Player", "Player")
	```
	:::

	@param variableName string
	@param variableType string
	@param variableData any
	@return self: UtilityAction
]=]
function UtilityAction:AddVariable(variableName: string, variableType: string, variableData: any?, defaultValue: any?): table
	if (table.find(self._VariableNames, variableName)) then
		return error(string.format("Tried to assign existing variable %s to action %s!", variableName, self.Name))
	end

	table.insert(self._Variables, {
		Name = variableName,
		Type = variableType,
		Data = variableData,
		DefaultValue = defaultValue
	})

	table.insert(self._VariableNames, variableName)

	return self
end

--[=[
	Adds variables to the Action.  This is called internally when passing a descriptor containing variables.

	:::tip
	This can be called on the UtilityAction that's returned when calling AddAction() on a UtilityCategory.

	```lua
	local action = Category:AddAction(actionName, descriptor)
	action:AddVariables({
		{Name = "Player", Type = "Player"},
		{Name = "Reason", Type = "longstring"}
	})
	```
	:::

	@param variables {{[string]: string}}
	@return self: UtilityAction
]=]
function UtilityAction:AddVariables(variables: {{[string]: string}}): table

	-- Add variables to Action
	for _, descriptor in pairs(variables or {}) do
		self:AddVariable(descriptor.Name, descriptor.Type, descriptor.Data, descriptor.DefaultValue)
	end

	return self
end

--[=[
	Sets the actions runner.  This is called interanlly when passing a descriptor containing a runner.

	:::tip
	This can be called on the UtilityAction that's returned when calling AddAction() on a UtilityCategory.

	```lua
	local action = Category:AddAction(actionName, descriptor)
	action:SetRunner(function(player, variables)
		print("Haiiii")
	end)
	```
	:::

	:::caution
	Calling this multiple times will overwrite the previous runner. This should only be called once.
	:::

	@param runner (player: Player, parameters: {[string]: any}) -> nil
	@return self: UtilityAction
]=]
function UtilityAction:SetRunner(runner: (any) -> any)
	self._Runner = runner

	return self
end

--[=[
	Executes the Actions Runner.  Returns a pcall-wrapped call to the Runner function.

	:::caution
	This is called automatically on the server when it received a request.
	:::

	@param any any
	@return success: boolean, response: any
]=]
function UtilityAction:ExecuteRunner(...)
	return pcall(self._Runner, ...)
end

--[=[
	Exports the UtilityAction in a format that the client can interperet.

	@return {[string]: any}
]=]
function UtilityAction:Export(): {[string]: any}
	local actionVariables = {}

	-- Add variables to array
	for i, variable in pairs(self._Variables) do
		table.insert(actionVariables, i, variable)
	end

	return {
		ActionName = self.Name,
		ActionGuid = self._Guid,
		ActionOrder = self._Order,
		ActionVariables = actionVariables
	}
end

return UtilityAction