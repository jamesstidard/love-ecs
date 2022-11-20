local ecs = require("love.ecs")
local world = ecs.World()

local System = {}
System.filter = nil
function System.run(_, _, _) end

local uid = world.add_system(System, "update")
world:update(0)
assert(#world.systems == 1, "system not added")
world.remove_system(uid)
world:update(0)
assert(#world.systems == 0, "system not removed")
