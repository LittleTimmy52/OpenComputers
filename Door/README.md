# Door
## Purpose
In simple words this is just a remote door opening program that puts good use to microcontrollers

## What I have
### Door
This is the program to open and close doors

Door \<option: open, close, list, config, setupInfo> \<option: door>

### DoorControl
This is the program to be flashed to an EEPROM to run the microcontroller

## Setup info
Microcontroller: T1 redstone card, T1 wireless network card, T1 ram, T1 CPU, and sign upgrade. Note this is the bare minimum, use
whatever tier you like.

Tablet (recomended) or computer: T1 wireless network card, T1 ram, T1 CPU. Note this is the bare minimum, use whatever tier you
like.

Microcontroller setup: Flash DoorControl to the EEPROM and insert it into the microcontroller. the signal comes from the back and a
sign needs to be placed on the front which says the port on top and the door name on the next line example is 808 followed by door1.

Tablet (recomended) or computer setup: Run Door config to generate the default config file then run it again to edit it.

## To do
Wiki entry