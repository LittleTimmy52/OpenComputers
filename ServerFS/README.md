# ServerFS

## The origonal
The origonal was made for standard OpenComputers, it can be found at https://oc.cil.li/topic/844-serverfs-host-a-filesystem-over-the-network/.

## The goal
All I wish to acheive is a server filesystem that works with GERT networking so I can have an easier, cheaper (in materials), and broader network,
that just so happens to have a server filesystem. GERT can be found here https://github.com/GlobalEmpire/GERT.

## Usage
### Host
The host script is autorun.lua and it shuld be placed in the root folder and reboot then the host shuld be setup and you shuld leave it be, unless of course you wish to
change some of the config variables.

### Client
The client script is 98_serverfilesystem.lua and it shuld be placed in the boot folder and reboot, once that is done you are good to go. To actually access it change
directory to srv which is in root (/srv) and simply use it as if it was just another folder, the only caveat being that it's slow because everything is being ran accross 
the network.

## To do
Actually make my own FS, all I did was copy it and have it here, my intent was to make my own but I never did it yet

NO THIS IS NOT MY CODE HERE I DO NOT TAKE CREDIT FOR IT
I have it here to learn from it and mekr my own hopfully better for my needs version.