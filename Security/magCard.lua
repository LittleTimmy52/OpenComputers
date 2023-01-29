event = require("event")
doorController = require("component").os_doorController

-- Change to data you want to open the door
correctData = "Clerance level 3 for example"

function check(eventName, address, playerName, cardData, cardUniqueId, isCardLocked, side)
	print("player " .. playerName .. " used card " .. cardUniqueId .. " data " .. cardData)
	if cardData == correctData then
		doorController.open()
		os.sleep(2)
		doorController.close()
	end
end

event.listen("magData", ckeck)
event.pull("interrupted")
event.ignore("magData", check)