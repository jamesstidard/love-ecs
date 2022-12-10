local utils = require("rune.utils")

local UINT8_MIN = 0
local UINT8_MAX = 2^8 - 1
local UINT32_MIN = 0
local UNIT32_MAX = 2^32 - 1
local KEYS = {"W_DOWN", "W_UP", "A_DOWN", "A_UP", "S_DOWN", "S_UP", "D_DOWN", "D_UP"}
local PLAYERS = {1, 2, 3, 4, 5, 6, 7, 8}


local ROOM_ID = {
    name="room_id",
    type="number",
    min=UINT8_MIN,
    max=UINT8_MAX,
}
local SEED = {
    name="seed",
    type="number",
    min=UINT8_MIN,
    max=UINT8_MAX,
}
local PLAYER = {
    name="player",
    type="enum",
    options=PLAYERS,
}
local TIME = {
    name="time",
    type="number",
    min=UINT32_MIN,
    max=UNIT32_MAX,
}
local MOVES = {
    name="moves",
    type="enum",
    options=KEYS,
    variadic=true,
}


local schema = {
    {
        -- Client submission to create game.
        name="create",
        implemented_by="server",
        arguments={},
        returns={ROOM_ID, SEED, PLAYER},
    },
    {
        -- Client submission to join game.
        name="join",
        implemented_by="server",
        arguments={ROOM_ID},
        returns={SEED, PLAYER},
    },
    {
        -- Client/Server submission/assertions for inputs for simulation tick.
        name="insert_tick",
        implemented_by={"server", "client"},
        arguments={TIME, PLAYER, MOVES},
        returns={},
    },
}


local function is_variadic(item)
    return item["variadic"]
end


local function validate_argument(path, argument)
    assert(not utils.isarray(argument), path.." must be an table, not array.")

    local provided = utils.keys(argument)
    local required = {"name", "type"}
    local defaults = {}

    if argument["type"] == "number" then
        utils.extend(required, {"min", "max"})
    elseif argument["type"] == "enum" then
        utils.extend(required, {"options"})
    else
        assert(false, "unknown type: "..argument["type"])
    end

    local optional = utils.keys(defaults)
    local missing = utils.difference(required, provided)
    local unknown = utils.difference(provided, utils.union(required, optional))

    assert(#missing == 0, path.." has missing keys: "..table.concat(missing, ", "))
    assert(#unknown == 0, path.." has unknown keys: "..table.concat(unknown, ", "))

    -- apply defaults
    argument = utils.merge(argument, defaults)

    return argument
end


local function validate_action(path, action)
    assert(not utils.isarray(action), path.." must be an table, not array.")

    local provided = utils.keys(action)
    local required = {"name", "implemented_by"}
    local defaults = {arguments={}, returns={}}
    local optional = utils.keys(defaults)

    local missing = utils.difference(required, provided)
    local unknown = utils.difference(provided, utils.union(required, optional))

    assert(#missing == 0, path.." has missing keys: "..table.concat(missing, ", "))
    assert(#unknown == 0, path.." has unknown keys: "..table.concat(unknown, ", "))

    -- apply defaults
    action = utils.merge(action, defaults)

    -- normalise implemented_by
    if type(action["implemented_by"]) == "string" then
        action["implemented_by"] = {action["implemented_by"]}
    end

    assert(utils.issubset(action["implemented_by"], {"client", "server"}), path..".implemented_by must be 'client' and/or 'server'.")
    assert(utils.isarray(action["arguments"]), path..".arguments must be array, not table; deterministic order is important for optimising packet size.")
    assert(utils.isarray(action["returns"]), path..".returns must be array, not table; deterministic order is important for optimising packet size.")

    for index, argument in ipairs(action["arguments"]) do
        argument = validate_argument(path..".arguments."..index, argument)
        action["arguments"][index] = argument
    end
    local variadics = utils.filter(action["arguments"], is_variadic)
    assert(#variadics <= 1, path..".arguments can only have single variadic argument.")
    assert(#variadics == 0 or is_variadic(action["arguments"][-1]), path.." variadic argument must be last.")

    for index, return_ in ipairs(action["returns"]) do
        return_ = validate_argument(path..".returns."..index, return_)
        action["returns"][index] = return_
    end
    variadics = utils.filter(action["returns"], is_variadic)
    assert(#variadics <= 1, path..".returns can only have single variadic return.")
    assert(#variadics == 0 or is_variadic(action["returns"][-1]), path.." variadic return must be last.")

    return action
end


local function validate_schema(schema)
    assert(utils.isarray(schema), "schema must be an array, not table; deterministic order is important for optimising packet size.")

    local implements = {server={}, client={}}
    for index, action in ipairs(schema) do
        local path = "schema"..index
        action = validate_action(path, action)

        -- assert no name collisions on implementor
        for _, peer in ipairs(action["implemented_by"]) do
            assert(not utils.contains(action["name"], implements[peer]), path..".name "..action["name"].." already implemented by "..peer)
            table.insert(implements[peer], action["name"])
        end

        schema[index] = action  -- update with any changes. feels pretty yikes.
    end

end

validate_schema(schema)
