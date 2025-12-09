--[[
    src/core/iso.lua
    Isometric coordinate transforms and depth calculations.
]]

local Constants = require "src.core.constants"

local Iso = {}

local geom = {
    cos = 1, sin = 0,
    width = 64, height = 32, zHeight = 16, zWeight = 0.25,
}

Iso.rotation = 0
Iso.targetRotation = 0
Iso.viewIndex = 0
Iso.VIEW_DIRS = { [0] = "SOUTH", [1] = "EAST", [2] = "NORTH", [3] = "WEST" }

function Iso.refreshGeometry()
    geom.width   = Constants.get("TILE_WIDTH")
    geom.height  = Constants.get("TILE_HEIGHT")
    geom.zHeight = Constants.get("Z_HEIGHT")
    geom.zWeight = Constants.get("DEPTH_Z_WEIGHT")
    geom.cos     = math.cos(Iso.rotation)
    geom.sin     = math.sin(Iso.rotation)
end

function Iso.getTileWidth()    return geom.width end
function Iso.getTileHeight()   return geom.height end
function Iso.getZHeight()      return geom.zHeight end
function Iso.getDepthEpsilon() return Constants.get("DEPTH_EPSILON") end

function Iso.worldToScreen(wx, wy, wz, camX, camY)
    camX, camY, wz = camX or 0, camY or 0, wz or 0
    local tx, ty = wx - camX, wy - camY
    local rx = tx * geom.cos - ty * geom.sin
    local ry = tx * geom.sin + ty * geom.cos
    local sx = (rx - ry) * (geom.width / 2)
    local sy = (rx + ry) * (geom.height / 2) - (wz * geom.zHeight)
    return sx, sy
end

function Iso.screenToWorld(sx, sy, camX, camY)
    camX, camY = camX or 0, camY or 0
    local adjY = sy / geom.height
    local adjX = sx / geom.width
    local rx = adjX + adjY
    local ry = adjY - adjX
    local tx = rx * geom.cos + ry * geom.sin
    local ty = -rx * geom.sin + ry * geom.cos
    return tx + camX, ty + camY
end

function Iso.calculateDepth(x, y, z)
    z = z or 0
    local rx = x * geom.cos - y * geom.sin
    local ry = x * geom.sin + y * geom.cos
    return (rx + ry) + (z * geom.zWeight)
end

function Iso.calculateTileDepth(tx, ty, tz)
    local d1 = Iso.calculateDepth(tx, ty, tz)
    local d2 = Iso.calculateDepth(tx + 1, ty, tz)
    local d3 = Iso.calculateDepth(tx, ty + 1, tz)
    local d4 = Iso.calculateDepth(tx + 1, ty + 1, tz)
    return math.min(d1, d2, d3, d4)
end

function Iso.calculateEntityDepth(x, y, z, zOffset)
    return Iso.calculateDepth(x, y, z + (zOffset or 0)) + Constants.get("ENTITY_DEPTH_BIAS")
end

function Iso.updateRotation(dt)
    if math.abs(Iso.targetRotation - Iso.rotation) > 0.001 then
        local speed = Constants.get("CAM_ROTATION_SPEED")
        local diff = Iso.targetRotation - Iso.rotation
        Iso.rotation = Iso.rotation + diff * speed * dt
    else
        Iso.rotation = Iso.targetRotation
    end
    Iso.refreshGeometry()
end

function Iso.rotate90(dir)
    Iso.targetRotation = Iso.targetRotation + (math.pi / 2) * dir
    Iso.viewIndex = (Iso.viewIndex + dir) % 4
end

function Iso.setRotation(index)
    Iso.viewIndex = index
    Iso.targetRotation = index * (math.pi / 2)
    Iso.rotation = Iso.targetRotation
    Iso.refreshGeometry()
end

Iso.refreshGeometry()

return Iso
