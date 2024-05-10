local ecs = require("rune.ecs")
local utils = require("example.vampire.utils")


Lifetimes = {}


Lifetimes.filter = ecs.And{
    "ttl",
}


local function recursive_remove(world, entity)
    world.remove_entity(entity.uid)

    local children = world.children(entity.uid)
    for _, child in pairs(children) do
        recursive_remove(world, child)
    end
end


function Lifetimes.run(world, entities, dt)
    for _, entity in pairs(entities) do
        entity.ttl.dt = entity.ttl.dt - dt

        if entity.ttl.dt > 0 then
            goto continue
        end

        recursive_remove(world, entity)

        ::continue::
    end
end
