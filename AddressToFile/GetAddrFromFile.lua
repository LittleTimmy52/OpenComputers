local filesystem = require("filesystem")

local arg = {...}

-- does the address file exist
if arg[1] == "-h" or arg[1] == "help" or arg[1] == nil then
	print("Usage: getAddrFromFile <option: address path> <option: component name> <option: insert path>")
	os.exit()
elseif filesystem.exists(arg[1]) then
	-- open file and save it's data then close it
	file = io.open(arg[1], "r")
	addrTable = serialization.unserialize(file:read("*a"))
	file:close()
else
	print("ERROR: This is an invalid path.")
	os.exit()
end

-- find the component and store its address
for k,v in pairs(addrTable) do
	if string.find(v, arg[2]) then
		compAddr = v .. " " .. k
	end
end

-- if the address is found
if compAddr then
	-- does the file to insert to exist
	if filesystem.exists(arg[3]) then
		-- open the file to insert into and copy its data and combine with new data
		file = io.open(arg[3], "r")
		data = compAddr .. "\n" .. file:read("*a")
		file:close()
		file = io.open(arg[3], "w")
		file:write(data)
		file:close()
	else
		print("ERROR: This is an invalid path.")
		os.exit()
	end
else
	print("ERROR: The component specified wasn't found")
	os.exit()
end