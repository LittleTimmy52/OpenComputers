local component = require("component")
local modem = component.modem
local event = require("event")
local term = require("term")
local serialization = require("serialization")
local gpu = component.gpu
local data = nil

local timerID
local recieved = false
local stop = false
local width, height = gpu.getResolution()

local port = 2025
local timeOut = 10
local iterationLimit = 15
local useData = true
local password = "SecurePresharedPassword"
local port2 = 1234
local controllerAddress = "network card address here"

-- load conf
local conf = io.open("/etc/AggriculturalController/AggriculturalControllerInterface.cfg", "r")
if conf then
	for line in conf:lines() do
		local k, v = line:match("^(%w+)%s*=%s*(%S+)$")
		if k == "port" then
			port = tonumber(v)
		elseif k == "timeOut" then
			timeOut = tonumber(v)
		elseif k == "iterationLimit" then
			iterationLimit = tonumber(v)
		elseif k == "useData" then
			useData = (v == "true")
		elseif k == "password" then
			password = v
		elseif k == "port2" then
			port2 = tonumber(v)
		elseif k == "controllerAddress" then
			controllerAddress = v
		end
	end

	conf:close()
else
	require("filesystem").makeDirectory("/etc/AggriculturalController/")
	conf = io.open("/etc/AggriculturalController/AggriculturalControllerInterface.cfg", "w")
	conf:write("port=2025\ntimeOut=10\niterationLimit=15\nuseData=true\npassword=SecurePresharedPassword\nport2=1234")
	conf:close()
end

if useData then
	data = component.data
end

local function encr(decryptedData, password)
	local key = data.md5(password)
	local iv = data.random(16)
	local encryptedData = data.encrypt(decryptedData, key, iv)
	return serialization.serialize({encrypted = encryptedData, iv = iv})
end

local function decr(encryptedData, password)
	local key = data.md5(password)
	local decoded = serialization.unserialize(encryptedData)
	return serialization.unserialize(data.decrypt(decoded.encrypted, key, decoded.iv))
end

local function out(data, address)
	if address ~= nil then
		if useData then
			modem.send(address, port2, encr(data))
		else
			modem.send(address, port2, data)
		end
	else
		print(data)
	end
end

local function getInfo(address, option)

end

local function manToggle(address, name, signal)
	recieved = false

	timerID = event.timer(timeOut, function()
		modem.broadcast(port, "toggle-" .. name .. "-" .. tostring(signal))
	end, iterationLimit)

	if not recieved then
		out("Could not reach the controller server (timed out, limit reached)", address)
		os.sleep(5)
	end
end

local function manUpdate(address)
	recieved = false

	timerID = event.timer(timeOut, function()
		modem.broadcast(port, "update")
	end, iterationLimit)
	
	if not recieved then
		out("Could not reach the controller server (timed out, limit reached)", address)
		os.sleep(5)
	end
end

local function manReset(address)
	recieved = false

	timerID = event.timer(timeOut, function()
		modem.broadcast(port, "reset")
	end, iterationLimit)
	
	if not recieved then
		out("Could not reach the controller server (timed out, limit reached)", address)
		os.sleep(5)
	end
end

local function messageHandler(_, _, from, portFrom, _, message)
	if portFrom == port then
		if message == "executed" then
			event.cancel(timerID)
			recieved = true
		elseif message == "info" then

		elseif message:sub(1, 5) == "info-" then

		elseif message:sub(1, 5) == "done-" then
			
		end
	elseif portFrom == port2 then		
		if message:sub(1, 7) == "getInfo" then
			getInfo(from, message:sub(9))
		elseif message:sub(1, 9) == "manToggle" then
			local parts = {}
			for part in string.gmatch(message, "([^-]+)") do
				table.insert(parts, part)
			end

			manToggle(from, parts[2], parts[3])
		elseif message == "manUpdate" then
			manUpdate(from)
		elseif message == "manReset" then
			manReset(from)
		elseif message == "role" then
			modem.broadcast(port, "role")
		end
	end
end

local function exit()
	event.ignore("modem_message", messageHandler)
	stop = true
end

local function UI()
	local mainMenu = {
		"Main Menu:",
		"[1] Get information",
		"[2] Manual toggle",
		"[3] Manual reset",
		"[4] Manual update",
		"[5] Help",
		"[6] Exit program"
	}

	local dataMenu = {
		"Information:",
		"[1] Update stored data",
		"[2] Microcontroller names",
		"[3] Items controlled",
		"[4] Signal assignments",
		"[5] Status",
		"[6] Limits",
		"[7] Addresses",
		"[8] Main menu"
	}

	local helpMenu = {
		"Help:",
		"This is the interface for \"AggriculturalController,\" this program just tells the controller what to do because the controller is fully automated and can only be interacted this way over the network.",
		"Main Menu:",
		"[1] Get information",
		"Takes you to a sub menu to find out specific information the controller has at its disposal.",
		"Note: This aids in \"[2] Manual toggle\" because you need the microcontroller name and the signal you wish to toggle.",
		"[2] Manual toggle",
		"This asks you for which microcontroller, by name (see: \"[1] Get infoormation\" to find that out), that the specific item you wish to toggle is attached to, and the signal assigned to said item to then tell the controller to toggle it.",
		"[3] Manual reset",
		"This tells the controller to physically reset all redstone decoder flip flops.",
		"[4] Manual update",
		"This tells the controller to run its update scan.",
		"Note: The controller automatically runs its update scan, but this is here if you want to run it for your self.",
		"[5] Help",
		"Shows this very insightful menu.",
		"[6] Exit program",
		"Need I explain this one? Well if its not objious it closes the program.",
		"Information:",
		"[1] Update stored data",
		"The information from the server is only updated when this is called or if its nil when selecting one fo the other options. Therefore you MUST select this option for more accurate information.",
		"Note: This is dont this way because caching the information will cut the time for subsequent lookups down significantly.",
		"[2] Microcontroller names",
		"This lists the names of all microcontrollers the controller controls.",
		"Note: \"[2] Manual toggle\" on the main menu needs this along with the signal for the desired item (see \"[4] Signal assignments\").",
		"[3] Items controlled",
		"This lists the item names in standard mod:item format the controller monitors per a specified microcontroller.",
		"[4] Signal assignments",
		"This lists the various signals that are assigned per a specified microcontroller.",
		"Note: \"[2] Manual toggle\" on the main menu needs this along with the name for the desired item (see \"[2] Microcontroller names\").",
		"[5] Status",
		"This lists the status of the various monitered items per a specific microcontroller.",
		"[6] Limits",
		"This lists the various limits of the various items per a specific microcontroller.",
		"[7] Addresses",
		"This lists the various addresses of the microcontrollers network cards.",
		"[8] Main menu",
		"Need I explain this? well, it takes you back to the main menu.",
		"Special note in regards to the information pages:",
		"For options 3-6, an index wil be displayed next to the values, this is for tracking the information as a set. Essentially say there is an item being tracked, minecraft:potato for instance, its the first item so its index is 1, in the other pages, anything with and index of 1 belongs to minecraft:potato, thus you can line up information."
	}

	local function printMenu(menu)
		term.clear()
		for i = 1, #menu do
			print(menu[1])
		end
	end

	local function fittedPrint(tableToPrint, addIndex)
		term.clear()
		local lines = 0

		for k, v in ipairs(tableToPrint) do
			if addIndex then
				v = k .. ": " .. v
			end

			local linesNeeded = math.ceil(#v / width)
			local linesLeft = height - lines - 2 -- Reserve 2 lines for "Press any key"

			if linesNeeded > linesLeft then
				print("\nPress any key to continue")
				while true do
					local _, _, _, pn = event.pull("key_down")
					if pn then break end
					os.sleep(0)
				end
				term.clear()
				lines = 0
			end

			print(v)
			lines = lines + linesNeeded
		end

		print("\nPress any key to return to the menu...")
		while true do
			local _, _, _, pn = event.pull("key_down")
			if pn then break end
			
			os.sleep(0)
		end
	end
end

event.listen("modem_message", messageHandler)

while not stop do
	pcall(UI)
	os.sleep(0)
end