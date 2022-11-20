-- forgive me father for I have sinned...
-- import all other .lua files in this directory
local dir = "systems"

for _, file in pairs(love.filesystem.getDirectoryItems(dir)) do
    if file ~= "*.lua" then
        require(table.concat({dir, file:sub(1, -5)}, "."))
    end
end
