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

-- get the server address
modem.broadcast(port, "hello")
local recievedCorrect = false
local _, myAddr, srvAddr, srvPort, srvDist, srvMsg
while not recievedCorrect do
    _, myAddr, srvAddr, srvPort, srvDist, srvMsg = event.pull("modem_message")
    if keepLog then
        if not fileSystem.exists(logPath) then
            local logFile = io.open(logPath, "w")
            logFile:write("Client log")
            logFile:close()
        end
    
        local logFile = io.open(logPath, "a")
        local log = string.format("\nLog:\nlocalAddress: %s remoteAddress: %s port: %d distance: %d message: %s", myAddr, srvAddr, srvPort, srvDist, srvMsg)
        if isVerbose then
            print(log)
        end
        
        logFile:write(log)
        logFile:close()
    end
    
    if srvMsg == "returnHello" then
        recievedCorrect = true
    end
end

-- options
local function getList()
	modem.send(srvAddr, port, "getList")
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
	local name, passwd
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

	modem.send(srvAddr, port, "reserve:" .. name .. "/" .. modem.address)

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

    local roomInfo = serialization.serialize({name, passwd})
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