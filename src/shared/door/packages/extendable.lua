local class = require(script.Parent.class)

local function constructor(self)
    self.x = 5
    self.y = 2
    return self
end

local extendable = class(constructor)

function extendable.schema.test(self: schema)
    self.
end

type prototype = typeof(constructor())
type schema = typeof(extendable.schema)
type extendable = prototype & schema

return extendable.interface