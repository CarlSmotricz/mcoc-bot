-- broadcast.lua
--
-- send some text to a given port for all listening hosts.

local STRENGTH   = 255
local ACK_PORT   = 667

local event = require("event")
local modem = require("component").modem
local listening = false


function stopListening()
    local status = event.ignore("modem_message", onMessage)
    if (not status) then
        print("+++ ignore() failed - not listening!")
    end
    modem.close(ACK_PORT)
    print("Stopped listening (I hope)")
    listening = false
end


function onMessage(evt, _, bossAddr, port, distance, msg)
    print(string.format("Received message \"%s\"", msg))
    stopListening()
end


-- MAIN

local args = { ... }
if (not args) then
    error("+++ Missing arguments (port and message)!")
end
local port = tonumber(args[1])
if (type(port) ~= "number") then
    error(string.format("+++ Non-numeric \"%s\" for port number!", port))
end

-- Set up to listen for ACK

local status = event.listen("modem_message", onMessage)
if (not status) then
    print("+++ listen() failed - already listening!")
end
modem.open(ACK_PORT)
listening = true

-- Transmit command

local strength = modem.getStrength()
modem.setStrength(STRENGTH)
modem.broadcast(port, table.concat(args, " ", 2))
modem.setStrength(strength)

-- Wait for ACK

os.sleep(1)
if (listening) then
    stopListening()
end
