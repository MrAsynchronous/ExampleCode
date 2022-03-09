-- Topbar
-- Brandon Wilcox
-- 01/04/2022

--[[

	Creates a topbar for the debug UI

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local Fusion = SuperStack:GetModule("Fusion")
local Searchbox = SuperStack:GetModule("Searchbox")
local StyledFrame = SuperStack:GetModule("StyledFrame")
local Icon = SuperStack:GetModule("Icon")

local New = Fusion.New
local Children = Fusion.Children


return function(properties)
	return New "Frame" {
		Name = "Topbar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(1, 0.1),
		BackgroundTransparency = 1,
		ZIndex = 15,

		[Children] = {
			Icon {
				AspectRatio = 0.816,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Image = properties.Favicon or "rbxassetid://8447675061",
				ImageColor3 = Color3.fromRGB(255, 255, 255)
			},
			
			StyledFrame {
				AnchorPoint = Vector2.new(1, 0.5),
				Size = UDim2.fromScale(.055, .8),
				Position = UDim2.fromScale(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(231, 76, 60),
				StrokeColor = Color3.fromRGB(255, 255, 255),

				[Children] = {
					Icon {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Image = "rbxassetid://8910288701",
						ImageColor3 = Color3.fromRGB(255, 255, 255),

						OnClick = function()
							properties.OpenState:set(not properties.OpenState:get())
						end
					},
				}
			},

			New "TextLabel" {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromScale(0.5, 0.5),
				Position = UDim2.fromScale(0.075, 0.5),

				TextScaled = true,
				TextXAlignment = "Left",
				Font = "SourceSansBold",
				Text = properties.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255)
			},

			Searchbox {
				Text = properties.SearchText,
				Database = properties.SearchDB,
				ItemSelected = properties.SearchResultSelected
			}
		}
	}
end