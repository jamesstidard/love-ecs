local Public, Private = {}, {}


function Public.extend(list, values)
    for _, v in pairs(values) do
        table.insert(list, v)
    end
end


function Public.contains(value, table)
    for _, element in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end


function Public.nextlowest(list)
    -- finds next lowest possible index to insert into a list
    -- so if index 1 gets removed, but index 2, 3, etc exist
    -- 1 will be returned.
    local index = 1
    while true do
        if list[index] == nil then
            return index
        end
        index = index + 1
    end
end


function Public.sorted(list, fn)
    local copy = Public.copy(list)
    table.sort(copy, fn)
    return copy
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


function Public.keys(list)
    local keys = {}
    for k, _ in pairs(list) do
        table.insert(keys, k)
    end
    return keys
end


function Public.values(list)
    local arr = {}
    for _, v in pairs(list) do
        table.insert(arr, v)
    end
    return arr
end


function Public.filter(list, fn)
    local matches = {}
    for k, v in pairs(list) do
        if fn(v) then
            matches[k] = v
        end
    end
    return matches
end


function Public.keyinsert(list, name, value)
    list[name] = value
end


function Public.keydelete(list, name)
    list[name] = nil
end


function Public.map(list, fn)
    local out = {}
    for k, v in pairs(list) do
        out[k] = fn(v)
    end
    return out
end


function Public.zip(keys, values)
    local out = {}
    local len = math.min(#keys, #values)
    local idx = 1
    while idx <= len do
        out[keys[idx]] = values[idx]
        idx = idx + 1
    end
    return out
end


function Public.slice(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
      sliced[#sliced+1] = tbl[i]
    end

    return sliced
  end


function Public.setdeafult(list, name, value)
    if list[name] == nil then
        list[name] = value
    end
    return list[name]
end


function Public.invert(tbl)
    -- flips keys and values
    local out = {}
    for k, v in pairs(tbl) do
        out[v] = k
    end
    return out
end


function Public.counter()
    local count = 0
    return function()
        count = count + 1
        return count
    end
end


function Public.prime(fn, args)
    return function()
        fn(unpack(args))
    end
end


function Public.isarray(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end


function Public.union(a, b)
    -- all values in both a and b combined
    -- i.e. set(a) | set(b)
    local values = {}
    for _, value in ipairs(a) do
        table.insert(value)
    end
    for _, value in ipairs(b) do
        if not Public.contains(value, values) then
            table.insert(value)
        end
    end
    return values
end


function Public.difference(a, b)
    -- values in a that are not in b
    -- i.e. set(a) - set(b)
    local values = {}
    for _, value in ipairs(a) do
        if not Public.contains(value, b) then
            table.insert(value)
        end
    end
    return values
end


return Public
