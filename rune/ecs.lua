local HERE = (...):match("(.-)[^%.]+$") -- relative import hack
local utils = require(HERE.."utils")

local Public, Private = {}, {}


function Private.associate_system_entities(systems, entities)
    local association = {}
    for suid, system in pairs(systems) do
        local matches = {}
        if system.filter == nil then
            matches["uids"] = utils.keys(entities)
        elseif type(system.filter) == "function" then
            matches["uids"] = utils.keys(utils.filter(entities, system.filter))
        elseif type(system.filter) == "table" then
            matches["groups"] = {}
            for group, filter in pairs(system.filter) do
                matches["groups"][group] = utils.keys(utils.filter(entities, filter))
            end
        else
            assert(false, "unhandled")
        end

        association[suid] = matches
    end
    return association
end


function Private.associate_entity_children(entities)
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


function Public.World()
    local next_uid = utils.counter()
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
            system_entities = Private.associate_system_entities(systems, entities)
            _entity_children = Private.associate_entity_children(entities)
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
        assert(utils.contains(on, {"update", "draw"}), "on must be 'update' or 'draw'")
        local uid = next_uid()
        table.insert(promised_changes, utils.prime(utils.keyinsert, {systems, uid, system}))
        table.insert(promised_changes, utils.prime(table.insert, {type_system[on], uid}))
        return uid
    end

    local function remove_system(system_or_uid)
        local uid = system_or_uid
        if type(system_or_uid) == "table" then
            uid = system_or_uid.uid
        end
        table.insert(promised_changes, utils.prime(utils.keydelete, {systems, uid}))
        for _, type_systems in pairs(type_system) do
            table.insert(promised_changes, utils.prime(table.remove, {type_systems, uid}))
        end
    end

    local function add_entity(entity)
        local uid = next_uid()
        local _entity = {uid=uid}
        for _, component in pairs(entity) do
            _entity[component.name] = component
        end
        table.insert(promised_changes, utils.prime(utils.keyinsert, {entities, uid, _entity}))
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

    local function remove_entity(entity_or_uid)
        local uid = entity_or_uid
        if type(entity_or_uid) == "table" then
            uid = entity_or_uid.uid
        end
        table.insert(promised_changes, utils.prime(utils.keydelete, {entities, uid}))
    end

    local function add_component(entity_or_uid, component)
        -- TODO:
        -- do entities loojup inside function wrapper to handle case where
        -- add_component is used on same tick as the entity was added.
        local entity = entity_or_uid
        if type(entity_or_uid) ~= "table" then
            local uid = entity_or_uid
            entity = entities[uid]
        end
        table.insert(promised_changes, utils.prime(utils.keyinsert, {entity, component.name, component}))
    end

    local function children(entity_or_uid)
        local uid = entity_or_uid
        if type(entity_or_uid) == "table" then
            uid = entity_or_uid.uid
        end

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


function Private.eval(requirement, entity)
    if type(requirement) == "string" then
        return entity[requirement] ~= nil
    elseif type(requirement) == "function" then
        return requirement(entity)
    else
        assert(false, "unhandled case")
    end
end


function Public.And(requirements)
    local function evaluate(entity)
        local pass = true
        for _, requirement in pairs(requirements) do
            pass = pass and Private.eval(requirement, entity)
        end
        return pass
    end
    return evaluate
end


function Public.Or(requirements)
    local function evaluate(entity)
        local pass = false
        for _, requirement in pairs(requirements) do
            pass = pass or Private.eval(requirement, entity)
        end
        return pass
    end
    return evaluate
end


function Public.Xor(requirements)
    local function evaluate(entity)
        local pass = false
        for _, requirement in pairs(requirements) do
            local current = Private.eval(requirement, entity)
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


function Public.Not(requirements)
    local function evaluate(entity)
        return not Private.eval(requirements, entity)
    end
    return evaluate
end


function Public.Required(requirements)
    local function evaluate(entity)
        return Private.eval(requirements, entity)
    end
    return evaluate
end


function Public.Optional(requirements)
    local function evaluate(entity)
        return true
    end
    return evaluate
end


function Private.Parent(uid)
    return {
        name="parent",
        uid=uid
    }
end


Public.Components = {
    Parent=Private.Parent,
}


return Public
