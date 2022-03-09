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
local State = Fusion.State
local OnChange = Fusion.OnChange
local Children = Fusion.Children
local Computed = Fusion.Computed

return function(properties)
	local xState = State(if (properties.DefaultValue) then properties.DefaultValue.X else 0)
	local yState = State(if (properties.DefaultValue) then properties.DefaultValue.Y else 0)
	local zState = State(if (properties.DefaultValue) then properties.DefaultValue.Z else 0)

	local getState = Computed(function()
		return Vector3.new(xState:get(), yState:get(), zState:get())
	end)

	properties.State:set(getState:get())

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

			New "UIPadding" {
				PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0,5),
				PaddingLeft = UDim.new(0, 15),
				PaddingRight = UDim.new(0, 15)
			},

			New "TextBox" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(.3, .98),

				Font = "SourceSansBold",
				Text = xState:get(),
				TextSize = 18,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, 15)
					}
				},

				[OnChange "Text"] = function(newText)
					xState:set(tonumber(newText))

					properties.State:set(getState:get())
				end
			},
			New "TextBox" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(.3, 1),

				Font = "SourceSansBold",
				Text = yState:get(),
				TextSize = 18,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, 15)
					}
				},

				[OnChange "Text"] = function(newText)
					yState:set(tonumber(newText))

					properties.State:set(getState:get())
				end
			},
			New "TextBox" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(.3, 1),

				Font = "SourceSansBold",
				Text = zState:get(),
				TextSize = 18,
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				TextColor3 = Color3.fromRGB(255, 255, 255),

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, 15)
					}
				},

				[OnChange "Text"] = function(newText)
					zState:set(tonumber(newText))

					properties.State:set(getState:get())
				end
			}
		}
	}
end