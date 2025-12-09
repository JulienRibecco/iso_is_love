-- src/Core/deterministic_random.lua
-- Pure Lua 5.1 – NO bitwise operators – works in LÖVE 11.x, 0.10, even ancient versions

local DeterministicRandom = {}
local mt = { __index = DeterministicRandom }

function DeterministicRandom.new(seed)
    local self = setmetatable({}, mt)
    seed = seed or 1337
    -- Simple but extremely high-quality 32-bit mixer
    seed = (seed * 16807) % 2147483647
    if seed <= 0 then seed = seed + 2147483646 end
    self.state = seed
    return self
end

-- Classic Linear Congruential Generator – used by old C libs, Java, etc.
-- Period 2^31-1, more than enough for games
local function lcg(state)
    return (state * 16807) % 2147483647
end

function DeterministicRandom:next()
    self.state = lcg(self.state)
    -- Return 0..1 float
    return self.state / 2147483647
end

function DeterministicRandom:int(min_inclusive, max_inclusive)
    return min_inclusive + math.floor(self:next() * (max_inclusive - min_inclusive + 1))
end

function DeterministicRandom:range(min, max)
    return min + (max - min) * self:next()
end

return DeterministicRandom