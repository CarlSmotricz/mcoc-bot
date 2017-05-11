local args = { ... }
if (not args) then
    error("+++ Missing arguments!", 1)
end
local filename = args[1]
if (not filename) then
    error("+++ Missing filename", 2)
end
local internet = require("internet")
local prefix = "http://minecraft-carlsmotricz.c9users.io:8081/"
local req, reason = internet.request(prefix .. filename)
if (not req) then
    error(reason, 3)
end
local data, reason = req()
if (not data) then
    error(reason, 4)
end
local file = io.open(filename, "w")
if (not file) then
    error("couldn't open file " .. filename, 5)
end
if (type(data) ~= "string") then
    error("data isn't string!", 6)
end
print("Received " .. tostring(#data) .. " bytes.")
file:write(data)
file:close
