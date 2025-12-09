--[[
    src/world/world.lua
    Tile grid, spatial hash, terrain queries.
]]

local Constants     = require "src.core.constants"
local Iso           = require "src.core.iso"
local EntityManager = require "src.ecs.entity_manager"

local World = {}
local GameState = require("src.Core.game_state")  -- ← make sure this line exists
World.__index = World

function World.new(width, height)
    local self = setmetatable({}, World)
    
    self.width = width
    self.height = height
    self.entityManager = EntityManager.new(self)
    
    self.tiles = {}
    for x = 0, width - 1 do
        self.tiles[x] = {}
        for y = 0, height - 1 do
            self.tiles[x][y] = {
                type = "grass",
                elevation = 0,
                isSlope = false,
                slopeDir = Constants.SlopeDir.FLAT,
                zNW = 0, zNE = 0, zSE = 0, zSW = 0,
                entities = {},
            }
        end
    end
    
    return self
end

function World:update(dt, time)
    self.entityManager:update(dt, self, time)
end

function World:addEntityToTile(entity, tx, ty)
    if self:isValidTile(tx, ty) then
        self.tiles[tx][ty].entities[entity] = entity
    end
end

function World:removeEntityFromTile(entity, tx, ty)
    if self:isValidTile(tx, ty) then
        self.tiles[tx][ty].entities[entity] = nil
    end
end

function World:updateEntityTile(entity, ox, oy, nx, ny)
    local otx, oty = math.floor(ox), math.floor(oy)
    local ntx, nty = math.floor(nx), math.floor(ny)
    if otx ~= ntx or oty ~= nty then
        self:removeEntityFromTile(entity, otx, oty)
        self:addEntityToTile(entity, ntx, nty)
    end
end

function World:getEntitiesAt(x, y)
    local tx, ty = math.floor(x), math.floor(y)
    if self:isValidTile(tx, ty) then
        return self.tiles[tx][ty].entities
    end
    return {}
end

function World:saveMap(filename)
    local header = string.format("meta:viewIndex=%d\n", Iso.viewIndex)
    local buf = { header }
    for x = 0, self.width - 1 do
        for y = 0, self.height - 1 do
            local t = self.tiles[x][y]
            table.insert(buf, string.format("%d,%d,%.2f,%d,%s|", x, y, t.elevation, t.slopeDir, t.type))
        end
    end
    love.filesystem.write(filename, table.concat(buf))
end

function World:loadMap(filename)
    if not love.filesystem.getInfo(filename) then return end
    local content = love.filesystem.read(filename)
    
    local headerEnd = content:find("\n")
    local body = content
    if headerEnd then
        local header = content:sub(1, headerEnd)
        body = content:sub(headerEnd + 1)
        local vi = header:match("meta:viewIndex=(%d+)")
        if vi then Iso.setRotation(tonumber(vi)) end
    end
    
    for line in body:gmatch("([^|]+)") do
        local x, y, elev, slope, ttype = line:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        if x and y then
            x, y, slope, elev = tonumber(x), tonumber(y), tonumber(slope), tonumber(elev)
            if self:isValidTile(x, y) then
                if slope > 0 then
                    self:setSlope(x, y, elev, slope)
                else
                    self:setFlat(x, y, elev)
                end
                self.tiles[x][y].type = ttype
            end
        end
    end
end

function World:isValidTile(x, y)
    local tx, ty = math.floor(x), math.floor(y)
    return tx >= 0 and tx < self.width and ty >= 0 and ty < self.height
end

function World:setFlat(x, y, h)
    if not self:isValidTile(x, y) then return end
    local t = self.tiles[x][y]
    t.elevation, t.isSlope, t.slopeDir = h, false, Constants.SlopeDir.FLAT
    t.zNW, t.zNE, t.zSE, t.zSW = h, h, h, h
end

function World:setSlope(x, y, base, dir)
    if not self:isValidTile(x, y) then return end
    local t = self.tiles[x][y]
    t.elevation, t.isSlope, t.slopeDir = base, true, dir
    t.zNW, t.zNE, t.zSE, t.zSW = base, base, base, base
    
    if dir == Constants.SlopeDir.NORTH then     t.zNW, t.zNE = base + 1, base + 1
    elseif dir == Constants.SlopeDir.EAST then  t.zNE, t.zSE = base + 1, base + 1
    elseif dir == Constants.SlopeDir.SOUTH then t.zSE, t.zSW = base + 1, base + 1
    elseif dir == Constants.SlopeDir.WEST then  t.zSW, t.zNW = base + 1, base + 1
    end
end

function World:getGroundLevel(x, y)
    local tx, ty = math.floor(x), math.floor(y)
    if not self:isValidTile(tx, ty) then return -100 end
    
    local t = self.tiles[tx][ty]
    local u, v = x - tx, y - ty
    local zN = t.zNW * (1 - u) + t.zNE * u
    local zS = t.zSW * (1 - u) + t.zSE * u
    return zN * (1 - v) + zS * v
end

function World:spawnPlayer(x, y)
    return self.entityManager:spawnPlayer(x, y)
end

function World:getEntities()
    return self.entityManager.entities
end

return World
