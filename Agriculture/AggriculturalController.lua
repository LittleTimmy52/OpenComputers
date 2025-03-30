local component = require("component")
local modem = component.modem
local redstone = component.redstone
local event = require("event")
local serialization = require("serialization")
local rs = component.refinedstorage_interface
local thread = require("thread")

local infoChart = {}	-- name-items it controlls-signal-status-limit-address (string-table-table-table-table-string)
local recieved = false
local check

local port = 2025
local timeOut = 5
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
	conf:write("port=2025\ntimeOut=5\niterationLimit=15\ncheckInterval=15")
	conf:close()
end

local function physicleReset()
	-- output on back of computer the signal
	redstone.setOutput(2, 15)
	os.sleep(1)
	redstone.setOutput(2, 0)

	for _, v in ipairs(infoChart) do
		if v[4] then
			for i = 1, #v[4] do
				v[4][i] = false
			end
		end
	end
end

local function toggle(name, signal)
	local address

	for _, v in ipairs(infoChart) do
		if v[1] == name then
			address = v[6]
			local location

			for k, j in ipairs(v[3]) do
				if j == signal then
					location = k
					break
				end
			end

			if address and location ~= nil then
				local iteration = 1
				recieved = false

				while not recieved and iteration < iterationLimit do
					modem.send(address, port, name .. "-toggle-" .. signal)
					iteration = iteration + 1
					if not recieved then os.sleep(timeOut) end
				end

				if recieved then
					v[4][location] = not v[4][location]
				end
			end
		end
	end
end

local function checkStorage()
	local itemMap = {}

	for _, item in ipairs(rs.getItems()) do
		itemMap[item.name] = item.size
	end

	for i = 1, #infoChart do
		for k, itemName in ipairs(infoChart[i][2]) do
			local size = itemMap[itemName]

			if size == nil then
				if infoChart[i][4][k] == false then
					toggle(infoChart[i][1], infoChart[i][3][k])
				end
			else
				if infoChart[i][5][k] > size then
					if infoChart[i][4][k] == false then
						toggle(infoChart[i][1], infoChart[i][3][k])
					end
				elseif size > infoChart[i][5][k] then
					if infoChart[i][4][k] then
						toggle(infoChart[i][1], infoChart[i][3][k])
					end
				end
			end
		end
	end
end

local function messageHandler(_, _, from, _, _, message)
	if message:sub(1, 9) == "rolecall-" then
		-- break the name off the rest
		local name, itemDataString = message:match("rolecall%-(%d+)%-%{(.+)%}")

		-- splitting on commas
		local itemStrings = {}
		for item in itemDataString:gmatch("([^,]+)") do
			table.insert(itemStrings, item:match("^%s*(.-)%s*$"))
		end

		local items = {}
		local signalAssignments = {}
		local limits = {}

		for _, itemString in ipairs(itemStrings) do
			-- breaking down further
			local item, signal, limit = itemString:match("([^%-]+)%-(%d+)%-(%d+)")

			if item and signal and limit then
				table.insert(items, item)
				table.insert(signalAssignments, tonumber(signal))
				table.insert(limits, tonumber(limit))
			end
		end

		-- should all be off, so there all false
		local status = {}
		for _ in ipairs(signalAssignments) do
			table.insert(status, false)
		end

		-- slap it all into the main data chart
		table.insert(infoChart, {
			name,
			items,
			signalAssignments,
			status,
			limits,
			from
		})
	elseif message == "Acknowlaged" then
		recieved = true
	elseif message == "reset" then
		physicleReset()
		modem.send(from, port, "executed")
	elseif message:sub(1, 8) == "getInfo-" then
		local section = message:sub(9)
		local listSelection
		local tableIndex = 0
		if tonumber(section) == 1 then
			listSelection = 1
		elseif tonumber(section) == 6 then
			listSelection = 6
		else
			listSelection = tonumber(string.char(message:byte(9)))
			tableIndex = tonumber(message:sub(11))
		end

		local good = (tableIndex <= #infoChart and tableIndex > 0)

		if good then
			if listSelection == 2 then
				modem.send(from, port, "items-" .. serialization.serialize(infoChart[tableIndex][2]))
			elseif listSelection == 3 then
				modem.send(from, port, "signals-" .. serialization.serialize(infoChart[tableIndex][3]))
			elseif listSelection == 4 then
				modem.send(from, port, "status-" .. serialization.serialize(infoChart[tableIndex][4]))
			elseif listSelection == 5 then
				modem.send(from, port, "limits-" .. serialization.serialize(infoChart[tableIndex][5]))
			end
		else
			if listSelection == 1 then
				local names = {}
				for i = 1, #infoChart do
					table.insert(names, infoChart[i][1])
				end

				modem.send(from, port, "names-" .. serialization.serialize(names))
			elseif listSelection == 6 then
				local addresses = {}
				for i = 1, #infoChart do
					table.insert(addresses, infoChart[i][6])
				end

				modem.send(from, port, "addresses-" .. serialization.serialize(addresses))
			end
		end
	elseif message:sub(1, 7) == "toggle-" then
		local parts = {}
		for part in string.gmatch(message, "([^-]+)") do
			table.insert(parts, part)
		end

		toggle(parts[2], tonumber(parts[3]))
		modem.send(from, port, "executed")
	elseif message == "update" then
		check:suspend()
		checkStorage()
		check:resume()
		modem.send(from, port, "executed")
	end
end

local success, _ = pcall(function()
	event.listen("modem_message", messageHandler)

	modem.open(port)

	modem.broadcast(port, "rolecall")
	physicleReset()

	check = thread.create(function() while true do checkStorage() os.sleep(checkInterval) end end)

	-- "Ahh, Ahh, Ahh, Ahh, stayin alive, stayin alive"
	while true do
		os.sleep(0.05)
	end
end)

if not success then
	check:kill()
	event.ignore("modem_message", messageHandler)
	modem.close(port)
	physicleReset()
end