-- src/Features/Player/player_rendering.lua
local GameState = require("src.Core.game_state")

local PlayerRendering = {}

-- Load once at startup (safe – if file missing, we fall back to a colored rectangle)
local player_image = nil
local ok, img = pcall(love.graphics.newImage, "Assets/player.png")
if ok then
    player_image = img
    player_image:setFilter("nearest", "nearest")
end

function PlayerRendering.draw()
    local p = GameState.player

    if player_image then
        love.graphics.draw(player_image, p.pos.x, p.pos.y, 0, 4) -- 4× scale, looks nice
    else
        -- Fallback: bright green rectangle so you ALWAYS see the player
        love.graphics.setColor(0.2, 1, 0.3)
        love.graphics.rectangle("fill", p.pos.x - 16, p.pos.y - 16, 32, 32)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("PLAYER", p.pos.x - 20, p.pos.y - 30)
    end
end

return PlayerRendering