-- Searchbox
-- Brandon Wilcox
-- 01/04/2022

--[[

	Creates a searchbox object

]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local Fusion = SuperStack:GetModule("Fusion")
local StyledFrame = SuperStack:GetModule("StyledFrame")
local Icon = SuperStack:GetModule("Icon")

local New = Fusion.New
local State = Fusion.State
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Children = Fusion.Children
local ComputedPairs = Fusion.ComputedPairs

local function trim(str)
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

local function buildQuery(database, query)
	local queryResult = {}

	if (query == "") then
		return queryResult
	end

	for _, category in pairs(database) do
		for _, action in pairs(category.CategoryActions) do
			local actionName = string.lower(action.ActionName)
			local query = trim(string.lower(query))

			if (string.find(actionName, query)) then
				table.insert(queryResult, {
					Category = category.CategoryName,
					Action = action.ActionName
				})
			end

		end
	end

	return queryResult
end

return function(properties)
	local database = properties.Database
	local queryResult = State({})
	local visible = State(false)

	return StyledFrame {
		Name = "Searchbox",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(.92, 0.5),
		Size = UDim2.fromScale(.35, .8),
		ZIndex = 15,

		[Children] = {
			Icon {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Image = "rbxassetid://8447654914",
				ImageColor3 = Color3.fromRGB(255, 255, 255)
			},

			New "TextBox" {
				Name = "TextBox",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.85, 0.7),
				Position = UDim2.fromScale(0.15, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				
				Font = "SourceSansBold",
				PlaceholderText = properties.Text,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextXAlignment = "Left",

				[OnChange "Text"] = function(newText)
					local query = buildQuery(database, newText)

					if (#query == 0) then
						visible:set(false)
					else
						visible:set(true)
					end

					queryResult:set(query)
				end
			},

			New "Frame" {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Visible = Computed(function()
					return visible:get()
				end),

				Position = UDim2.fromScale(0.5, 1.15),
				Size = Computed(function()
					if (#queryResult:get() > 0) then
						return UDim2.new(1, 0, 0, (#queryResult:get() * 30) + ((#queryResult:get() - 1) * 10) + 10)
					else
						return UDim2.fromScale(1, 0)
					end
				end),
				ClipsDescendants = true,
				ZIndex = 15,

				[Children] = {
					New "Frame" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(25, 25, 25),
						Visible = true,
		
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
		
						[Children] = {
							New "UICorner" {
								CornerRadius = UDim.new(0, 15)
							}
						}
					},

					New "Frame" {
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 0.5),
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,

						[Children] ={ 
							New "UIListLayout" {
								Padding = UDim.new(0, 10),
								FillDirection = "Vertical",
								VerticalAlignment = "Top"
							},
							
							New "UIPadding" {
								PaddingTop = UDim.new(0, 5),
								PaddingBottom = UDim.new(0,5),
								PaddingLeft = UDim.new(0, 5),
								PaddingRight = UDim.new(0, 5)
							},

							Computed(function()
								return ComputedPairs(queryResult:get(), function(index, result)
									return New "Frame" {
										AnchorPoint = Vector2.new(0.5, 0),
										BackgroundColor3 = Color3.fromRGB(25, 25, 25),
										Size = UDim2.new(1, 0, 0, 30),

										[Children] = {
											New "UICorner" {
												CornerRadius = UDim.new(0, 15)
											},

											New "UIStroke" {
												Color = Color3.fromRGB(60, 60, 60),
												Thickness = 3
											},

											New "TextButton" {
												AnchorPoint = Vector2.new(0.5, 0.5),
												BackgroundTransparency = 1,
												Position = UDim2.fromScale(0.5, 0.5),
												Size = UDim2.fromScale(1, 0.6),

												Font = "SourceSansBold",
												Text = result.Action,
												TextColor3 = Color3.fromRGB(255, 255, 255),
												TextSize = 18,

												[OnEvent "Activated"] = function()
													visible:set(false)

													properties.ItemSelected:Fire(result)
												end
											}
										}
									}
								end)
							end)
						}
					}
				}
			}
		}
	}
end