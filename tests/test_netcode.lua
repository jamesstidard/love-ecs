local utils = require("rune.utils")

local KEYS = {"W", "A", "S", "D"}
local PLAYERS = {1, 2, 3, 4, 5, 6, 7, 8}

local schema = {
    {
        name="join",
        description="Client submission to join game.",
        implemented_by="server",
        authenticated=false,  -- no signature required on this message (default true)
        arguments={
            {
                name="public_key",
                description="Client public key to be used by the server to authenticate subsequent messages.",
                type="bit256",
            },
        },
        returns={
            {
                name="seed",
                description="Game seed to drive clients deterministic simulation.",
                type="uint16",
            },
            {
                name="player",
                description="Assign player number for client.",
                type=PLAYERS,
            },
            {
                name="public_key",
                description="Server public key to be used by the client to authenticate subsequent messages.",
                type="bit256",
            },
        }
    },
    {
        name="insert_tick",
        description="Client submission for their inputs for simulation tick.",
        implemented_by="server",
        arguments={
            {
                name="time",
                type="uint22",  -- (2^22)/60/60/60 == 19.42 hours max  (maybe should wrap a lower bit number instead?)
            },
            {
                name="moves",
                type="enum",
                options=KEYS,
                variadic=true,
            },
        },
        returns={},
    },
    {
        name="insert_tick",
        description="Server broadcast for their inputs for simulation tick.",
        implemented_by="client",
        arguments={
            {
                name="time",
                type="uint22",  -- (2^22)/60/60/60 == 19.42 hours max  (maybe should wrap a lower bit number instead?)
            },
            {
                name="player",
                type="enum",
                options=PLAYERS,
            },
            {
                name="moves",
                type="enum",
                options=KEYS,
                variadic=true,
            },
        },
        returns={},
    }
}



local function is_variadic(item)
    return item["variadic"]
end


local function validate_action(path, action)
    assert(not utils.isarray(action), path.." must be an table, not array.")

    local provided = utils.keys(action)
    local required = {"name", "implemented_by"}
    local defaults = {description="", authenticated=true, arguments={}, returns={}}
    local optional = utils.keys(defaults)

    local missing = utils.difference(required, provided)
    local unknown = utils.difference(provided, utils.union(required, optional))

    assert(#missing > 0, path.." has missing keys: "..table.concat(missing, ", "))
    assert(#unknown > 0, path.." has unknown keys: "..table.concat(unknown, ", "))

    -- apply defaults
    for key, default in pairs(defaults) do
        if action[key] == nil then
            action[key] = default
        end
    end

    assert(utils.contains(action["implemented_by"], {"client", "server"}), path..".implemented_by must be 'client' or 'server'.")
    assert(utils.isarray(action["arguments"]), path..".arguments must be array, not table; deterministic order is important for optimising packet size.")
    assert(utils.isarray(action["returns"]), path..".returns must be array, not table; deterministic order is important for optimising packet size.")

    for index, argument in ipairs(action["arguments"]) do
        validate_argument(path..".arguments."..index, argument)
    end
    local variadics = utils.filter(action["arguments"], is_variadic)
    assert(#variadics <= 1, path..".arguments can only have single variadic argument.")
    assert(#variadics == 0 or is_variadic(action["arguments"][-1]), path.." variadic argument must be last.")

    for index, return_ in ipairs(action["returns"]) do
        validate_return(path..".returns."..index, return_)
    end
    variadics = utils.filter(action["returns"], is_variadic)
    assert(#variadics <= 1, path..".returns can only have single variadic return.")
    assert(#variadics == 0 or is_variadic(action["returns"][-1]), path.." variadic return must be last.")
end


local function validate_schema(schema)
    assert(utils.isarray(schema), "schema must be an array, not table; deterministic order is important for optimising packet size.")
    for index, action in ipairs(schema) do
        validate_action("schema."..index, action)
    end
end

validate_schema(schema)
