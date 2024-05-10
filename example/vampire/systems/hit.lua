local ecs = require("rune.ecs")
local utils = require("example.vampire.utils")


Hit = {}


Hit.filter = {
    -- homing missles, have a single target they can hit
    homing_missles=ecs.And{"target", "position"},
    -- will hit pretty much anything
    missiles=ecs.And{"position", "hitbox", ecs.Optional("team")},
    -- potential targets
    targets=ecs.And{"position", "hitbox", ecs.Optional("team")}
}


function Hit.run(world, entities, dt)
    -- homing missles
    for _, entity in pairs(entities.homing_missles) do
        local target = world.entities[entity.target.uid]

        -- the target has died. kill self
        if target == nil then
            world.remove_entity(entity)
            goto continue
        end

        -- collided, remove self and target
        if utils.is_colliding(world, entity, target) then
            world.remove_entity(entity.target)
            world.remove_entity(entity)
        end

        ::continue::
    end

    -- directional missles
    for _, missile in pairs(entities.missiles) do
        for _, target in pairs(entities.targets) do
            if missile.uid == target.uid then
                goto continue  -- skip self
            end

            if (
                missile.team ~= nil
                and target.team ~=nil
                and missile.team.number == target.team.number
            ) then
                goto continue  -- skip friendly fire
            end

            -- collided, remove self and target
            if utils.is_colliding(world, missile, target) then
                world.remove_entity(missile)
                world.remove_entity(target)
            end

            ::continue::
        end
    end
end
