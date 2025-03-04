local modem = require("component").modem
local event = require("event")
local term = require("term")
local serialization = require("serialization")
local gpu = require("component").gpu
local data = require("component").data

local infoChart = {}	-- name:items it controlls:signal:status:limit (string:table:table:table:table)
local stop = false
local run = true
local width, height = gpu.getResolution()

local port = 1234
local timeOut = 10
local iterationLimit = 15
local password = "SecurePresharedPassword"

--[[
	This is a sample only, if you wish to use  it please set the values, its not going to be as fancy

	This is basically a copy paste of the regular interface but modified without any compensation for loss

	Please consider implementing your own better way as this is an example
]]

local function encrypt(decryptedData, password)
	local key = data.md5(password)
	local iv = data.random(16)
	local encryptedData = data.encrypt(decryptedData, key, iv)
	return serialization.serialize({encrypted = encryptedData, iv = iv})
end

local function decrypt(encryptedData, password)
	local key = data.md5(password)
	local decoded = serialization.unserialize(encryptedData)
	return serialization.unserialize(data.decrypt(decoded.encrypted, key, decoded.iv))
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
			term.clear()
			local iteration = -1
			local recieved = false

			-- loop to get the chart lest it fails then you get a message
			while not recieved and iteration < iterationLimit do
				modem.broadcast(port, encrypt("g"))
				local _, _, _, _, _, msg = event.pull("modem_message", timeOut)
				msg = decrypt(msg)

				if msg == "info" then
					recieved = true
				end

				iteration = iteration + 1
			end

			local go = recieved
			local packetErr = false
			local packets = {}

			-- if it was recieved, now we wait for the packets
			while go do
				local _, _, _, _, _, msg = event.pull("modem_message", timeOut)
				msg = decrypt(msg)
				if msg == nil then
					recieved = false
					packetErr = true
					break
				else
					-- stop once we get the final packet
					if msg == string.find("info-") then
						go = false
						-- if we got all packets stich it all together
						if #packet == string.match(msg, "([^-]+)")[2] then
							local preData = ""
							for _,v in ipairs(packets) do
								preData = preData .. v
							end

							infoChart = serialization.unserialize(preData)
						else
							recieved = false
							packetErr = true
						end
					else
						table.insert(packets, msg)
					end
				end
			end

			local function printTableWithPages(tab, first)
				print(first)
				local lines = 1
				for k, v in ipairs(tab) do
					local line = k .. ": " .. v
					local linesNeeded = string.len(line) / width
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

			if recieved then
				local choice
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

				term.clear()

				if choice == 1 then
					print("Names:")
					local lines = 1
					for k, v in ipairs(infoChart) do
						local line = k .. ": " .. v[1]
						local linesNeeded = string.len(line) / width
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
					
					printTableWithPages(infoChart[index][2], "Items:")
				elseif choice == 3 then
					local index = nil
					repeat
						term.clear()
						print("Enter microcontroller index (in option 1)")
						index = tonumber(io.read())
					until index ~= nil and index > 0 and index < #infoChart + 1
				
					printTableWithPages(infoChart[index][3], "Signal:")
				elseif choice == 4 then
					local index = nil
					repeat
						term.clear()
						print("Enter microcontroller index (in option 1)")
						index = tonumber(io.read())
					until index ~= nil and index > 0 and index < #infoChart + 1
				
					printTableWithPages(infoChart[index][4], "Status:")
				elseif choice == 5 then
					local index = nil
					repeat
						term.clear()
						print("Enter microcontroller index (in option 1)")
						index = tonumber(io.read())
					until index ~= nil and index > 0 and index < #infoChart + 1
				
					printTableWithPages(infoChart[index][5], "Limit:")
				end
			else
				if packetErr then
					print("Packets were not recieved properly, please check all connections.")
					os.sleep(5)
				else
					print("Could not reach the controller server (timed out, limit reached).")
					os.sleep(5)
				end
			end
		end

		local function manToggle()
			local index = nil
			local signal = nil
			repeat
				term.clear()
				print("Enter microcontroller index (in option 1 of \"Get information\")")
				index = tonumber(io.read())
			until index ~= nil and index > 0 and index < #infoChart + 1

			repeat
				term.clear()
				print("Enter the signal value (1-15)")
				signal = tonumber(io.read())
			until signal ~= nil and signal > 0 and signal < 16
			
			modem.broadcast(port, encrypt("t-" .. infoChart[index][1] .. "-" .. tostring(signal)))
		end

		local function manReset()
			modem.broadcast(port, encrypt("r"))
		end

		local function manUpdate()
			lmodem.broadcast(port, encrypt("u"))
		end

		local function help()
			local helpList = {
				"Main menu:",
				"[1] Get information:",
				"Takes you to a sub menu to provide you the specified information.",
				"[2] Manual toggle:",
				"Askes you for the index of the microcontroller and the signal stregnth of the desired output and tells that microcontroller to send that",
				"redstone signal stregnth to toggle the item assigned to that signal.",
				"\"[1] Microcontroller names\" of \"[1] Get information\" provides the index.",
				"[3] Manual reset:",
				"Pulses a redstone signal to the back of the host which should be wired up in a way such that it turnns everything off",
				"[4] Manual update:",
				"Tells the server to update its item list.",
				"[5] Help:",
				"Takes you to this very page.",
				"[6] Exit program:",
				"Closes the program so you can do whatever you need to do on the device this is on.",
				"Information:",
				"[1] Microcontroller names:",
				"Takes you through a list of names with the index (This is what was refered to when askinbg for index).",
				"[2] Items controlled:",
				"Askes for the index of the microcontroller you wish to view and lists the different item oreDict names with their index.",
				"Note that this index is so you know what is assigned to what. For instance at index 1 is minecraft:dirt, in the other menu options say",
				"\"[3] Signal assignments\" at index 1 is signal stregnth 1, therefore minecraft:dirt was assigned a signal of 1.",
				"[3] Signal assignments:",
				"Askes for the index of the microcontroller you wish to view and lists the different signal assignments with their index.",
				"Note that the reason for the index is the same as \"[2] Items controlled\".",
				"[4] Status:",
				"Askes for the index of the microcontroller you wish to view and lists the different item statuses with their index.",
				"Note that the reason for the index is the same as \"[2] Items controlled\".",
				"[5] Limit:",
				"Askes for the index of the microcontroller you wish to view and lists the different item limits with their index.",
				"Note that the reason for the index is the same as \"[2] Items controlled\".",
				"[6] Main menu:",
				"Takes you back to the main menu."
			}

			print("Help:")
			local lines = 1
			for k, v in ipairs(helpList) do
				local line = k .. ": " .. v
				local linesNeeded = string.len(line) / width
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
			elseif choice == 6 then
				term.clear()
				stop = true
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