-- SchedulerService
-- MrAsync
-- 02/28/2022


local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SuperStack = require(ReplicatedStorage.SuperStack.SuperStack)

local RunService = game:GetService("RunService")

local TypeValidator = SuperStack:GetModule("TypeValidator")

local SchedulerService = {}
SchedulerService.__index = SchedulerService

function SchedulerService.new()
	local self = setmetatable({}, SchedulerService)
	
	self._Schedule = {}

	return self
end

--[[
	Adds a new task to the schedule to be executed every interval

	@param taskName string
	@param interval number
	@param taskRunner (nil) -> nil

	@return nil
]]
function SchedulerService:AddTask(taskName: string, interval: number, taskRunner: (nil) -> nil): nil
	if (not TypeValidator:Validate(taskName, "string") or
		not TypeValidator:Validate(interval, "number") or
		not TypeValidator:Validate(taskRunner, "function")) then
			
		return
	end

	-- Don't allow more than one task with the same name
	if (self._Schedule[taskName]) then
		return warn(string.format("Task with name %s already exists!", taskName))
	end

	-- Insert task into schedule
	self._Schedule[taskName] = {
		NextExecution = os.time() + interval,
		TaskRunner = taskRunner,
		Interval = interval
	}
end

--[[
	Removes a task from the schedule

	@param taskName string

	@return nil
]]
function SchedulerService:RemoveTask(taskName: string): nil
	self._Schedule[taskName] = nil
end

--[[
	Returns true if a task with the given name exists in the schedule, false otherwise

	@param tasksName string
	
	@return boolean
]]
function SchedulerService:HasTask(taskName: string): boolean
	return (self._Schedule[taskName] ~= nil)
end

--[[
	Returns the number in seconds until the task with the given taskName is next
	executed

	@param taskName

	@return number
]]
function SchedulerService:GetTimeUntilNextExecution(taskName: string): number
	local taskInfo = self._Schedule[taskName]
	if (not taskInfo) then return 0 end

	local now = os.time()

	return (taskInfo.NextExecution - now)
end

--[[
	Starts executing tasks in the schedule
]]
function SchedulerService:Initialize()
	RunService.Stepped:Connect(function()
		local now = os.time()
		
		-- Iterate through all tasks
		for taskName, taskInfo in pairs(self._Schedule) do

			-- Only execute at the proper interval3
			if (now < taskInfo.NextExecution) then continue end
			taskInfo.NextExecution = (now + taskInfo.Interval)

			-- Synchronously execute runner
			task.spawn(function()
				-- Scafely call task runner
				local success = pcall(taskInfo.TaskRunner)
				
				-- Handle error case
				if (not success) then
					warn(string.format("Couldn't execute task %s!", taskName))
				end
			end)
		end
	end)
end

local Singleton = SchedulerService.new()
return Singleton