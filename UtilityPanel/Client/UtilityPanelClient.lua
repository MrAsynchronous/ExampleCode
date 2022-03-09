-- UtilityPanelClient
-- Brandon Wilcox
-- 12/30/2021

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local NetworkClient = SuperStack:GetModule("NetworkClient")
local Fusion = SuperStack:GetModule("Fusion")
local Signal = SuperStack:GetModule("Signal")

local DebugMenu = SuperStack:GetModule("DebugMenuCore")
local Children = Fusion.Children
local Computed = Fusion.Computed
local State = Fusion.State
local New = Fusion.New

local Player = Players.LocalPlayer

local UtilityPanelClient = {}
UtilityPanelClient.__index = UtilityPanelClient

function UtilityPanelClient.new()
	local self = setmetatable({}, UtilityPanelClient)

	self._Menus = State({})

	self._OpenedStates = {}
	self._Keybinds = {}

	self.ActionExecuted = Signal.new()
	self._ActionExecuted = Signal.new()

	return self
end

function UtilityPanelClient:Initialize()

	-- Attempt to fetch UtilityPanelSchema from the server
	NetworkClient:InvokeServer("FetchUtilityPanelSchema"):andThen(function(schema: {[string]: any})
		if (schema == nil) then
			return
		end

		-- Begin to create menus
		for i, menu in pairs(schema.Menus) do
			self._OpenedStates[menu.MenuName] = State(false)
			self._Keybinds[menu.MenuKeybind.Name] = menu.MenuName

			local menus = self._Menus:get()

			table.insert(menus, DebugMenu {
				ActionExecuted = self._ActionExecuted,
				Categories = menu.MenuCategories,
				Name = menu.MenuName,

				OpenState = self._OpenedStates[menu.MenuName],
				Favicon = menu.MenuFavicon,

				Visible = Computed(function()
					return self._OpenedStates[menu.MenuName]:get()
				end)
			})

			self._Menus:set(menus)
		end
	end):finally(function()
		-- Parent all the menus to a ScreenGui
		New "ScreenGui" {
			Name = "Debug",
			Parent = Player:WaitForChild("PlayerGui"),

			DisplayOrder = 100000,
	
			[Children] = self._Menus
		}
	end)

	-- Begin listening to input began to know when to open the menus
	UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
		if (gameProcessed) then return end

		-- Check inputObject KeyCode against OpenedStates
		local menuName = self._Keybinds[inputObject.KeyCode.Name]
		if (menuName) then
			local state = self._OpenedStates[menuName]

			state:set(not state:get())
		end
	end)

	-- Relay action execution information to the server
	self._ActionExecuted:Connect(function(menuName, categoryName, actionName, variableData)
		local processedParameters = {}

		-- Attempt to convert types to intended type
		for _, parameter in pairs(variableData) do
			local value: string = parameter.Value
			local cleanedValue: any = value

			if (parameter.Type == "number") then
				cleanedValue = tonumber(value)

				if (cleanedValue == nil) then
					cleanedValue = value
				end

			elseif (parameter.Type == "Player") then
				cleanedValue = Players:FindFirstChild(value)
			end

			processedParameters[parameter.Name] = cleanedValue
		end

		self.ActionExecuted:Fire(menuName, categoryName, actionName, processedParameters)

		NetworkClient:FireServer("UtilityPanelGateway", {
			MenuName = menuName,
			ActionName = actionName,
			CategoryName = categoryName,
			Parameters = processedParameters
		})
	end)
end
	
local Singleton = UtilityPanelClient.new()
return Singleton
