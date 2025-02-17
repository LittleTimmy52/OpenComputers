local modem = require("component").modem
local redstone = require("component").redstone
local event = require("event")
local serialization = require("serialization")
local rs = require("component").block_refinedstorage_interface
local term = require("term")
local gpu = require("component").gpu

local port = 2025

local infoChart = {}	-- name:devices it controlls:signal:status:limit (string:table:table:table:table)
local recieved = false
local timeOut = 2
local iterationLimit = 15
local checkInterval = 15

local width, height = gpu.getResolution()

local function physicleReset()
	-- Output on back of computer the signal
	redstone.setOutput(2, 15)

	for _, v in ipairs(infoChart) do
		for i = 1, #v[4] do
			v[4][i] = false
		end
	end
end

local function toggle(name, signal)
	local iteration = 0
	while recieved == false and iteration < iterationLimit do
		modem.broadcast(port, name .. ":toggle:" .. signal)
		os.sleep(timeOut)
		iteration = iteration + 1
	end

	if recieved then
		for _, v in ipairs(infoChart) do
			if v[1] == name then
				local location
				for _, v in ipairs(v[3]) do
					if v == signal then
						location = v
					end
				end

				v[5][location] = not v[5][location]
			end
		end
	end

	recieved = false
end

local function checkStorage()
	for i = 1, #infoChart do
		for k, itemName in ipairs(infoChart[i][2]) do
			local stack = rs.getItem({name = itemName})
			if stack == nil or stack.size == nil then
				if infoChart[i][5][k] == false then
					toggle(infoChart[i][1], infoChart[i][3][k])
				end
			else
				if infoChart[i][4][k] > stack.size then
					if infoChart[i][5][k] == false then
						toggle(infoChart[i][1], infoChart[i][3][k])
					end
				else
					if infoChart[i][5][k] then
						toggle(infoChart[i][1], infoChart[i][3][k])
					end
				end
			end
		end
	end
end

local function messageHandler(_, _, from, _, _, message)
	if string.find(message, "rolecall:") then
		local parts = {}

		-- Split the main string by :
		for part in string.gmatch(message, "([^:]+)") do
			table.insert(parts, part)
		end

		table.remove(parts, 1)

		local name = parts[1]
		local itemDataString = parts[2]

		-- Remove curly braces and split by comma
		itemDataString = string.sub(itemDataString, 2, -2)
		local itemStrings = {}
		for itemString in string.gmatch(itemDataString, "([^,]+)") do
			table.insert(itemStrings, itemString)
		end

		local items = {}
		local signalAssignments = {}
		local limits = {}

		for _, itemString in ipairs(itemStrings) do
			local parts = {}
			for itemPart in string.gmatch(itemString, "([^:]+)") do
				table.insert(parts, itemPart)
			end

			table.insert(items, parts[1])
			table.insert(signalAssignments, tonumber(parts[2]) or parts[2])
			table.insert(limits, tonumber(parts[3]))
		end

		local status = {}
		for i = 1, #signalAssignments do
			table.insert(status, false)
		end

		table.insert(infoChart, {
			name = name,
			items = items,
			signalAssignments = signalAssignments, 
			limits = limits,
			status = status
		})
	elseif message == "Acknowlaged" then
		recieved = true
	elseif message == "Reset" then
		physicleReset()
	elseif message == "getInfo" then
		modem.send(from, port, serialization.serialize(infoChart))
	elseif string.find(message, "manualToggle:") then
		local parts = {}
		for part in string.gmatch(message, "([^:]+)") do
			table.insert(parts, part)
		end

		toggle(parts[2], parts[3])
	elseif message == "manualUpdate" then
		checkStorage()
	end
end

event.listen("modem_message", messageHandler)

modem.open(2025)

modem.broadcast(port, "rolecall")
physicleReset()

local check = coroutine.create(function() while true do checkStorage() os.sleep(checkInterval) end end)
coroutine.resume(check)

-- UI

--[[



fix the ui menu



find a way to get inoput in a nonblocking way



maybe event drivewn






the below is a incorrect and b incomplete





]]
local function mainMenu()
	term.clear()
	print("AggriculturalController")
	print("------------------------")
	print("1: View data")
	print("2: Manual toggle")
	print("3: Manual update")
	print("4: Exit")
	print("Please enter your choice: (1-5)")
end

local function viewDataMenu()
	term.clear()
	print("View Data")
	print("------------------------")
	print("1: List devices")
	print("2: Device details")
	print("3: Back")
	print("Please enter your choice (1-3)")
end

local function deviceListMenu(start, count)
	term.clear()
	local linesPrinted = 0
	print("Registered devices")
	print("------------------------")

	for i = start, math.min(start + count -1, #infoChart) do
		local device = infoChart[i]
		print(i .. ": " .. device.name)
		linesPrinted = linesPrinted + 1
		if linesPrinted >= height - 3 then
			print("Enter any for next page.")
			unblockRead.read()
			term.clear()
			linesPrinted = 0
		end
	end

	print("Enter any to return")
end

local function detailMenu(deviceName, dataType)
	term.clear()
	for _, device in ipairs(infoChart) do
		if device.name == deviceName then
			if dataType == "items" then
				print("Items: " .. serialization.serialize(device.items))
			elseif dataType == "signals" then
				print("Signals: " .. serialization.serialize(device.signalAssignments))
			elseif dataType == "limits" then
				print("Limits: " .. serialization.serialize(device.limits))
			elseif dataType == "status" then
				print("Status: " .. serialization.serialize(device.status))
			end

			print("Enter any to return")
			unblockRead.read()
			return
		end
	end
end

local function menuHandler(choice)
	if choice == "1" then
		viewDataMenu()
		local viewChoice = unblockRead.read()
		if viewChoice == "1" then
			local devicesPerPage = height - 3
			deviceListMenu(2, devicesPerPage)
			mainMenu()
		elseif viewChoice == "2" then
			term.clear()
			print("Enter device name:")
			local name = unblockRead.read()
			print("Enter data type (items, signals, limits, status):")
			local dataType = unblockRead.read()
			detailMenu(name, dataType)
			mainMenu()
		else
			mainMenu()
		end
	elseif choice == "2" then
		term.clear()
		print("Enter device name:")
		local name = unblockRead.read()
		print("Enter signal:")
		local signal = tonumber(unblockRead.read())

		if name and signal then
			modem.broadcast(port, name .. ":toggle:" .. signal)
		end

		mainMenu()
	elseif choice == "3" then
		checkStorage()
		mainMenu()
	elseif choice == "4" then
		coroutine.close(check)
		os.exit()
	else
		mainMenu()
	end
end

while true do
	menuHandler(unblockRead.read())

	os.sleep(0)
end