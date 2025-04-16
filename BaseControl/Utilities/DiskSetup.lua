-- does both modules and server
--[[



]]

local term = require("term")
local fs = require("filesystem")

local path = ""
local confirmed = false

repeat
	term.clear()
	print("Please enter disk path:")
	path = io.read()

	if fs.isDirectory(path) then
		local ans = ""
		repeat
			term.clear()
			print("Is this path correct? (Y/N)")
		until string.lower(ans) == "y" or string.lower(ans) == "yes" or string.lower(ans) == "n" or string.lower(ans) == "no"

		if string.lower(ans) == "y" or string.lower(ans) == "yes" then
			confirmed = true
		end
	else
		print("Path not found.")
		os.sleep(5)
	end
until confirmed

term.clear()
pritn("Please wait, moving files.")
print("DO NOT TOUCH ANYTHING, KEEP COMPUTER RUNNING")

