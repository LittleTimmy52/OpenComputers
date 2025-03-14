local component = require("component")
local modem = component.modem
local redstone = component.redstone
local event = require("event")
local serialization = require("serialization")
local rs = component.refinedstorage_interface

local infoChart = {}	-- name-items it controlls-signal-status-limit (string-table-table-table-table)
local recieved = false

local port = 2025
local timeOut = 10
local iterationLimit = 15
local checkInterval = 15

-- load conf
local conf = io.open("/etc/AggriculturalController/AggriculturalController.cfg", "r")
if conf then
	for line in conf:lines() do
		local k, v = line:match("^(%w+)%s*=%s*(%S+)$")
		if k == "port" then
			port = tonumber(v)
		elseif k == "timeOut" then
			timeOut = tonumber(v)
		elseif k == "iterationLimit" then
			iterationLimit = tonumber(v)
		elseif k == "checkInterval" then
			checkInterval = tonumber(v)
		end
	end

	conf:close()
else
	require("filesystem").makeDirectory("/etc/AggriculturalController/")
	conf = io.open("/etc/AggriculturalController/AggriculturalController.cfg", "w")
	conf:write("port=2025\ntimeOut=10\niterationLimit=15\ncheckInterval=15")
	conf:close()
end

local function physicleReset()
	-- output on back of computer the signal
	redstone.setOutput(2, 15)
	os.sleep(1)
	redstone.setOutput(2, 0)

	for _, v in ipairs(infoChart) do
		for i = 1, #v[4] do
			v[4][i] = false
		end
	end
end

local function toggle(name, signal)
	local iteration = -1
	while recieved == false and iteration < iterationLimit do
		modem.broadcast(port, name .. "-toggle-" .. signal)
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
	if string.find(message, "rolecall-") then
		local parts = {}

		-- split the main string by -
		for part in string.gmatch(message, "([^-]+)") do
			table.insert(parts, part)
		end

		table.remove(parts, 1)

		local name = parts[1]
		local itemDataString = parts[2]

		-- remove curly braces and split by comma
		itemDataString = string.sub(itemDataString, 2, -2)
		local itemStrings = {}
		for itemString in string.gmatch(itemDataString, "([^,]+)") do
			table.insert(itemStrings, itemString)
		end

		local items = {}
		local signalAssignments = {}
		local limits = {}

		-- split the items controlled
		for _, itemString in ipairs(itemStrings) do
			local parts = {}
			for itemPart in string.gmatch(itemString, "([^-]+)") do
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
	elseif message == "reset" then
		physicleReset()
		modem.send(from, port, "reset")
	elseif message == "getInfo" then
		local preData = serialization.serialize(infoChart)
		local tmp = ""
		local packets = 0

		-- give the sender the dtarting flag and then the chunks there after
		modem.send(from, port, "info")
		for i = 1, #preData do
			if string.len(tmp) < modem.maxPacketSize() - 7 then
				tmp = tmp .. string.sub(preData, i, i)
			else
				modem.send(from, port, "info-" .. tmp)
				tmp = ""
				packets = packets + 1
			end
		end

		-- send the last packet
		if tmp ~= "" then
			modem.send(from, port, tmp)
			packets = packets + 1
		end

		-- tell sender were done
		modem.send(from, port, "done-" .. tostring(packets))
	elseif string.find(message, "manualToggle-") then
		local parts = {}
		for part in string.gmatch(message, "([^-]+)") do
			table.insert(parts, part)
		end

		toggle(parts[2], parts[3])
		modem.send(from, port, "toggled")
	elseif message == "manualUpdate" then
		checkStorage()
		modem.send(from, port, "updated")
	end
end

event.listen("modem_message", messageHandler)

modem.open(port)

modem.broadcast(port, "rolecall")
physicleReset()

local check = coroutine.create(function() while true do checkStorage() os.sleep(checkInterval) end end)
coroutine.resume(check)

-- "Ahh, Ahh, Ahh, Ahh, stayin alive, stayin alive"
while true do
	os.sleep(0)
end