--[[ newtransfer.lua

Transfer a file to a computer running "newslaved.lua"

--]]


local PROG = "newtransfer"
local VERSION= "Mo2221"
local SLAVE_PORT = 666
local ACK_PORT = 667
local STRENGTH = 255
local CHUNK_SIZE = 1500

local component = require("component")
local event = require("event")
local filesystem = require("filesystem")
local modem = component.modem or die("No modem installed!")

local state = "?"


-- Utility functions

local function fmt(form, ...)
  return string.format(form, ...)
end



local function say(form, ...)
  local s = fmt(form, ...)
  print(s)
  return s
end



local function die(msg)
  say("+++ %s", msg)
  os.exit(1)
end



-- Background listener function

local function onAck(_, _, peonAddr, port, dist, ackNak, cmd, mesg)
  say("onAck: %s (%4d) -> %5d: %s", 
    peonAddr, dist, port, string.sub(cmd,1,15))
  if port ~= ACK_PORT then return true end
  if not cmd then return true end
  if type(cmd) ~= "string" then return true end
  if cmd ~= "STOR" then return true end
  if ackNak == "ACK" then
    state = "ACKED"
    return true
  else
    say("NAK with message: %s", mesg)
    state = "STOP"
    return false
  end
end



-- Main

local args = { ... }
if not args or not args[1] or not args[2] then
  die("Missing arguments: destination host, file name!")
end

local hostName = args[1]
local hostFileName = "/home/hosts/" .. hostName
if (not filesystem.exists(hostFileName)) then
  die("+++ No such host in /home/hosts: \"%s\"", hostName)
end
local hostFile, reason = io.open(hostFileName)
if (not hostFile) then
  die("+++ Couldn't open %s: %s", hostFileName, reason)
end
local hostAddr = hostFile:read()
say("Host address for '%s': %s .", hostName, hostAddr)
hostFile:close()

local fileName = args[2]
if (string.sub(fileName,1,1) ~= "/") then
    local pwd = os.getenv("PWD")
    if (pwd) then
        fileName = pwd .. "/" .. fileName
    end
end

if (not filesystem.exists(fileName)) then
    die("+++ No such file: \"%s\"", fileName)
end

if (filesystem.isDirectory(fileName)) then
    die("+++ \"%s\" is a directory!", fileName)
end
    
local fileSize = filesystem.size(fileName)
say("%6d bytes in file \"%s\" ;", fileSize, fileName)
say("%6d bytes per chunk.", CHUNK_SIZE)

modem.setStrength(STRENGTH)
modem.open(ACK_PORT)
event.listen("modem_message", onAck)

local file = filesystem.open(fileName, "rb")
local offs = 0
local left = fileSize
-- Send file chunk by chunk to overcome packet limit
while (left > 0) and (state ~= "STOP") do
  local bite = math.min(left, CHUNK_SIZE)
  local data = file:read(bite)
  say("Read %d bytes.", #data)
  if (#data < bite) then
    die("Expected to read %d bytes!", bite)
  end
  state = "WAIT_ACK"
  local ticks = 0
  modem.send(hostAddr, SLAVE_PORT, "STOR", offs, bite, fileName, data)
  -- Wait for ACK before sending next packet
  while state == "WAIT_ACK" do
    os.sleep(0.01)
    ticks = ticks + 1
    if ticks > 15 then
      say("Timeout!")
      state = "STOP"
    end
  end
  left = left - bite
  offs = offs + bite
end
file:close()

modem.close(ACK_PORT)
event.ignore("modem_message", onAck)
