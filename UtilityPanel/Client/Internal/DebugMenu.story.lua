local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local Fusion = SuperStack:GetModule("Fusion")
local DebugMenu = SuperStack:GetModule("DebugMenuCore")
local Signal = SuperStack:GetModule("Signal")
local Maid = SuperStack:GetModule("Maid")


return function(target)
    local maid = Maid.new()
	local signal = Signal.new()

	signal:Connect(function(menuName, categoryName, actionName, parameters)
		print(string.format("%s -> %s -> %s", menuName, categoryName, actionName))
		print(parameters)
	end)

	local debugMenu = DebugMenu {
		Name = "First Panel",
		ActionExecuted = signal,
		Categories = {
			{
				CategoryName = "First Category",
				CategoryOrder = 1,
				CategoryActions = {
					{
						ActionName = "First Action",
						ActionGuid = "ABC123",
						ActionOrder = 1,
						ActionVariables = {
							{Name = "Player to Kill", Type = "Enum", Data = {
								"MrAsync",
								"Koob85",
								"Synthhhh",
								"Cheekysquid"
							}, DefaultValue = "Koob85"},
							{Name = "Loopkill", Type = "Vector3"}
						}
					},
					{
						ActionName = "First 2",
						ActionGuid = "ABC123a",
						ActionOrder = 1,
						ActionVariables = {
							{Name = "Player to Kill", Type = "Enum", Data = {
								"MrAsync",
								"Koob85",
								"Synthhhh",
								"Cheekysquid"
							}},
							{Name = "Loopkill", Type = "boolean"},
						}
					}
				}
			},
			{
				CategoryName = "Second Category",
				CategoryOrder = 2,
				CategoryActions = {
					{
						ActionName = "Test Action",
						ActionGuid = "ABC123456",
						ActionOrder = 1,
						ActionVariables = {}
					}
				}
			}
		}
	}

	debugMenu.Parent = target
	maid:GiveTask(debugMenu)

    return function()
        maid:DoCleaning()
    end
end