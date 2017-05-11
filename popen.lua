--[[ popen.lua 

Test: Run a command and capture its output.

--]]

local channel = io.popen("ls", "r")
local output = channel:read("*a")
channel:close()
print("Output: " .. output)
