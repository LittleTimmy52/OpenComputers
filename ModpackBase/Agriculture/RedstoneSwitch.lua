local modem = component.proxy(component.list("modem")())
local redstone = component.proxy(component.list("redstone")())
local computer = component.proxy(component.list("computer")())

local name = "1"
local devicesControlled = "{item1:1:1000, item2:2:1000, item3:3:1000}"	-- itemname:signalAssigned:limit
local port = 2025

modem.open(port)

local function sleep(delay)
    local time = os.time()
    local newTime = time + delay
    while time < newTime do
        computer.pullSignal(newTime - time)
        time = os.time()
    end
end

local function messageHandler(message, from)
	if message == "rolecall" then
		modem.send(from, port, "rolecal:" .. name .. ":" .. devicesControlled)
	elseif string.find(message, name .. ":toggle") then
		local signal = tonumber(string.match(message, ".*:(.*)"))
		redstone.setOutput(1, signal)
		sleep(1)
		redstone.setOutput(1, 0)
	end

	modem.broadcast(port, "Acknowlaged")
end

while true do
	sleep(0.1)
	local type, _, from, _, _, message = computer.pullSignal(1)
	if type == "modem_message" then
		messageHandler(message, from)
	end
end