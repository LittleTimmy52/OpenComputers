local component = require("component")
local modem = component.modem
local event = require("event")
local term = require("term")
local serialization = require("serialization")
local gpu = component.gpu
local data = nil

local recieved = false
local temp = ""
local stop = false
local width, height = gpu.getResolution()
local calledFromRemote = false
local tmpAddr

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

local function encr(decryptedData)
	local key = data.md5(password)
	local iv = data.random(16)
	local encryptedData = data.encrypt(decryptedData, key, iv)
	return serialization.serialize({encrypted = encryptedData, iv = iv})
end

local function decr(encryptedData)
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

local function fittedPrint(tableToPrint, noIndex)
	term.clear()
	local lines = 0

	for k, v in ipairs(tableToPrint) do
		if noIndex == false or noIndex == nil then
			v = tostring(k) .. ": " .. v
		end

		while #v > width do
			local chunk = v:sub(1, width)  -- take the first 'width' characters
			v = v:sub(width + 1)           -- remove the printed part
			print(chunk)
			lines = lines + 1

			if lines >= height - 2 then  -- reserve 2 lines for the "Press any key"
				print("\nPress any key to continue...")
				event.pull("key_down")
				term.clear()
				lines = 0
			end
		end

		print(v)
		lines = lines + 1

		if lines >= height - 2 then
			print("\nPress any key to continue...")
			event.pull("key_down")
			term.clear()
			lines = 0
		end
	end

	print("\nPress any key to return to the menu...")
	event.pull("key_down")
end

local function getInfo(option, address)
	if option == 1 then
		if address == nil then print("Please wait, getting names...") end

		local iteration = 0
		temp = ""

		repeat
			iteration = iteration + 1
			modem.send(controllerAddress, port, "getInfo-1")
			os.sleep(timeOut)
		until temp:sub(1, 6) == "names-" or iteration > iterationLimit

		if temp:sub(1, 6) == "names-" then
			if address == nil then 
				fittedPrint(serialization.unserialize(temp:sub(7)))
			else
				if useData then
					modem.send(address, port2, encr(temp:sub(7)))
				else
					modem.send(address, port2, temp:sub(7))
				end
			end
		else
			out("Could not reach the controller server (timed out, limit reached)", address)
			os.sleep(5)
		end
	elseif option == 2 then
		out("Please enter the index of the microcontroller.", address)
		local tableIndex
		if address == nil then
			repeat
				tableIndex = tonumber(io.read())
			until tableIndex ~= nil and tableIndex > 0

			term.clear()
		else
			local iteration = 0
			temp = ""
			repeat
				os.sleep(timeOut)
			until tonumber(temp) ~= nil or iteration > iterationLimit
	
			if tonumber(temp) ~= nil then
				tableIndex = tonumber(temp)
			end
		end

		if tableIndex ~= nil then
			if address == nil then print("Please wait getting info...") end

			local iteration = 0
			temp = ""

			repeat
				iteration = iteration + 1
				modem.send(controllerAddress, port, "getInfo-2-" .. tableIndex)
				os.sleep(timeOut)
			until temp:sub(1, 6) == "items-" or iteration > iterationLimit

			if temp:sub(1, 6) == "items-" then
				if address == nil then 
					fittedPrint(serialization.unserialize(temp:sub(7)))
				else
					if useData then
						modem.send(address, port2, encr(temp:sub(7)))
					else
						modem.send(address, port2, temp:sub(7))
					end
				end
			else
				out("Could not reach the controller server (timed out, limit reached)", address)
				os.sleep(5)
			end
		end
	elseif option == 3 then
		out("Please enter the index of the microcontroller.", address)
		local tableIndex
		if address == nil then
			repeat
				tableIndex = tonumber(io.read())
			until tableIndex ~= nil and tableIndex > 0

			term.clear()
		else
			local iteration = 0
			temp = ""
			repeat
				os.sleep(timeOut)
			until tonumber(temp) ~= nil or iteration > iterationLimit
	
			if tonumber(temp) ~= nil then
				tableIndex = tonumber(temp)
			end
		end

		if tableIndex ~= nil then
			if address == nil then print("Please wait getting info...") end

			local iteration = 0
			temp = ""

			repeat
				iteration = iteration + 1
				modem.send(controllerAddress, port, "getInfo-3-" .. tableIndex)
				os.sleep(timeOut)
			until temp:sub(1, 8) == "signals-" or iteration > iterationLimit

			if temp:sub(1, 8) == "signals-" then
				if address == nil then 
					fittedPrint(serialization.unserialize(temp:sub(9)))
				else
					if useData then
						modem.send(address, port2, encr(temp:sub(9)))
					else
						modem.send(address, port2, temp:sub(9))
					end
				end
			else
				out("Could not reach the controller server (timed out, limit reached)", address)
				os.sleep(5)
			end
		end
	elseif option == 4 then
		out("Please enter the index of the microcontroller.", address)
		local tableIndex
		if address == nil then
			repeat
				tableIndex = tonumber(io.read())
			until tableIndex ~= nil and tableIndex > 0

			term.clear()
		else
			local iteration = 0
			temp = ""
			repeat
				os.sleep(timeOut)
			until tonumber(temp) ~= nil or iteration > iterationLimit
	
			if tonumber(temp) ~= nil then
				tableIndex = tonumber(temp)
			end
		end

		if tableIndex ~= nil then
			if address == nil then print("Please wait getting info...") end

			local iteration = 0
			temp = ""

			repeat
				iteration = iteration + 1
				modem.send(controllerAddress, port, "getInfo-4-" .. tableIndex)
				os.sleep(timeOut)
			until temp:sub(1, 7) == "status-" or iteration > iterationLimit

			if temp:sub(1, 7) == "status-" then
				if address == nil then 
					fittedPrint(serialization.unserialize(temp:sub(8)))
				else
					if useData then
						modem.send(address, port2, encr(temp:sub(8)))
					else
						modem.send(address, port2, temp:sub(8))
					end
				end
			else
				out("Could not reach the controller server (timed out, limit reached)", address)
				os.sleep(5)
			end
		end
	elseif option == 5 then
		out("Please enter the index of the microcontroller.", address)
		local tableIndex
		if address == nil then
			repeat
				tableIndex = tonumber(io.read())
			until tableIndex ~= nil and tableIndex > 0

			term.clear()
		else
			local iteration = 0
			temp = ""
			repeat
				os.sleep(timeOut)
			until tonumber(temp) ~= nil or iteration > iterationLimit
	
			if tonumber(temp) ~= nil then
				tableIndex = tonumber(temp)
			end
		end

		if tableIndex ~= nil then
			if address == nil then print("Please wait getting info...") end

			local iteration = 0
			temp = ""

			repeat
				iteration = iteration + 1
				modem.send(controllerAddress, port, "getInfo-5-" .. tableIndex)
				os.sleep(timeOut)
			until temp:sub(1, 7) == "limits-" or iteration > iterationLimit

			if temp:sub(1, 7) == "limits-" then
				if address == nil then 
					fittedPrint(serialization.unserialize(temp:sub(8)))
				else
					if useData then
						modem.send(address, port2, encr(temp:sub(8)))
					else
						modem.send(address, port2, temp:sub(8))
					end
				end
			else
				out("Could not reach the controller server (timed out, limit reached)", address)
				os.sleep(5)
			end
		end
	elseif option == 6 then
		if address == nil then print("Please wait, getting addresses...") end

		local iteration = 0
		temp = ""

		repeat
			iteration = iteration + 1
			modem.send(controllerAddress, port, "getInfo-6")
			os.sleep(timeOut)
		until temp:sub(1, 10) == "addresses-" or iteration > iterationLimit

		if temp:sub(1, 10) == "addresses-" then
			if address == nil then 
				fittedPrint(serialization.unserialize(temp:sub(11)))
			else
				if useData then
					modem.send(address, port2, encr(temp:sub(11)))
				else
					modem.send(address, port2, temp:sub(11))
				end
			end
		else
			out("Could not reach the controller server (timed out, limit reached)", address)
			os.sleep(5)
		end
	end	
end

local function manToggle(name, signal, address)
	if address == nil then
		term.clear()
		print("Please wait...")
	end

	local iteration = 0
	recieved = false

	repeat
		iteration = iteration + 1
		modem.send(controllerAddress, port, "toggle-" .. name .. "-" .. tostring(signal))
		if not recieved then os.sleep(timeOut) end
	until recieved or iteration > iterationLimit

	if not recieved then
		out("Could not reach the controller server (timed out, limit reached)", address)
		os.sleep(5)
	end
end

local function manUpdate(address)
	out("Only sending once, large operation", address)
	modem.send(controllerAddress, port, "update")
	os.sleep(5)
end

local function manReset(address)
	if address == nil then
		term.clear()
		print("Please wait...")
	end

	local iteration = 0
	recieved = false

	repeat
		iteration = iteration + 1
		modem.send(controllerAddress, port, "reset")
		if not recieved then os.sleep(timeOut) end
	until recieved or iteration > iterationLimit
	
	if not recieved then
		out("Could not reach the controller server (timed out, limit reached)", address)
		os.sleep(5)
	end
end

local function messageHandler(_, _, from, portFrom, _, message)
	if useData and portFrom == port2 then message = decr(message) end

	if portFrom == port then
		if message == "executed" then
			recieved = true
		elseif message ~= "rolecall" then
			temp = message
		end
	elseif portFrom == port2 then		
		if message:sub(1, 8) == "getInfo-" then
			getInfo(from, message:sub(9))
		elseif message:sub(1, 9) == "manToggle" then
			local parts = {}
			for part in string.gmatch(message, "([^-]+)") do
				table.insert(parts, part)
			end

			manToggle(parts[2], parts[3], from)
		elseif message == "manUpdate" then
			manUpdate(from)
		elseif message == "manReset" then
			manReset(from)
		elseif message:sub(1, 6) == "index-" then
			temp = message:sub(7)
		end
	end
end

local function exit()
	term.clear()
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
		"[1] Microcontroller names",
		"[2] Items controlled",
		"[3] Signal assignments",
		"[4] Status",
		"[5] Limits",
		"[6] Addresses",
		"[7] Main menu"
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
		"[1] Microcontroller names",
		"This lists the names of all microcontrollers the controller controls.",
		"Note: \"[2] Manual toggle\" on the main menu needs this along with the signal for the desired item (see \"[4] Signal assignments\").",
		"[2] Items controlled",
		"This lists the item names in standard mod:item format the controller monitors per a specified microcontroller.",
		"[3] Signal assignments",
		"This lists the various signals that are assigned per a specified microcontroller.",
		"Note: \"[2] Manual toggle\" on the main menu needs this along with the name for the desired item (see \"[2] Microcontroller names\").",
		"[4] Status",
		"This lists the status of the various monitered items per a specific microcontroller.",
		"[5] Limits",
		"This lists the various limits of the various items per a specific microcontroller.",
		"[6] Addresses",
		"This lists the various addresses of the microcontrollers network cards.",
		"[7] Main menu",
		"Need I explain this? well, it takes you back to the main menu.",
		"Special note in regards to the information pages:",
		"For all options an index wil be displayed next to the values, this is for tracking the information as a set. Essentially say there is an item being tracked, minecraft:potato for instance, its the first item so its index is 1, in the other pages, anything with and index of 1 belongs to minecraft:potato, thus you can line up information.",
		"Additionally, the index associated to the name or address is nessicairy in choosing the correct microcontroller to view in the other options, say microcontroller \"test\" was at index 1, when seeing say the limits, you specify this index to see the data for this microcontroller."
	}


	local function printMenu(menu)
		term.clear()
		for i = 1, #menu do
			print(menu[i])
		end
	end

	while not stop do
		local choice
		repeat
			term.clear()
			printMenu(mainMenu)
			choice = tonumber(io.read())
		until choice ~= nil and choice > 0 and choice < 7

		if choice == 1 then
			choice = nil
			repeat
				term.clear()
				printMenu(dataMenu)
				choice = tonumber(io.read())
			until choice ~= nil and choice > 0 and choice < 8

			if choice ~= 7 then 
				getInfo(choice, nil)
			end
		elseif choice == 2 then
			local name = nil
			local signal = nil
		
			repeat
				term.clear()
				print("Enter microcontroller name")
				name = io.read()
			until name ~= nil

			repeat
				term.clear()
				print("Enter the signal value (1-15)")
				signal = tonumber(io.read())
			until signal ~= nil and signal > 0 and signal < 16

			manToggle(name, signal, nil)
		elseif choice == 3 then
			manReset(nil)
		elseif choice == 4 then
			manUpdate(nil)
		elseif choice == 5 then
			fittedPrint(helpMenu, true)
		elseif choice == 6 then
			exit()
		end
	end
end

modem.open(port)
modem.open(port2)

event.listen("modem_message", messageHandler)

while not stop do
	pcall(UI)
	os.sleep(0)
end