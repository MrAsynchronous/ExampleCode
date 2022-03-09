-- UtilityCategory
-- Brandon Wilcox
-- 12/30/2021

--[=[
	@class UtilityCategory
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local Action = SuperStack:GetModule("UtilityAction")

local UtilityCategory = {}
UtilityCategory.__index = UtilityCategory

function UtilityCategory.new(categoryName: string, order: number)
	local self = setmetatable({}, UtilityCategory)

	self.Name = categoryName

	self._Order = order
	self._Actions = {}
	self._ActionNames = {}
	self._ActionCache = {}

	return self
end

--[=[
	Creates and stores a new action in the category.

	:::tip
	See [UtilityAction](UtilityAction) for more information.
	:::
	:::caution
	Action names must be unique!
	:::

	@param actionName string
	@param descriptor {[string]: any}?
	@return action: UtilityAction
]=]
function UtilityCategory:AddAction(actionName: string, descriptor: {[string]: any}?): table
	if (table.find(self._ActionNames, actionName)) then
		return error(string.format("Action with name %s already exists!", actionName))
	end

	-- Create a new action
	local action = Action.new(actionName, #self._Actions + 1, descriptor)
	
	table.insert(self._Actions, action)
	table.insert(self._ActionNames, actionName)
	self._ActionCache[actionName] = action

	return action
end

--[=[
	Returns the action associated with the actionName.

	@param actionName string
	@return action: UtilityAction
]=]
function UtilityCategory:GetAction(actionName: string)
	return self._ActionCache[actionName]
end

--[=[
	Exports the UtilityCategory in a format that the client can interperet.

	@return {[string]: any}
]=]
function UtilityCategory:Export(): {[string]: any}
	local categoryActions = {}

	-- Add actions to array
	for i, action in pairs(self._Actions) do
		table.insert(categoryActions, i, action:Export())
	end

	return {
		CategoryName = self.Name,
		CategoryOrder = self._Order,
		CategoryActions = categoryActions
	}
end

return UtilityCategory