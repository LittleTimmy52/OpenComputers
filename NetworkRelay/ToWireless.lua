local component = require("component")
local event = require("event")
local modem = component.modem

-- print data
local printMsg = true

local function main()
	-- gather nessicairy data
	local _, _, _, port, _, data = event.pull("modem_message")
	if port == 0 then
		if printMsg == true then
			print("port: " .. port .. " data: " .. data)
		end

		-- unserialize and broadcast
		modem.open(unserEvt[1])
		unserEvt = serialization.unserialize(data)

		if printMsg == true then
			print("is port " .. unserEvt[1] .. " open? " .. modem.isOpen(unserEvt[1]))
			print("unserialized table:")
			for k,v in pairs(unserEvt) do
				print(tostring(k)..": "..tostring(v))
			end
		end

		modem.broadcast(unserEvt[1], unserEvt[2])
	end
end

while true do
	main()
end