-- UtilityPanel
-- Brandon Wilcox
-- 12/31/2021

--[=[
	@class UtilityPanel
	@server


]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local Category = SuperStack:GetModule("UtilityCategory")

local UtilityPanel = {}
UtilityPanel.__index = UtilityPanel

function UtilityPanel.new(menuName: string, keybind: Enum.KeyCode, faviconId: string?)
	local self = setmetatable({}, UtilityPanel)

	self.Name = menuName
	self._Keybind = keybind
	self._FaviconId = faviconId

	self._IsAuthorizedUser = function(player)
		return true
	end

	self._Categories = {}
	self._CatagoryNames = {}
	self._CategoryCache = {}
	
	return self
end

--[=[
	Set callback function of whether a player is able to access panel.

	:::tip
	We recommend using player:GetRankInGroup and user internal Roblox roles to categorize access
	:::

	:::note
	Default function defined is that all players have access to panel.  Make sure to set this callback to filter users
	properly
	:::

	@param callback function
]=]
function UtilityPanel:SetIsAuthorizedUserCallback(callback: table): nil
	assert(callback ~= nil, "SetIsAuthorizedUserCallback callback is nil")

	self._IsAuthorizedUser = callback
end

--[=[
	Returns whether a player is able to access this panel.

	@param player Player
	@return boolean
]=]
function UtilityPanel:IsAuthorizedUser(player: Player): boolean
	return self._IsAuthorizedUser(player)
end

--[=[
	Creates and stores a new category in the panel.

	:::tip
	See [UtilityCategory](UtilityCategory) for more information.
	:::

	@param categoryName string
	@param setup (UtilityCategory) -> nil?
	@return UtilityCategory
]=]
function UtilityPanel:AddCategory(categoryName: string, setup: (table) -> nil?): nil
	if (table.find(self._CatagoryNames, categoryName)) then
		return error(string.format("Category %s already exists!", categoryName))
	end

	-- Create category
	local category = Category.new(categoryName, #self._Categories + 1)

	-- Add category to arrays
	table.insert(self._Categories, category)
	table.insert(self._CatagoryNames, categoryName)
	self._CategoryCache[categoryName] = category

	-- Setup category if callback exists
	if (setup) then
		local success, res = pcall(setup, category)

		if (not success) then
			warn(string.format("Couldn't setup category %s! %s", categoryName, tostring(res)))
		end
	end

	return category
end

--[=[
	Returns the category object associated with the categoryName.

	@param categoryName stirng
	@return UtilityCategory: table
]=]
function UtilityPanel:GetCategory(categoryName: string): any
	return self._CategoryCache[categoryName]
end

--[=[
	Exports the UtilityPanel in a format that the client can interperet.

	@return {[string]: any}
]=]
function UtilityPanel:Export()
	local debugCategories = {}

	for i, category in ipairs(self._Categories) do
		table.insert(debugCategories, i, category:Export())
	end

	return {
		MenuName = self.Name,
		MenuKeybind = self._Keybind,
		MenuFavicon = self._FaviconId,
		MenuCategories = debugCategories
	}
end

return UtilityPanel