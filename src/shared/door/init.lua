local packages = script.packages
local config = require(script.config)
local signal = require(packages.signal)

local publicConfig = config.public
local privateConfig = config.private
local types = privateConfig.types
local outputMessages = privateConfig.outputMessages
local doorModelComponentNames = publicConfig.doorModelComponentNames

local door = {}
door.util = {}
door.interface = {}
door.schema = {}
door.metatable = {__index = door.schema}

--[[    If the `instance` contains an attribute listed under the provided `attributeName`, and the attributes value's type is the same as `expectedType`,
            the attribute will be assigned as a property of the given `object`.     ]]
local function assignAttributeToObject(object, instance: Instance, attributeName: string, expectedType: string)
    local attributeValue = instance:GetAttribute(attributeName)
    if attributeValue then
        local attributeValueType = typeof(attributeValue)
        assert(
            attributeValueType == expectedType, 
        outputMessages.incorrectAttributeType:format(attributeName, attributeValueType, expectedType)
        )
        object[attributeName] = attributeValue
    end
end

--[[    Ensures that the `model` meets the systems basic expectations of the Instance hierarchy.  ]]
local function assertDoorModel(model: doorModel)
    assert(
        model:FindFirstChild(doorModelComponentNames.Hinge) and model:IsA("BasePart"), 
        outputMessages.missingOrIncorrectComponentOfModel:format("door", "Hinge", "BasePart")
    )
    assert(
        model:FindFirstChild(doorModelComponentNames.Hitbox) and model:IsA("BasePart"),
        outputMessages.missingOrIncorrectComponentOfModel:format("door", "Hitbox", "BasePart")
    )
    return model.Hinge, model.Hitbox
end

local function connectDestroyMethod(self: door)
    self.model.Destroying:Connect(function()
        self:destroy()
    end)
end

local function initializeDoorObject(self: door)
    connectDestroyMethod(self)
end

function door.interface.new(model: doorModel)
    local hinge, hitbox = assertDoorModel(model)
    local self = setmetatable(publicConfig.defaultProperties(), door.metatable)
    assignAttributeToObject(self, model, "activationRange", "number")
    assignAttributeToObject(self, model, "activationCooldown", "number")
    assignAttributeToObject(self, model, "locked", "boolean")
    assignAttributeToObject(self, model, "mode", "string")
    self.model = model
    self.hinge = hinge
    self.hitbox = hitbox
    self._extensionsIntialized = {}
    self.signals = {
        activated = signal.new(),
        activationConfirmed = signal.new(),
        activationRejected = signal.new(),
        destroying = signal.new()
    }
    initializeDoorObject(self)
    return self
end

function door.util.loadExtension(self: door, extension: ModuleScript)
    if extension:IsA("ModuleScript") then
        local loadedExtension: extension = require(extension)
        local init = loadedExtension.init
        assert(init and typeof(init) == "function", outputMessages.missingExtensionInitializer:format(extension.Name))
        self._extensionsIntialized[extension] = true
        return loadedExtension
    end
end

function door.util.waitForExtension(self: door, extensionName: string, timeout: number?)
    timeout = timeout or 10
    local waitBeganTimestamp = time()
    while not self._extensionsIntialized[extensionName] do
        local timeElapsed = time() - waitBeganTimestamp
        if timeElapsed > timeout then
            if publicConfig.moduleSettings.showWarnings then
                warn(outputMessages.waitTimeExceededExpectation:format(timeElapsed, timeout, "`"..extensionName.."` extension to load."))
            end
        end
        task.wait()
    end
end

function door.schema.destroy(self: door)
    self.signals.destroying:fire()
    setmetatable(self, nil)
    table.clear(self)
end

type door = typeof(door.interface.new(table.unpack(...)))
type doorModel = types.doorModel
type extension = types.extension

return door