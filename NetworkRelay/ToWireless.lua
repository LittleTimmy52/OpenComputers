local component = require("component")
local serialization = require("serialization")
local event = require("event")
local modem = component.modem

while true do
	local _, _, _, port, _, data = event.pull("modem_message")
	if port = 0 then
		unserEvt = serialization.unserialize(data)
		modem.broadcast(unserEvt[1], unserEvt[2])
	end
end