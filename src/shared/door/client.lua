local players = game:GetService("Players")

local door = require(script.Parent)
local config = require(script.Parent.config)

local privateConfig = config.private
local publicConfig = config.public
local moduleSettings = publicConfig.moduleSettings
local outputMessages = privateConfig.outputMessages
local types = privateConfig.types
local doorActivationReplicated: RemoteEvent
local activeDoorObjects = {} :: {[Model]: doorServer}

local function dispatchDoorActivationReplicated(doorModel: doorModel, ...)
    local activeDoorObject = activeDoorObjects[doorModel]
    if activeDoorObject then
        print("xyz")
    elseif moduleSettings.showWarnings then
        warn(outputMessages.doorObjectDoesNotExistInEnvironment:format("server"), "Model: ", doorModel)
    end
end

local function connectDoorNetwork()
    doorActivationReplicated.OnClientEvent:Connect(dispatchDoorActivationReplicated)
end

local function initializeDoorNetwork()
    doorActivationReplicated = Instance.new("RemoteEvent")
    doorActivationReplicated.Name = "activated"
    doorActivationReplicated.Parent = script.Parent
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
        fireRemoteEventToAllExcept(doorActivated, player, player)
    else
        self.signals.activationRejected:fire(player)
    end
end

type doorModel = types.doorModel
type extension = types.extension
type doorServer = typeof(doorServer.interface.new(table.unpack(...)))

initializeModule()
return doorServer.interface