local component = require("component")
local serialization = require("serialization")
local event = require("event")
local fileSystem = require("filesystem")
local modem = component.modem

local port = 0
local keepLog = false
local isVerbose = false
local logPath = "/etc/STMClient/STMClient.log"

-- load config
local cfgPath = "/etc/STMClient/STMClient.cfg"
local cfgDir = "/etc/STMClient/"	-- the code is being retarded and I cant extract this from the above string so I am putting it here
local cfgFile = io.open(cfgPath, "r")

-- check if config exists
if cfgFile then
	for line in cfgFile:lines() do
		if string.find(line, "port") then
			port = tonumber(string.match(line, ":(.*)"))
		elseif string.find(line, "keepHistory") then
			keepLog = string.lower(string.match(line, ":(.*)")) == "true"
		elseif string.find(line, "isVerbose") then
			isVerbose = string.lower(string.match(line, ":(.*)")) == "true"
		end
	end
else
	print("No config file, generating one with default settings.")
	if not fileSystem.exists(cfgDir) then
		fileSystem.makeDirectory(cfgDir)
	end
	
	-- set defaults
	cfgFile = io.open(cfgPath, "w")
	cfgFile:write("port:8443\nkeepHistory:false\nisVerbose:false")
	cfgFile:close()
	port = 8443
	keepHistory = false
	isVerbose = false
end

-- open port
modem.open(port)

-- options
local function getList()
	modem.broadcast(port, "getList")
	local recievedCorrect = false
	local _, localAddress, remoteAddress, port, distance, message
	while not recievedCorrect do
		_, localAddress, remoteAddress, port, distance, message = event.pull("modem_message")
		if keepLog then
			if not fileSystem.exists(logPath) then
				local logFile = io.open(logPath, "w")
				logFile:write("Client log")
				logFile:close()
			end
		
			local logFile = io.open(logPath, "a")
			local log = string.format("\nLog:\nlocalAddress: %s remoteAddress: %s port: %d distance: %d message: %s", localAddress, remoteAddress, port, distance, message)
			if isVerbose then
				print(log)
			end
			
			logFile:write(log)
			logFile:close()
		end
		
		if message:match("^returnList:") then
			recievedCorrect = true
		end
	end

	return serialization.unserialize(string.match(message, ":(.*)"))
end

local function getTier()
	local recievedCorrect = false
	local _, localAddress, remoteAddress, port, distance, message
	while not recievedCorrect do
		_, localAddress, remoteAddress, port, distance, message = event.pull("modem_message")
		if keepLog then
			if not fileSystem.exists(logPath) then
				local logFile = io.open(logPath, "w")
				logFile:write("Client log")
				logFile:close()
			end
		
			local logFile = io.open(logPath, "a")
			local log = string.format("\nLog:\nlocalAddress: %s remoteAddress: %s port: %d distance: %d message: %s", localAddress, remoteAddress, port, distance, message)
			if isVerbose then
				print(log)
			end
			
			logFile:write(log)
			logFile:close()
		end
		
		if message:match("^returnTier:") then
			recievedCorrect = true
		end
	end

	return tonumber(message:match(":(.*)"))
end

local function listRooms()
	local rooms = getList()
	for k, v in pairs(rooms) do
		print(k .. " " .. v)
	end
end

local function join(name)
	
end

local function create()
	--[[modem.broadcast(port, "create")
	local recievedCorrect = false
	local _, localAddress, remoteAddress, port, distance, message
	while not recievedCorrect do
		_, localAddress, remoteAddress, port, distance, message = event.pull("modem_message")
		if keepLog then
			local logFile = io.open(logPath, "a")
			local log = string.format("\nLog:\nlocalAddress: %s remoteAddress: %s port: %d distance: %d message: %s", localAddress, remoteAddress, port, distance, message)
			if isVerbose then
				print(log)
			end
			
			logFile:write(log)
			logFile:close()
		end

		if message:match("^options:") then
			recievedCorrect = true
		end
	end]]--

	-- collect room info
	local validAnswer = false
	local name, security, passwd
	while not validAnswer do
		local currentRooms = getList()
		print("What would you like the name of the room to be?")
		name = io.read()
		local found = false
		for k, v in pairs(currentRooms) do
			if name == v then
				print("This room already exists")
				found = true
			end
		end

		if not found then
			validAnswer = true
		end
	end

	modem.broadcast(port, "reserve:" .. name .. "/" .. modem.address)

	validAnswer = false
	while not validAnswer do
		local serverTier = getTier()
		print("What security level do you want this room to be? 0-3, 0 being none, up to 3, each number corrisponding to data card tier")
		print("The server can support up to level: " .. getTier())
		security = tonumber(io.read())
		if security == 0 or security == 1 or security == 2 or security == 3 then
			if security <= serverTier then
				validAnswer = true
			else
				print("Security level higher than the server can use")
			end
		else
			print("Invalid security level")
		end
	end

	validAnswer = false
	while not validAnswer do
		print("What password do you want? (blank if none)")
		passwd = io.read()
		if passwd == "" then
			print("No password will be used")
			validAnswer = true
		else
			print("Reenter your password")
			local ans = io.read()
			if ans == passwd then
				print("Your password will bw used")
				validAnswer = true
			else
				print("The password does not match")
			end
		end
	end

	validAnswer = false
	local sendSecurity = security
	while not validAnswer do
		print("Now this room info needs to be sent to the server, it will use your selected security level for the room to send it, this may be an issue if it is 0 since anyone could see this data if they are scanning for broadcasts")
		print("Do you wish to send this info at the current security or would you like to use an elevated security for this time? (1 or 2)")
		local ans = tonumber(io.read())
		if ans == 1 then
			validAnswer = true
		elseif ans == 2 then
			local serverTier = getTier()
			print("What level do you want to use? (The server can handle up to: " .. serverTier .. ")")
			ans = io.read()
			if ans > serverTier then
				print("Security level greater than what the server can handle")
			else
				print("Sending data with preferred security level")
				sendSecurity = ans
				validAnswer = true
			end
		else
			print("Invalid response")
		end
	end

	if sendSecurity == 0 then
		-- no data card encryption xor string encrypt
	elseif sendSecurity == 1 then
		-- data card tier 1 sha256 hash
	elseif sendSecurity == 2 then
		-- datacard tier 2 encrypt
	elseif sendSecurity == 3 then
		-- datacard 3 fancy encryption/ better keyys/idk
	end
end

local function options()
	print("What would you like to do?\nList rooms: list\nJoin a room: join <name>\nCreate a room: create\nExit: exit")
	local response = io.read()
	if string.lower(response) == "list" then
		listRooms()
	elseif response:match("^join") then
		local rooms = getList()
		if rooms ~= nil and rooms ~= "There are no rooms open" then
			local exists = false
			for k, v in pairs(rooms) do
				if response:sub(6) == v then
					exists = true
				end
			end

			if exists then
				join(response:sub(6))
			else
				print("Invalid room")
				options()
			end
		else
			print("There are no rooms open")
			options()
		end
	elseif string.lower(response) == "create" then
		create()
	elseif string.lower(response) == "exit" then
		os.exit()
	else
		print("Invalid choise")
		options()
	end
end

listRooms()
options()