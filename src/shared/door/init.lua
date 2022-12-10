local config = require(script.config)

local publicConfig = config.public
local privateConfig = config.private

local types = privateConfig.types
local outputMessages = privateConfig.outputMessages
local doorModelComponentNames = publicConfig.doorModelComponentNames

local door = {}
door.interface = {
    config = config,
    extensions = script.extensions
}
door.schema = {}
door.metatable = {__index = door.schema}

--[[   If the `instance` contains an attribute listed under the provided `attributeName`, and the attributes value's type is the same as `expectedType`,
         the attribute will be assigned as a property of the given `object`.   ]]
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

local function assertDoorModel(model: doorModel)
    assert(
        model:FindFirstChild(doorModelComponentNames.Hinge) and model:IsA("BasePart"), 
        outputMessages.missingOrIncorrectComponentOfModel:format("door", "Hinge", "BasePart")
    )
    assert(
        model:FindFirstChild(doorModelComponentNames.Hitbox) and model:IsA("BasePart"),
        outputMessages.missingOrIncorrectComponentOfModel:format("door", "Hitbox", "BasePart")
    )
    local handle: BasePart? = model:FindFirstChild(doorModelComponentNames.Handle)
    if handle then
        assert(
            handle:IsA("BasePart"),
            outputMessages.missingOrIncorrectComponentOfModel:format("door", "Handle", "BasePart")
        )
    end
    local lock: BasePart? = model:FindFirstChild(doorModelComponentNames.Lock)
    if lock then
        assert(
            lock:IsA("BasePart"),
            outputMessages.missingOrIncorrectComponentOfModel:format("door", "Lock", "BasePart")
        )
    end
    return model.Hinge, model.Hitbox, handle, lock
end

function door.interface.new(model: doorModel)
    local hinge, hitbox, handle, lock = assertDoorModel(model)
    local self = setmetatable(publicConfig.defaultProperties(), door.metatable)
    assignAttributeToObject(self, model, "activationRange", "number")
    assignAttributeToObject(self, model, "activationCooldown", "number")
    assignAttributeToObject(self, model, "locked", "boolean")
    assignAttributeToObject(self, model, "mode", "string")
    self.model = model
    self.hinge = hinge
    self.hitbox = hitbox
    self.handle = handle
    self.lock = lock
    return self
end

type door = typeof(door.interface.new(table.unpack(...)))
type doorModel = types.doorModel

return door