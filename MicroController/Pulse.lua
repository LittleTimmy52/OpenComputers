local redstone = component.proxy(component.list("redstone")())
local pulseLength = 60 -- 1 minute in seconds
local delayBetweenPulses = 300 -- 5 minutes in seconds

local function emitPulse()
	redstone.setOutput(0, true)
	redstone.setOutput(2, true)
	redstone.setOutput(3, true)
	redstone.setOutput(4, true)
	redstone.setOutput(5, true)
	os.sleep(pulseLength)
	redstone.setOutput(0, false)
	redstone.setOutput(2, false)
	redstone.setOutput(3, false)
	redstone.setOutput(4, false)
	redstone.setOutput(5, false)
end

local function isActive()
  return redstone.getInput(1) == false
end

local function mainLoop()
  while true do
	if isActive() then
	  os.sleep(delayBetweenPulses)
	else
	  -- Wait for top to be unpowered
	  while redstone.getInput(1) == false do
		os.sleep(0.1)
	  end
	end
	emitPulse()
  end
end

mainLoop()
