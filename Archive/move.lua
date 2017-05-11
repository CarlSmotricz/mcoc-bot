-- move.lua
--
-- turn the robot left or right, move forward, back, up or down.

local args = { ... }
if (not args) then
    error("+++ No args!", 1)
end
local dir = args[1]
if (not dir) then
    error("+++ No dir!", 2)
end
robot = require("robot")
dir = string.gsub(dir, "^(%a)", "%1")
if (dir == "L") then
    robot.turnLeft()
elseif (dir == "R") then
    robot.turnRight()
elseif (dir == "U") then
    robot.up()
elseif (dir == "D") then
    robot.down()
elseif (dir == "F") then
    robot.forward()
elseif (dir == "B") then
    robot.back()
else
    print(string.format("+++ bad command: %s", dir))
end
