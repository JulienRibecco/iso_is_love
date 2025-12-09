--[[
    src/tools/brush.lua
    Terrain sculpting tools.
]]

local Brush = {}

function Brush.applyElevation(world, cx, cy, radius, strength, dt, raise)
    local dir = raise and 1 or -1
    local amt = strength * dt * dir
    
    local minX, maxX = math.floor(cx - radius), math.ceil(cx + radius)
    local minY, maxY = math.floor(cy - radius), math.ceil(cy + radius)
    
    for tx = minX, maxX do
        for ty = minY, maxY do
            if world:isValidTile(tx, ty) then
                local t = world.tiles[tx][ty]
                
                local function apply(vx, vy, field)
                    local d = math.sqrt((vx - cx)^2 + (vy - cy)^2)
                    if d < radius then
                        t[field] = t[field] + amt * (1 - d / radius)
                    end
                end
                
                apply(tx, ty, "zNW")
                apply(tx + 1, ty, "zNE")
                apply(tx + 1, ty + 1, "zSE")
                apply(tx, ty + 1, "zSW")
                
                t.elevation = (t.zNW + t.zNE + t.zSE + t.zSW) / 4
                t.isSlope = not (t.zNW == t.zNE and t.zNE == t.zSE and t.zSE == t.zSW)
            end
        end
    end
end

function Brush.applySmoothing(world, cx, cy, radius, strength, dt)
    local blend = math.min(1, strength * dt * 0.5)
    
    local minX, maxX = math.floor(cx - radius), math.ceil(cx + radius)
    local minY, maxY = math.floor(cy - radius), math.ceil(cy + radius)
    
    -- Calculate targets first
    local targets = {}
    for tx = minX, maxX do
        targets[tx] = {}
        for ty = minY, maxY do
            if world:isValidTile(tx, ty) then
                targets[tx][ty] = {
                    zNW = Brush.getNeighborAvg(world, tx, ty, "NW"),
                    zNE = Brush.getNeighborAvg(world, tx, ty, "NE"),
                    zSE = Brush.getNeighborAvg(world, tx, ty, "SE"),
                    zSW = Brush.getNeighborAvg(world, tx, ty, "SW"),
                }
            end
        end
    end
    
    -- Apply
    for tx = minX, maxX do
        for ty = minY, maxY do
            if world:isValidTile(tx, ty) and targets[tx] and targets[tx][ty] then
                local t = world.tiles[tx][ty]
                local tgt = targets[tx][ty]
                
                local function apply(vx, vy, field)
                    local d = math.sqrt((vx - cx)^2 + (vy - cy)^2)
                    if d < radius then
                        local f = 1 - d / radius
                        t[field] = t[field] + (tgt[field] - t[field]) * blend * f
                    end
                end
                
                apply(tx, ty, "zNW")
                apply(tx + 1, ty, "zNE")
                apply(tx + 1, ty + 1, "zSE")
                apply(tx, ty + 1, "zSW")
                
                t.elevation = (t.zNW + t.zNE + t.zSE + t.zSW) / 4
                t.isSlope = not (t.zNW == t.zNE and t.zNE == t.zSE and t.zSE == t.zSW)
            end
        end
    end
end

function Brush.getNeighborAvg(world, tx, ty, corner)
    local heights = {}
    local t = world.tiles[tx][ty]
    
    local function add(valid, getter)
        if valid then table.insert(heights, getter()) end
    end
    
    if corner == "NW" then
        table.insert(heights, t.zNW)
        add(world:isValidTile(tx - 1, ty), function() return world.tiles[tx - 1][ty].zNE end)
        add(world:isValidTile(tx, ty - 1), function() return world.tiles[tx][ty - 1].zSW end)
        add(world:isValidTile(tx - 1, ty - 1), function() return world.tiles[tx - 1][ty - 1].zSE end)
    elseif corner == "NE" then
        table.insert(heights, t.zNE)
        add(world:isValidTile(tx + 1, ty), function() return world.tiles[tx + 1][ty].zNW end)
        add(world:isValidTile(tx, ty - 1), function() return world.tiles[tx][ty - 1].zSE end)
        add(world:isValidTile(tx + 1, ty - 1), function() return world.tiles[tx + 1][ty - 1].zSW end)
    elseif corner == "SE" then
        table.insert(heights, t.zSE)
        add(world:isValidTile(tx + 1, ty), function() return world.tiles[tx + 1][ty].zSW end)
        add(world:isValidTile(tx, ty + 1), function() return world.tiles[tx][ty + 1].zNE end)
        add(world:isValidTile(tx + 1, ty + 1), function() return world.tiles[tx + 1][ty + 1].zNW end)
    elseif corner == "SW" then
        table.insert(heights, t.zSW)
        add(world:isValidTile(tx - 1, ty), function() return world.tiles[tx - 1][ty].zSE end)
        add(world:isValidTile(tx, ty + 1), function() return world.tiles[tx][ty + 1].zNW end)
        add(world:isValidTile(tx - 1, ty + 1), function() return world.tiles[tx - 1][ty + 1].zNE end)
    end
    
    if #heights == 0 then return 0 end
    local sum = 0
    for _, h in ipairs(heights) do sum = sum + h end
    return sum / #heights
end

return Brush
