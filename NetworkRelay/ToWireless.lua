local component = require("component")
local serialization = require("serialization")
local event = require("event")
local modem = component.modem

-- print data
local printMsg = true

local function main()
	-- open the port on all modems
	for addr, t in component.list("modem") do
		component.invoke(addr, "open", 123)
	end

	-- gather nessicairy data
	local _, _, _, port, _, data = event.pull("modem_message")
	if port = 0 then
		if printMsg == true then
			print("port: " .. port .. " data: " .. data)
		end

		-- unserialize and broadcast
		modem.open(unserEvt[1])
		unserEvt = serialization.unserialize(data)

		if printMsg == true then
			print("is port " .. unserEvt[1] .. " open? " .. modem.isOpen(unserEvt[1]))
			print("unserialized table: " .. tprint(unserEvt))
		end

		modem.broadcast(unserEvt[1], unserEvt[2])
	end
end

while true do
main()
end