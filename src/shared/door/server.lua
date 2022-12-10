local players = game:GetService("Players")

local door = require(script.Parent)
local config = require(script.Parent.config)

local privateConfig = config.private
local outputMessages = privateConfig.outputMessages
local types = privateConfig.types
local doorActivated: RemoteEvent
local activeDoorObjects = {} :: {[Model]: doorServer}

--[[    Fires all clients through the provided `event` excluding the `excludedPlayer`.
            Additional arguments `...` provided will be passed through the remote event.   ]]
local function fireRemoteEventToAllExcept(event: RemoteEvent, excludedPlayer: Player, ...)
    for _, replicationTarget in pairs(players:GetPlayers()) do
        if replicationTarget ~= excludedPlayer then
            event:FireClient(replicationTarget, ...)
        end
    end
end

--[[    When the `player` signals to the server that it has activated a door, it will pass the `doorModel`, which will be
            used to index the corresponding object and it's `:activated()` method, passing the `player` as an argument.    ]]
local function dispatchDoorActivated(player: Player, doorModel: Model)
    if doorModel and typeof(doorModel) == "Instance" and doorModel:IsA("Model") then
        local activeDoorObject = activeDoorObjects[doorModel]
        if activeDoorObject then
            activeDoorObject:activated(player)
        end
    end
end

local function connectDoorNetwork()
    doorActivated.OnServerEvent:Connect(dispatchDoorActivated)
end

local function initializeDoorNetwork()
    doorActivated = Instance.new("RemoteEvent")
    doorActivated.Name = "activated"
    doorActivated.Parent = script.Parent
    connectDoorNetwork()
end

local function initializeModule()
    initializeDoorNetwork()
end

local function initializeServerExtensions() : {extension}
    local output = {}
    for _, extension in pairs(script.Parent.extensions:GetChildren()) do
        extension = (extension:IsA("ModuleScript")) and extension or extension:FindFirstChild("server")
        if extension:IsA("ModuleScript") then
            table.insert(output, door.util.loadExtension(extension))
        end
    end
    return output
end

local extensions = initializeServerExtensions()
local doorServer = {}
doorServer.interface = {}
doorServer.schema = {}
doorServer.metatable = {__index = doorServer.schema}
setmetatable(doorServer.schema, door.metatable)

local function initializeDoorModel(model: doorModel)
    local hinge = model.Hinge
    local hitbox = model.Hitbox
    hinge.Anchored = true
    for _, modelComponent: BasePart in pairs(model:GetDescendants()) do
        if modelComponent:IsA("BasePart") then
            local weldConstraint: WeldConstraint = Instance.new("WeldConstraint")
            weldConstraint.Part0 = modelComponent
            weldConstraint.Part1 = hinge
            weldConstraint.Parent = modelComponent
            if modelComponent == hitbox then
                modelComponent.CanCollide = true
            end
            modelComponent.Anchored = false
        end
    end
end

local function loadExtensions(self: doorServer)
    for _, extension in pairs(extensions) do
        extension.init(self)
    end
end

local function initializeDoorObject(self: doorServer)
    initializeDoorModel(self.model)
    loadExtensions(self)
end

function doorServer.interface.new(model: doorModel)
    local self = setmetatable(door.interface.new(model), doorServer.metatable)
    initializeDoorObject(self)
    return self
end

function doorServer.schema.activated(self: doorServer, player: Player)
    local rejected = false
    local function reject()
        rejected = true
    end
    self.signals.activated:fire(player, reject)
    if not rejected then
        self.signals.activationConfirmed:fire(player)
        fireRemoteEventToAllExcept(doorActivated, player, self.model, player)
    else
        self.signals.activationRejected:fire(player)
    end
end

type doorModel = types.doorModel
type extension = types.extension
type doorServer = typeof(doorServer.interface.new(table.unpack(...)))

initializeModule()
return doorServer.interface