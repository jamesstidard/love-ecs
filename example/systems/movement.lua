local ecs = require("love.ecs")
local utils = require("example.utils")


Movement = {}


Movement.filter = {
    players=ecs.And{"control", "position", "speed"},
    modifiers=ecs.And{"parent", "speed"},
    collidables=ecs.And{"hitbox", "collidable"}
}


function Movement.run(world, entities, dt)
    -- movement modifiers
    local modifiers = {}
    for _, entity in pairs(entities.modifiers) do
        local puid = entity.parent.uid
        local current = modifiers[puid] or 0
        modifiers[puid] = current + entity.speed.pixels
    end

    for euid, entity in pairs(entities.players) do
        local modifier = modifiers[euid] or 0
        local speed = math.max(0, entity.speed.pixels + modifier)

        local x = entity.position.x
        local y = entity.position.y

        if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
            y = y - (speed * dt)
        end
        if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            x = x - (speed * dt)
        end
        if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
            y = y + (speed * dt)
        end
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            x = x + (speed * dt)
        end

        local moved = utils.deepcopy(entity)
        moved.position.x = x
        moved.position.y = y
        for _, collidable in pairs(entities.collidables) do
            if utils.is_colliding(world, moved, collidable) then
                -- oh, we've hit something... lets call it quits
                return
            end
        end

        entity.position.x = x
        entity.position.y = y
    end
end
