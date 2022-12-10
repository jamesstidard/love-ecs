local socket = require("socket")
local utils = require("rune.utils")


local Public, Private = {}, {}


function Private.is_variadic(item)
    return item["variadic"]
end


function Private.validate_argument(path, argument)
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


function Private.validate_action(path, action)
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
        argument = Private.validate_argument(path..".arguments."..index, argument)
        action["arguments"][index] = argument
    end
    local variadics = utils.filter(action["arguments"], is_variadic)
    assert(#variadics <= 1, path..".arguments can only have single variadic argument.")
    assert(#variadics == 0 or is_variadic(action["arguments"][-1]), path.." variadic argument must be last.")

    for index, return_ in ipairs(action["returns"]) do
        return_ = Private.validate_argument(path..".returns."..index, return_)
        action["returns"][index] = return_
    end
    variadics = utils.filter(action["returns"], is_variadic)
    assert(#variadics <= 1, path..".returns can only have single variadic return.")
    assert(#variadics == 0 or Private.is_variadic(action["returns"][-1]), path.." variadic return must be last.")

    return action
end


function Private.validate_api(api)
    assert(utils.isarray(api), "schema must be an array, not table; deterministic order is important for optimising packet size.")

    local implements = {server={}, client={}}
    for index, action in ipairs(api) do
        local path = "schema"..index
        action = Private.validate_action(path, action)

        -- assert no name collisions on implementor
        for _, peer in ipairs(action["implemented_by"]) do
            assert(not utils.contains(action["name"], implements[peer]), path..".name "..action["name"].." already implemented by "..peer)
            table.insert(implements[peer], action["name"])
        end

        api[index] = action  -- update with any changes. feels pretty yikes.
    end

    return api
end


function Public.Client(host, port, api)
    local udp = socket.udp()
    udp:setpeername(host, port)
    udp:settimeout(0)

    api = Private.validate_api(api)

    return {udp=udp, api=api}
end


function Public.Server(host, port, api)
    local udp = socket.udp()
    udp:setsockname(host, port)
    udp:settimeout(0)

    api = Private.validate_api(api)

    return {udp=udp, api=api}
end


return Public
