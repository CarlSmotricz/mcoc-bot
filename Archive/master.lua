-- master.lua
--
-- program to tell the robot what to do.
--
local args = { ... }
if (not args) then
    error("+++ Missing args!", 1)
end
local command = ""
for k, v in pairs(args) do
    if (command ~= "") then
        command = command .. " "
    end
    command = command .. tostring(v)
end
print("Command = " .. command)
local component = require("component")
local modem = component.modem
modem.setStrength(15)
modem.broadcast(666, command)
print("... broadcasted.")