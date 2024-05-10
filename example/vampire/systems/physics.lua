local ecs = require("rune.ecs")
local utils = require("example.vampire.utils")


Physics = {}


Physics.filter = ecs.And{
    "direction",
    "position",
    "speed",
}


function Physics.run(world, entities, dt)
    for _, entity in pairs(entities) do
        local x1 = entity.position.x
        local y1 = entity.position.y
        local distance = entity.speed.pixels * dt
        local angle = math.rad(entity.direction.degrees)

        -- move entity towards target along angle
        local x = distance * math.cos(angle) + x1
        local y = distance * math.sin(angle) + y1

        entity.position.x = x
        entity.position.y = y
    end
end
