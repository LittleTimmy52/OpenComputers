local component = require("component")
local data = component.data

local keyPath = "/.key.txt"
local oldKeysPath = "/.oldKeys.txt"
local tmpPath = "/tmp/.tmp.txt"

local arg = {...}

local function help()
	print("This is a simple encryption and decryption program which can be used with any tier data card. I am not liable for any data loss due to misuse or key loss, nor am I liable for data leaaks, just be responsible")
	print("Usage: Cryption <option: key, encrypt, decrypt, clear, help> <option: path> <option: 1>")
	print("key: Generate a key used for encryption and decryption. Cryption key")
	print("encrypt: Encrypt a file, no directories. Cryption encrypt <path>")
	print("decrypt: Decrypt an encrypted file no directories. Cryption decrypt <path>")
	print("clear: Clear the tmp file. be careful, if the file is messed up this is the only backup of sorts made by this program. Cryption clear")
	print("The third arguement: pass a 1 to use tier 1 function when you have a tier 2.")
	print("help: Display this text")
end

local function key()
	-- check if the key file exists
	local file = io.open(keyPath, "r")
	if file then
		local key = file:read("*all")
		file:close()

		-- check if the oldKeys file exists
		local file2 = io.open(oldKeysPath, "a")
		if file2 then
			-- put the old key in oldKeys if there is a key
			if key then
				file2:write(key .. "\n")
			end
			file2:close()
		else
			-- if the oldKeys file doesn't exist, create it and add the key if there is one
			file2 = io.open(oldKeysPath, "w")
			if key then
				file2:write(key .. "\n")
			end
			file2:close()
		end
	end

	-- generate a new key and write it to the file
	local newKey = data.random(16)
	local keyFile = io.open(keyPath, "w")
	keyFile:write(newKey)
	keyFile:close()
end

local function processFile(mode)
	if arg[2] == nil then
		print("No specified path")
		os.exit()
	end

	local dataTier = 1
	if component.isAvailable("data") then
		local count = 0

		for k, v in pairs(component.methods(data.address)) do
			count = count + 1
		end

		if count > 8 then
			dataTier = 2
		end
	end

	if tonumber(arg[3]) == 1 then
		dataTier = 1
	elseif arg[3] ~= nil then
		print("Pass 1 to use tier 1 if you have a tier 2.")
		os.exit()
	end

	local key = nil

	if dataTier == 2 then
		local keyFile = io.open(keyPath, "r")

		if not keyFile then
			print("No key, generate one with the key function or put an existing key in " .. '"' .. keyPath .. '"')
			os.exit()
		end

		key = keyFile:read("*all")
		keyFile:close()

		if key == nil then
			print("Key is empty, generate one with the key function or put an existing key in ".. '"' .. keyPath .. '"')
			os.exit()
		end
	end

	-- copy the file contents to the temporary file
	local tmpFile = io.open(tmpPath, "w")
	local file = io.open(arg[2], "r")
	for line in file:lines() do
		tmpFile:write(line .. "\n")
	end
	
	tmpFile:close()
	file:close()

	-- process based on the specified mode
	if mode == "encrypt" then
		tmpFile = io.open(tmpPath, "r")
		file = io.open(arg[2], "w")
		for line in tmpFile:lines() do
			line = tostring(line)
			if dataTier == 1 then
				file:write(data.encode64(line) .. "\n")
			elseif dataTier == 2 then
				file:write(data.encode64(data.encrypt(line, key, key)) .. "\n")
			end

			os.sleep(0)
		end

		file:close()
		tmpFile:close()
	elseif mode == "decrypt" then
		tmpFile = io.open(tmpPath, "r")
		file = io.open(arg[2], "w")
		for line in tmpFile:lines() do
			if dataTier == 1 then
				file:write(data.decode64(line) .. "\n")
			else
				file:write(data.decrypt(data.decode64(line), key, key) .. "\n")
			end

			os.sleep(0)
		end

		file:close()
		tmpFile:close()
	else
		print("Invalid mode specified")
		os.exit()
	end

	local action = mode == "encrypt" and "encrypted" or "decrypted"
	print("File " .. action .. ". You can clear " .. tmpPath .. " manually or with the clear option.")
end

local function clear()
	io.open(tmpPath, "w"):close()
end

-- process args
if arg[1] == "key" then
	key()
elseif arg[1] == "encrypt" then
	processFile("encrypt")
elseif arg[1] == "decrypt" then
	processFile("decrypt")
elseif arg[1] == "clear" then
	clear()
else
	help()
end