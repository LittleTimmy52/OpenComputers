local component = require("component")
local keypad = component.os_keypad
local doorController = component.os_doorcontroller
local event = require("event")

local pin = "1234"
local input = ""

local runInBack = false

local function updateDisplay()
	local displayString = ""
	for i=1,#input do
		displayString = displayString .. "*"
	end

	keypad.setDisplay(displayString, 7)
end

local function checkPin()
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

local function keypadEvent(eventName, address, button, button_label)
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