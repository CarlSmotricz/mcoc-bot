-- transfer.lua
--
-- transfer a file to a computer running "slaved.lua"
--

local PROG       = "slaved"
local VERSION    = "19:17"
local SLAVE_PORT = 666
local ACK_PORT   = 667
local LOGD_PORT  = 514
local STRENGTH   = 255
local CHUNK_SIZE = 1500

local filesystem = require("filesystem")
local modem      = require("component").modem

local args = { ... }
if (not args or not args[1]) then
    print("+++ Missing destination host!")
    os.exit(1)
end

local hostName = args[1]
local hostFileName = "/home/hosts/" .. hostName
if (not filesystem.exists(hostFileName)) then
    print(string.format("+++ No such host in /home/hosts: \"%s\"", hostName))
    os.exit(2)
end
local hostFile, reason = io.open(hostFileName)
if (not hostFile) then
    print(string.format("+++ Couldn't open %s: %s", hostFileName, reason))
    os.exit(3)
end
local hostAddr = hostFile:read()
print(string.format("Host address for '%s': %s .", hostName, hostAddr))
hostFile:close()

if (not args[2]) then
    print("+++ Missing file name!")
    os.exit(4)
end

local fileName = args[2]
if (string.sub(fileName,1,1) ~= "/") then
    local pwd = os.getenv("PWD")
    if (pwd) then
        fileName = pwd .. "/" .. fileName
    end
end

if (not filesystem.exists(fileName)) then
    print(string.format("+++ No such file: \"%s\"", fileName))
    os.exit(5)
end

if (filesystem.isDirectory(fileName)) then
    print(string.format("+++ \"%s\" is a directory!", fileName))
    os.exit(6)
end
    
local fileSize = filesystem.size(fileName)
print(string.format("File \"%s\" size: %d bytes.", fileName, fileSize))

print(string.format("Chunk size: %d bytes.", CHUNK_SIZE))

local file = filesystem.open(fileName, "rb")
local offset, sizeRemain = 0, fileSize
while (sizeRemain > 0) do
    local sizeToRead = math.min(sizeRemain, CHUNK_SIZE)
    local data = file:read(sizeToRead)
    print(string.format("Read %d bytes.", #data))
    if (#data < sizeToRead) then
        print(string.format("Expected to read %d bytes!", sizeToRead))
        os.exit(7)
    end
    local header = string.format("STOR %d %d %s\n", offset, sizeToRead, fileName)
    modem.send(hostAddr, SLAVE_PORT, header .. data)
    sizeRemain = sizeRemain - sizeToRead
    offset = offset + sizeToRead
end
file:close()
