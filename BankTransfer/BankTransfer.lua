---@diagnostic disable: cast-local-type
local libCB = require("libCB")
local bank = require("bank_api")
local shell = require("shell")
local yawl = require("yawl")
local event = require("event")
local component = require("component")
local gpu = component.gpu
local disk_drive = component.disk_drive
local proxy =  component.proxy

local uuids = {}
local uuidFilePath = "/.uuids.txt"

local event_touch, event_drive, event_eject, event_magData = nil, nil, nil, nil

local old_res_x, old_res_y = nil, nil

local run = true

---@type Component
local drive = nil
---@type cardData
local cbData = nil
---@type encryptedCardData
local encryptedData = nil
local solde = 0
local uuid = nil
local eject = disk_drive.eject

local root = yawl.widget.Frame()
root:backgroundColor(0x000000)
local cardWaitFrame = yawl.widget.Frame(root)
local menuFrame = yawl.widget.Frame(root)
local selectorFrame = yawl.widget.Frame(root)
--local keypad = nil
local balanceText = yawl.widget.Text(menuFrame, 1, 2, "Balance: 0", 0xffffff)

-- closeing the client
local function closeClient()
	if (event_touch) then event.cancel(event_touch) end
	if (event_eject) then event.cancel(event_eject) end
	if (event_drive) then event.cancel(event_drive) end
	if (event_magData) then event.cancel(event_magData) end
	gpu.setResolution(old_res_x, old_res_y)
	root:visible(false)
	run = false
end

local function endSession()
	cardWaitFrame:visible(true)
	menuFrame:visible(false)
	--keypad:visible(false)
	cbData = nil
	encryptedData = nil
	solde = 0
	balanceText:text("Balance: 0")
	eject()
end  

-- handlers
local function buttonHandler(buttonName)
	if buttonName == "send" then
		menuFrame:visible(false)
		selectorFrame:visible(true)
		root:draw()
	elseif buttonName == "eject" then
		endSession()
	elseif buttonName == "left" then

	elseif buttonName == "back" then
		selectorFrame:visible(false)
		menuFrame:visible(true)
	elseif buttonName == "right" then

	end
end

-- set screen size
old_res_x, old_res_y = gpu.getResolution()
gpu.setResolution(26, 13)

-- menues and setup
cardWaitFrame:backgroundColor(0xffffff)
yawl.widget.Image(cardWaitFrame, 9, 4, "/usr/share/bank_atm/floppy8x8.pam")

balanceText:maxWidth(26)
balanceText:maxHeight(1)
local UUIDText = yawl.widget.Text(menuFrame, 1, 3, "UUID: 123-abc", 0xffffff)
UUIDText:maxWidth(26)
UUIDText:maxHeight(1)
local sendButton = yawl.widget.Rectangle(menuFrame, 1, 5, 3, 2, 0xffffff)
sendButton:callback(buttonHandler("send"))
local sendText = yawl.widget.Text(menuFrame, 4, 6, "SEND", 0xffffff)
sendText:maxWidth(8)
sendText:maxHeight(1)
local ejectButton = yawl.widget.Rectangle(menuFrame, 1, 11, 3, 2, 0xffffff)
ejectButton:callback(buttonHandler("eject"))
local ejectText = yawl.widget.Text(menuFrame, 4, 12, "EXIT", 0xffffff)
ejectText:maxWidth(8)
ejectText:maxHeight(1)

local leftButton = yawl.widget.Rectangle(selectorFrame, 7, 13, 2, 1, 0xffffff)
leftButton:callback(buttonHandler("left"))
local leftButtonText = yawl.widget.Text(selectorFrame, 7, 13, "<", 0x000000)
leftButtonText:maxWidth(1)
leftButtonText:maxHeight(1)
local backButton = yawl.widget.Rectangle(selectorFrame, 10, 13, 7, 1, 0xffffff)
backButton:callback(buttonHandler("back"))
local backButtonText = yawl.widget.Text(selectorFrame, 11, 13, "GO BACK", 0x000000)
backButtonText:maxWidth(7)
backButtonText:maxHeight(1)
local rightButton = yawl.widget.Rectangle(selectorFrame, 18, 13, 2, 1, 0xffffff)
rightButton:callback(buttonHandler("right"))
local rightButtonText = yawl.widget.Text(selectorFrame, 19, 13, ">", 0x000000)
rightButtonText:maxWidth(1)
rightButtonText:maxHeight(1)
local listFrame = yawl.widget.Frame(selectorFrame)
listFrame:height(12)

-- show the correct one first
selectorFrame:visible(false)
menuFrame:visible(false)

-- for testing on emulator without movable card
cardWaitFrame:visible(false)
menuFrame:visible(true)

local function componentAddedHandler()
	
end

local function driveEjectedHandler()
	
end

local function magDataHandler()
	
end

-- events
event_drive = event.listen("component_added", componentAddedHandler)
event_eject = event.listen("component_unavailable", driveEjectedHandler)
event_magData = event.listen("magData", magDataHandler)
event.listen("interrupted", closeClient)

while run do
	root:draw()
	os.sleep()
end
closeClient()

--[[

I gave up on gui

I will come back to it later

thats why the text based exists

]]