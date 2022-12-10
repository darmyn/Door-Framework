local modes = require(script.Parent.Parent.private).modes

return function()
    return {
        mode = modes.prompt,
        activationRange = 20,
        activationCooldown = 2,
        locked = false,
        open = false
    }
end