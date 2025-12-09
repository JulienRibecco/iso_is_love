--[[
    src/rendering/renderer.lua
    Depth-sorted rendering with X-ray occlusion.
]]

local Constants = require "src.core.constants"
local Iso       = require "src.core.iso"

local RenderableType = Constants.RenderableType

local Renderer = {}
Renderer.__index = Renderer

function Renderer.new(camera)
    local self = setmetatable({}, Renderer)
    self.camera = camera
    self.renderQueue = {}
    self.occludedTiles = {}
    return self
end

local function shouldDrawFace(nx, ny)
    local rot = Iso.rotation
    local vx = nx * math.cos(rot) - ny * math.sin(rot)
    local vy = nx * math.sin(rot) + ny * math.cos(rot)
    return (vx + vy) > 0.1
end

function Renderer:renderWorld(world, time, hoveredTile, brushSize)
    love.graphics.push()
    local sw, sh = love.graphics.getDimensions()
    love.graphics.translate(sw / 2, sh / 2)
    love.graphics.scale(self.camera.zoom)
    love.graphics.translate(-self.camera.x, -self.camera.y)
    
    -- Clear queue
    for k in pairs(self.renderQueue) do self.renderQueue[k] = nil end
    
    -- Player position for X-ray
    local px, py, pz = 0, 0, 0
    local hasPlayer = false
    if world.entityManager.player and world.entityManager.player.transform then
        local t = world.entityManager.player.transform
        px, py, pz = t.x, t.y, t.z
        hasPlayer = true
    end
    
    self:calculateOccludingTiles(world, px, py, pz, hasPlayer)
    
    -- Queue tiles
    for x = 0, world.width - 1 do
        for y = 0, world.height - 1 do
            local t = world.tiles[x][y]
            local maxZ = math.max(t.zNW, t.zNE, t.zSE, t.zSW)
            if maxZ >= 0 then
                local alpha = self:calculateXRayAlpha(x, y)
                local color = self:getTileColor(t.type, t.elevation)
                table.insert(self.renderQueue, {
                    type = RenderableType.TILE_BASE,
                    depth = Iso.calculateTileDepth(x, y, maxZ),
                    x = x, y = y, zBase = 0,
                    zNW = t.zNW, zNE = t.zNE, zSE = t.zSE, zSW = t.zSW,
                    color = color, alpha = alpha,
                })
            end
        end
    end
    
    -- Queue entities
    if world.entityManager then
        world.entityManager:render(self, world)
    end
    
    -- Hover highlight
    if hoveredTile and hoveredTile.x and world:isValidTile(hoveredTile.x, hoveredTile.y) then
        local t = world.tiles[hoveredTile.x][hoveredTile.y]
        local maxZ = math.max(t.zNW, t.zNE, t.zSE, t.zSW)
        table.insert(self.renderQueue, {
            type = RenderableType.EFFECT,
            depth = Iso.calculateTileDepth(hoveredTile.x, hoveredTile.y, maxZ) + 0.1,
            renderFn = function()
                self:drawTileHighlight(hoveredTile.x, hoveredTile.y, t.zNW, t.zNE, t.zSE, t.zSW)
            end,
        })
    end
    
    -- Sort
    table.sort(self.renderQueue, function(a, b)
        local dd = a.depth - b.depth
        if math.abs(dd) < Iso.getDepthEpsilon() then
            return a.type < b.type
        end
        return a.depth < b.depth
    end)
    
    -- Draw
    for _, item in ipairs(self.renderQueue) do
        if item.renderFn then
            item.renderFn()
        elseif item.type == RenderableType.TILE_BASE then
            self:drawSlope(item.x, item.y, item.zBase,
                item.zNW, item.zNE, item.zSE, item.zSW,
                item.color, item.alpha)
        end
    end
    
    love.graphics.pop()
end

function Renderer:drawSlope(x, y, zBase, zNW, zNE, zSE, zSW, color, alpha)
    alpha = alpha or 1.0
    local t1x, t1y = Iso.worldToScreen(x, y, zNW)
    local t2x, t2y = Iso.worldToScreen(x + 1, y, zNE)
    local t3x, t3y = Iso.worldToScreen(x + 1, y + 1, zSE)
    local t4x, t4y = Iso.worldToScreen(x, y + 1, zSW)
    
    local zh = Iso.getZHeight()
    local b1y = t1y + (zNW - zBase) * zh
    local b2y = t2y + (zNE - zBase) * zh
    local b3y = t3y + (zSE - zBase) * zh
    local b4y = t4y + (zSW - zBase) * zh
    local b1x, b2x, b3x, b4x = t1x, t2x, t3x, t4x
    
    -- Top face
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.polygon("fill", t1x, t1y, t2x, t2y, t3x, t3y, t4x, t4y)
    
    -- Side shading
    local darkM  = Constants.get("SIDE_DARK_MULT")
    local lightM = Constants.get("SIDE_LIGHT_MULT")
    local dark   = { color[1] * darkM, color[2] * darkM, color[3] * darkM }
    local light  = { color[1] * lightM, color[2] * lightM, color[3] * lightM }
    
    if shouldDrawFace(0, 1) then
        love.graphics.setColor(light[1], light[2], light[3], alpha)
        love.graphics.polygon("fill", t4x, t4y, t3x, t3y, b3x, b3y, b4x, b4y)
    end
    if shouldDrawFace(1, 0) then
        love.graphics.setColor(dark[1], dark[2], dark[3], alpha)
        love.graphics.polygon("fill", t3x, t3y, t2x, t2y, b2x, b2y, b3x, b3y)
    end
    if shouldDrawFace(0, -1) then
        love.graphics.setColor(light[1], light[2], light[3], alpha)
        love.graphics.polygon("fill", t2x, t2y, t1x, t1y, b1x, b1y, b2x, b2y)
    end
    if shouldDrawFace(-1, 0) then
        love.graphics.setColor(dark[1], dark[2], dark[3], alpha)
        love.graphics.polygon("fill", t1x, t1y, t4x, t4y, b4x, b4y, b1x, b1y)
    end
    
    -- Outlines
    local outA = Constants.get("TILE_OUTLINE_ALPHA")
    if outA > 0 then
        love.graphics.setColor(0, 0, 0, outA * alpha)
        love.graphics.setLineWidth(1)
        love.graphics.polygon("line", t1x, t1y, t2x, t2y, t3x, t3y, t4x, t4y)
        if shouldDrawFace(0, 1)  then love.graphics.line(t4x, t4y, b4x, b4y); love.graphics.line(t3x, t3y, b3x, b3y) end
        if shouldDrawFace(1, 0)  then love.graphics.line(t3x, t3y, b3x, b3y); love.graphics.line(t2x, t2y, b2x, b2y) end
        if shouldDrawFace(0, -1) then love.graphics.line(t2x, t2y, b2x, b2y); love.graphics.line(t1x, t1y, b1x, b1y) end
        if shouldDrawFace(-1, 0) then love.graphics.line(t1x, t1y, b1x, b1y); love.graphics.line(t4x, t4y, b4x, b4y) end
    end
end

function Renderer:calculateOccludingTiles(world, px, py, pz, hasPlayer)
    self.occludedTiles = {}
    if not hasPlayer then return end
    
    local TW = Iso.getTileWidth()
    local ZH = Iso.getZHeight()
    local xMargin = Constants.get("XRAY_X_MARGIN")
    local waistH  = Constants.get("XRAY_WAIST_HEIGHT")
    
    local psx, psy = Iso.worldToScreen(px, py, pz)
    local pTopY = psy - waistH * ZH
    local pBotY = psy
    local pDepth = Iso.calculateEntityDepth(px, py, pz)
    
    for x = 0, world.width - 1 do
        for y = 0, world.height - 1 do
            local t = world.tiles[x][y]
            local maxZ = math.max(t.zNW, t.zNE, t.zSE, t.zSW)
            
            if maxZ > pz then
                local tDepth = Iso.calculateTileDepth(x, y, maxZ)
                if tDepth > pDepth then
                    local tsx, tsy = Iso.worldToScreen(x + 0.5, y + 0.5, maxZ)
                    if math.abs(tsx - psx) < TW * 0.6 + xMargin then
                        local tBot = tsy + Iso.getTileHeight() * 1.5
                        if tsy < pBotY and tBot > pTopY then
                            self.occludedTiles[x .. "," .. y] = { alpha = Constants.get("XRAY_ALPHA") }
                        end
                    end
                end
            end
        end
    end
end

function Renderer:calculateXRayAlpha(x, y)
    local d = self.occludedTiles[x .. "," .. y]
    return d and d.alpha or 1.0
end

function Renderer:drawTileHighlight(x, y, zNW, zNE, zSE, zSW)
    local t1x, t1y = Iso.worldToScreen(x, y, zNW)
    local t2x, t2y = Iso.worldToScreen(x + 1, y, zNE)
    local t3x, t3y = Iso.worldToScreen(x + 1, y + 1, zSE)
    local t4x, t4y = Iso.worldToScreen(x, y + 1, zSW)
    love.graphics.setColor(1, 1, 0, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.polygon("line", t1x, t1y, t2x, t2y, t3x, t3y, t4x, t4y)
end

function Renderer:drawBrushCursor(world, cx, cy, radius, color)
    local segs = 32
    local step = math.pi * 2 / segs
    love.graphics.setColor(color)
    love.graphics.setLineWidth(2)
    local pts = {}
    for i = 0, segs do
        local th = i * step
        local wx, wy = cx + math.cos(th) * radius, cy + math.sin(th) * radius
        local h = 0
        local tx, ty = math.floor(wx), math.floor(wy)
        if world:isValidTile(tx, ty) then h = world.tiles[tx][ty].zNW end
        local sx, sy = Iso.worldToScreen(wx, wy, h)
        pts[#pts + 1] = sx
        pts[#pts + 1] = sy
    end
    love.graphics.line(pts)
end

function Renderer:getTileColor(ttype, elev)
    local base = ttype == "dirt" and { 0.6, 0.4, 0.2 } or { 0.3, 0.6, 0.3 }
    local b = elev * 0.05
    return { math.min(1, base[1] + b), math.min(1, base[2] + b), math.min(1, base[3] + b) }
end

function Renderer:screenToWorld(sx, sy)
    local sw, sh = love.graphics.getDimensions()
    return Iso.screenToWorld(
        (sx - sw / 2 + self.camera.x) / self.camera.zoom,
        (sy - sh / 2 + self.camera.y) / self.camera.zoom
    )
end

return Renderer
