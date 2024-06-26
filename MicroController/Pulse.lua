local redstone = component.proxy(component.list("redstone")())
local pulseLength = 30 -- 30 seconds
local delayBetweenPulses = 300 -- 5 minutes
local active = true

local function sleep(delay)
    local time = os.time()
    local newTime = time + delay
    while time < newTime do
        computer.pullSignal(newTime - time)
        time = os.time()
    end
end

local function mainLoop()
	while true do
		active = redstone.getInput(1) == 0

		if active then
			redstone.setOutput(0, 15)
			redstone.setOutput(2, 15)
			redstone.setOutput(3, 15)
			redstone.setOutput(4, 15)
			redstone.setOutput(5, 15)
		end

		sleep(pulseLength)

		redstone.setOutput(0, 0)
		redstone.setOutput(2, 0)
		redstone.setOutput(3, 0)
		redstone.setOutput(4, 0)
		redstone.setOutput(5, 0)

		sleep(delayBetweenPulses)
	end
end

mainLoop()
