--- Rectangle
-- @param mode "fill" or "line"
-- @param width in pixels
-- @param height in pixels
-- @param rx x-axis of round corner. Cannot be greater then half the width.
-- @param ry y-axis of round corner. Cannot be greater then half the height..
function Rectangle(mode, width, height, rx, ry)
    return {
        name="rectangle",
        mode=mode,
        width=width,
        height=height,
        rx=rx,
        ry=ry,
    }
end
