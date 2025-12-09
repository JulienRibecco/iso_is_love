-- src/Core/game_state.lua
local GameState = {
    player = {
        id = "player",
        pos = {x = 400, y = 300},
        velocity = {x = 0, y = 0},
        speed = 200,
        health = 100,
        max_health = 100,
        state = "idle",
        is_active = true,
    },
    entities = {},
    current_seed = 1337,
}

-- Create the seeded RNG once
local DeterministicRandom = require("src.Core.deterministic_random")
GameState.rng = DeterministicRandom.new(GameState.current_seed)

return GameState