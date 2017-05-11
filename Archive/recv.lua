local component=require("component")
local event=require("event")
local modem=component.modem
modem.open(123)
local evt, _, rem, por, dis, msg = event.pull("modem_message")
print(tostring(msg))
