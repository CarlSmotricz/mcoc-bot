-- logd.lua
-- 
-- write remote log messages to a file.

local modem = require("component").modem
local event = require("event")
local FILENAME = "/tmp/log"
local PORT = 514

function onMessage(evt, recvAddr, sendAddr, port, distance, ...)
    if (port ~= PORT) then
        return
    end
    local file = io.open("/tmp/log.2", "a")
    if (not file) then
        print(string.format("+++ Couldn't append to file %s", FILENAME))
        return
    end
    local timestamp = os.date("!%Y-%m-%d %H:%M")
    local source = string.sub(sendAddr, 1, 4)
    local dist = math.floor(distance)
    local msg = table.concat({ ... }, " ", 1)
    file:write(string.format("%s %s (%d): %s\n", timestamp, source, dist, msg))
    file:close()
end
    
function start()
    print("logd Ver. 12:14")
    if (modem.isOpen(PORT)) then
        error(string.format("+++ Port %d is already open!", PORT), 1)
    end
    local ok = event.listen("modem_message", onMessage)
    if (not ok) then
        error("+++ listen() failed - already listening!", 2)
    end
    modem.open(PORT)
end

function stop()
    if (not modem.isOpen(PORT)) then
        error(string.format("+++ Port %d is not listening!", PORT))
    end
    local ok = event.ignore("modem_message", onMessage)
    if (not ok) then
        error("+++ ignore() failed - not listening!", 3)
    end
    modem.close(PORT)
end
