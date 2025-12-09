--[[
    src/init.lua
    Engine bootstrap - loads all modules.
    
    Usage:
        local Engine = require "src"
        Engine.World.new(32, 32)
]]

local Core      = require "src.core"
local ECS       = require "src.ecs"
local Rendering = require "src.rendering"
local WorldMod  = require "src.world"
local Tools     = require "src.tools"

return {
    -- Core
    Constants = Core.Constants,
    Iso       = Core.Iso,
    
    -- ECS
    Components    = ECS.Components,
    EntityManager = ECS.EntityManager,
    Systems       = ECS.Systems,
    
    -- Rendering
    Renderer = Rendering.Renderer,
    
    -- World
    World = WorldMod.World,
    
    -- Tools
    Brush = Tools.Brush,
}
