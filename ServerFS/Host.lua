local modem = require("component").modem
local data = require("component").data
local event = require("event")
local fs = require("filesystem")

local function processModem(_, _, _, _, _, msg)
	if msg == "list" or msg == "ls" then
		fs.list()
	end
end

event.listen("modem_messsage", processModem())



--[[
clearly not done
please work on it more
]]