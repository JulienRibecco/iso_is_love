love.window.setTitle("iso_is_love – now unbreakable")

local Game = require("src.Core.bootstrap")
require("src.Core.game_state")  -- creates the global GameState table

-- Clamp crazy dt + fixed timestep
local FIXED_DT = 1/60
local accumulator = 0

function love.update(dt)
    dt = math.min(dt, 0.033)        -- prevent spiral of death
    accumulator = accumulator + dt

    while accumulator >= FIXED_DT do
        Game.PlayerMovement.update(FIXED_DT)
        accumulator = accumulator - FIXED_DT
    end

    Game.PlayerInput.update(dt)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.2)
    Game.PlayerRendering.draw()
end