local modem = require("component").modem
local redstone = require("component").redstone
local event = require("event")
local serialization = require("serialization")
local rs = require("component").block_refinedstorage_cable

local port = 2025

local infoChart = {}	-- name:devices it controlls:signal:status:limit (string:table:table:table:table)
local recieved = false
local timeOut = 2
local iterationLimit = 15

local function physicleReset()
	-- Output on back of computer the signal
	redstone.setOutput(2, 15)

	for _, v in ipairs(infoChart) do
		for i = 1, #v[4] do
			v[4][i] = false
		end
	end
end

local function messageHandler(_, _, from, _, _, message)
	if message ~= "Acknowlaged" then

		-- logic bad, make it account for the new table after status or move it to be before to make it easier
		-- also make the if statemebnt like if message  is formatted like the table then








		

		local parts = {}

		-- Split the main string by :
		for part in string.gmatch(inputString, "([^:]+)") do
			table.insert(parts, part)
		end

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

		for _, itemString in ipairs(itemStrings) do
			local itemParts = {}
			for itemPart in string.gmatch(itemString, "([^:]+)") do
			table.insert(itemParts, itemPart)
			end
			table.insert(items, itemParts[1])
			table.insert(signalAssignments, tonumber(itemParts[2]) or itemParts[2])
		end

		local status = {}
		for i = 1, #signalAssignments do
			table.insert(status, false)
		end

		table.insert(infoChart, {
			name = name,
			items = items,
			signalAssignments = signalAssignments, 
			status = status
		})
	elseif message == "Acknowlaged" then
		recieved = true
	elseif message == "Reset" then
		physicleReset()
	elseif message == "getInfo" then
		modem.send(from, port, serialization.serialize(infoChart))
	elseif string.find("manualToggle") then
		-- manualToggle:name:signal
	end
end

local function toggle(name, signal)
	local iteration = 0
	while recieved == false && iteration < iterationLimit do
		modem.broadcast(port, name .. ":toggle:" .. signal)
		os.sleep(timeOut)
		iteration = iteration + 1
	end

	if recieved then
		for _, v in ipairs(infoChart) do
			if v[1] == name then
				local location
				for _, v, in ipairs(v[3]) do
					if v == signal then
						location = v
					end
				end

				v[4][location] = not v[4][location]
			end
		end
	end

	recieved = false
end

local function checkStorage()
	local trackedInventory = {}
	for i = 1, #infoChart do
		for _, itemName in ipairs(infoChart[i][2]) do
			local item = refinedStorage.getItem(itemName)
			trackedInventory[itemName] = item.amount or 0
		end
	end

	for itemName, ammount in pairs do
		if ammount >
	end
end

event.listen("modem_message", messageHandler)

modem.open(2025)

modem.broadcast(port, "rolecall")
physicleReset()

while true do
	os.sleep(0)
end