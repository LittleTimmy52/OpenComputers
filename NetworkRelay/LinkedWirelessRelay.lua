local component = require("component")
local event = require("event")
local tunnel = component.tunnel
local modem = component.modem


-- config
local ignoreAddr = {} -- set to the wireless network card of any computer to ignore
local ports = {300, 280, 250, 245} -- set to a port for relaying
local printMsg = true -- print data

local function main()
	-- open the port on all modems
	for addr, t in component.list("modem") do
		for k,v in ipairs(ports) do
			component.invoke(addr, "open", v)
		end
	end

	-- gather nessicairy data
	local _, _, from, port, _, data = event.pull("modem_message")
	evtDat = {}

	-- ignore any messages from ports to ignore
	if ignoreAddr then
		for k,v in ipairs(ignoreAddr) do
			if from == v then return end
		end
	end

	-- check if it's a wireless network message
	if port ~= 0 then
		-- add data to the table
		table.insert(evtDat, port)
		table.insert(evtDat, data)
		
		if printMsg then
			print("event data:")
			for k,v in pairs(unserEvt) do
				print(tostring(k)..": "..tostring(v))
			end
		end

		-- serialize and send over the linked card
		local serEvt = serialization.serialize(evtDat)

		if printMsg then
			print("serialized data: " .. serEvt)
		end

		tunnel.send(serEvt)
	else
		if printMsg then
			print("port: " .. port .. " data: " .. data)
		end

		-- unserialize and broadcast
		modem.open(unserEvt[1])
		unserEvt = serialization.unserialize(data)

		if printMsg == true then
			print("is port " .. unserEvt[1] .. " open? " .. tostring(modem.isOpen(unserEvt[1])))
			print("unserialized table:")
			for k,v in ipairs(unserEvt) do
				print(tostring(k)..": "..tostring(v))
			end
		end

		modem.broadcast(unserEvt[1], unserEvt[2])
	end
end

while true do
	main()
end