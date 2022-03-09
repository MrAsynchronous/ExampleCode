-- ItemEntry
-- Brandon Wilcox
-- 01/04/2022

--[[

	Creates a styled button

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local Fusion = SuperStack:GetModule("Fusion")
local StyledFrame = SuperStack:GetModule("StyledFrame")

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children


return function(properties)
	return StyledFrame {
		BackgroundColor3 = properties.StrokeColor,
		Size = UDim2.new(1, 0, 0, 40),
		Padding = 4,
		NoStroke = true,

		[Children] = {
			New "Frame" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = properties.BackgroundColor3,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, 15)
					}
				}
			},

			New "TextButton" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),

				Font = "SourceSansBold",
				Text = properties.Text,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = "18",

				[OnEvent "Activated"] = properties.ItemSelected
			}
		}
	}
end