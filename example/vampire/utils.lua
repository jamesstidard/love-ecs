local Public, Private = {}, {}


function Public.contains(value, table)
    for _, element in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end


function Public.keys(list)
    local arr = {}
    for k, _ in pairs(list) do
        table.insert(arr, k)
    end
    return arr
end


function Public.values(list)
    local arr = {}
    for _, v in pairs(list) do
        table.insert(arr, v)
    end
    return arr
end


function Public.empty(list)
    return next(list) == nil
end


function Public.map(list, fn)
    local arr = {}
    for k, v in pairs(list) do
        arr[k] = fn(v)
    end
    return arr
end


function Public.find(list, fn_or_value)
    local fn = nil

    if type(fn_or_value) == 'function' then
        fn = fn_or_value
    else
        fn = function (i) return i == fn_or_value end
    end

    for k, v in pairs(list) do
        if fn(v) then
            return k
        end
    end
end


function Public.copy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end


function Public.deepcopy(original)
    local orig_type = type(original)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, original, nil do
            copy[Public.deepcopy(orig_key)] = Public.deepcopy(orig_value)
        end
        setmetatable(copy, Public.deepcopy(getmetatable(original)))
    else -- number, string, boolean, etc
        copy = original
    end
    return copy
end


function Public.distance_between(position_1, position_b)
    local x1 = position_1.x
    local y1 = position_1.y
    local x2 = position_b.x
    local y2 = position_b.y
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end


local function is_colliding_rects(world, rect_a, rect_b)
    local position_a = Public.world_position(world, rect_a)
    local position_b = Public.world_position(world, rect_b)
    local scale_a = Public.world_scale(world, rect_a)
    local scale_b = Public.world_scale(world, rect_b)
    local hitbox_a = {
        width=rect_a.hitbox.width*scale_a.fraction,
        height=rect_a.hitbox.height*scale_a.fraction,
    }
    local hitbox_b = {
        width=rect_b.hitbox.width*scale_b.fraction,
        height=rect_b.hitbox.height*scale_a.fraction,
    }
    return (
        position_a.x + (hitbox_a.width/2) >= (position_b.x - (hitbox_b.width/2))
        and position_a.x - (hitbox_a.width/2) <= (position_b.x + (hitbox_b.width/2))
        and position_a.y + (hitbox_a.height/2) >= (position_b.y - (hitbox_b.height/2))
        and position_a.y - (hitbox_a.height/2) <= (position_b.y + (hitbox_b.height/2))
    )
end


local function is_colliding_circles(world, circle_a, circle_b)
    local position_a = Public.world_position(world, circle_a)
    local position_b = Public.world_position(world, circle_b)
    local scale_a = Public.world_scale(world, circle_a)
    local scale_b = Public.world_scale(world, circle_b)
    local radius_a = circle_a.hitbox.radius * scale_a.fraction
    local radius_b = circle_a.hitbox.radius * scale_b.fraction
    local dx = position_a.x - position_b.x
    local dy = position_a.y - position_b.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return (distance < radius_a + radius_b)
end


local function is_colliding_rect_circle(world, rectangle, circle)
    local rp = Public.world_position(world, rectangle)
    local rs = Public.world_scale(world, rectangle)
    local rw = rectangle.hitbox.width * rs.fraction
    local rh = rectangle.hitbox.height * rs.fraction
    rp.x = rp.x - (rw/2)
    rp.y = rp.y - (rh/2)

    local cp = Public.world_position(world, circle)
    local cs = Public.world_scale(world, circle)
    local cr = circle.hitbox.radius * cs.fraction

    -- http://www.jeffreythompson.org/collision-detection/circle-rect.php
    -- which edge is closest?
    local x = cp.x
    if cp.x < rp.x then
        x = rp.x
    elseif cp.x > rp.x+rw then
        x = rp.x + rw
    end

    local y = cp.y
    if cp.y < rp.y then
        y = rp.y
    elseif cp.y > rp.y+rh then
        y = rp.y + rh
    end

    -- get distance from closest edges
    local dist_x = cp.x-x
    local dist_y = cp.y-y
    local distance = math.sqrt((dist_x*dist_x) + (dist_y*dist_y))

    return distance <= cr
end


function Public.is_colliding(world, entity_a, entity_b)
    if entity_a.hitbox.shape == "rectangle" and entity_b.hitbox.shape == "rectangle" then
        return is_colliding_rects(world, entity_a, entity_b)
    elseif entity_a.hitbox.shape == "circle" and entity_b.hitbox.shape == "circle" then
        return is_colliding_circles(world, entity_a, entity_b)
    elseif entity_a.hitbox.shape == "rectangle" and entity_b.hitbox.shape == "circle" then
        return is_colliding_rect_circle(world, entity_a, entity_b)
    elseif entity_a.hitbox.shape == "circle" and entity_b.hitbox.shape == "rectangle" then
        return is_colliding_rect_circle(world, entity_b, entity_a)
    else
        assert(false, "unhandled")
    end
end


local DEFAULT_POSITION = {x=0, y=0}
local DEFAULT_SCALE = {fraction=1}
local DEFAULT_PARENT = {uid=nil}
local DEFAULT_ROTATION = {degrees=0}


function Public.world_position(world, entity)
    local position = Public.copy(entity.position or DEFAULT_POSITION)

    local parent = entity.parent or DEFAULT_PARENT
    while parent.uid ~= nil do
        parent = world.entities[parent.uid]

        local parent_position = parent.position or DEFAULT_POSITION
        position.x = position.x + parent_position.x
        position.y = position.y + parent_position.y
    end

    return position
end


function Public.world_scale(world, entity)
    local scale = Public.copy(entity.scale or DEFAULT_SCALE)

    local parent = entity.parent or DEFAULT_PARENT
    while parent.uid ~= nil do
        parent = world.entities[parent.uid]

        local parent_scale = parent.scale or DEFAULT_SCALE
        scale.fraction = scale.fraction * parent_scale.fraction
    end

    return scale
end


function Public.world_rotation(world, entity)
    local rotation = Public.copy(entity.rotation or DEFAULT_ROTATION)

    local parent = entity.parent or DEFAULT_PARENT
    while parent.uid ~= nil do
        parent = world.entities[parent.uid]

        local parent_rotation = parent.rotation or DEFAULT_ROTATION
        rotation.degrees = rotation.degrees + parent_rotation.degrees
    end

    return rotation
end



return Public
