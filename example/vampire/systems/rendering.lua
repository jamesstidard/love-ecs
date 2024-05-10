local ecs = require("rune.ecs")
local utils = require("example.vampire.utils")


Rendering = {}


Rendering.filter = ecs.And{
    ecs.Xor{"rectangle", "circle"},
    ecs.Optional("position"),
    ecs.Optional("rotation"),
    ecs.Optional("scale"),
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
    entities = utils.values(entities)  -- prepare for sorting (looses uids)
    table.sort(entities, zcompare)

    for _, entity in pairs(entities) do
        local position = utils.world_position(world, entity)
        local rotation = utils.world_rotation(world, entity)
        local scale = utils.world_scale(world, entity)
        local color = entity.color or DEFAULT_COLOR

        love.graphics.setColor(color.red, color.green, color.blue, color.alpha)

        -- draw rectangle
        if entity.rectangle ~= nil then
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
        elseif entity.circle ~= nil then
            local mode = entity.circle.mode
            local radius = entity.circle.radius * scale.fraction
            love.graphics.push()
            love.graphics.translate(position.x, position.y)
            love.graphics.rotate(math.rad(rotation.degrees))
            love.graphics.circle(mode, radius/2, radius/2, radius)
            love.graphics.pop()
        else
            assert(false, "unhandled entity")
        end
    end
end
