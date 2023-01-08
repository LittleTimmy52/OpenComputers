local serialization = require("serialization")
local filesystem = require("filesystem")

local arg = {...}

-- does the address file exist
if filesystem.exists(tostring(arg[1])) then
	-- open file and save it's data then close it
	file = io.open(tostring(arg[1]))
	addrTable = serialization.unserialize(file:read("*a"))
	file:close()
elseif tostring(arg[1]) == "-h" then
	print("Usage: getAddrFromFile <pathOfAddressFile> <componentName> <pathOfFileToInsertIn>")
else
	print("ERROR: This is an invalid path.")
end

-- find the component and store its address
for k,v in pairs(addrTable) do
	if string.find(tostring(v), tostring(arg[2])) then
		compAddr = tostring(v) .. " " .. tostring(k)
	end
end

-- if the address is found
if compAddr then
	-- does the file to onsert to exist
	if filesystem.exists(tostring(arg[3])) then
		-- open the file to insert into and copy its data and combine with new data
		file = io.open(tostring(arg[3]), "r")
		data = compAddr .. "\n" .. file:read("*a")
		file:close()
		file = io.open(tostring(arg[3]), "w")
		file:write(data)
		file:close()
	else
		print("ERROR: This is an invalid path.")
	end
else
	print("ERROR: The component specified wasn't found")
end