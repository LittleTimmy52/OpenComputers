local component = require("component")
local serialization = require("serialization")
local event = require("event")
local modem = component.modem

local function main()
	-- gather nessicairy data
	local _, _, _, port, _, data = event.pull("modem_message")
	if port = 0 then
		-- unserialize and broadcast
		modem.open(unserEvt[1])
		unserEvt == serialization.unserialize(data)
		modem.broadcast(unserEvt[1], unserEvt[2])
	end
end

while true do
main()
end