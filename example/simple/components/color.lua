--- Color
-- @param red 0-255
-- @param green 0-255
-- @param blue 0-255
-- @param alpha 0-1
function Color(red, green, blue, alpha)
    return {
        name="color",
        red=red / 255,
        green=green / 255,
        blue=blue / 255,
        alpha=alpha
    }
end
