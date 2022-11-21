local ecs = require("rune.ecs")
local world = ecs.World()

function Rectangle(width, height)
    return {
        name="rectangle",
        width=width,
        height=height,
    }
end

function Position(x, y)
    return {
        name="position",
        x=x,
        y=y,
    }
end

function Physics()
    return {
        name="physics",
    }
end

local box_1 = {
    Rectangle{width=10, height=10},
    Position(0, 100),
    Physics(),
}
local box_2 = {
    Rectangle{width=5, height=10},
    Position(50, 50),
}

world.add_entity(box_1)
world.add_entity(box_2)

Gravity = {}

-- Entities require both the 'physics' and 'position' Components
-- to be effected by this system.
Gravity.filter = ecs.And{"physics", "position"}

--- Gravity System
-- @param world the world instance
-- @param entities entities meeting the filter criteria
-- @param dt delta time since last simulation tick
function Gravity.run(world, entities, dt)
    -- entities are keyed by a unique entity uid (aka: euid)
    for euid, entity in pairs(entities) do
        -- components of a entity can be accessed via their name
        -- modify the entities instance itself to update the state
        entity.position.y =- (0.1 * dt)
    end
end

world.add_system(Gravity, "update")

-- the entities we added will not be part of the world until
-- the first tick following them being added. So lets tick,
-- but advance the simulation by 0 time.
world:update(0)

-- print current state of entities
print("first state")
for euid, entity in pairs(world.entities) do
    print("euid", euid, "position", entity.position.x, entity.position.y)
end

world:update(1)

-- print current state of entities, to see the change
print("second state")
for euid, entity in pairs(world.entities) do
    print("euid", euid, "position", entity.position.x, entity.position.y)
end
