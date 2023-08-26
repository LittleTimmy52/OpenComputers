local component = require("component")
local serialization = require("serialization")

local arg = ...

if arg == "-h" or arg == "help" or arg == nil then
	print("addressToFile <option: path>")
	os.exit()
else
	-- store all component addresses
	local compAddrs = component.list()
	local serCompAddrs = serialization.serialize(compAddrs)

	-- writes the addresses to a file
	file = io.open(arg, "w")
	file:write(serCompAddrs)
	file:close()
end
