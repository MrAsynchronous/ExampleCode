-- EnumEntry
-- Brandon Wilcox
-- 01/04/2022

--[[

	Creates a styled button

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local StyledFrame = SuperStack:GetModule("StyledFrame")
local Fusion = SuperStack:GetModule("Fusion")
local Icon = SuperStack:GetModule("Icon")

local New = Fusion.New
local State = Fusion.State
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local ComputedPairs = Fusion.ComputedPairs


return function(properties)
	local openState = State(false)
	local selection = properties.State
	selection:set(properties.DefaultValue or properties.Values[1])

	local numItems = math.clamp(#properties.Values, 1, 4)

	return StyledFrame {
		Size = Computed(function()
			if (openState:get()) then
				return UDim2.new(1, 0, 0, 67 + (numItems * 30) + ((numItems - 1) * 10) + 25)
			else
				return UDim2.new(1, 0, 0, 67)
			end
		end),
		Padding = 4,
		ZIndex = 10,

		[Children] = {
			New "TextLabel" {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.new(1, 0, 0, 20),
				Font = "SourceSansBold",
				Text = properties.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20
			},

			New "Frame" {
				Name = "InputContainer",
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				Position = UDim2.new(0.5, 0, 0, 22),
				Size = UDim2.new(1, 0, 0, 36),

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, 15)
					},

					New "TextButton" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						Position = UDim2.fromScale(0.5, 0.5),
		
						Font = "SourceSansBold",
						Text = Computed(function()
							return selection:get()
						end),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 18,
		
						[OnEvent "Activated"] = function()
							openState:set(not openState:get())
						end
					},
		
					Icon {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(0.951, 0.5),
						Size = UDim2.fromScale(0.089, 0.486),
						Rotation = Computed(function()
							return if openState:get() then 90 else -90
						end),
						Image = "rbxassetid://6088189489",
						ImageColor3 = Color3.fromRGB(255, 255, 255),
		
						OnClick = function()
							openState:set(not openState:get())
						end
					}
				}
			},

			New "Frame" {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Visible = Computed(function()
					return openState:get()
				end),

				Position = UDim2.new(0.5, 0, 0, 64),
				Size = Computed(function()
					if (openState:get()) then
						return UDim2.new(1, 0, 0, (numItems * 30) + ((numItems - 1) * 10) + 20)
					else
						return UDim2.fromScale(1, 0)
					end
				end),
				ClipsDescendants = true,
				ZIndex = 15,

				[Children] = {
					StyledFrame {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Visible = Computed(function()
							return openState:get()
						end),
		
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(.965, .965),
		
						[Children] = {
							New "UICorner" {
								CornerRadius = UDim.new(0, 15)
							}
						}
					},

					New "ScrollingFrame" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(.96, 1),
						AutomaticCanvasSize = "Y",
						BorderSizePixel = 0,
						CanvasSize = UDim2.fromScale(0, 0),
						BackgroundTransparency = 1,
						VerticalScrollBarInset = "Always",
						ScrollBarThickness = 6,
						ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),

						[Children] ={ 
							New "UIListLayout" {
								Padding = UDim.new(0, 10),
								FillDirection = "Vertical",
								VerticalAlignment = "Top",
								HorizontalAlignment = "Center"
							},
							
							New "UIPadding" {
								PaddingTop = UDim.new(0, 10),
								PaddingBottom = UDim.new(0, 10),
							},

							ComputedPairs(properties.Values, function(index, value)
								return StyledFrame {
									AnchorPoint = Vector2.new(0.5, 0),
									BackgroundColor3 = Color3.fromRGB(25, 25, 25),
									Size = UDim2.new(.9, 0, 0, 30),

									[Children] = {
										New "UICorner" {
											CornerRadius = UDim.new(0, 15)
										},

										New "TextButton" {
											AnchorPoint = Vector2.new(0.5, 0.5),
											BackgroundTransparency = 1,
											Position = UDim2.fromScale(0.5, 0.5),
											Size = UDim2.fromScale(1, 0.6),

											Font = "SourceSansBold",
											Text = value,
											TextSize = 18,
											TextColor3 = Color3.fromRGB(255, 255, 255),

											[OnEvent "Activated"] = function()
												selection:set(value)
												openState:set(false)
											end
										}
									}
								}
							end)
						}
					}
				}
			}
		}
	}
end