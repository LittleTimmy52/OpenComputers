local component = require("component")
local serialization = require("serialization")
local event = require("event")
local tunnel = component.tunnel

-- set to addr of any nearby relays wireless networkcard to avoid send loop
local relayAddr = "addr"

-- set reue if using above
local useAbove = true

local function main()
	-- gather nessicairy data
	local _, _, from, port, _, data = event.pull("modem_message")
	evtDat = {}

	if useAbove == true then
		if from == relayAddr then return end
	end

	-- check if it's a wireless network message
	if port ~= 0 then
		-- add data to the table
		table.insert(evtDat, port)
		table.insert(evtDat, data)

		-- serialize and send over the linked card
		local serEvt = serialization.serialize(evtDat)
		tunnel.send(serEvt)
	end
end

while true do
main()
end