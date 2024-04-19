local component = require("component")
local serialization = require("serialization")
local event = require("event")
local fileSystem = require("filesystem")
local modem = component.modem
local data = component.data

local port = 0
local keepLog = false
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
		end
	end
else
	print("No config file, generating one with default settings.")
	if not fileSystem.exists(cfgDir) then
		fileSystem.makeDirectory(cfgDir)
	end
	
	cfgFile = io.open(cfgPath, "w")
	cfgFile:write("port:8443\nkeepHistory:false")
	cfgFile:close()
	port = 8443
	keepHistory = false
end

-- open port
modem.open(port)

-- ask host for room list
modem.broadcast(port, "list rooms")
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
		local log = string.format("\nlocalAddress: %s remoteAddress: %s port: %d distance: %d message: %s", localAddress, remoteAddress, port, distance, message)
		print("log: " .. log)
		logFile:write(log)
		logFile:close()
	end
	
	if string.find(message, "rooms list:") then
		recievedCorrect = true
	end
end