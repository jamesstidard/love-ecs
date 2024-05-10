-- Hitbox

function Hitbox(shape, width, height, radius)
    local hitbox = {
        name="hitbox"
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
        error("invalid hitbox arguments")
    end

    return hitbox
end
