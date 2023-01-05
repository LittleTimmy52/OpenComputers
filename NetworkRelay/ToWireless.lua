local component = require("component")
local serialization = require("serialization")
local event = require("event")
local modem = component.modem

while true do
	local evt = {event.pull("modem_message")}
	if evt[1] ~= 
	local unserEvt = serialization.unserialize(evt[6])
	if unserEvt[4]
	modem.broadcast(unserEvt[4], unserEvt[6])
end