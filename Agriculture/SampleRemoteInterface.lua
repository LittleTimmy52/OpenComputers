local component = require("component")
local modem = component.modem
local event = require("event")
local term = require("term")
local serialization = require("serialization")
local gpu = component.gpu
local data = nil

local stop = false
local width, height = gpu.getResolution()

local port = 1234
local useData = true
local password = "SecurePresharedPassword"

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
	return data.decrypt(decoded.encrypted, key, decoded.iv)
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

local function sendOption(address)
	local option
	repeat
		option = tonumber(io.read())
	until option ~= nil

	if useData then
		modem.send(address, port, encr(option))
	else
		modem.send(address, port, "option-" .. option)
	end
end

local function messageHandler(_, _, from, _, _, message)
	if useData then message = decr(message) end
	if message:sub(1, 6) == "names-" then
		fittedPrint(serialization.unserialize(message:sub(7)))
	elseif message:sub(1, 6) == "items-" then
		fittedPrint(serialization.unserialize(message:sub(7)))
	elseif message:sub(1, 8) == "signals-" then
		fittedPrint(serialization.unserialize(message:sub(9)))
	elseif message:sub(1, 7) == "status-" then
		fittedPrint(serialization.unserialize(message:sub(8)))
	elseif message:sub(1, 7) == "limits-" then
		fittedPrint(serialization.unserialize(message:sub(8)))
	elseif message:sub(1, 10) == "addresses-" then
		fittedPrint(serialization.unserialize(message:sub(11)))
	elseif message:sub(1, 6) == "error-" or message:sub(1, 6) == "Please" or message:sub(1, 4) == "Only" then
		term.clear()
		print(message)

		if message:sub(1, 6) == "Please" then
			sendOption(from)
		end
	end
end

modem.open(port)

event.listen("modem_message", messageHandler)

while not stop do
	term.clear()
	print("Main Menu:")
	print("[1] Get information")
	print("[2] Manual toggle")
	print("[3] Manual reset")
	print("[4] Manual update")
	print("[5] Toggle updates")
	print("[6] Exit program")

	local choice
	repeat
		term.clear()
		print("Main Menu:")
		print("[1] Get information")
		print("[2] Manual toggle")
		print("[3] Manual reset")
		print("[4] Manual update")
		print("[5] Toggle updates")
		print("[6] Exit program")
		choice = tonumber(io.read())
	until choice ~= nil and choice > 0 and choice < 7

	if choice == 1 then
		choice = nil
		repeat
			term.clear()
			print("Information:")
			print("[1] Microcontroller names")
			print("[2] Items controlled")
			print("[3] Signal assignments")
			print("[4] Status")
			print("[5] Limits")
			print("[6] Addresses")
			print("[7] Main menu")
			choice = tonumber(io.read())
		until choice ~= nil and choice > 0 and choice < 8

		if choice ~= 7 then
			if useData then
				modem.broadcast(port, encr("getInfo-" .. choice))
			else
				modem.broadcast(port, "getInfo-" .. choice)
			end
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
			
		if useData then
			modem.broadcast(port, encr("manToggle-" .. name .. "-" .. signal))
		else
			modem.broadcast(port, "manToggle-" .. name .. "-" .. signal)
		end

	elseif choice == 3 then
		if useData then
			modem.broadcast(port, encr("manReset"))
		else
			modem.broadcast(port, "manReset")
		end
	elseif choice == 4 then
		if useData then
			modem.broadcast(port, encr("manUpdate"))
		else
			modem.broadcast(port, "manUpdate")
		end
	elseif choice == 5 then
		if useData then
			modem.broadcast(port, encr("checkToggle"))
		else
			modem.broadcast(port, "checkToggle")
		end
	elseif choice == 6 then
		term.clear()
		stop = true
		event.ignore("modem_message", messageHandler)
	end

	os.sleep(0)
end