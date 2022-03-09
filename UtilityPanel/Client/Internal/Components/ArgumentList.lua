local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local Fusion = SuperStack:GetModule("Fusion")
local ItemEntry = SuperStack:GetModule("ItemEntry")
local StyledFrame = SuperStack:GetModule("StyledFrame")

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

return function(properties)
	return StyledFrame {
		Name = properties.Name,
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromScale(.32, .95),
		AutomaticSize = properties.AutomaticSize,

		[Children] = {
			New "TextLabel" {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.065),
				Position = UDim2.new(0.5, 0, 0, -7),

				TextScaled = true,
				TextYAlignment = "Top",
				Font = "SourceSansBold",
				Text = properties.Title or properties.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
			},

			StyledFrame {
				BackgroundColor3 = Color3.fromRGB(253, 140, 51),
				StrokeColor = Color3.fromRGB(255, 255, 255),

				Size = UDim2.new(1, -10, 0, 45),
				Position = UDim2.new(0.5, 0, .988, 0),
				AnchorPoint = Vector2.new(0.5, 1),

				[Children] = {

					New "UIPadding" {
						PaddingBottom = UDim.new(0, 15)
					},
		
					New "TextButton" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						
						BackgroundTransparency = 1,
						Font = "SourceSansBold",
						Text = "Execute",
						TextColor3 = Color3.fromRGB(25, 25, 25),
						TextSize = 22,

						[OnEvent "Activated"] = properties.Executed
					}
				}
			},

			New "ScrollingFrame" {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.fromScale(1, .85),

				AutomaticCanvasSize = "Y",
				CanvasSize = UDim2.fromScale(0, 0),
				ScrollBarThickness = 4,
				VerticalScrollBarInset = "ScrollBar",
				ZIndex = 10,

				[Children] = {
					New "UIListLayout" {
						Padding = UDim.new(0, 10),
						HorizontalAlignment = "Center",
						SortOrder = "Name",
						VerticalAlignment = "Top"
					},

					New "UIPadding" {
						PaddingRight = UDim.new(0, 5),
						PaddingTop = UDim.new(0, 4),
						PaddingLeft = UDim.new(0, 3)
,					},

					properties.ArgumentFrames
				}
			},
		}
	}
end