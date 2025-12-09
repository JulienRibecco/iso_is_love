local GameState = require("src.Core.game_state") -- we’ll create this in a sec, it’s ok if red for now

local PlayerMovement = {}

function PlayerMovement.update(dt)
    local p = GameState.player
    if p.state == "dead" or p.state == "stunned" then return end

    local input_x, input_y = 0, 0
    if love.keyboard.isDown("q", "left")  then input_x = input_x - 1 end
    if love.keyboard.isDown("d", "right") then input_x = input_x + 1 end
    if love.keyboard.isDown("z", "up")    then input_y = input_y - 1 end
    if love.keyboard.isDown("s", "down")  then input_y = input_y + 1 end

    if input_x ~= 0 or input_y ~= 0 then
        p.state = "walking"
        if input_x ~= 0 and input_y ~= 0 then
            input_x = input_x * 0.707
            input_y = input_y * 0.707
        end
    else
        p.state = "idle"
    end

    p.velocity.x = input_x * p.speed
    p.velocity.y = input_y * p.speed

    p.pos.x = p.pos.x + p.velocity.x * dt
    p.pos.y = p.pos.y + p.velocity.y * dt
end

return PlayerMovement