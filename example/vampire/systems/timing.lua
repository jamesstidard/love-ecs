local ecs = require("rune.ecs")
local utils = require("example.vampire.utils")


Timing = {}


Timing.filter = ecs.Required("duration")


function Timing.run(world, entities, dt)
    for _, entity in pairs(entities) do
        entity.duration.value = entity.duration.value + dt
    end
end
