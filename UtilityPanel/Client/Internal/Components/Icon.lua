-- Icon
-- Brandon Wilcox
-- 01/04/2022

--[[

	Creates an icon that scales at the right aspect ratio

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)
local Fusion = SuperStack:GetModule("Fusion")

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children


return function(properties)
	return New "ImageButton" {
		Image = properties.Image,
		BackgroundTransparency = 1,
		Position = properties.Position,
		Rotation = properties.Rotation,
		ImageColor3 = properties.ImageColor3,
		Size = properties.Size or UDim2.fromScale(1, 1),
		AnchorPoint = properties.AnchorPoint or Vector2.new(0.5, 0.5),

		[OnEvent "Activated"] = properties.OnClick,
		
		[Children] = {
			New "UIAspectRatioConstraint" {
				AspectRatio = properties.AspectRatio or 1,
				AspectType = "FitWithinMaxSize",
				DominantAxis = "Width"
			}
		}
	}
end