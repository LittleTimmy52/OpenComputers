local event = require("event")
local fs = require("filesystem")
local serialization = require("serialization")
local modem = require("component").modem

local arg = {...}

local port = 808
local doors = {"door1"}

modem.open(port)

local function loadValues()
	-- If cfg exists then load values
	if fs.exists("/.door.cfg") then
		local file = io.open("/.door.cfg", "r")
		local fileContent = {}
		for line in file:lines() do
			table.insert(fileContent, line)
		end

		file:close()

		port = tonumber(string.sub(fileContent[1], 8))
		doors = serialization.unserialize(string.sub(fileContent[2], 9))
	end
end

local function openClose(oC, door)
	-- does the door exist?
	local function inTable(tab, element)
		for _, v in pairs(tab) do
			if v == element then
				return true
			end
		end 

		return false
	end

	if not inTable(doors, door) then
		print("Not a valid door")
		os.exit()
	end

	if oC then
		modem.broadcast(port, door .. " open")
	else
		modem.broadcast(port, door .. " close")
	end
end

local function config()
	-- make cfg if its nonexistant
	if not fs.exists("/.door.cfg") then
		print("Config file does not exist, making one now")
		local file = io.open("/.door.cfg", "w")
		file:write("port = 808\ndoors = {" .. '"' .. "door1" .. '"' .. "}")
		file:close()
	else
		-- options
		print("What would you like to change?")
		print("1: port\n2: doors\n3: view")
		local ans = io.read()
		if ans == "port" or ans == "1" then
			local file = io.open("/.door.cfg", "r")
			local fileContent = {}
			for line in file:lines() do
				table.insert(fileContent, line)
			end

			file:close()

			print("The old " .. fileContent[1])
			print("New port? (123, 808, 321, etc)")
			local ans2 = io.read()
			if ans2 then
				file = io.open("/.door.cfg", "w")
				file:write("port = " .. ans2 .. "\n" .. fileContent[2])
				file:close()
				print("New port is " .. ans2)
			else
				print("Port needed")
				os.exit()
			end
		elseif ans == "doors" or ans == "2" then
			print("Please type out the table in the following format: doors = {\"door1\", \"door2\"} and the doors must be called door followed by a number")
			print("Note if you call the door some other name please make sure this is taken into account for in the microcontrollers code")
			print("Current doors:")

			-- list current table
			local file = io.open("/.door.cfg", "r")
			local fileContent = {}
			for line in file:lines() do
				table.insert(fileContent, line)
			end

			file:close()

			print(serialization.serialize(fileContent[2]))
			local ans2 = io.read()
			-- if the answer is not nil write
			if ans2 then
				file = io.open("/.door.cfg", "w")
				file:write(fileContent[1] .. "\n" .. ans2)
				file:close()
				print("Doors saved as: " .. ans2)
			else
				print("Doors needed")
			end
		elseif ans == "view" or ans == "3" then
			-- list cfg
			local file = io.open("/.door.cfg", "r")
			for line in file:lines() do
				print(line)
			end
			
			file:close()
		else
			print("Invalid Option")
			os.exit()
		end
	end

	loadValues()
end

loadValues()

-- selection
if arg[1] == "open" and arg[2] ~= nil then
	openClose(true, arg[2])
elseif arg[1] == "close" and arg[2] ~= nil then
	openClose(false, arg[2])
elseif arg[1] == "list" then
	for _, v in pairs(doors) do
		print(v)
	end
elseif arg[1] == "config" then
	config()
elseif arg[1] == "setupInfo" then
	print("Microcontroller: T1 redstone card, T1 wireless network card, T1 ram, T1 CPU, and sign upgrade. Note this is the bare minimum, use whatever tier you like.")
	print("Tablet (recomended) or computer: T1 wireless network card, T1 ram, T1 CPU. Note this is the bare minimum, use whatever tier you like.")
	print("Microcontroller setup: Flash DoorControl to the EEPROM and insert it into the microcontroller. the signal comes from the back and a sign needs to be placed on the front which says the port on top and the door name on the next line example is 808 followed by door1.")
	print("Tablet or computer setup: Run Door config to generate the default config file then run it again to edit it.")
else
	print("Usage: Door <option: open, close, list, config, setupInfo> <option: door>")
	os.exit()
end