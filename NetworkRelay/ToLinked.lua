local component = require("component")
local event = require("event")
local tunnel = component.tunnel

-- set to addr of any nearby relays wireless networkcard to avoid send loop
local relayAddr = "addr"

-- set reue if using above
local useAbove = true

-- print data
local printMsg = true

local function main()
	-- gather nessicairy data
	local _, _, from, port, _, data = event.pull("modem_message")
	evtDat = {}

	if useAbove == true then
		if from == relayAddr then return end
	end

	-- open the port on all modems
	for addr, t in component.list("modem") do
		component.invoke(addr, "open", 123)
	end

	-- check if it's a wireless network message
	if port ~= 0 then
		-- add data to the table
		table.insert(evtDat, port)
		table.insert(evtDat, data)
		
		if printMsg == true then
			print("event data:")
			for k,v in pairs(unserEvt) do
				print(tostring(k)..": "..tostring(v))
			end
		end

		-- serialize and send over the linked card
		local serEvt = serialization.serialize(evtDat)

		if printMsg == true then
			print("serialized data: " .. serEvt)
		end

		tunnel.send(serEvt)
	end
end

while true do
	main()
end