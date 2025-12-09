-- src/Core/bootstrap.lua
local PlayerMovement  = require("src.Features.Player.player_movement")
local PlayerRendering = require("src.Features.Player.player_rendering")
local PlayerInput     = require("src.Features.Player.player_input")
local World           = require("src.Features.World.world")      -- correct lowercase
local Tools           = require("src.Features.Tools.brush")      -- correct lowercase

return {
    PlayerMovement  = PlayerMovement,
    PlayerRendering = PlayerRendering,
    PlayerInput     = PlayerInput,
    World           = World,
    Tools           = Tools,
}
