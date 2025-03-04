# Aggriculture
## Purpose
The programs here are for controlling aggriculture output based on the ammounts in a refined storage
inventory system. It is intended to be a wired connection to keep the system secure as with wireless
networks are subject to interference and bad actors, I did not make any secure connection protocol to
make it hack proof. However, the server communication with the interface or other systems will be.

### Note
This program set is intended to be installed all at once on a seperate computer and then from there,
copied to whatever devices they are needed on.

## RedstoneSwitch
This is an EEPROM program designed for a tier 1 microcontroller with a network and redstone card.
It will take a rolecall and toggle command, if toggle is called it pulses a specific signal to the
back to be used in a signal decoder. To set it up, before flashing the bios, you need to edit
itemsControlled to reflect the items it will controll in the format of itemname-signal-limit os
for example minecraft:dirt-1-1000 dirt is assigned to a redstone stregnth of 1 and its item limit is
1000. Then after that place a sign on the front with the name then on the next line the port.
Names for the microcontroller must be unique or issues may arise

## AggriculturalController
This program is a program designed to be placed on a T1 server. To set it up, just install it
and edit the config to your liking, You need a network card, and redstone card, all
the other components can be whatever level you wish. This is the brain of the system, it holds the
logic, it looks at the refined storage inventory and automatically turns on and off the items flowing
in based on the given data from the microcontrollers rolecall, this is why it is imperitive to set up
the controllers perfectly or issues may arise. This is designed to be wired into the microcontrollers
and the back connected via redstone to the toggle mechanism to reset everything physically.

### AggriculturalControllerInterface
This is an interface program for the controller as the name suggests, it is meant to run on either a
tier 3 computer or tier 2 server because of the tier 3 data card, but thats configurable in the config.
Given the autanomus nature of the controller, you cant manually do anything, so using its event driven
command chain, this program just tells the server to do what you want it to. You can force a reset,
manually toggle an item, manually update the item quantities list, and get all the information the
controller has on each item and what have you. Setup is the same as the controller but, you dont need
a redstone card, and you need a tier 3 datacard. Additionally this interface acts as a bridge to let
a wireless device talk to the controller, thats whats the data card for, secure messaging if you do
not want to physically be where the interface is to controll it, like on a tablet or such.

### RemoteInterfaceRelay
This is the rc that does exactly the above, just in the background and instead of using keys it uses
modem messages. This is the reason for the data card.

### SampleRemoteInterface
This is a basic example script on remotely controlling the controller.