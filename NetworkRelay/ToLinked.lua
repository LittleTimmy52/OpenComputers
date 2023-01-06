local component = require("component")
local serialization = require("serialization")
local event = require("event")
local tunnel = component.tunnel

while true do
	-- gather nessicairy data
	local _, _, _, port, _, data = event.pull("modem_message")
	local evtDat = {}

	-- check if it's a wireless network message
	if port ~= 0 then
	-- add data to the table
		table.insert(evtDat, port)
		table.insert(evtDat, data)

		-- serialize and send over the linked card
		local serEvt = serialization.serialize(serEvt)
		tunnel.send(serEvt)
	end
end