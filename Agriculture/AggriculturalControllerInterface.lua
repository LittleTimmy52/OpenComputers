local modem = require("component").modem
local event = require("event")
local term = require("term")
local serialization = require("serialization")
local gpu = require("component").gpu

local infoChart = {}	-- name:items it controlls:signal:status:limit (string:table:table:table:table)
local recieved = false
local stop = false
local run = true
local width, height = gpu.getResolution()

local port = 2025
local timeOut = 2
local iterationLimit = 15

-- load conf
local conf = io.open("/etc/AggriculturalController/AggriculturalControllerInterface.cfg", "r")
if conf then
	for line in conf:lines() do
		local k, v = line:match("^(%w+)%s*=%s*(%S+)$")
		if k == "port" then
			port = tonumber(v)
		elseif k == "timeOut" then
			timeOut = tonumber(v)
		elseif k == "iterationLimit" then
			iterationLimit = tonumber(v)
		end
	end

	conf:close()
else
	conf = io.open("/etc/AggriculturalController/AggriculturalControllerInterface.cfg", "w")
	conf:write("port=2025\ntimeOut=2\niterationLimit=15\nuseData=true")	-- useData is for the remote rc but they use the same config
	conf:close()
end

modem.open(port)

while not stop do
	local status = pcall(function()
		-- menues
		local function mainMenu()
			term.clear()
			print("Main menu:")
			print("[1] Get information")
			print("[2] Manual toggle")
			print("[3] Manual reset")
			print("[4] Manual update")
			print("[5] Help")
			print("[6] Exit program")
		end

		local function getInfo()
			infoChart = nil
			local iteration = -1
			term.clear()
			recieved = false
			while not recieved and iteration < iterationLimit do
				modem.broadcast(port, "getInfo")
				local _, _, _, _, _, msg = event.pull("modem_message", timeOut)

				if string.find(msg, "info-") then
					recieved = true
					tmp = string.gmatch(msg, "([^-]+)")
					infoChart = serialization.unserialize(tmp[2])
				end

				iteration = iteration + 1
			end

			local function printTableWithPages(tab)
				local lines = 0
				for k, v in ipairs(tab) do
					local line = k .. ": " .. v
					local linesNeeded = line.len() / width
					local linesLeft = (height - lines) - 1

					if linesLeft > linesNeeded then
						print(line)
						lines = lines + linesNeeded
					else
						print("Press any to continue")
						local continue = true
						while continue do
							local _, _, _, pn = event.pull("key_down", timeOut)
							if pn ~= nil then
								continue = false
							end

							os.sleep(0)
						end

						term.clear()
						print(line)
						lines = 1
					end
				end

				print("Press any to continue")
				local continue = true
				while continue do
					local _, _, _, pn = event.pull("key_down", timeOut)
					if pn ~= nil then
						continue = false
					end

					os.sleep(0)
				end
			end

			if infoChart ~= nil then
				repeat
					term.clear()
					print("Information:")
					print("[1] Microcontroller names")
					print("[2] Items controlled")
					print("[3] Signal assignments")
					print("[4] Status")
					print("[5] Limit")
					print("[6] Main menu")
					choice = tonumber(io.read())
				until choice ~= nil and choice > 0 and choice < 7

				if choice == 1 then
					local lines = 0
					for k, v in ipairs(infoChart) do
						local line = k .. ": " .. v[1]
						local linesNeeded = line.len() / width
						local linesLeft = (height - lines) - 1

						if linesLeft > linesNeeded then
							print(line)
							lines = lines + linesNeeded
						else
							print("Press any to continue")
							local continue = true
							while continue do
								local _, _, _, pn = event.pull("key_down", timeOut)
								if pn ~= nil then
									continue = false
								end

								os.sleep(0)
							end

							term.clear()
							print(line)
							lines = 1
						end
					end

					print("Press any to continue")
					local continue = true
					while continue do
						local _, _, _, pn = event.pull("key_down", timeOut)
						if pn ~= nil then
							continue = false
						end

						os.sleep(0)
					end
				elseif choice == 2 then
					local index = nil
					repeat
						term.clear()
						print("Enter microcontroller index (in option 1)")
						index = tonumber(io.read())
					until index ~= nil and index > 0 and index < #infoChart + 1
					
					printTableWithPages(infoChart[index][2])
				elseif choice == 3 then
					local index = nil
					repeat
						term.clear()
						print("Enter microcontroller index (in option 1)")
						index = tonumber(io.read())
					until index ~= nil and index > 0 and index < #infoChart + 1
				
					printTableWithPages(infoChart[index][3])
				elseif choice == 4 then
					local index = nil
					repeat
						term.clear()
						print("Enter microcontroller index (in option 1)")
						index = tonumber(io.read())
					until index ~= nil and index > 0 and index < #infoChart + 1
				
					printTableWithPages(infoChart[index][4])
				elseif choice == 5 then
					local index = nil
					repeat
						term.clear()
						print("Enter microcontroller index (in option 1)")
						index = tonumber(io.read())
					until index ~= nil and index > 0 and index < #infoChart + 1
				
					printTableWithPages(infoChart[index][5])
				end
			else
				print("Could not reach the controller server (timed out, limit reached)")
				os.sleep(5)
			end
		end

		local function manToggle()
			term.clear()
			
		end

		local function manReset()

		end

		local function manUpdate()

		end

		local function help()

		end

		local function main()
			local choice
			repeat
				mainMenu()
				choice = tonumber(io.read())
			until choice ~= nil and choice > 0 and choice < 7

			if choice == 1 then
				getInfo()
			elseif choice == 2 then
				manToggle()
			elseif choice == 3 then
				manReset()
			elseif choice == 4 then
				manUpdate()
			elseif choice == 5 then
				help()
			else if choice == 6 then
				term.clear()
				stop = true
				break
			end
		end

		local function start()
			while run do
				main()
				os.sleep(0)
			end

			-- for restarting purposes
			run = true
			start()
		end

		start()
	end)

	if not status then os.sleep(0) end
end