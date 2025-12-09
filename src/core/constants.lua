--[[
    src/core/constants.lua
    Tunable parameters with metadata.
]]

local Constants = {}

---@enum RenderableType
Constants.RenderableType = {
    SHADOW = 1,
    TILE_BASE = 2,
    ENTITY = 3,
    EFFECT = 4,
}

---@enum SlopeDir
Constants.SlopeDir = {
    FLAT = 0,
    NORTH = 1,
    EAST = 2,
    SOUTH = 3,
    WEST = 4,
}

---@type table<string, TunableConstant>
Constants.Tunable = {
    DEPTH_Z_WEIGHT    = { value = 0.25,  min = 0.01,   max = 1.0,   step = 0.01,   desc = "Height influence on depth" },
    DEPTH_EPSILON     = { value = 0.001, min = 0.0001, max = 0.1,   step = 0.0001, desc = "Tie-breaker threshold" },
    ENTITY_DEPTH_BIAS = { value = 0.05,  min = 0,      max = 0.5,   step = 0.01,   desc = "Entity depth bias" },
    TILE_WIDTH        = { value = 64,   min = 16,  max = 128, step = 1,    desc = "Tile width" },
    TILE_HEIGHT       = { value = 32,   min = 8,   max = 64,  step = 1,    desc = "Tile height" },
    Z_HEIGHT          = { value = 16,   min = 4,   max = 64,  step = 1,    desc = "Z height pixels" },
    TILE_OUTLINE_ALPHA= { value = 0.3,  min = 0,   max = 1,   step = 0.05, desc = "Outline opacity" },
    SIDE_DARK_MULT    = { value = 0.7,  min = 0.3, max = 1,   step = 0.05, desc = "Dark side" },
    SIDE_LIGHT_MULT   = { value = 0.85, min = 0.5, max = 1,   step = 0.05, desc = "Light side" },
    GRAVITY           = { value = 30,   min = 0,   max = 100, step = 1,    desc = "Gravity" },
    JUMP_FORCE        = { value = 14,   min = 1,   max = 50,  step = 0.5,  desc = "Jump force" },
    PLAYER_SPEED      = { value = 15,   min = 1,   max = 50,  step = 0.5,  desc = "Player speed" },
    PLAYER_DRAG       = { value = 10,   min = 0,   max = 30,  step = 0.5,  desc = "Player drag" },
    MAX_CLIMB_HEIGHT  = { value = 1.0,  min = 0.1, max = 3,   step = 0.1,  desc = "Max climb" },
    CAM_FOLLOW_SPEED  = { value = 5,    min = 0.5, max = 20,  step = 0.5,  desc = "Camera speed" },
    CAM_ROTATION_SPEED= { value = 4,    min = 0.5, max = 30,  step = 0.5,  desc = "Rotation speed" },
    XRAY_ALPHA        = { value = 0.3,  min = 0,   max = 1,   step = 0.05, desc = "X-ray alpha" },
    XRAY_WAIST_HEIGHT = { value = 1.0,  min = 0.2, max = 3,   step = 0.1,  desc = "X-ray height" },
    XRAY_X_MARGIN     = { value = 32,   min = 0,   max = 100, step = 1,    desc = "X margin" },
    XRAY_Y_MARGIN     = { value = 16,   min = 0,   max = 50,  step = 1,    desc = "Y margin" },
    ENTITY_SIZE_MULT  = { value = 15,   min = 5,   max = 30,  step = 1,    desc = "Entity size" },
    SHADOW_ALPHA      = { value = 0.3,  min = 0,   max = 1,   step = 0.05, desc = "Shadow alpha" },
}

Constants.TunableCategories = {
    { name = "DEPTH",     items = { "DEPTH_Z_WEIGHT", "DEPTH_EPSILON", "ENTITY_DEPTH_BIAS" } },
    { name = "RENDERING", items = { "TILE_WIDTH", "TILE_HEIGHT", "Z_HEIGHT", "TILE_OUTLINE_ALPHA", "SIDE_DARK_MULT", "SIDE_LIGHT_MULT" } },
    { name = "PHYSICS",   items = { "GRAVITY", "JUMP_FORCE", "PLAYER_SPEED", "PLAYER_DRAG", "MAX_CLIMB_HEIGHT" } },
    { name = "CAMERA",    items = { "CAM_FOLLOW_SPEED", "CAM_ROTATION_SPEED" } },
    { name = "X-RAY",     items = { "XRAY_ALPHA", "XRAY_WAIST_HEIGHT", "XRAY_X_MARGIN", "XRAY_Y_MARGIN" } },
    { name = "ENTITY",    items = { "ENTITY_SIZE_MULT", "SHADOW_ALPHA" } },
}

Constants.TunableOrder = {}
for _, cat in ipairs(Constants.TunableCategories) do
    for _, name in ipairs(cat.items) do
        table.insert(Constants.TunableOrder, name)
    end
end

function Constants.get(name)
    local c = Constants.Tunable[name]
    return c and c.value or 0
end

function Constants.set(name, value)
    if Constants.Tunable[name] then
        Constants.Tunable[name].value = value
    end
end

function Constants.save(filename)
    filename = filename or "data/constants.dat"
    local lines = {}
    for name, t in pairs(Constants.Tunable) do
        table.insert(lines, name .. "=" .. tostring(t.value))
    end
    love.filesystem.write(filename, table.concat(lines, "\n"))
end

function Constants.load(filename)
    filename = filename or "data/constants.dat"
    if not love.filesystem.getInfo(filename) then return false end
    local content = love.filesystem.read(filename)
    for line in content:gmatch("[^\n]+") do
        local name, val = line:match("([^=]+)=(.+)")
        if name and val and Constants.Tunable[name] then
            Constants.Tunable[name].value = tonumber(val) or Constants.Tunable[name].value
        end
    end
    return true
end

return Constants
