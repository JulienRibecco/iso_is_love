-- src/Core/types.lua – SACRED GLOBAL SCHEMA
---@class Vector2
---@field x number
---@field y number

---@class Entity
---@field id            string
---@field pos           Vector2
---@field velocity      Vector2
---@field is_active     boolean
---@field state         "idle" | "walking" | "attacking" | "dead" | "stunned"

---@class Player : Entity
---@field health        integer
---@field max_health    integer
---@field speed         number
---@field facing        "up" | "down" | "left" | "right" | "up_left" | "up_right" | "down_left" | "down_right"

---@class GameState
---@field player        Player
---@field entities      table<string, Entity>
---@field rng           any        -- will hold DeterministicRandom
---@field current_seed  integer