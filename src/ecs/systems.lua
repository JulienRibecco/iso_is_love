--[[
    src/ecs/systems.lua
    ECS Systems: stateless functions operating on entities.
]]

local Constants = require "src.core.constants"
local Iso       = require "src.core.iso"

local Systems = {}

function Systems.Physics(dt, entities, world)
    local gravity = Constants.get("GRAVITY")
    local maxClimb = Constants.get("MAX_CLIMB_HEIGHT")
    
    for _, e in ipairs(entities) do
        if e.transform and e.body then
            local t, b = e.transform, e.body
            
            if not b.isGrounded then
                b.vz = b.vz - gravity * b.gravity * dt
            end
            
            local nx, ny = t.x + b.vx * dt, t.y + b.vy * dt
            local currGround = world:getGroundLevel(t.x, t.y)
            local nextGround = world:getGroundLevel(nx, ny)
            local diff = nextGround - currGround
            
            local canMove = true
            if b.isGrounded then
                if diff > maxClimb then canMove = false end
            else
                if t.z < nextGround - 0.1 then canMove = false end
            end
            
            if canMove then
                t.x, t.y = nx, ny
                if b.isGrounded and b.vz <= 0 then
                    t.z = nextGround
                    b.vz = 0
                else
                    t.z = t.z + b.vz * dt
                end
            else
                b.vx, b.vy = 0, 0
                t.z = t.z + b.vz * dt
            end
            
            local groundNow = world:getGroundLevel(t.x, t.y)
            if t.z <= groundNow then
                t.z = groundNow
                if b.vz < 0 then b.vz = 0 end
                b.isGrounded = true
            elseif t.z > groundNow + 0.05 then
                b.isGrounded = false
            end
            
            local drag = math.exp(-b.drag * dt)
            b.vx, b.vy = b.vx * drag, b.vy * drag
            
            local ox, oy = t.x - b.vx * dt, t.y - b.vy * dt
            world:updateEntityTile(e, ox, oy, t.x, t.y)
        end
    end
end

function Systems.PlayerControl(dt, entities, world)
    local speed = Constants.get("PLAYER_SPEED")
    local jump  = Constants.get("JUMP_FORCE")
    local viewIdx = Iso.viewIndex
    
    for _, e in ipairs(entities) do
        if e.player and e.body then
            local b = e.body
            local dx, dy = 0, 0
            
            if love.keyboard.isDown("w") then dx, dy = dx - 1, dy - 1 end
            if love.keyboard.isDown("s") then dx, dy = dx + 1, dy + 1 end
            if love.keyboard.isDown("a") then dx, dy = dx - 1, dy + 1 end
            if love.keyboard.isDown("d") then dx, dy = dx + 1, dy - 1 end
            
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0 then
                dx, dy = dx / len, dy / len
                local rad = viewIdx * (math.pi / 2)
                local c, s = math.cos(-rad), math.sin(-rad)
                local rx, ry = dx * c - dy * s, dx * s + dy * c
                b.vx = b.vx + rx * speed * dt
                b.vy = b.vy + ry * speed * dt
            end
            
            if love.keyboard.isDown("space") and b.isGrounded then
                b.vz = jump
                b.isGrounded = false
            end
        end
    end
end

function Systems.Render(renderer, entities, world)
    local sizeMult = Constants.get("ENTITY_SIZE_MULT")
    
    for _, e in ipairs(entities) do
        if e.transform then
            local t = e.transform
            
            if e.player then
                local depth = Iso.calculateEntityDepth(t.x, t.y, t.z, 0)
                local groundZ = world:getGroundLevel(t.x, t.y)
                local sx, sy = Iso.worldToScreen(t.x, t.y, groundZ)
                
                -- Shadow
                table.insert(renderer.renderQueue, {
                    type = Constants.RenderableType.SHADOW,
                    depth = Iso.calculateTileDepth(math.floor(t.x), math.floor(t.y), groundZ) + 0.05,
                    renderFn = function()
                        love.graphics.setColor(0, 0, 0, 0.4)
                        love.graphics.ellipse("fill", sx, sy, 0.4 * sizeMult, 0.2 * sizeMult)
                    end,
                })
                
                -- Height stick
                if math.abs(t.z - groundZ) > 0.1 then
                    table.insert(renderer.renderQueue, {
                        type = Constants.RenderableType.EFFECT,
                        depth = depth + 1000,
                        renderFn = function()
                            local px, py = Iso.worldToScreen(t.x, t.y, t.z)
                            love.graphics.setColor(1, 0, 0, 0.6)
                            love.graphics.setLineWidth(2)
                            love.graphics.line(px, py, sx, sy)
                            love.graphics.setColor(1, 1, 0, 0.8)
                            love.graphics.circle("line", sx, sy, 3)
                        end,
                    })
                end
                
                -- Body
                table.insert(renderer.renderQueue, {
                    type = Constants.RenderableType.ENTITY,
                    depth = depth,
                    renderFn = function()
                        local px, py = Iso.worldToScreen(t.x, t.y, t.z)
                        local size = 0.8 * sizeMult
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.circle("fill", px, py, size)
                        love.graphics.setColor(0, 0, 0, 0.5)
                        love.graphics.setLineWidth(2)
                        love.graphics.circle("line", px, py, size)
                    end,
                })
                
            elseif e.sprite then
                local s = e.sprite
                local zOff = s.zOffset or 0
                local depth = Iso.calculateEntityDepth(t.x, t.y, t.z, zOff)
                
                table.insert(renderer.renderQueue, {
                    type = Constants.RenderableType.ENTITY,
                    depth = depth,
                    renderFn = function()
                        local ex, ey = Iso.worldToScreen(t.x, t.y, t.z + zOff)
                        local size = s.size * sizeMult
                        love.graphics.setColor(s.color)
                        if s.shape == "circle" then
                            love.graphics.circle("fill", ex, ey, size)
                        elseif s.shape == "diamond" then
                            love.graphics.polygon("fill",
                                ex, ey - size,
                                ex + size, ey,
                                ex, ey + size,
                                ex - size, ey)
                        end
                    end,
                })
            end
        end
    end
end

return Systems
