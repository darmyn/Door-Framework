local door = require(script.Parent)

local config = door.interface.config
local publicConfig = config.public
local privateConfig = config.private
local types = privateConfig.types

local doorServer = {}
doorServer.interface = {}
doorServer.schema = {}
doorServer.metatable = {__index = doorServer.schema}
setmetatable(doorServer.schema, door.metatable)

local function init(self: doorServer)
    self.activated.OnServerEvent:Connect(function(...)
        self:activated(...)
    end)
end

function doorServer.interface.new(model: Model)
    local self = setmetatable(door.interface.new(model), doorServer.metatable)
    self.activated = Instance.new("RemoteEvent")
    self.activated.Name = "activated"
    self.activated.Parent = self.model
    init(self)
    return self
end

function doorServer.schema.activated(self: doorServer, ...)
    
end

type doorModel = types.doorModel
type doorServer = typeof(doorServer.interface.new(table.unpack(...)))

return doorServer.interface