local ecs = require("rune.ecs")
local utils = require("example.vampire.utils")


AI = {}


AI.filter = ecs.And{
    "target",
    "position",
    ecs.Not("control"),
}


function AI.run(world, entities, dt)
    for eid, entity in pairs(entities) do
        local x1 = entity.position.x
        local y1 = entity.position.y
        local d = entity.speed.pixels * dt

        local t = world.entities[entity.target.uid]
        if t == nil then
            world.remove_entity(eid)
            goto continue
        end

        local x2 = t.position.x
        local y2 = t.position.y

        -- angle in rads between entity and target
        local angle = math.atan2(y2-y1, x2-x1)

        -- move entity towards target along angle
        local x = d * math.cos(angle) + x1
        local y = d * math.sin(angle) + y1

        entity.position.x = x
        entity.position.y = y
        ::continue::
    end
end
