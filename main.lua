love.window.setTitle("iso_is_love – now with tiles + tools back")

local Game = require("src.Core.bootstrap")
require("src.Core.game_state")

local FIXED_DT = 1/60
local accumulator = 0

function love.update(dt)
    dt = math.min(dt, 0.033)
    accumulator = accumulator + dt

    while accumulator >= FIXED_DT do
        Game.PlayerMovement.update(FIXED_DT)
        Game.World.update(FIXED_DT)        -- ← back
        accumulator = accumulator - FIXED_DT
    end

    Game.PlayerInput.update(dt)
    Game.Tools.update(dt)                  -- ← hot-reloading back
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.2)

    Game.World.draw()                      -- ← tiles + camera back
    Game.PlayerRendering.draw()            -- player on top
    Game.Tools.draw()                      -- ← UI/tools overlay back
end

-- Forward key/mouse events to Tools (for hot-reloading, etc.)
function love.keypressed(key)    Game.Tools.keypressed(key) end
function love.mousepressed(x,y,b) Game.Tools.mousepressed(x,y,b) end