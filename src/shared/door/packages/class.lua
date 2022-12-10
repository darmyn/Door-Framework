return function(constructor: (object: any) -> any)
    local self = {}
    self.interface = {}
    self.schema = {}
    self.metatable = {__index = self.schema}

    function self.interface.new()
        local object = setmetatable({}, self.metatable)
        constructor(object)
        return object
    end

    return self
end