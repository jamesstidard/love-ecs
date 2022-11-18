# Love ECS
A modest ECS framework for lua!

This as originally was built to work with the [LÖVE](https://love2d.org)
game framework, though nothing stops Love ECS being used elsewhere.

## Prerequisites
This is tested on `lua v5.1`, which is the one [LÖVE](https://love2d.org)
ships with, as of writing. I'm aware newer versions of `lua` do not currently
work, due to breaking changes. I'll address this... at some point... if needed.

You'll also need a understanding of the ECS architecture, but if you're here
you probably do.

## Install
Nothing special yet, just copy and paste the `love` directory into your
project.

## Quick Start
Everything you need is on a the returned variable from the `love/ecs.lua`
file, which isn't much.

```lua
local ecs = require("love.ecs")
```

### World Initialisation
Everything revolves around `ecs.World`. Initiate your world, and then
add your Systems and Entities to it.

```lua
local ecs = require("love.ecs")

local world = ecs.World.init()
```

### Component Definition
Love ECS comes with no Components, that's on you to define (with an exception
for a special `ecs.Components.Parent`, covered later). A Component should take 
a form of a function that returns a table of its attributes.

One of these attributes must be a unique `name` of the Component,
Love ECS uses this to identify Components on a Entity. Systems will also
use this name to register what Component they interact with.

For example, here are some Components you might define to capture a 
on-screen rectangle:

```lua
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
```

### Entity Definition
Once you have your Components defined, you can create your Entity.
A Entity is just a table composed of all its Components.

Lets make two box Entities and add them to our `ecs.World`:

```lua
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
```

### Systems
Now we have some Entities, we want to define out Systems. Lets
make a `Gravity` System to interact with our Entities.

A System is comprised of a `System.run` function, which will be called
on every world update (aka: tick). The System will be called indirectly
every time `world:update` is called.

Additionally to a `System.run` an optional, but almost always wanted, 
`System.filter` can also be provided. This will be used to filter all
the entities that would otherwise be passed to the `System.run` function.

Lets define and add our System:

```lua
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
        entity.position.y = entity.position.y - (0.1 * dt)
    end
end

-- add Gravity as a System to be called on "update".
-- alternately a system can be registered to only called on "draw".
world.add_system(Gravity, "update")
```

### Run the Simulation
Now we have our Entities, Components, and System, we can now run the simulation.
As hinted to above, we can advance our simulation by calling it with a `dt` 
(delta time) since the last update.

Lets just manually update it, and we'll add it into a game-loop later.

```lua
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
```

```console
first state
euid	1	position	0	100
euid	2	position	50	50
second state
euid	1	position	0	99.9
euid	2	position	50	50
```

Notice the second box (`euid` `2`) is not effected by the Gravity System,
because our `box_2` had no `Physics` Component.
