local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)
local Fusion = SuperStack:GetModule("Fusion")
local Signal = SuperStack:GetModule("Signal")

local StyledFrame = SuperStack:GetModule("StyledFrame")
local ArgumentList = SuperStack:GetModule("ArgumentList")
local Topbar = SuperStack:GetModule("Topbar")
local List = SuperStack:GetModule("List")

local Vector3Entry = SuperStack:GetModule("Vector3Entry")
local BooleanEntry = SuperStack:GetModule("BooleanEntry")
local StringEntry = SuperStack:GetModule("StringEntry")
local EnumEntry = SuperStack:GetModule("EnumEntry")
local LongStringEntry = SuperStack:GetModule("LongStringEntry")

local New = Fusion.New
local State = Fusion.State
local Children = Fusion.Children
local Computed = Fusion.Computed
local ComputedPairs = Fusion.ComputedPairs

local function GetCategory(categories, categoryName)
	for _, category in pairs(categories) do
		if (category.CategoryName == categoryName) then
			return category
		end
	end
end

local function GetAction(actions, actionName)
	for _, action in pairs(actions) do
		if (action.ActionName == actionName) then
			return action
		end
	end
end

local function GetCategoryActions(category)
	return ComputedPairs(category.CategoryActions, function(index, value)
		return {
			Name = value.ActionName,
			Order = value.ActionOrder
		}
	end)
end

local function GetActionVariables(action)
	return ComputedPairs(action.ActionVariables, function(index, value)
		return {
			Name = value.Name,
			Order = index,
			Type = value.Type,
			Data = value.Data,
			DefaultValue = value.DefaultValue,
			State = State("")
		}
	end)
end

local function RenderVariables(variables)
	if (#variables:get():get() == 0) then
		return {
			New "TextLabel" {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.065),

				TextScaled = true,
				TextYAlignment = "Top",
				Font = "SourceSansBold",
				Text = "Action has no arguments",
				TextColor3 = Color3.fromRGB(255, 255, 255),
			}
		}
	end

	return ComputedPairs(variables:get(), function(index, value)
		if (value.Type == "boolean") then
			return BooleanEntry {
				Name = value.Name,
				State = value.State,
				DefaultValue = value.DefaultValue
			}
		elseif (value.Type == "Enum") then
			return EnumEntry {
				Name = value.Name,
				State = value.State,
				Values = value.Data,
				DefaultValue = value.DefaultValue
			}
		elseif (value.Type == "Vector3") then
			return Vector3Entry {
				Name = value.Name,
				State = value.State,
				DefaultValue = value.DefaultValue
			}
		elseif (value.Type == "Player") then
			return EnumEntry {
				Name = value.Name,
				State = value.State,
				Values = ComputedPairs(Players:GetPlayers(), function(index, player)
					return player.Name or ""
				end):get()
			}
		elseif (value.Type == "longstring") then
			return LongStringEntry {
				Name = value.Name,
				State = value.State,
				DefaultValue = value.DefaultValue
			}
		else
			return StringEntry {
				Name = value.Name,
				State = value.State,
				DefaultValue = value.DefaultValue
			}
		end
	end)
end

return function(properties)
	local categories = State(properties.Categories)
	local variableFrames = State({})
	local variables = State({})
	local actions = State({})

	local selectedCategory = State(categories:get()[1])
	local selectedAction = State(categories:get()[1].CategoryActions[1])

	local categorySelected = Signal.new()
	local actionSelected = Signal.new()

	local queryResultSelected = Signal.new()

	-- setup actions
	actions:set(GetCategoryActions(selectedCategory:get()))
	variables:set(GetActionVariables(selectedAction:get()))
	variableFrames:set(RenderVariables(variables))

	local variableStates = Computed(function()
		return ComputedPairs(variables:get(), function(index, value)
			return {
				Name = value.Name,
				Type = value.Type,
				Value = value.State:get()
			}
		end)
	end)

	queryResultSelected:Connect(function(item)
		local category = GetCategory(categories:get(), item.Category)
		if (selectedAction:get().ActionName == item.Action) then return end
		if (not category) then return end

		local action = GetAction(category.CategoryActions, item.Action)

		-- Update selected category
		selectedCategory:set(category)
		selectedAction:set(action)

		-- Update action state
		actions:set(GetCategoryActions(category))
		variables:set(GetActionVariables(action))
		variableFrames:set(RenderVariables(variables))
		
		-- Alert lists that category was changed
		categorySelected:Fire()
		actionSelected:Fire()
	end)

	return StyledFrame {
		Name = "Container",
		Size = UDim2.fromScale(0.751, .561),
		Padding = 10,
		Visible = properties.Visible,
		Draggable = false,

		[Children] = {
			New "UIAspectRatioConstraint" {
				AspectRatio = 1.429,
				DominantAxis = "Width"
			},

			Topbar {
				SearchText = "Search for an action...",
				SearchDB = properties.Categories,
				SearchResultSelected = queryResultSelected,
				Name = properties.Name,

				OpenState = properties.OpenState,
				Favicon = properties.Favicon
			},

			StyledFrame {
				Name = "ActionContainer",
				Size = UDim2.fromScale(1, 0.872),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),

				[Children] = {
					New "UIListLayout" {
						Padding = UDim.new(0, 10),
						FillDirection = "Horizontal",
						HorizontalAlignment = "Center",
						SortOrder = "LayoutOrder",
						VerticalAlignment = "Bottom"
					},

					List {
						Name = "Categories",
						SelectedItem = selectedCategory,
						
						Source = ComputedPairs(categories, function(index, value)
							return {
								Name = value.CategoryName,
								Order = value.CategoryOrder
							}
						end),

						ItemSelected = function(categoryName)
							local category = GetCategory(categories:get(), categoryName)
							if (categoryName == selectedCategory:get().CategoryName) then return end
							if (not category) then return end

							local categoryActions = GetCategoryActions(category):get()
							local action = GetAction(category.CategoryActions, categoryActions[1].Name)

							-- Update selected category
							selectedCategory:set(category)
							selectedAction:set(action)

							-- Update action state
							actions:set(GetCategoryActions(category))

							-- Update action variables
							variables:set(GetActionVariables(action))
							variableFrames:set(RenderVariables(variables))
							
							-- Alert lists that category was changed
							categorySelected:Fire()
							actionSelected:Fire()
						end
					},

					List {
						Name = "Actions",
						Source = actions,

						SelectedItem = selectedAction,
						UpdatedSignal = categorySelected,

						ItemSelected = function(actionName)
							if (selectedAction:get().ActionName == actionName) then return end

							local category = selectedCategory:get()
							local action = GetAction(category.CategoryActions, actionName)

							-- Setup selected action
							selectedAction:set(action)

							-- Update action variables
							variables:set(GetActionVariables(action))
							variableFrames:set(RenderVariables(variables))

							-- Alert list that state has changed
							actionSelected:Fire()
						end,
					},

					ArgumentList {
						Name = "Arguments",
						Title = "Action Arguments",

						ArgumentFrames = variableFrames,

						Executed = function()
							properties.ActionExecuted:Fire(
								properties.Name,
								selectedCategory:get().CategoryName,
								selectedAction:get().ActionName,
								variableStates:get():get()
							)
						end
					}
				}
			}
		}
	}
end
