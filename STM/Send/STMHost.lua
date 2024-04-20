local component = require("component")
local serialization = require("serialization")
local fileSystem = require("filesystem")
local event = require("event")
local modem = component.modem

local port = 0
local keepLog = false
local isVerbose = false
local reserveClearDelay = 300
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
		elseif string.find(line, "isVerbose") then
			isVerbose = string.lower(string.match(line, ":(.*)")) == "true"
        elseif string.find(line, "reserveClearDelay:") then
            reserveClearDelay = tonumber(string.match(":(.*)"))
		end
	end
else
	print("No config file, generating one with default settings.")
	if not fileSystem.exists(cfgDir) then
		fileSystem.makeDirectory(cfgDir)
	end

	-- set defaults
	cfgFile = io.open(cfgPath, "w")
	cfgFile:write("port:8443\nkeepLog:false\nisVerbose:false\nreserveClearDelay:300")
	cfgFile:close()
	port = 8443
	keepLog = false
	isVerbose = false
    reserveClearDelay = 300
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

-- helper functions
local reservedNames = {}
local function hello(remote)
    modem.send(remote, port, "returnHello")
end
local function listRooms(remote)
	if roomsList ~= nil then
		modem.send(remote, port, "returnList:" .. serialization.serialize(roomsList))
	else
		local table = {"There are no rooms open"}
		modem.send(remote, port, "returnList:" .. serialization.serialize(table))
	end
end

local function create(remote, msg)
	-- make sure to check the reserve with the remnote to allow the name send back if failed
end

local function reserve(name)
	table.insert(reservedNames, name)
end

local function processModem(localAddress, remoteAddress, port, distance, message)
	if keepLog then
		local logFile = io.open(logPath, "a")
		local log = string.format("\nLog:\nlocalAddress: %s remoteAddress: %s port: %d distance: %d message: %s", localAddress, remoteAddress, port, distance, message)
		if isVerbose then
			print(log)
		end

		logFile:write(log)
		logFile:close()
	end

	if message == "hello" then
        hello(remoteAddress)
    elseif message == "getList" then
		listRooms(remoteAddress)
	elseif message == "create" then
		create(remoteAddress, message:match(":(.*)"))
	elseif message:match("^reserve:") then
		reserve(message:match(":(.*)"))
	end
end

local function removeReservedAferDelay (delay)
    while true do
        os.sleep(delay)
        if #reservedNames > 0 then
            table.remove(reservedNames, 1)
        end
    end
end

local removeReservedAferDelayCoroutine = coroutine.create(removeReservedAferDelay)
coroutine.resume(removeReservedAferDelayCoroutine, reserveClearDelay)

-- listen for the messages
while true do
	local _, localAddress, remoteAddress, port, distance, message = event.pull("modem_message")
	local processCoroutine = coroutine.create(processModem)
	local success, error = coroutine.resume(processCoroutine, localAddress, remoteAddress, port, distance, message)
	if not success and keepLog then
		local logFile = io.open(logPath, "a")
		local log = "\nError:\n" .. error
		if isVerbose then
			print(log)
		end

		logFile:write(log)
		logFile:close()
	end
end