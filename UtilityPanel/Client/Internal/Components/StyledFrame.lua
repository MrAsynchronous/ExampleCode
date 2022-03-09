-- StyledFrame
-- Brandon Wilcox
-- 01/04/2022

--[[

	Creates a container frame in the style of this UI. This includes a 15px UICorner and 5px UIStroke

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)
local Fusion = SuperStack:GetModule("Fusion")

local New = Fusion.New
local State = Fusion.State
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Children = Fusion.Children

return function(properties)
	local drag = State()
	local position = State(properties.Position or UDim2.fromScale(0.5, 0.5))

	local camera = Workspace.CurrentCamera

	if (properties.Draggable) then
		local scalePosition = position:get()

		local viewportSize = camera.ViewportSize
		local newPosition = UDim2.fromOffset(
			viewportSize.X * scalePosition.X.Scale,
			viewportSize.Y * scalePosition.Y.Scale
		)
		
		position:set(newPosition)
	end

	return New "Frame" {
		Name = properties.Name,
		AnchorPoint = properties.AnchorPoint or Vector2.new(0.5, 0.5),
		BackgroundColor3 = properties.BackgroundColor3 or Color3.fromRGB(25, 25, 25),
		Position = Computed(function()
			return position:get()
		end),
		Size = properties.Size or UDim2.fromScale(1, 1),
		Visible = if properties.Visible ~= nil then properties.Visible else true,
		AutomaticSize = properties.AutomaticSize,
		ZIndex = properties.ZIndex or 1,
		LayoutOrder = properties.LayoutOrder or 1,

		[OnEvent "InputBegan"] = function(inputObject)
			if (not properties.Draggable) then return end

			if (inputObject.UserInputType == Enum.UserInputType.MouseButton1) then
				local start = position:get()

				drag:set(RunService.RenderStepped:Connect(function()
					local newPos = UserInputService:GetMouseLocation()
					local change = newPos - Vector2.new(start.X.Offset, start.Y.Offset)

					local newPosition = UDim2.fromOffset(
						start.X.Offset + change.X,
						start.Y.Offset + change.Y
					)
					
					position:set(newPosition)
				end))
				
			end
		end,

		[OnEvent "InputEnded"] = function(inputObject)
			if (not properties.Draggable) then return end

			if (inputObject.UserInputType == Enum.UserInputType.MouseButton1) then
				drag:get():Disconnect()
			end
		end,

		[Children] = {
			New "UICorner" {
				CornerRadius = UDim.new(0, 15)
			},

			New "UIStroke" {
				Color = properties.StrokeColor or Color3.fromRGB(60, 60, 60),
				Thickness = if properties.NoStroke then 0 else 3
			},

			New "UIPadding" {
				PaddingTop = UDim.new(0, properties.Padding or 5),
				PaddingBottom = UDim.new(0, properties.Padding or 5),
				PaddingLeft = UDim.new(0, properties.Padding or 5),
				PaddingRight = UDim.new(0, properties.Padding or 5)
			},

			properties[Children]
		}
	}
end