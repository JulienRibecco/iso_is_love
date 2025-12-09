--[[
    src/ecs/entity_manager.lua
    Entity lifecycle management.
]]

local Components = require "src.ecs.components"
local Systems    = require "src.ecs.systems"

local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager.new(world)
    local self = setmetatable({}, EntityManager)
    self.entities = {}
    self.player = nil
    self.worldReference = world
    self.nextId = 1
    return self
end

function EntityManager:createEntity()
    local id = self.nextId
    self.nextId = self.nextId + 1
    local entity = { id = id }
    table.insert(self.entities, entity)
    return entity
end

function EntityManager:spawnPlayer(x, y)
    if self.player then
        self:removeEntity(self.player)
    end
    
    local e = self:createEntity()
    e.transform = Components.Transform(x + 0.5, y + 0.5, 0)
    e.body = Components.Body({ drag = 10.0, gravity = 2.0, radius = 0.4 })
    e.sprite = Components.Sprite("circle", { 1, 1, 1 }, 0.8)
    e.player = Components.Player()
    
    self.player = e
    
    if self.worldReference then
        self.worldReference:addEntityToTile(e, math.floor(x), math.floor(y))
    end
    
    return e
end

function EntityManager:removeEntity(entity)
    for i, e in ipairs(self.entities) do
        if e == entity then
            if e.transform and self.worldReference then
                local tx = math.floor(e.transform.x)
                local ty = math.floor(e.transform.y)
                self.worldReference:removeEntityFromTile(e, tx, ty)
            end
            
            table.remove(self.entities, i)
            
            if e == self.player then
                self.player = nil
            end
            
            return
        end
    end
end

function EntityManager:update(dt, world, time)
    Systems.PlayerControl(dt, self.entities, world)
    Systems.Physics(dt, self.entities, world)
end

function EntityManager:render(renderer, world)
    Systems.Render(renderer, self.entities, world)
end

return EntityManager
