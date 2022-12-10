local runService = game:GetService("RunService")

local signal = {}

local function newSignal()
    local self = setmetatable({}, {__index = signal})
    self.connections = {
        callbacks = {},
        waiting = {}
    }
    return self
end

function signal.connect(self: signal, callback: callback)
    local callbacks = self.connections.callbacks
    table.insert(callbacks, callback)
    return {
        disconnect = function()
            local index = table.find(callbacks, callback)
            if index then
                table.remove(callbacks, index)
            end
        end
    }
end

function signal.fire(self: signal, ...)
    local connections = self.connections
    for _, connection in pairs(connections.callbacks) do
        connection(...)
    end
    for _, waiting in pairs(connections.waiting) do
        waiting(...)
    end
    table.clear(connections.waiting)
end

function signal.wait(self: signal)
    local result
    table.insert(self.connections.waiting, function(...)
        result = table.pack(...)
    end)
    while not result do
        runService.Heartbeat:Wait()
    end
    return table.unpack(result)
end

type callback = (...any) -> ...any
type signal = typeof(newSignal())
export type Type = signal

--[[
do
    local test = newSignal()
    test:connect(function(arg1, arg2, arg3)
        print("I've been fired")
        print(arg1, arg2, arg3)
        return 5, 190, "lol"
    end)
    task.spawn(function()
        print("starting wait")
        local arg1, arg2, arg3 = test:wait()
        print("wait ended")
        print(arg1, arg2, arg3)
    end)
    task.wait(2)
    test:fire(21, "loll", true)
end
--]]

return {
    new = newSignal
}