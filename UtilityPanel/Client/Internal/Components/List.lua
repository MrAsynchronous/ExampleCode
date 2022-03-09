local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local Fusion = SuperStack:GetModule("Fusion")
local ItemEntry = SuperStack:GetModule("ItemEntry")
local StyledFrame = SuperStack:GetModule("StyledFrame")

local New = Fusion.New
local State = Fusion.State
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local ComputedPairs = Fusion.ComputedPairs
local Children = Fusion.Children

local t = "8456591184"

local function ChangeSort(currentSort: number): number
	local newSort = currentSort + 1
	return if newSort > 3 then 1 else newSort
end

local function CreateEntries(data, sort, properties)
	if (properties.Entries) then return properties.Entries end

	-- Sort data
	table.sort(data, function(a, b)
		if (sort == 1) then
			return a.Order < b.Order
		elseif (sort == 2) then
			return a.Name < b.Name
		elseif (sort == 3) then
			return a.Name > b.Name
		end
	end)

	-- Return created array
	return ComputedPairs(data, function(index, listItem)
		return ItemEntry {
			Name = index,
			Text = listItem.Name,

			StrokeColor = Computed(function()
				local selectedItem = properties.SelectedItem:get()
				local actionName = selectedItem.ActionName
				local categoryName = selectedItem.CategoryName

				if (actionName == listItem.Name or categoryName == listItem.Name) then
					return Color3.fromRGB(255, 255, 255)
				else
					return Color3.fromRGB(60, 60, 60)
				end
			end),
			BackgroundColor3 = Computed(function()
				local selectedItem = properties.SelectedItem:get()
				local actionName = selectedItem.ActionName
				local categoryName = selectedItem.CategoryName

				if (actionName == listItem.Name or categoryName == listItem.Name) then
					return Color3.fromRGB(50, 50, 50)
				else
					return Color3.fromRGB(25, 25, 25)
				end
			end),

			ItemSelected = function()
				return properties.ItemSelected(listItem.Name)
			end
		}
	end)
end

return function(properties)
	local entries = State({})
	local sort = State(1)

	-- Create function to update entries
	local function updateEntries()
		entries:set(CreateEntries(
			properties.Source:get(),
			sort:get(),
			properties
		))
	end

	-- Update entries if owner asks us
	if (properties.UpdatedSignal) then
		properties.UpdatedSignal:Connect(updateEntries)
	end

	-- Initially populate entries
	updateEntries()

	return StyledFrame {
		Name = properties.Name,
		-- NoStroke = true,
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromScale(.32, .95),

		[Children] = {
			New "TextLabel" {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.065),
				Position = UDim2.new(0.5, 0, 0, -5),

				TextScaled = true,
				TextYAlignment = "Top",
				Font = "SourceSansBold",
				Text = properties.Title or properties.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
			},

			New "ImageButton" {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 1),
				Size = UDim2.fromScale(0.1, 0.065),
				Position = UDim2.fromOffset(0, -5),

				Image = "rbxassetid://8456955874",
				ImageColor3 = Color3.fromRGB(255, 255, 255),

				Visible = if properties.DisableSort then false else true,

				[OnEvent "Activated"] = function()
					sort:set(ChangeSort(sort:get()))

					-- Update entries
					updateEntries()
				end
			},

			New "ScrollingFrame" {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromScale(1, 1),

				AutomaticCanvasSize = "Y",
				CanvasSize = UDim2.fromScale(0, 0),
				ScrollBarThickness = 4,
				VerticalScrollBarInset = "ScrollBar",

				[Children] = {
					New "UIListLayout" {
						Padding = UDim.new(0, 5),
						HorizontalAlignment = "Center",
						SortOrder = "Name",
						VerticalAlignment = "Top"
					},

					New "UIPadding" {
						PaddingRight = UDim.new(0, 5)
					},

					entries
				}
			},
		}
	}
end