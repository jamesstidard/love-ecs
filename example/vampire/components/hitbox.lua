-- Hitbox

function Hitbox(shape, width, height, radius)
    local hitbox = {
        name="hitbox",
        shape=shape,
    }

    if (
        shape == "rectangle"
        and width ~= nil
        and height ~= nil
        and radius == nil
    ) then
        hitbox.width = width
        hitbox.height = height
    elseif (
        shape == "circle"
        and width == nil
        and height == nil
        and radius ~= nil
    ) then
        hitbox.radius = radius
    else
        print(shape, width, height, radius)
        error("invalid hitbox arguments")
    end

    return hitbox
end
