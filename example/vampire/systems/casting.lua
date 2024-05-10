local ecs = require("rune.ecs")
local utils = require("example.vampire.utils")


Casting = {}


Casting.filter = {
    weapons=ecs.And{"spell", "parent", ecs.Optional("team")},
    enemies=ecs.And{"target", "position", ecs.Not("control")},
}



function Casting.run(world, entities, dt)
    local casters_cloest_enemy = {}

    for eid, weapon in pairs(entities.weapons) do
        weapon.spell.dt = weapon.spell.dt + dt

        if weapon.spell.dt < weapon.spell.cooldown then
            goto continue
        end

        weapon.spell.dt = 0

        if utils.empty(entities.enemies) then
            goto continue
        end

        local caster = world.entities[weapon.parent.uid]

        if caster == nil then
            world.remove_entity(eid)
            goto continue
        end

        if casters_cloest_enemy[weapon.parent.uid] == nil then
            local all_targets = utils.values(entities.enemies)
            local distances = utils.map(all_targets, function (target)
                return utils.distance_between(caster.position, target.position)
            end)
            local cloest = math.min(unpack(distances))
            local index = utils.find(distances, cloest)
            casters_cloest_enemy[weapon.parent.uid] = all_targets[index]
        end

        local target = casters_cloest_enemy[weapon.parent.uid]

        local x1, y1 = caster.position.x, caster.position.y
        local x2, y2 = target.position.x, target.position.y
        local d = math.deg(math.atan2(y2-y1, x2-x1))

        local projectile = {
            Position(x1, y1),
            Direction(d),
            Circle("fill", 2.5),
            Hitbox("circle", nil, nil, 2.5),
            Color(0, 255, 0),
            Speed(250),
            TTL(5),
            Damage(4),
        }

        if caster.team ~= nil then
            table.insert(projectile, Team(caster.team.number))
        end

        world.add_entity(projectile)

        ::continue::
    end
end
