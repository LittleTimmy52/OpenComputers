# Security
## purpose
This is a collection of my very simple security door scripts for the OpenSecurity mod for OpenComputers.

Note: As of making this readme, all doors need their own computer, this may cause lagg for using a lot of doors.
Note: As of making this readme none of thies use encryption.

## What I have
### MagCard

This reads the data off a magnetic card, comapirs it to the data in the code, if it matches the door opens, if not it stays closed.
To set the data nessicary to open, simply open the file and change the local correctData to the data that you want to be on the card
to open the door. To have multipal unique card data to work, simply add or cardData == other variable you add that has the data you
want to open the door.

Ex:

card1 contains "1234" and card2 contains "abcd"

local correctData = "1234" then

if cardData == correct data
code to open and close door
end

card1 can open the door but card to can not. To make both work do:

local correctData1 = "1234"
local correctData2 = "abcd"

if cardData == correctData1 or cardData == correctData2 then
code to open and close door
end

### Keypad

This reads input from a keypad and opens the door if the correct pin is inputed. To change the pin simply change the local correctPin
to the pin you want to open the door.
To work with rolldoor change the doorcontroller to rolldoorcontroller in line 3 and increase the variable called delay.