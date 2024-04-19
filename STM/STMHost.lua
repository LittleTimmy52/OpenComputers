local component = require("component")
local serialization = require("serialization")
local fileSystem = require("filesystem")
local event = require("event")
local thread = require("thread")
local modem = component.modem
local data = component.data

local port = 0
local keepLog = false
local logPath = "/etc/STMHost/STMHost.log"
local roomsList = {}

-- load config
local cfgPath = "/etc/STMHost/STMHost.cfg"
local cfgDir = "/etc/STMHost/"	-- the code is being retarded and I cant extract this from the above string so I am putting it here
local cfgFile = io.open(cfgPath, "r")

-- check if config exists
if cfgFile then
	for line in cfgFile:lines() do
		if string.find(line, "port") then
			port = tonumber(string.match(line, ":(.*)"))
		elseif string.find(line, "keepLog") then
			keepLog = string.lower(string.match(line, ":(.*)")) == "true"
		end
	end
else
	print("No config file, generating one with default settings.")
	if not fileSystem.exists(cfgDir) then
		fileSystem.makeDirectory(cfgDir)
	end

	cfgFile = io.open(cfgPath, "w")
	cfgFile:write("port:8443\nkeepLog:false")
	cfgFile:close()
	port = 8443
	keepLog = false
end

-- open port
modem.open(port)

-- log if logging
if keepLog then
	if not fileSystem.exists(logPath) then
		local logFile = io.open(logPath, "w")
		logFile:write("Host log")
		logFile:close()
	end
end

-- processor functions
local function listRooms(remote)
	if roomsList == nil then
		modem.send(remote, port, "rooms list:" + serialization.serialize(roomsList))
	else
		table = {"There are no rooms open"}
		print(serialization.serialize(tab))
		modem.send(remote, port, "rooms list: " + serialization.serialize(table))
	end
end

local function processModem(...)
	local _, localAddress, remoteAddress, port, distance, message = ...
	if keepLog then
		local logFile = io.open(logPath, "a")
		local log = string.format("\nlocalAddress: %s remoteAddress: %s port: %d distance: %d message: %s", localAddress, remoteAddress, port, distance, message)
		print("log: " .. log)
		logFile:write(log)
		logFile:close()
	end

	if message == "list rooms" then
		listRooms(remoteAddress)
	end
end

-- register the listener
event.listen("modem_message", processModem)

-- loop to stay running
while true do os.sleep(1) end