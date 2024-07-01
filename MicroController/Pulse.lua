local sides = { "bottom", "north", "east", "south", "west" }
local redstone = require("component").redstone
local pulseLength = 60 -- 1 minute in seconds
local delayBetweenPulses = 300 -- 5 minutes in seconds
local topSide = "up"

local function emitPulse(exceptSide)
  for _, side in ipairs(sides) do
	if side ~= exceptSide then
	  redstone.setOutput(side, true)
	  os.sleep(pulseLength)
	  redstone.setOutput(side, false)
	end
  end
end

local function isActive()
  return redstone.getInput(topSide) == false
end

local function mainLoop()
  while true do
	if isActive() then
	  os.sleep(delayBetweenPulses)
	else
	  -- Wait for top to be unpowered
	  while redstone.getInput(topSide) == false do
		os.sleep(0.1)
	  end
	end
	emitPulse(topSide)
  end
end

mainLoop()
