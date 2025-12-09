--[[
    main.lua
    LÖVE entry point.
]]

local Engine = require "src"

local Constants = Engine.Constants
local Iso       = Engine.Iso
local World     = Engine.World
local Renderer  = Engine.Renderer
local Brush     = Engine.Brush

local game = {
    world = nil,
    renderer = nil,
    camera = { x = 0, y = -200, zoom = 1 },
    
    hoveredTile = { x = nil, y = nil },
    hoveredVertex = { x = 0, y = 0 },
    debugText = "",
    
    toolMode = "raise",
    brushRadius = 2.5,
    brushStrength = 5.0,
    
    editorOpen = false,
    editorSelected = 1,
    editorScroll = 0,
    editorMaxScroll = 0,
}

function love.load()
    Constants.load()
    
    game.world = World.new(32, 32)
    game.renderer = Renderer.new(game.camera)
    
    for x = 10, 22 do
        for y = 10, 22 do
            game.world:setFlat(x, y, 2)
        end
    end
    
    game.world:spawnPlayer(16, 16)
end

function love.update(dt)
    Iso.updateRotation(dt)
    game.world:update(dt, 0)
    
    if game.world.entityManager.player then
        local t = game.world.entityManager.player.transform
        local tx, ty = Iso.worldToScreen(t.x, t.y, t.z)
        local spd = Constants.get("CAM_FOLLOW_SPEED")
        game.camera.x = game.camera.x + (tx - game.camera.x) * spd * dt
        game.camera.y = game.camera.y + (ty - game.camera.y) * spd * dt
    end
    
    local mx, my = love.mouse.getPosition()
    local wx, wy = game.renderer:screenToWorld(mx, my)
    game.hoveredTile = { x = math.floor(wx), y = math.floor(wy) }
    game.hoveredVertex = { x = math.floor(wx + 0.5), y = math.floor(wy + 0.5) }
    
    if game.editorOpen or love.keyboard.isDown("lalt") then return end
    
    local vx, vy = game.hoveredVertex.x, game.hoveredVertex.y
    
    if love.mouse.isDown(1) then
        if game.toolMode == "raise" then
            Brush.applyElevation(game.world, vx, vy, game.brushRadius, game.brushStrength, dt, true)
        elseif game.toolMode == "smooth" then
            Brush.applySmoothing(game.world, vx, vy, game.brushRadius, game.brushStrength, dt)
        end
    elseif love.mouse.isDown(2) and game.toolMode == "raise" then
        Brush.applyElevation(game.world, vx, vy, game.brushRadius, game.brushStrength, dt, false)
    end
end

function love.draw()
    love.graphics.clear(0.12, 0.12, 0.14)
    
    game.renderer:renderWorld(game.world, 0, game.hoveredTile, 1)
    
    if not game.editorOpen and game.hoveredVertex then
        local col = game.toolMode == "raise" and { 0.2, 0.8, 0.2, 0.8 } or { 0.4, 0.4, 1, 0.8 }
        if love.mouse.isDown(2) then col = { 0.8, 0.2, 0.2, 0.8 } end
        game.renderer:drawBrushCursor(game.world, game.hoveredVertex.x, game.hoveredVertex.y, game.brushRadius, col)
    end
    
    if game.editorOpen then
        drawEditor()
    else
        drawDebugHUD()
    end
end

local function handleEditorInput(key)
    local name = Constants.TunableOrder[game.editorSelected]
    local t = Constants.Tunable[name]
    local total = #Constants.TunableOrder
    
    if key == "up" then
        game.editorSelected = math.max(1, game.editorSelected - 1)
    elseif key == "down" then
        game.editorSelected = math.min(total, game.editorSelected + 1)
    elseif key == "left" then
        Constants.set(name, t.value - t.step)
    elseif key == "right" then
        Constants.set(name, t.value + t.step)
    elseif key == "pageup" then
        game.editorSelected = math.max(1, game.editorSelected - 5)
    elseif key == "pagedown" then
        game.editorSelected = math.min(total, game.editorSelected + 5)
    elseif key == "s" then
        Constants.save()
    end
end

local function handleGameInput(key)
    if key == "z" then Iso.rotate90(-1)
    elseif key == "x" then Iso.rotate90(1)
    elseif key == "1" then game.toolMode = "raise"
    elseif key == "2" then game.toolMode = "smooth"
    elseif key == "[" then game.brushRadius = math.max(0.5, game.brushRadius - 0.5)
    elseif key == "]" then game.brushRadius = game.brushRadius + 0.5
    elseif key == "c" and game.debugText then love.system.setClipboardText(game.debugText)
    elseif key == "f5" then game.world:saveMap("data/map.dat")
    elseif key == "f9" then game.world:loadMap("data/map.dat")
    elseif key == "escape" then love.event.quit()
    end
end

function love.keypressed(key)
    if key == "tab" then
        game.editorOpen = not game.editorOpen
        return
    end
    if game.editorOpen then handleEditorInput(key) else handleGameInput(key) end
end

function love.wheelmoved(x, y)
    if game.editorOpen then
        if love.keyboard.isDown("lshift", "rshift") then
            local name = Constants.TunableOrder[game.editorSelected]
            local t = Constants.Tunable[name]
            Constants.set(name, t.value + t.step * y)
        else
            game.editorScroll = math.max(0, math.min(game.editorMaxScroll, game.editorScroll - y * 30))
        end
    else
        game.camera.zoom = math.max(0.5, math.min(3, game.camera.zoom + y * 0.1))
    end
end

function drawDebugHUD()
    local lines = {}
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("[TAB] Editor [1] Raise [2] Smooth [[ / ]] Brush [Z/X] Rotate", 10, 10)
    
    if game.world.entityManager.player then
        local t = game.world.entityManager.player.transform
        table.insert(lines, string.format("PLAYER pos: %.2f, %.2f, %.2f", t.x, t.y, t.z))
    end
    table.insert(lines, string.format("BRUSH %s r=%.1f v=%d,%d",
        game.toolMode:upper(), game.brushRadius, game.hoveredVertex.x, game.hoveredVertex.y))
    table.insert(lines, string.format("VIEW %s", Iso.VIEW_DIRS[Iso.viewIndex]))
    
    love.graphics.setColor(1, 1, 1)
    for i, line in ipairs(lines) do
        love.graphics.print(line, 10, 30 + (i - 1) * 16)
    end
    game.debugText = table.concat(lines, "\n")
end

function drawEditor()
    local sw, sh = love.graphics.getDimensions()
    local pw, ph = 420, sh - 40
    local px, py = sw - pw - 20, 20
    
    love.graphics.setColor(0.1, 0.1, 0.12, 0.95)
    love.graphics.rectangle("fill", px, py, pw, ph, 8)
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("line", px, py, pw, ph, 8)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("CONSTANTS EDITOR", px + 10, py + 10)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("[TAB] Close  [S] Save  [Arrows] Adjust", px + 10, py + 28)
    
    local cx, cy = px + 5, py + 55
    local cw, ch = pw - 10, ph - 80
    love.graphics.setScissor(cx, cy, cw, ch)
    
    local y = cy - game.editorScroll
    local idx = 0
    
    for _, cat in ipairs(Constants.TunableCategories) do
        if y + 28 > cy and y < cy + ch then
            love.graphics.setColor(0.4, 0.5, 0.6)
            love.graphics.rectangle("fill", cx, y, cw, 24, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("-- " .. cat.name .. " --", cx + 10, y + 4)
        end
        y = y + 28
        
        for _, name in ipairs(cat.items) do
            idx = idx + 1
            local t = Constants.Tunable[name]
            local sel = idx == game.editorSelected
            
            if y + 36 > cy and y < cy + ch then
                if sel then
                    love.graphics.setColor(0.2, 0.25, 0.3)
                    love.graphics.rectangle("fill", cx, y, cw, 34, 4)
                end
                
                love.graphics.setColor(sel and { 1, 1, 0.5 } or { 0.8, 0.8, 0.8 })
                love.graphics.print(name, cx + 10, y + 2)
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.print(t.desc, cx + 10, y + 16)
                
                local slx, slw = cx + 250, 100
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", slx, y + 8, slw, 8, 2)
                local pct = (t.value - t.min) / (t.max - t.min)
                love.graphics.setColor(0.3, 0.6, 0.9)
                love.graphics.rectangle("fill", slx, y + 8, slw * pct, 8, 2)
                love.graphics.setColor(1, 1, 1)
                love.graphics.circle("fill", slx + slw * pct, y + 12, 5)
                
                local vs = t.step < 1 and string.format("%.2f", t.value) or string.format("%d", t.value)
                love.graphics.print(vs, slx + slw + 8, y + 6)
            end
            y = y + 36
        end
    end
    
    game.editorMaxScroll = math.max(0, y - cy + game.editorScroll - ch)
    love.graphics.setScissor()
end
