-- FractHub Core Library
-- This file contains all the core dependencies required for FractHub scripts.
-- Host this file on your GitHub repository (e.g., https://raw.githubusercontent.com/YourName/FractHub-Core/main/Core.lua)

local Core = {}

-- ==========================================
-- GoodSignal Implementation
-- (Original by stravant, lightweight version)
-- ==========================================
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _h = {} }, Signal)
end

function Signal:Connect(f)
	table.insert(self._h, f)
	return {
		Disconnect = function()
			for i, v in ipairs(self._h) do
				if v == f then
					table.remove(self._h, i)
					break
				end
			end
		end
	}
end

function Signal:Fire(...)
	for _, f in ipairs(self._h) do
		task.spawn(f, ...)
	end
end

Core.Signal = Signal

-- ==========================================
-- Promise Implementation
-- (Lightweight robust version)
-- ==========================================
local Promise = {}
Promise.__index = Promise

function Promise.new(executor)
    local self = setmetatable({
        _status = "Pending",
        _value = nil,
        _handlers = {},
    }, Promise)

    local function resolve(...)
        if self._status ~= "Pending" then return end
        self._status = "Resolved"
        self._value = {...}
        for _, handler in ipairs(self._handlers) do
            if handler.onResolve then
                task.spawn(handler.onResolve, ...)
            end
        end
    end

    local function reject(...)
        if self._status ~= "Pending" then return end
        self._status = "Rejected"
        self._value = {...}
        for _, handler in ipairs(self._handlers) do
            if handler.onReject then
                task.spawn(handler.onReject, ...)
            end
        end
    end

    local success, err = pcall(executor, resolve, reject)
    if not success and self._status == "Pending" then
        reject(err)
    end

    return self
end

function Promise:andThen(onResolve, onReject)
    if self._status == "Pending" then
        table.insert(self._handlers, {
            onResolve = onResolve,
            onReject = onReject
        })
    elseif self._status == "Resolved" and onResolve then
        task.spawn(onResolve, unpack(self._value))
    elseif self._status == "Rejected" and onReject then
        task.spawn(onReject, unpack(self._value))
    end
    return self
end

function Promise:catch(onReject)
    return self:andThen(nil, onReject)
end

function Promise:await()
    if self._status ~= "Pending" then
        return self._status == "Resolved", unpack(self._value)
    end
    
    local bindable = Instance.new("BindableEvent")
    
    self:andThen(
        function(...) bindable:Fire(true, ...) end,
        function(...) bindable:Fire(false, ...) end
    )
    
    local success, result = bindable.Event:Wait()
    bindable:Destroy()
    
    if type(result) == "table" then
        return success, unpack(result)
    end
    return success, result
end

function Promise.delay(seconds)
    return Promise.new(function(resolve)
        task.delay(seconds, resolve)
    end)
end

Core.Promise = Promise

-- ==========================================
-- Maid Implementation
-- (Lightweight resource manager)
-- ==========================================
local Maid = {}
Maid.ClassName = "Maid"

function Maid.new()
    return setmetatable({
        _tasks = {}
    }, Maid)
end

function Maid:__index(index)
    if Maid[index] then
        return Maid[index]
    else
        return self._tasks[index]
    end
end

function Maid:__newindex(index, newTask)
    if Maid[index] ~= nil then
        error(("'%s' is reserved"):format(tostring(index)), 2)
    end
    local tasks = self._tasks
    local oldTask = tasks[index]
    if oldTask == newTask then
        return
    end
    tasks[index] = newTask
    if oldTask then
        if type(oldTask) == "function" then
            oldTask()
        elseif typeof(oldTask) == "RBXScriptConnection" then
            oldTask:Disconnect()
        elseif oldTask.Destroy then
            oldTask:Destroy()
        elseif oldTask.Disconnect then
            oldTask:Disconnect()
        elseif type(oldTask) == "thread" then
            task.cancel(oldTask)
        end
    end
end

function Maid:GiveTask(task)
    if not task then
        error("Task cannot be false or nil", 2)
    end
    local taskId = #self._tasks + 1
    self[taskId] = task
    return taskId
end

function Maid:DoCleaning()
    local tasks = self._tasks
    for index, job in pairs(tasks) do
        if type(job) == "function" then
            job()
        elseif typeof(job) == "RBXScriptConnection" then
            job:Disconnect()
        elseif type(job) == "thread" then
            task.cancel(job)
        elseif job.Destroy then
            job:Destroy()
        elseif job.Disconnect then
            job:Disconnect()
        end
        tasks[index] = nil
    end
    self._tasks = {}
end

function Maid:Destroy()
    self:DoCleaning()
end

Core.Maid = Maid

return Core
