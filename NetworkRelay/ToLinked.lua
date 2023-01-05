local component = require("component")
local serialization = require("serialization")
local event = require("event")
local tunnel = component.tunnel

while true do
	local evt = {event.pull("modem_message")}
	local serEvt = serialization.serialize(evt)
	tunnel.send(serEvt)
end