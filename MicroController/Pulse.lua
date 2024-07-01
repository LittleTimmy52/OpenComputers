local redstone = component.proxy(component.list("redstone")())
local pulseLength = 60 -- 1 minute in seconds
local delayBetweenPulses = 300 -- 5 minutes in seconds

local function sleep(delay)
	local start = os.clock()
	while (os.clock() - start) < delay do
		coroutine.yield()
	end
end

local function emitPulse()
	redstone.setOutput(0, 15)
	redstone.setOutput(2, 15)
	redstone.setOutput(3, 15)
	redstone.setOutput(4, 15)
	redstone.setOutput(5, 15)

	sleep(pulseLength)

	redstone.setOutput(0, 0)
	redstone.setOutput(2, 0)
	redstone.setOutput(3, 0)
	redstone.setOutput(4, 0)
	redstone.setOutput(5, 0)
end

local function isActive()
  return redstone.getInput(1) == false
end

local function mainLoop()
  while true do
	if isActive() then
	  sleep(delayBetweenPulses)
	else
	  -- Wait for top to be unpowered
	  while redstone.getInput(1) == false do
		sleep(0.1)
	  end
	end
	emitPulse()
  end
end

mainLoop()
