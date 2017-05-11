-- sendfile.lua
-- 
-- send a file to the robot.
--
local args = { ... }
local filename = args[1]
if (not filename) then
    error("+++ Missing file name!", 1)
end
print("Filename: " .. filename)

-- Read file
local file, reason = io.open(filename, "r")
if (not file) then
    error(reason, 2)
end
local stuff = ""
while (true) do
    local line, reason = file:read()
    if (line) then
        stuff = stuff .. line .. "\n"
    else
        if (reason) then
            print("No (more) data: " .. reason)
        end
        break
    end
end
-- print("Data read: " .. stuff)
print(string.format("%d bytes read.", #stuff))
file:close()

-- Send file
local modem = require("component").modem
modem.setStrength(15)
modem.broadcast(123, stuff)
