RedstoneSwitch - for microcontroller eeprom
AggriculturalController - for controlling the process

AggCont lookes at refined storage and compairs it to a chart (thats loaded at boot), if whatever item is below the value it turns it off, exceeding turns it on, should have some sort of delay to compensate for redstone, and should have some check to ensure it actually turned on. the switch neds to emmit a pulse of a signal stregnth that then goes to a signal decoder to get an output to toggle the farm. there should be some startup identification for the microcontrollers, like server does rolecall and tthe microcontrollers say their name and what items they controll then the server can know what it has and what to turn on


test


make an actual nice readme