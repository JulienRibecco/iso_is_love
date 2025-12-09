# Iso Engine

An isometric game engine built with LÖVE (Love2D).

## Project Structure

```
iso_engine/
├── main.lua              # Entry point (LÖVE callbacks)
├── conf.lua              # LÖVE configuration
├── .luarc.json           # LuaLS type checker config
│
├── src/
│   ├── init.lua          # Bootstrap, returns engine API
│   ├── core/             # Constants, Iso math, Types
│   ├── ecs/              # Components, Systems, EntityManager
│   ├── rendering/        # Renderer
│   ├── world/            # World, tiles, spatial hash
│   └── tools/            # Brush sculpting
│
├── lib/                  # Third-party libraries
├── assets/               # Sprites, sounds, fonts
└── data/                 # Save files
```

## Usage

```lua
local Engine = require "src"
local world = Engine.World.new(32, 32)
```

## Controls

| Key | Action |
|-----|--------|
| WASD | Move player |
| Space | Jump |
| Z/X | Rotate camera |
| 1/2 | Tool: Raise/Smooth |
| [ / ] | Brush size |
| Tab | Constants editor |
| F5/F9 | Save/Load map |

## Requirements

- LÖVE 11.4+
