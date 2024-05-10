local ecs = require("rune.ecs")
local utils = require("example.vampire.utils")


Waves = {}


Waves.filter = {
    players=ecs.And{"control"},
    durations=ecs.Required("duration"),
}


function Waves.run(world, entities, dt)
    -- probably do some kinda exponential distribution for spawn times?
    -- do something half baked for now.
    for eid, _ in pairs(entities.players) do
        for _, entity in pairs(entities.durations) do
            local number = math.floor(math.random(0, entity.duration.value * dt))
            for _=1, number do
                local window = world.ctx.window
                local angle = math.rad(math.random(0, 360))
                local distance = math.max(window.width, window.height)
                local x = distance * math.cos(angle) + window.width / 2
                local y = distance * math.sin(angle) + window.height / 2
                world.add_entity({
                    Circle("fill", 5),
                    Hitbox("circle", nil, nil, 5),
                    Color(255, 0, 0, 1),
                    Position(x, y),
                    Speed(100),
                    Target(eid),
                    Team(2),
                    HP(10),
                    Damage(10),
                })
            end
        end
    end
end
