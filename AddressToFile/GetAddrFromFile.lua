local serialization = require("serialization")
local filesystem = require("filesystem")

local arg = {...}

-- does the address file exist
if filesystem.exists(tostring(arg[1])) then
	-- open file and save it's data then close it
	file = io.open(tostring(arg[1]))
	local addrTable = serialization.unserialize(file:read(100000))
	file:close()
elseif tostring(arg[1]) == "-h" then
	print("Usage: getAddrFromFile <pathOfAddressFile> <componentName> <pathOfFileToInsertIn>")
else
	print("ERROR: This is an invalid path.")
end

-- find the component and store its address
for v,k in ipairs(addrTable) do
	if string.find(tostring(k), arg[2]) then
		local compAddr = tostring(k)
	end
end

-- if the address is found
if compAddr then
	-- does the file to onsert to exist
	if filesystem.exists(tostring(arg[3]))
		-- open the file to insert into
		file = io.open(tostring(arg[3]), "w")
		data = compAddr .. "\n" .. file:read(100000)
	else
		print("ERROR: This is an invalid path.")	
	end
else
	print("ERROR: The component specified wasn't found")
end