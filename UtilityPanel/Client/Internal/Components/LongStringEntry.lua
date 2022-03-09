-- StringEntry
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
local OnChange = Fusion.OnChange
local Children = Fusion.Children


return function(properties)
	return StyledFrame {
		Size = UDim2.new(.975, 0, 0, 150),
		Padding = 6,

		[Children] = {
			New "TextLabel" {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, -.025),
				Size = UDim2.new(1, 0, 0, 20),
				Font = "SourceSansBold",
				Text = properties.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20
			},

			StyledFrame {
				Name = "InputContainer",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, 0),
				Size = UDim2.new(1, 0, .85, 0),
				Padding = 0,

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, 15)
					},

					New "UIPadding" {
						PaddingTop = UDim.new(0, 5),
						PaddingBottom = UDim.new(0,5),
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5)
					},
		
					New "TextBox" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
		
						Font = "SourceSansBold",
						PlaceholderText = "Enter String",
						Text = properties.DefaultValue,
						TextYAlignment = "Top",
						TextWrap = "true",
						TextSize = 18,
						TextColor3 = Color3.fromRGB(255, 255, 255),
		
						[Children] = {
							New "UICorner" {
								CornerRadius = UDim.new(0, 15)
							}
						},
		
						[OnChange "Text"] = function(newText)
							properties.State:set(newText)
						end
					}
				}
			},
		}
	}
end