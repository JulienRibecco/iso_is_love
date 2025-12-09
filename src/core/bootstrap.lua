-- Central place – every feature is required exactly ONCE here
local PlayerMovement  = require("src.Features.Player.player_movement")
local PlayerRendering = require("src.Features.Player.player_rendering")
local PlayerInput     = require("src.Features.Player.player_input")
-- Add new features here later (Combat, World, etc.)

return {
    PlayerMovement  = PlayerMovement,
    PlayerRendering = PlayerRendering,
    PlayerInput     = PlayerInput,
}