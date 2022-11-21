# Rune ECS
A modest ECS framework for lua!

This as originally was built to work with the [LÖVE](https://love2d.org)
game framework, though nothing stops Rune ECS being used elsewhere.

## Prerequisites
This is tested on `lua v5.1`, which is the one [LÖVE](https://love2d.org)
ships with, as of writing. I'm aware newer versions of `lua` do not currently
work, due to breaking changes. I'll address this... at some point... if needed.

You'll also need a understanding of the ECS architecture, but if you're here
you probably do.

Finally, you'll need a tolerance for breaking changes, which will probably
come as soon as this gets used at all. Still deciding how I want to 
package/namespace the module, for example.

## Install
Nothing special yet, just copy and paste the `rune` directory into your
project.

## Quick Start
Everything you need is on the returned variable from the `rune/ecs.lua`
file.

```lua
local ecs = require("rune.ecs")
```

### World Initialisation
Everything revolves around `ecs.World`. Initiate your world, and then
add your Systems and Entities to it. Let's initiate our world:

```lua
local world = ecs.World()
```

### Component Definition
Rune ECS comes with no Components, that's on you to define (with an exception
for a special `ecs.Components.Parent`, covered later). A Component should take 
a form of a function that returns a table of its attributes.

One of these attributes must be a unique `name` of the Component,
Rune ECS uses this to identify Components on a Entity. Systems will also
use this name to register what Component they interact with.

For example, lets define some Components you might define to capture some on-screen boxes:

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
Now we have some Entities, we want to define our Systems. Lets
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
As hinted to above, we can advance our simulation by calling `world:update` with a `dt` 
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

Notice the second box (`euid: 2`) is not effected by the Gravity System,
because our `box_2` had no `Physics` Component.

## Reference
### ecs.World
Instance properties of a `ecs.World.init()`.

property                               | description
-------------------------------------- | ---
`world.ctx`                                  | A context property to store your arbitrary data outside the scope of your entity components; so it can be accessed in your Systems, for example. I've used it to hold on to sprite sheets in the past.
`world.add_system(system, on)`               | Adds the system to the world. `on` ("update" or "draw") determines when the `System.run` function is called. System is added for the next tick. Returns the system `uid`.
`world.remove_system(uid)`                   | Removes the system from the world. Takes effect on next tick.
`world.add_entity(entity)`                   | Adds the entity to the world. Takes effect on next tick. Returns the entities `uid`.
`world.add_entities(entities)`               | Convenience for adding multiple entities to the world at once. Takes effect on next tick. Returns a list of entity `uids` in the same order as passed list.
`world.remove_entity(uid)`                   | Removes the entity from the world. Takes effect on next tick.
`world.add_component(entity_uid, component)` | Adds a component to an existing entity. Takes effect on next tick.
`world.entities`                             | All entities in the world, keyed by their entity uid. Treat as read-only, use `add_entity` to add new entities.
`world.systems`                             | All systems in the world, keyed by their system uid. Treat as read-only, use `add_system` to add new systems.
`world.children(entity_uid)`                 | A list of their immediate children. Add a parent-child relationship by adding a `ecs.Components.Parent` to your entity.
`world:update(dt)`                           | Progress the simulation by the given delta time value. Indirectly calls all registered "update" Systems.
`world:draw()`                               | Indirectly calls all "draw" registered Systems that _do not_ progress the simulation, but _are_ responsible for rendering.

### System Filters
A bit more documentation on the options you have defining your `System.filter`
predicates.

These predicate conditions can be composed to create filters
on the entities that will be handed into your Systems.

#### Predicates
Under the `ecs` object. Here's what's available:

name | description
--- | ---
`ecs.And` | All contained predicates or components must be met.
`ecs.Or` | Any of the contained predicates or components must be met.
`ecs.Xor` | One, and only one, of the contained predicates or components must be met.
`ecs.Not` | Inverts the truthiness of the contained predicate or component.
`ecs.Required` | Makes contained predicate or components required.
`ecs.Optional` | Makes contained predicate or components optional.

#### Groups
On top of defining a single filter, it's also possible to define
multiple filters, if your System, for example, wants access to
two or more distinct lists of entities (maybe bullets and targets).

To provide multiple filters, key the `System.filter` with the names
of the groups you want to receive. The will be available as their
group name under the passed `entities` argument to your System.

See some examples below.

#### Examples
```lua
Shooting = {}

Shooting.filter = {
    targets=ecs.And{"hitbox", "position", "health"},
    bullets=ecs.And{"hitbox", "position", "bullet"},
}

function Shooting.run(world, entities, dt)
    for tuid, target_entity in pairs(entities.targets) do
        for buid, bullet_entity in pairs(entities.bullets) do
            if is_colliding(world, target_entity, bullet_entity) then
                target_entity.health.current = target_entity.health.current - 1

                if target_entity.health.current == 0 then
                    world.remove_entity(tuid)
                end
            end
        end
    end
end

world.add_system(Shooting, "update")
```

```lua
Rendering = {}

Rendering.filter = ecs.And{
    ecs.Xor{"sprite", "rectangle"},
    ecs.Optional("position"),
    ecs.Optional("scale"),
    ecs.Optional("rotation"),
    ecs.Optional("zindex"),
    ecs.Optional("parent"),
    ecs.Optional("color")
}

local DEFAULT_COLOR = {red=1, green=1, blue=1, alpha=1}

local function zcompare(a, b)
    local left = a.zindex or {index=0}
    local right = b.zindex or {index=0}
    return left.index > right.index
end

function Rendering.run(world, entities)
    entities = table.values(entities)  -- prepare for sorting (looses uids)
    table.sort(entities, zcompare)

    for _, entity in pairs(entities) do
        local position = world_position(world, entity)
        local rotation = world_rotation(world, entity)
        local scale = world_scale(world, entity)
        local color = entity.color or DEFAULT_COLOR

        love.graphics.setColor(color.red, color.green, color.blue, color.alpha)

        -- draw sprite
        if entity.sprite ~= nil then
            love.graphics.draw(
                entity.sprite.image,
                entity.sprite.quad,
                position.x,
                position.y,
                math.rad(rotation.degrees),
                scale.fraction * entity.sprite.scale,
                scale.fraction * entity.sprite.scale,
                entity.sprite.width/2,
                entity.sprite.height/2
            )

        -- draw rectangle
        elseif entity.rectangle ~= nil then
            local mode = entity.rectangle.mode
            local width = entity.rectangle.width * scale.fraction
            local height = entity.rectangle.height * scale.fraction
            local rx = entity.rectangle.rx
            local ry = entity.rectangle.ry
            love.graphics.push()
            love.graphics.translate(position.x, position.y)
            love.graphics.rotate(math.rad(rotation.degrees))
            love.graphics.rectangle(mode, -width/2, -height/2, width, height, rx, ry)
            love.graphics.pop()

        else
            assert(false, "unhandled entity")
        end
    end
end

world.add_system(Rendering, "draw")
```

### Parent Component
The `ecs.Component.Parent` is currently the only bundled component with
Rune ECS. Rune ECS will look for this Component on entities it encounters
and will use it to drive the `world.children(entity_uid)` which can be useful
to access in your Systems.

Associating Entities with other Entities in a parent-child hierarchy can be
useful for modeling things such as power ups, where a power up might have many
components that each augment the player when collected. Those augments can
be all stored as children of a power up and transferred to the player on 
pick up.

```lua
-- Spawns a power up
Spawning = {}

Spawning.filter = {
    buffs=ecs.Required("buff"),
}

function Spawning.run(world, entities, dt)
    for _, _ in pairs(entities.buffs) do
        -- skip if already a buff out there
        return
    end

    -- create power up in random position
    local x = math.random(32, 32*15)
    local y = math.random(32, 32*15)
    local duration = math.random(5, 10)
    local buff_uid = world.add_entity({
        Rectangle("fill", 20, 20, 10, 10),
        Hitbox{shape="circle", radius=12},
        Color(255, 0, 0, 1),
        Position(x, y),
        Buff(duration),
        ZIndex(1)
    })

    -- Apply a effect to the player so they know their powered up
    local _ = world.add_entity({
        Parent(buff_uid),
        Rectangle("line", 20, 20, 10, 10),
        Color(255, 0, 0, 1),
        ZIndex(-1)
    })

    -- Add a speed augment to this power up of random amount
    local speed = math.random(100, 300)
    local _ = world.add_entity({
        Parent(buff_uid),
        Speed(speed)
    })

    -- Add a power augment to this power up of random amount
    local power = math.random(0, 100)
    local _ = world.add_entity({
        Parent(buff_uid),
        AttackPower(power)
    })
end

Buffing = {}

Buffing.filter = {
    buffable=ecs.And{"hitbox", "position", "buffable"},
    buffs=ecs.And{"hitbox", "position", "buff"},
}

function Buffing.run(world, entities, dt)
    for euid, buffable_entity in pairs(entities.buffable) do
        for cuid, buff_entity in pairs(entities.buffs) do
            if is_colliding(world, buffable_entity, buff_entity) then
                -- remove pickup
                world.remove_entity(cuid)
                -- transfer associated buff components
                for iuid, buff in pairs(world.children(cuid)) do
                    -- Movement and Attack Systems can now 
                    -- augment speed and damage based on the
                    -- associated power up.
                    buff.parent.uid = euid
                    -- Only temporary powers. 
                    -- Schedule for deletion after duration
                    world.add_component(iuid, Delete(buff_entity.buff.duration))
                end
            end
        end
    end
end

```

## Example
The projects repository has a example "game" written with 
[LÖVE](https://love2d.org).

If you have `love` installed the project can be run from the
root directory with:

```bash
$ love example
```
