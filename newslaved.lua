--[[ newslaved.lua

Responds to remote action commands.

* PING
    Request an ACK only.
* STOR <offs> <leng> <name> <data>
    Store file data.
* EXEC <command>
    Execute command in shell.
* MOVE <dir-string> ([FBLRUD]+)
    Perform a series of movements.
* STOP
    Stop listening.

This program can be started/stopped from the shell
or by the rc daemon.

--]]

local PROG       = "newslaved"
local VERS       = "Mo2218"
local LISTENER   = PROG .. "_listener"
local SLAVE_PORT = 666
local ACK_PORT   = 667
local STRENGTH   = 255

local component = require("component")
local event = require("event")
local modem = component.modem or die("No modem installed!")
local robot = require("robot")



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



-- Command functions

local function EXEC(line)
  say("EXEC %s", line)
  local rc = os.execute(line)
  if rc == 0 then return true, nil end
  error(fmt("returned %d", rc))
end



local moveTab = {
  F=robot.forward,
  B=robot.back,
  L=robot.turnLeft,
  R=robot.turnRight,
  U=robot.up,
  D=robot.down
}

local function MOVE(moves)
  say("MOVE %s", moves)
  for j=1,#moves do
    local c = string.sub(moves,j,j)
    local fn = moveTab[c]
    if not fn then
      say("Bad move: %s", c)
    else
      pcall(fn)
    end
  end
  return "Moved."
end



local function PING()
  say("PONG")
  return "PONG"
end



local function STOP()
  if not _G[LISTENER] then error("Not started!") end
  modem.close(SLAVE_PORT)
  event.ignore("modem_message", _G[LISTENER])
  _G[LISTENER] = nil
  return "Stopped."
end



local function STOR(offs, leng, name, data)
  say("offs: %d; leng: %d; name: %s; #data: %d; data: %s...", 
    offs, leng, name, #data, string.sub(data,1,20))
  local filesystem = require("filesystem")
  if offs == 0 and filesystem.exists(name) then
    say("Deleting existing file \"%s\"", name)
    if not filesystem.remove(name) then
      error(fmt("Could not delete \"%s\"", name))
    end
  end
  local mode = (offs == 0) and "wb" or "ab"
  local file = filesystem.open(name, mode)
  if not file then error(fmt("Could not delete \"%s\"", name)) end
  file:seek("set", offs)
  if not file:write(data) then error("File write failed") end
  file:close()
  local msg
  if (offs == 0) then
      msg = fmt("Wrote %d bytes to file \"%s\".", leng, name)
  else
      msg = fmt("Wrote %d bytes @ offset %d in file \"%s\".", leng, offs, name)
  end
  return msg
end



local funTab = { EXEC=EXEC, MOVE=MOVE, PING=PING, STOP=STOP, STOR=STOR }



-- Background listener function

local function onMessage(_, _, bossAddr, port, dist, cmd, ...)
  say("onMessage: %s (%4d) -> %5d: %-25.25s", bossAddr, dist, port, cmd)
  if port ~= SLAVE_PORT then return true end
  if not cmd then return true end
  if type(cmd) ~= "string" then return true end
  local ucmd = string.upper(cmd)
  local fun = funTab[ucmd]
  -- say("cmd: %s; fun: %s", ucmd, tostring(fun))
  if not fun then return true end
  ----------------------------------
  local stat, res = pcall(fun, ...)
  ----------------------------------
  local ackNak = stat and "ACK" or "NAK"
  local mesg
  if res then 
    mesg = ": " .. tostring(res)
  else 
    mesg = ""
  end
  -- say("%s %s%s", ackNak, ucmd, mesg)
  modem.send(bossAddr, ACK_PORT, ackNak, ucmd, mesg)
  return (ucmd ~= "STOP")
end



-- rc lifecycle functions

function start()
  if _G[LISTENER] then die("Already listening!") end
  modem.open(SLAVE_PORT)
  event.listen("modem_message", onMessage)
  _G[LISTENER]=onMessage
  modem.setStrength(STRENGTH)
  return true, "Started."
end



function stop()
  local stat, mesg = pcall(STOP)
  say("%s", mesg)
end


-- Main --

print(string.format("*** %s %s running on console", PROG, VERS))
local args = { ... }
if (not args) or (not args[1]) then die("Missing argument!") end
local ucmd = string.upper(args[1])
if ucmd == "START" then
  start()
elseif ucmd == "STAT" then
  local msg1 = _G[LISTENER] and "Listening" or "Not listening"
  local msg2 = modem.isOpen(SLAVE_PORT) and "open" or "closed"
  say("%s; slave port %s.", msg1, msg2)
elseif ucmd == "STOP" then
  stop()
else
  die("+++ Bad command \"%s\"!", ucmd)
end
