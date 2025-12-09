--[[
    src/core/types.lua
    Central type definitions for LuaLS.
]]

---@class Vector2
---@field x number
---@field y number

---@class TransformComponent
---@field type "transform"
---@field x number
---@field y number
---@field z number
---@field rotation number

---@class BodyComponent
---@field type "body"
---@field vx number
---@field vy number
---@field vz number
---@field drag number
---@field gravity number
---@field radius number
---@field isGrounded boolean

---@class SpriteComponent
---@field type "sprite"
---@field shape "circle"|"diamond"
---@field color number[]
---@field size number
---@field visible boolean
---@field zOffset number
---@field shadow boolean

---@class PlayerComponent
---@field type "player"

---@class Entity
---@field id integer
---@field transform TransformComponent|nil
---@field body BodyComponent|nil
---@field sprite SpriteComponent|nil
---@field player PlayerComponent|nil

---@class Tile
---@field type "grass"|"dirt"
---@field elevation number
---@field isSlope boolean
---@field slopeDir integer
---@field zNW number
---@field zNE number
---@field zSE number
---@field zSW number
---@field entities table<Entity, Entity>

---@class World
---@field width integer
---@field height integer
---@field tiles table<integer, table<integer, Tile>>
---@field entityManager EntityManager

---@class EntityManager
---@field entities Entity[]
---@field player Entity|nil
---@field worldReference World
---@field nextId integer

---@class Camera
---@field x number
---@field y number
---@field zoom number

---@class Renderer
---@field camera Camera
---@field renderQueue table[]
---@field occludedTiles table<string, {alpha: number}>

---@class TunableConstant
---@field value number
---@field min number
---@field max number
---@field step number
---@field desc string

return {}
