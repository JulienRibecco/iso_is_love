--[[
    src/ecs/components.lua
    Component factory functions.
]]

local Components = {}

function Components.Transform(x, y, z)
    return {
        type = "transform",
        x = x or 0,
        y = y or 0,
        z = z or 0,
        rotation = 0,
    }
end

function Components.Body(config)
    config = config or {}
    return {
        type = "body",
        vx = 0, vy = 0, vz = 0,
        drag = config.drag or 5.0,
        gravity = config.gravity or 0,
        radius = config.radius or 0.4,
        isGrounded = false,
    }
end

function Components.Sprite(shape, color, size)
    return {
        type = "sprite",
        shape = shape or "circle",
        color = color or { 1, 1, 1 },
        size = size or 1.0,
        visible = true,
        zOffset = 0,
        shadow = true,
    }
end

function Components.Player()
    return { type = "player" }
end

return Components
