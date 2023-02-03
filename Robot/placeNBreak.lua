robot = require("robot")

robot.select(1)

function findItem(next)
	local invSize = robot.inventory()
	local slot = robot.select()
	local count = robot.count()

	if next then robot.select(slot + 1) end

	while count == 0 do
		robot.select(slot + 1)
		slot = robot.select()
		count = robot.count()
		if slot == invSize and count == 0 then os.exit() end
	end
end

function placeNBreak()
	local placed = robot.place()
	if placed == true then
		os.sleep(0.1)
		robot.swing()
	else
		findItem(true)
	end
end

findItem(false)

while true do placeNBreak() end