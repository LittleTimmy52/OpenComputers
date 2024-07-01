local redstone = component.proxy(component.list("redstone")())
local pulseLength = 60 -- 1 minute in seconds
local delayBetweenPulses = 300 -- 5 minutes in seconds
local active = true

local function sleep(delay)
	local start = os.clock()
	while (os.clock() - start) < delay do
		coroutine.yield()
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
