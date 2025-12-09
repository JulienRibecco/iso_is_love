# AI Development Directives — iso_is_love (v6 — Eternal Edition)

## GOLDEN RULES (Never Break — Auto-reject PRs that violate these)
1. Never add a field without updating `src/Core/types.lua` first.
2. Never nest more than 2 levels deep → guard clauses only.
3. Never abbreviate → full snake_case English words.
4. Never use `math.random()` → always use `GameState.rng`.
5. Never modify a table while iterating it.
6. All `require()` calls happen ONLY in `src/Core/bootstrap.lua` or `main.lua`.
7. New feature → new PascalCase folder under `src/Features/`.
8. No function > 80 lines. No file > 600 lines.
9. **FILESYSTEM LAW (2025+):**  
   • **Folders** → `PascalCase` (Player/, World/, Combat/, Tools/)  
   • **.lua files** → `all_lowercase_snake.lua` only (never World.lua, never Camera.Lua)  
   • Reason: LÖVE + Linux + web + Steam are case-sensitive. One capital letter = dead game for half the players.

## Naming Conventions (Token-Optimized)
- Variables/functions → `snake_case` (full English words)
- Types/classes → `PascalCase` in types.lua
- Prefer `player_current_speed` over `player.speed` if ambiguity possible

## Commenting Strategy
```lua
-- STRATEGY: Fixed timestep + accumulator
-- RATIONALE: Identical physics on 15 FPS laptop and 240 Hz monitor
-- TRADE-OFF: Slightly higher CPU on very high FPS (acceptable)