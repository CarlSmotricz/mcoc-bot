print("*** recv starting.")
local args = { ... }
if (not args) then
    error("+++ No arguments!", 1)
end
local filename = args[1]
if (not filename) then
    error("+++ No filename!", 2)
end
local event = require("event")
local modem = require("component").modem
modem.open(123)
local _, _, rem, _, dis, txt = event.pull("modem_message")
-- print("rem: " .. tostring(rem))
-- print("dis: " .. tostring(dis))
print("txt: ")
print(tostring(txt))
local file = io.open(filename, "w")
if (not file) then
    error(string.format("+++ Couldn't open file %s: %s", filename, reason), 3)
end
file:write(txt)
file:close()
print("*** recv finished.")
