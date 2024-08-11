local libCB = require("libCB")
local bank = require("bank_api")
local event = require("event")
local term = require("term")
local component = require("component")
local serialization = require("serialization")
local proxy =  component.proxy

local run = true
local stop = false

-- defaults
local adminPassword = "123456789"
local dataPath = "/.data.txt"
local doorControllerUUIDs = {}

-- load config
local conf = io.open("/etc/BankVault/BankVault.cfg", "r")
if conf then
	for line in conf:lines() do
		local k, v = line:match("^(%w+)%s*=%s*(%S+)$")
		if k == "adminPassword" then
			adminPassword = v
		elseif k == "dataPath" then
			dataPath = v
		elseif k == "doorControllerUUIDs" then
			doorControllerUUIDs = serialization.unserialize(v)
		end
	end
else
	conf = io.open("/etc/BankVault/BankVault.cfg", "w")
	conf:write("adminPassword=123456789\ndataPath=/.data.txt\ndoorControllerUUIDs={}")
	conf:close()
end

local data = {{}}

while not stop do
	local status = pcall(function()
		local function optionsMenu()
			term.clear()
			print("Please select one of the options:")
			print("1: Register account with vault.")
			print("2: Open vault.")
			print("3: Close vault.")
			print("4: Unregister vault.")
			print("5: Admin open.")
			print("6: Admin close.")
			print("7: Exit program.")
		end

		local function getPin()
			local pin = ""
			while true do
				local _, _, char, _ = event.pull("key_down")
				if char == 13 then
					break
				elseif char >= 32 and char <= 126 then
					pin = pin .. string.char(char)
					term.write("*")
				elseif char == 8 then
					if #pin > 0 then
						pin = pin:sub(1, -2)
						local x, y = term.getCursor()
						term.setCursor(x - 1, y)
						term.write(" ")
						term.setCursor(x - 1, y)
					end
				end
			end
			return pin
		end

		local function getAccountData()
			term.clear()

			print("Please insert or swipe card:")
			local address = nil

			-- events
			event.listen("component_added", function(_, addr, compType) 
				if compType == "drive" then
					address = addr
				end
			end)
			event.listen("component_unavailable", function (_, compType)
				if compType == "drive" then
					run = false
				end
			end)
			event.listen("magData", function(_, addr, ...) 
				address = addr
			end)

			while address == nil do
				os.sleep()
			end

			-- get pin
			print("Please enter your pin")
			local pin = getPin()
			print("")

			return libCB.getCB(libCB.loadCB(proxy(address)), pin)
		end

		local function register()
			local cbData = nil
			while cbData == nil do
				cbData = getAccountData()
				if cbData == nil then
					print("ERROR: INCORRECT PIN!!!")
					os.sleep(5)
				end
			end

			print("Enter the admin password:")
			local pin = getPin()

			-- get user to select an open vault
			if pin == adminPassword then
				local choice
				local validChoice = false
				repeat
					term.clear()
					local avaliable = {}
					for _, v in ipairs(data) do
						if v[2] == "nil" then
							avaliable.insert(v[3])
						end
					end

					print("Please choose from the avaliable vaults:")
					for _, v in ipairs(avaliable) do
						print("vault: " .. v)
					end

					choice = tonumber(io.read())

					-- check if their input is valid
					for _, v in ipairs(avaliable) do
						if choice == v then
							validChoice = true
							break
						end
					end
				until validChoice == true

				-- save this to the list
				for k, v in ipairs(data) do
					if v[3] == choice then
						data[k][2] = cbData.uuid
						break
					end
				end

				-- save the updated list to file
				local file = io.open(dataPath, "w")
				for _, v in ipairs(data) do
					file:write(v[1] .. ":" .. v[2] .. ":" .. v[3])
				end

				file:close()
			end
		end

		local function doorCont(operation)
			local cbData = nil
			while cbData == nil do
				cbData = getAccountData()
				if cbData == nil then
					print("ERROR: INCORRECT PIN!!!")
					os.sleep(5)
				end
			end

			-- find the users data
			local usrDat = {}
			for _, v in ipairs(data) do
				if v[2] == cbData.uuid then
					usrDat = v
					break
				end
			end

			if usrDat ~= {} then
				local vaultDoor = component.proxy(usrDat[1])
				if operation == "open" then
					vaultDoor.open()
				elseif operation == "close" then
					vaultDoor.close()
				end
			else
				print("You do not have a vault.")
				os.sleep(5)
			end
		end
		
		local function unregister()
			term.clear()
			print("Enter the admin password:")
			local pin = getPin()
			if pin == adminPassword then
				local choice
				local ans
				repeat
					term.clear()
					print("Enter the number of the vault to unregister:")
					choice = tonumber(io.read())

					-- confirm choice
					term.clear()
					print("Is " .. choice .. " correct?")
					ans = io.read()
				until choice ~= nil and choice > 0 and choice < #data + 1 and (string.lower(ans) == "yes" or string.lower(ans) == "y")

				-- save this to the list
				for k, v in ipairs(data) do
					if v[3] == choice then
						data[k][2] = "nil"
						break
					end
				end

				-- save the updated list to file
				local file = io.open(dataPath, "w")
				for _, v in ipairs(data) do
					file:write(v[1] .. ":" .. v[2] .. ":" .. v[3])
				end

				file:close()
			end
		end

		local function adminDoorCont(operation)
			term.clear()
			print("Enter the admin password:")
			local pin = getPin()
			if pin == adminPassword then
				local choice
				local ans
				repeat
					term.clear()
					print("Enter the number of the vault to " .. operation .. ":")
					choice = tonumber(io.read())

					-- confirm choice
					term.clear()
					print("Is " .. choice .. " correct?")
					ans = io.read()
				until choice ~= nil and choice > 0 and choice < #data + 1 and (string.lower(ans) == "yes" or string.lower(ans) == "y")

				-- find the users data
				local usrDat = {}
				for _, v in ipairs(data) do
					if v[3] == choice then
						usrDat = v
						break
					end
				end

				if usrDat ~= {} then
					local vaultDoor = component.proxy(usrDat[1])
					if operation == "open" then
						vaultDoor.open()
					elseif operation == "close" then
						vaultDoor.close()
					end
				end
			end
		end

		local function exitProgram()
			term.clear()
			print("Enter the admin password:")
			local pin = getPin()
			if pin == adminPassword then
				stop = true
				os.exit()
			end
		end

		local function main()
			local choice
			repeat
				optionsMenu()
				choice = tonumber(io.read())
			until choice ~= nil and choice > 0 and choice < 8

			if choice == 1 then
				register()
			elseif choice == 2 then
				doorCont("open")
			elseif choice == 3 then
				doorCont("close")
			elseif choice == 4 then
				unregister()
			elseif choice == 5 then
				adminDoorCont("open")
			elseif choice == 6 then
				adminDoorCont("close")
			elseif choice == 7 then
				exitProgram()
			end
		end

		local function start()
			-- load the data
			local file = io.open(dataPath, "r")
			if not file then
				file = io.open(dataPath, "w")
				for k, v in ipairs(doorControllerUUIDs) do
					file:write(v .. ":nil:" .. tostring(k) .. "\n")
					data[#data+1] = {v, "nil", k}
				end

				file:close()
			else
				for line in file:lines() do
					local doorUUID, actUUID, num = line:match("^(.*):(.*):(%d+)$")
					if doorUUID and actUUID and num then
						data[#data+1] = {doorUUID, actUUID, num}
					end
				end
			end

			while run do
				main()
				os.sleep()
			end

			-- for restarting purposes
			run = true
			start()
		end

		start()
	end)

	if not status then os.sleep() end
end