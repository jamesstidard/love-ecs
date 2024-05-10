--- ZIndex
-- Determins relative rendering order of entities.
-- i.e. what draws over the top of what.
-- @param index 0-100 where 0 is on top and 100 is behind.
function ZIndex(index)
    return {
        name="zindex",
        index=index,
    }
end
