local libCB = require("libCB")
local bank = require("bank_api")
local event = require("event")
local term = require("term")
local component = require("component")
local proxy =  component.proxy

local run = true
local stop = false

local uuids = {}
local uuidNames = {}

-- defaults
local uuidPath = "/.uuids.txt"
local adminPassword = "123456789"

-- load conf
local conf = io.open("/etc/BankTransfer/BankTransfer.cfg", "r")
if conf then
	for line in conf:lines() do
		local k, v = line:match("^(%w+)%s*=%s*(%S+)$")
		if k == "uuidPath" then
			uuidPath = v
		elseif k == "adminPassword" then
			adminPassword = v
		end
	end

	conf:close()
else
	conf = io.open("/etc/BankTransfer/BankTransfer.cfg", "w")
	conf:write("uuidPath=/.uuids.txt\nadminPassword=123456789")
	conf:close()
end

while not stop do
	local status = pcall(function()
		local function optionsMenu()
			term.clear()
			print("Please select one of the options:")
			print("1: Register for transfering and recieving.")
			print("2: See account data.")
			print("3: Send money.")
			print("4: Exit program.")
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

			local exists = false
			for k, v in ipairs(uuids) do
				if v == cbData.uuid then
					exists = true
					break
				end
			end

			if not exists then
				print("Please enter your display name (You can't change this):")
				local name = string.gsub(io.read(), "\n", "")
				local duplicate = false
				for k, v in ipairs(uuidNames) do
					if v == name then
						duplicate = true
					end
				end

				if duplicate then
					print("Your display name is taken, part of your uuid will be added to it")
					name = name .. " (" .. string.sub(cbData.uuid, 1, 4) .. ")"
				end

				uuids[#uuids+1] = cbData.uuid
				uuidNames[#uuidNames+1] = name

				-- save list
				local file = io.open(uuidPath, "w")
				for k, v in ipairs(uuids) do
					file:write(uuidNames[k] .. ":" .. v .. "\n")
				end

				file:close()

				-- notify the user
				term.clear()
				print("Your account is registered already")
				os.sleep(2)
			else
				print("Your account is registered already")
				os.sleep(2)
			end
		end

		local function getData()
			local cbData = nil
			while cbData == nil do
				cbData = getAccountData()
				if cbData == nil then
					print("ERROR: INCORRECT PIN!!!")
					os.sleep(5)
				end
			end

			local _, bal = bank.getCredit(cbData)
			print("Your balance is: " .. bal)
			print("Your uuid is: " .. cbData.uuid)
			local uuidIndex
			for k, v in ipairs(uuids) do
				if v == cbData.uuid then
					uuidIndex = k
				end
			end
			print("Registered under: ".. uuidNames[uuidIndex])
			print("Press anything to close.")
			event.pull("key_down")
		end

		local function send()
			local cbData = nil
			while cbData == nil do
				cbData = getAccountData()
				if cbData == nil then
					print("ERROR: INCORRECT PIN!!!")
					os.sleep(5)
				end
			end

			-- setup pages
			local pageSize = 10
			local currentPage = 1
			local totalPages = math.ceil(#uuidNames / pageSize)

			local function printPage(page)
				term.clear()
				local startIndex = (page - 1) * pageSize + 1
				local endIndex = math.min(startIndex + pageSize - 1, #uuidNames)
				
				for i = startIndex, endIndex do
					print(i .. ". " .. uuidNames[i])
				end
			end

			local function handleInput()
				while true do
					print("Page " .. currentPage .. " of " .. totalPages)
					printPage(currentPage)
					
					print("Enter 'exit' to exit, 'next' for next page, 'previous' for previous page, or a number to select an item:")
					local input = io.read()

					if input == "exit" then 
						term.clear()
						break
					elseif input == "next" then
						if currentPage < totalPages then
							currentPage = currentPage + 1
						else
							print("You are already on the last page.")
						end
					elseif input == "previous" then
						if currentPage > 1 then
							currentPage = currentPage - 1
						else
							print("You are already on the first page.")
						end
					elseif tonumber(input) then
						local itemNum = tonumber(input)
						if itemNum >= 1 and itemNum <= #uuidNames then
							local answer = ""
							repeat
								term.clear()
								print("You selected " .. itemNum .. ": " .. uuidNames[itemNum] .. "\nIs this correct?")
								answer = io.read()
							until string.lower(answer) == "yes" or string.lower(answer) == "y" or string.lower(answer) == "no" or string.lower(answer) == "n"

							if string.lower(answer) == "yes" or string.lower(answer) == "y" then
								local amount = 0
								repeat
									term.clear()
									print("Please enter how much you wish to send:")
									amount = tonumber(io.read())
								until amount > 0 and math.floor(amount) == amount

								repeat
									term.clear()
									print("You wish to send " .. amount .. ". Is this correct?")
									answer = io.read()
								until string.lower(answer) == "yes" or string.lower(answer) == "y" or string.lower(answer) == "no" or string.lower(answer) == "n"
			
								if string.lower(answer) == "yes" or string.lower(answer) == "y" then
									local _, bal = bank.getCredit(cbData)
									if amount > bal then
										print("Insufficent funds.")
										os.sleep(2)
										term.clear()
									else
										bank.makeTransaction(uuids[itemNum], cbData, amount)
									end
								else
									handleInput()
								end
							end
						else
							print("Invalid item number.")
							handleInput()
						end
					else
						term.clear()
					end
				end
			end

			handleInput()
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
			until choice ~= nil and choice > 0 and choice < 5

			if choice == 1 then
				register()
			elseif choice == 2 then
				getData()
			elseif choice == 3 then
				send()
			elseif choice == 4 then
				exitProgram()
			end
		end

		local function start()
			-- load the uuids
			local file = io.open(uuidPath, "r")
			if not file then
				io.open(uuidPath, "w"):close()
			else
				for line in file:lines() do
					local name, uuid = line:match("^(.*):(.*)$")
					if name and uuid then
						uuidNames[#uuidNames+1] = name
						uuids[#uuids+1] = uuid
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

	if not status then os.sleep(0) end
end