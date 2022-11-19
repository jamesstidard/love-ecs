local function associate_system_entities(systems, entities)
    local association = {}
    for suid, system in pairs(systems) do
        local matches = {}
        if system.filter == nil then
            matches["uids"] = table.keys(entities)
        elseif type(system.filter) == "function" then
            matches["uids"] = table.keys(table.filter(entities, system.filter))
        elseif type(system.filter) == "table" then
            -- todo: multiple filters handed into systems in groups
            matches["groups"] = {}
            for group, filter in pairs(system.filter) do
                matches["groups"][group] = table.keys(table.filter(entities, filter))
            end
        else
            assert(false, "unhandled")
        end

        association[suid] = matches
    end
    return association
end


local function associate_entity_children(entities)
    local children = {}

    for euid, entity in pairs(entities) do
        if children[euid] == nil then
            children[euid] = {}
        end

        if entity.parent ~= nil then
            local _children = children[entity.parent.uid] or {}
            table.insert(_children, euid)
            children[entity.parent.uid] = _children
        end
    end

    return children
end


World = {}

function World.init()
    local next_uid = counter()
    local entities = {}
    local systems = {}

    -- tracks draw/update to system uid
    local type_system = {
        draw={},
        update={},
    }
    -- system entities {system_uid: {entity_uid, ...}, ...}
    local system_entities = {}
    -- creations and deletions todo before next tick
    local promised_changes = {}
    -- tracks the parent to child relationship of entities {entity_uid: {entity_uid, ...}, ...}
    local _entity_children = {}

    local function apply_changes()
        if #promised_changes > 0 then
            for _, change in pairs(promised_changes) do
                change()
            end
            promised_changes = {}

            -- update cached state
            system_entities = associate_system_entities(systems, entities)
            _entity_children = associate_entity_children(entities)
        end
    end

    local function run_systems(self, uids, extra_args)
        apply_changes()

        for _, suid in pairs(uids) do
            local system = systems[suid]
            local associated = system_entities[suid]

            local selected = {}
            if associated.uids ~= nil then
                for _, euid in pairs(associated.uids) do
                    selected[euid] = entities[euid]
                end
            elseif associated.groups ~= nil then
                for group, euids in pairs(associated.groups) do
                    selected[group] = {}
                    for _, euid in pairs(euids) do
                        selected[group][euid] = entities[euid]
                    end
                end
            else
                assert(false, "unhandled")
            end

            system.run(self, selected, unpack(extra_args))
        end
    end

    local function update(self, dt)
        run_systems(self, type_system.update, {dt})
    end

    local function draw(self)
        run_systems(self, type_system.draw, {})
    end

    local function add_system(system, on)
        assert(table.contains(on, {"update", "draw"}), "on must be 'update' or 'draw'")
        local uid = next_uid()
        table.insert(promised_changes, prime(table.keyinsert, {systems, uid, system}))
        table.insert(promised_changes, prime(table.insert, {type_system[on], uid}))
        return uid
    end

    local function remove_system(uid)
        table.insert(promised_changes, prime(table.keydelete, {systems, uid}))
        for _, type_systems in pairs(type_system) do
            table.insert(promised_changes, prime(table.remove, {type_systems, uid}))
        end
    end

    local function add_entity(entity)
        local uid = next_uid()
        local _entity = {}
        for _, component in pairs(entity) do
            _entity[component.name] = component
        end
        table.insert(promised_changes, prime(table.keyinsert, {entities, uid, _entity}))
        return uid
    end

    local function add_entities(entities_)
        local uids = {}
        for _, entity in pairs(entities_) do
            local uid = add_entity(entity)
            table.insert(uids, uid)
        end
        return uids
    end

    local function remove_entity(uid)
        table.insert(promised_changes, prime(table.keydelete, {entities, uid}))
    end

    local function add_component(entity_uid, component)
        local entity = entities[entity_uid]
        table.insert(promised_changes, prime(table.keyinsert, {entity, component.name, component}))
    end

    local function children(uid)
        local _children = {}
        for _, cuid in pairs(_entity_children[uid]) do
            _children[cuid] = entities[cuid]
        end
        return _children
    end

    return {
        ctx={},
        add_system=add_system,
        remove_system=remove_system,
        add_entity=add_entity,
        add_entities=add_entities,
        remove_entity=remove_entity,
        add_component=add_component,
        entities=entities,
        systems=systems,
        children=children,
        update=update,
        draw=draw,
    }
end



function table.extend(list, values)
    for _, v in pairs(values) do
        table.insert(list, v)
    end
end


function table.contains(value, table)
    for _, element in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end


function table.nextlowest(list)
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


function table.sorted(list, fn)
    local copy = table.copy(list)
    table.sort(copy, fn)
    return copy
end


function table.copy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end


function table.deepcopy(original)
    local orig_type = type(original)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, original, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(original)))
    else -- number, string, boolean, etc
        copy = original
    end
    return copy
end


function table.keys(list)
    local keys = {}
    for k, _ in pairs(list) do
        table.insert(keys, k)
    end
    return keys
end


function table.values(list)
    local arr = {}
    for _, v in pairs(list) do
        table.insert(arr, v)
    end
    return arr
end


function table.filter(list, fn)
    local matches = {}
    for k, v in pairs(list) do
        if fn(v) then
            matches[k] = v
        end
    end
    return matches
end


function table.keyinsert(list, name, value)
    list[name] = value
end


function table.keydelete(list, name)
    list[name] = nil
end


function table.map(list, fn)
    local out = {}
    for k, v in pairs(list) do
        out[k] = fn(v)
    end
    return out
end


function table.zip(keys, values)
    local out = {}
    local len = math.min(#keys, #values)
    local idx = 1
    while idx <= len do
        out[keys[idx]] = values[idx]
        idx = idx + 1
    end
    return out
end


function table.slice(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
      sliced[#sliced+1] = tbl[i]
    end

    return sliced
  end


function table.setdeafult(list, name, value)
    if list[name] == nil then
        list[name] = value
    end
    return list[name]
end


function table.invert(tbl)
    -- flips keys and values
    local out = {}
    for k, v in pairs(tbl) do
        out[v] = k
    end
    return out
end


function counter()
    local count = 0
    return function()
        count = count + 1
        return count
    end
end


function prime(fn, args)
    return function()
        fn(unpack(args))
    end
end


local function eval(requirement, entity)
    if type(requirement) == "string" then
        return entity[requirement] ~= nil
    elseif type(requirement) == "function" then
        return requirement(entity)
    else
        assert(false, "unhandled case")
    end
end


function And(requirements)
    local function evaluate(entity)
        local pass = true
        for _, requirement in pairs(requirements) do
            pass = pass and eval(requirement, entity)
        end
        return pass
    end
    return evaluate
end


function Or(requirements)
    local function evaluate(entity)
        local pass = false
        for _, requirement in pairs(requirements) do
            pass = pass or eval(requirement, entity)
        end
        return pass
    end
    return evaluate
end


function Xor(requirements)
    local function evaluate(entity)
        local pass = false
        for _, requirement in pairs(requirements) do
            local current = eval(requirement, entity)
            if not pass and current then
                pass = true
            elseif pass and current then
                return false
            end
        end
        return pass
    end
    return evaluate
end


function Not(requirements)
    local function evaluate(entity)
        return not eval(requirements, entity)
    end
    return evaluate
end


function Required(requirements)
    local function evaluate(entity)
        return eval(requirements, entity)
    end
    return evaluate
end


function Optional(requirements)
    local function evaluate(entity)
        return true
    end
    return evaluate
end


function Parent(uid)
    return {
        name="parent",
        uid=uid
    }
end


return {
    World=World,
    And=And,
    Or=Or,
    Required=Required,
    Optional=Optional,
    Components={
        Parent=Parent,
    }
}
