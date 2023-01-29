component = require("component")
keypad = component.os_keypad
doorController = component.os_doorcontroller
event = require("event")

local pin = "1234"
local input = ""

local runInBack = false

function updateDisplay()
	local displayString = ""
	for i=1,#input do
		displayString = displayString .. "*"
	end

	keypad.setDisplay(displayString, 7)
end

function checkPin()
	if input == pin then
		keypad.setDisplay("GRANTED", 2)
		doorController.open()
		os.sleep(2)
		doorController.close()
	else
		keypad.setDisplay("DENIED", 4)
	end

	input = ""
	os.sleep(1)
end

function keypadEvent(eventName, address, button, button_label)
	if button_label == "*" then
		input = string.sub(input, 1, -2)
	elseif button_label == "#" then
		checkPin()
	else
		input = input .. button_label
	end
end

event.listen("keypad", keypadEvent)

keypad.setDisplay("")

if not runInBack then
	local = stopMe = false
	event.listen("interrupted", finction() stopMe = true; end)
	while not stopMe(0.1) end

	event.ignore("keypad", keypadEvent)

	event.setDisplay("Inactive", 6)
end