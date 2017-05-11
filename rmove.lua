--[[ rmove.lua

Send movement commands to reobot

--]]


local PROG = "newtransfer"
local VERSION= "Mo2228"
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
  if cmd ~= "MOVE" then return true end
  if ackNak == "ACK" then
    say("ACK with message: %s", mesg)
    state = "ACK"
    return true
  else
    state = "STOP"
    say("NAK with message: %s", mesg)
    return false
  end
end



-- Main

local args = { ... }
if not args or not args[1] or not args[2] then
  die("Missing argument(s): destination host, move string!")
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

local moveString = args[2]

modem.setStrength(STRENGTH)
modem.open(ACK_PORT)
event.listen("modem_message", onAck)

modem.send(hostAddr, SLAVE_PORT, "MOVE", moveString)

state = "WAIT_ACK"
local ticks = 0
-- Wait for ACK before sending next packet
while state == "WAIT_ACK" do
  os.sleep(0.05)
  ticks = ticks + 1
  if ticks > 20*#moveString then
    say("Timeout!")
    state = "STOP"
  end
end

modem.close(ACK_PORT)
event.ignore("modem_message", onAck)
