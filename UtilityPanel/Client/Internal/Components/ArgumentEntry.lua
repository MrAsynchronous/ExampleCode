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
		Size = UDim2.new(.975, 0, 0, if properties.Size then properties.Size else 65),
		Padding = 6,
		ZIndex = properties.ZIndex or 1,

		[Children] = {
			New "TextLabel" {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, -0.05),
				Size = UDim2.fromScale(1, 0.368),
				Font = "SourceSansBold",
				Text = properties.Name,
				TextColor3 = Color3.fromRGB(255, 255 ,255),
				TextSize = 20
			},

			StyledFrame {
				Name = "InputContainer",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromScale(1, 0.632),

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, 15)
					},

					properties[Children]
				}
			}
		}
	}
end