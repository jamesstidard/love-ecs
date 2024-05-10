require("components.*")
require("systems.*")

local DEBUG = arg[#arg] == "vsc_debug"
if DEBUG then
    require("lldebugger").start()
end

local WIDTH = 32*16
local HEIGHT = 32*16

local ecs = require("rune.ecs")
local world = nil


function love.load()
    love.window.setMode(WIDTH, HEIGHT)

    -- local bg_color = COLOR.PURPLE
    -- love.graphics.setBackgroundColor(bg_color.red, bg_color.green, bg_color.blue)

    world = ecs.World()

    world.ctx.window = {width=WIDTH, height=HEIGHT}

    -- register systems
    world.add_system(AI, "update")
    world.add_system(Casting, "update")
    world.add_system(Controller, "update")
    world.add_system(Hit, "update")
    world.add_system(Lifetimes, "update")
    world.add_system(Physics, "update")
    world.add_system(Rendering, "draw")
    world.add_system(Timing, "update")
    world.add_system(Waves, "update")

    -- load player entity
    local player_entity = {
        Circle("fill", 5),
        Hitbox("circle", nil, nil, 5),
        Color(255, 255, 255, 1),
        Position(world.ctx.window.width/2, world.ctx.window.height/2),
        Speed(150),
        Control(),
        Team(1),
        HP(100),
    }
    local player_uid = world.add_entity(player_entity)

    -- add initial weapon
    local weapon_entity = {
        Parent(player_uid),
        Spell(0.5),
    }
    world.add_entity(weapon_entity)

    local world_clock = {
        Duration(0)
    }
    world.add_entity(world_clock)
end


function love.update(dt)
    world:update(dt)
end


function love.draw()
    world:draw()
end
