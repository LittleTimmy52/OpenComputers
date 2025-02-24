local modem = component.proxy(component.list("modem")())
local redstone = component.proxy(component.list("redstone")())
local sign = component.proxy(component.list("sign")())

local name = "1"
local port = 2025

local n, p = sign.getValue():match("([^\n]+)\n([^\n]+)")
if n ~= nil and tonumber(p) ~= nil then
	name = n
	port = tonumber(p)
end

-- must be changed before flashing, this is not set by the sign
local devicesControlled = "{item1:1:1000, item2:2:1000, item3:3:1000}"	-- itemname:signalAssigned:limit

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

	modem.send(from, port, "Acknowlaged")
end

while true do
	sleep(0.1)
	local type, _, from, _, _, message = computer.pullSignal(1)
	if type == "modem_message" then
		messageHandler(message, from)
	end
end