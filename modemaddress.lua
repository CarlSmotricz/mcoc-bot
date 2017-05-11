-- modemaddress.lua
--
-- Prints the device's modem address.

local modem=require("component").modem
print(modem.address)