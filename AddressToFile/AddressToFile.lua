local component = require("component")
local serialization = require("serialization")
local filesystem = require("filesystem")

local arg = ...

if tostring(arg) == "-h" then
	print("addressToFile <pathToSave>")
else
	-- store all component addresses
	local compAddrs = component.list()
	local serCompAddrs = serialization.serialize(compAddrs)

	-- writes the addresses to a file
	file = io.open(tostring(arg), "w")
	file:write(serCompAddrs)
	file:close()
end