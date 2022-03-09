-- StringEntry
-- Brandon Wilcox
-- 01/04/2022

--[[

	Creates a styled button

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local Fusion = SuperStack:GetModule("Fusion")
local ArgumentEntry = SuperStack:GetModule("ArgumentEntry")

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed

return function(properties)
	properties.State:set(if (properties.DefaultValue ~= nil) then properties.DefaultValue else true)

	return ArgumentEntry {
		Name = properties.Name,

		[Children] = {
			New "UIListLayout" {
				Padding = UDim.new(0, 10),
				FillDirection = "Horizontal",
				HorizontalAlignment = "Center",
				SortOrder = "LayoutOrder",
				VerticalAlignment = "Center"
			},

			New "TextButton" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = Computed(function()
					if (properties.State:get()) then
						return 0
					else
						return 1
					end
				end),
				Size = UDim2.fromScale(0.35, 0.6),
				Font = "SourceSansBold",
				Text = "True",
				TextColor3 = Computed(function()
					if (properties.State:get()) then
						return Color3.fromRGB(0, 0, 0)
					else
						return Color3.fromRGB(255, 255, 255)
					end
				end),
				TextSize = 18,

				[OnEvent "Activated"] = function()
					properties.State:set(true)
				end,

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, 15)
					}
				}
			},

			New "TextButton" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = Computed(function()
					if (properties.State:get()) then
						return 1
					else
						return 0
					end
				end),
				Size = UDim2.fromScale(0.35, 0.6),
				Font = "SourceSansBold",
				Text = "False",
				TextColor3 = Computed(function()
					if (properties.State:get()) then
						return Color3.fromRGB(255, 255, 255)
					else
						return Color3.fromRGB(0, 0, 0)
					end
				end),
				TextSize = 18,

				[OnEvent "Activated"] = function()
					properties.State:set(false)
				end,

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, 15)
					}
				}
			}
		}
	}
end