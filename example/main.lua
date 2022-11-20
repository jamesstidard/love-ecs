require("components.*")
require("systems.*")

local DEBUG = arg[#arg] == "vsc_debug"
if DEBUG then
    require("lldebugger").start()
end

local ecs = require("love.ecs")
local world = nil


function love.load()
    love.window.setMode(32*16, 32*16)

    -- local bg_color = COLOR.PURPLE
    -- love.graphics.setBackgroundColor(bg_color.red, bg_color.green, bg_color.blue)

    world = ecs.World()

    -- register systems
    world.add_system(Rendering, "draw")
    world.add_system(Movement, "update")
    -- world.add_system(Buffing, "update")
    -- world.add_system(Deletion, "update")
    -- world.add_system(Spawning, "update")
    -- if DEBUG then
    --     world.add_system(Debugging, "draw")
    -- end

    -- -- load map entities
    -- Map.load(world)

    -- -- load player entity
    local player_entity = {
        Rectangle("fill", 10, 10),
        Hitbox("rectangle", 10, 10),
        Color(255, 255, 255, 1),
        Position(90, 90),
        Speed(150),
        Control(),
        Buffable(),
        Debug("player")
    }
    world.add_entity(player_entity)
end


function love.update(dt)
    world:update(dt)
end


function love.draw()
    world:draw()
end
