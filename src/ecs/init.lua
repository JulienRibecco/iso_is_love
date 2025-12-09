--[[
    src/ecs/init.lua
]]
return {
    Components    = require "src.ecs.components",
    EntityManager = require "src.ecs.entity_manager",
    Systems       = require "src.ecs.systems",
}
