local modem = require("component").modem
local redstone = require("component").redstone
local event = require("event")
local serialization = require("serialization")
local rs = require("component").block_refinedstorage_interface

local port = 2025

local infoChart = {}	-- name:devices it controlls:signal:status:limit (string:table:table:table:table)
local recieved = false
local timeOut = 2
local iterationLimit = 15
local checkInterval = 15

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

while true do
	os.sleep(0)
end

--[[




make the network protocol more secure





make seperate ui program





make config file




maybe make this an rc program then make some frontend




the second and fourth thing are neglagable if I can make some front end that
doesent blobk the working (yeilding to the coroutines)



]]