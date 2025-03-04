local modem = require("component").modem
local event = require("event")
local serialization = require("serialization")
local data = nil
local fs = require("filesystem")

local port = 2025
local timeOut = 10
local iterationLimit = 15
local useData = true
local port2 = 1234
local password = "SecurePresharedPassword"

local function encrypt(decryptedData, password)
	local key = data.md5(password)
	local iv = data.random(16)
	local encryptedData = data.encrypt(decryptedData, key, iv)
	return serialization.serialize({encrypted = encryptedData, iv = iv})
end

local function decrypt(encryptedData, password)
	local key = data.md5(password)
	local decoded = serialization.unserialize(encryptedData)
	return serialization.unserialize(data.decrypt(decoded.encrypted, key, decoded.iv))
end

local function getInfo()
	local iteration = -1
	local recieved = false

	-- loop to get the chart lest it fails then you get a message
	while not recieved and iteration < iterationLimit do
		modem.broadcast(port, "getInfo")
		local _, _, _, _, _, msg = event.pull("modem_message", timeOut)

		if msg == "info" then
			recieved = true

			if useData then
				modem.broadcast(port2, encrypt(msg))
			else
				modem.broadcast(port2, msg)
			end
		end

		iteration = iteration + 1
	end

	local go = recieved

	-- if it was recieved, now we wait for the packets
	while go do
		local _, _, _, _, _, msg = event.pull("modem_message", timeOut)
		if msg == nil then
			break
		else
			-- stop once we get the final packet
			if msg == string.find("info-") then
				if useData then
					modem.broadcast(port2, encrypt(msg))
				else
					modem.broadcast(port2, msg)
				end

				go = false
			else
				if useData then
					modem.broadcast(port2, encrypt(msg))
				else
					modem.broadcast(port2, msg)
				end
			end
		end
	end
end

local function manToggle(index, signal)
	local iteration = -1
	local recieved = false

	-- loop to get the reply lest it fails then you get a message
	while not recieved and iteration < iterationLimit do
		modem.broadcast(port, "manualToggle-" .. infoChart[index][1] .. tostring(signal))
		local _, _, _, _, _, msg = event.pull("modem_message", timeOut)

		if msg == "toggled" then
			recieved = true
		end

		iteration = iteration + 1
	end

	if not recieved then
		if useData then
			modem.broadcast(port2, encrypt("Err"))
		else
			modem.broadcast(port2, "Err")
		end
	end
end

local function manReset()
	local iteration = -1
	local recieved = false

	-- loop to get the reply lest it fails then you get a message
	while not recieved and iteration < iterationLimit do
		modem.broadcast(port, "reset")
		local _, _, _, _, _, msg = event.pull("modem_message", timeOut)

		if msg == "reset" then
			recieved = true
		end

		iteration = iteration + 1
	end

	if not recieved then
		if useData then
			modem.broadcast(port2, encrypt("Err"))
		else
			modem.broadcast(port2, "Err")
		end
	end
end

local function manUpdate()
	local iteration = -1
	local recieved = false

	-- loop to get the reply lest it fails then you get a message
	while not recieved and iteration < iterationLimit do
		modem.broadcast(port, "update")
		local _, _, _, _, _, msg = event.pull("modem_message", timeOut)

		if msg == "updated" then
			recieved = true
		end

		iteration = iteration + 1
	end

	if not recieved then
		if useData then
			modem.broadcast(port2, encrypt("Err"))
		else
			modem.broadcast(port2, "Err")
		end
	end
end

local function messageHandler(_, _, _, p, _, message)
	if useData and p == port2 then
		message = decrypt(message)
	end

	if p == p2 then
		--[[
			flags:
			getInfo-	g
			manToggle	t
			manReset	r
			manUpdate	u
		]]

		local flag = message

		-- if it is not just a flag take the data
		if string.len(message) > 1 then
			flag = message:sub(1, 1)
			message = message:sub(2) -- remove flag
		end

		if flag == "g" then
			getInfo()
		elseif flag == "t" then
			local parts = {}
			for part in string.gmatch(message, "([^-]+)") do
				table.insert(parts, part)
			end

			manToggle(parts[2], parts[3])
		elseif flag == "r" then
			manReset()
		elseif flag == "u" then
			manUpdate()
		end
	end
end

function start()
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
				password = tonumber(v)
			end
		end

		conf:close()
	else
		conf = io.open("/etc/AggriculturalController/AggriculturalControllerInterface.cfg", "w")
		conf:write("port=2025\ntimeOut=10\niterationLimit=15\nuseData=true\npassword=SecurePresharedPassword\nport2=1234")
		conf:close()
	end

	if useData then
		data = require("component").data
	end

	modem.open(port)
	modem.open(port2)

	event.listen("modem_message", messageHandler)
end