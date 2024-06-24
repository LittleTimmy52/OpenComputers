local component = require("component")
local event = require("event")
local term = require("term")

local keypad = component.os_keypad
local doorController = component.os_doorcontroller

local pin = "1234"
local delay = 2
local input = ""
local keypadEnabled = true

local runInBack = false
local stopMe = false

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
		os.sleep(delay)
		doorController.close()
	else
		keypad.setDisplay("DENIED", 4)
	end

	input = ""
	os.sleep(1)
end

local function keypadEvent(eventName, address, button, button_label)
	if not keypadEnabled then
		return
	end

	if button_label == "*" then
		input = string.sub(input, 1, -2)
	elseif button_label == "#" then
		checkPin()
	else
		input = input .. button_label
	end

	updateDisplay()
end

local function handleKeyboardInput(command)
	if command == "open" then
		doorController.open()
		keypad.setDisplay("OPENED", 2)
		print("Door opened.")
	elseif command == "close" then
		doorController.close()
		keypad.setDisplay("CLOSED", 2)
		print("Door closed.")
	elseif command == "lock" then
		keypadEnabled = false
		keypad.setDisplay("LOCKED", 4)
		print("Keypad locked.")
	elseif command == "unlock" then
		keypadEnabled = true
		keypad.setDisplay("")
		print("Keypad unlocked.")
	elseif command == "help" then
		print("Commands:")
		print("  open    - Open the door")
		print("  close   - Close the door")
		print("  lock    - Lock the keypad")
		print("  unlock  - Unlock the keypad")
		print("  exit    - Exit the program")
		print("  help    - Show this help message")
	elseif command == "exit" then
		stopMe = true
	else
		print("Unknown command: " .. command)
	end
end

event.listen("keypad", keypadEvent)

keypad.setDisplay("")

if not runInBack then
	event.listen("interrupted", function() stopMe = true; end)
	while not stopMe do
		print("Enter command: ")
		local command = term.read()
		command = command:gsub("\n", "") -- Remove newline character
		handleKeyboardInput(command)
		os.sleep(0.1)
	end

	event.ignore("keypad", keypadEvent)

	keypad.setDisplay("Inactive", 6)
end
