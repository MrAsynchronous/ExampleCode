-- UtilityPanelService
-- Brandon Wilcox
-- 12/30/2021

--[=[
	@class UtilityPanelService
	@server

]=]

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local NetworkService = SuperStack:GetModule("NetworkService")
local Panel = SuperStack:GetModule("UtilityPanel")

local UtilityPanelService = {}
UtilityPanelService.__index = UtilityPanelService

function UtilityPanelService.new()
	local self = setmetatable({}, UtilityPanelService)

	self._Panels = {}

	self._IsAuthorizedUser = function(player)
		return true
	end

	return self
end

--[=[
	Set callback function of whether a player is able to access all panels.

	:::tip
	We recommend using player:GetRankInGroup and user internal Roblox roles to categorize access
	:::

	:::note
	Default function defined is that all players have access to all panels.  Make sure to set this callback to filter users
	properly
	:::

	@param callback function
]=]
function UtilityPanelService:SetIsAuthorizedUserCallback(callback: table): nil
	assert(callback ~= nil, "SetIsAuthorizedUserCallback callback is nil")

	self._IsAuthorizedUser = callback
end

--[=[
	Returns whether a player is able to access all panels.

	@param player Player
	@return boolean
]=]
function UtilityPanelService:IsAuthorizedUser(player: Player): boolean
	return self._IsAuthorizedUser(player)
end

--[=[
	Creates a new UtilityPanel under the passed panelName.  The passed keybind will trigger then opening
	and closing of the UtilityPanel.

	Below is valid syntax for creating a Panel.

	:::tip
	See PanelMenu for information on how to add categories, and actions to your panel.
	:::

	```lua
	-- Store the panel in a variable
	local mainPanel = UtilityPanelService:CreatePanel("Main", Enum.KeyCode.Equals)
	mainPanel:AddCategory(...)

	-- or

	-- Pass a constructor as the third optional argument to encapsulate the setup
	UtilityPanelService:CreatePanel("Main", Enum.KeyCode.Equals, function(panel)
		panel:AddCategory(...)
	end)
	```

	@param panelName string
	@param keybind Enum.KeyCode
	@param setup (menu: table) -> nil?
	@return menu: DebugPanel
]=]
function UtilityPanelService:CreatePanel(panelName: string, keybind: Enum.KeyCode, setup: (any) -> nil)
	if (self._Panels[panelName] ~= nil) then
		return error(string.format("Panel %s already exists!", panelName))
	end

	-- Create panel
	local panel = Panel.new(panelName, keybind)
	self._Panels[panelName] = panel

	-- Call callback if it exists
	if (setup) then
		local success, res = pcall(setup, panel)

		if (not success) then
			warn(string.format("Couldn't setup panel %s! %s", panelName, tostring(res)))
		end
	end

	return panel
end

--[=[
	@private
	Exports the panel in a format that the UtilityPanelClient can interperet.
	
	@param player Player
	@return table
]=]
function UtilityPanelService:_Export(player: Player): {[string]: any}
	local debugMenus = {}

	-- Add categories to array
	for _, menu in pairs(self._Panels) do
		if not menu:IsAuthorizedUser(player) then
			continue
		end
		table.insert(debugMenus, menu:Export())
	end

	return {
		Menus = debugMenus
	}
end

function UtilityPanelService:Initialize()
	-- Register event with NetworkService
	NetworkService:RegisterEvent("UtilityPanelGateway")
	NetworkService:RegisterFunction("FetchUtilityPanelSchema")

	-- Handle fetching of debug menu schema
	NetworkService:OnServerInvoke("FetchUtilityPanelSchema", function(player)
		if (not self._IsAuthorizedUser(player)) then
			return
		end

		return self:_Export(player)
	end)

	-- Listen to incoming traffic for NetworkService
	NetworkService:OnServerEvent("UtilityPanelGateway", function(player: Player, data: table)
		if (not self._IsAuthorizedUser(player)) then
			return
		end

		-- Fetch menu, category and action
		local menu = self._Panels[data.MenuName]
		if not menu:IsAuthorizedUser(player) then
			return
		end

		local category = menu:GetCategory(data.CategoryName)
		local action = category:GetAction(data.ActionName)

		warn(string.format("%s executed action %s", player.Name, data.ActionName))

		-- Execute the runner
		local success, res = action:ExecuteRunner(player, data.Parameters)

		-- Output any errors
		if (not success) then
			print(string.format("Couldn't execute runner for action %s! %s", data.ActionName, tostring(res)))
		end
	end)
end

local Singleton = UtilityPanelService.new()
return Singleton