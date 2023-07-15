data = require("component").data
shell = require("shell")

keyPath = "/.key.txt"
oldKeysPath = "/.oldKeys.txt"
tmpPath = "/.tmp.txt"

arg = {...}

function help()
	print("Usage: cryption [option: key, encrypt, decrypt, clear]")
	print("key: Generate a key used for encryption and decryption (cryption key)")
	print("encrypt: Encrypt a file, no directories (cryption encrypt " .. '"' .. "/some/file/path" .. '"' .. ")")
	print("decrypt: Decrypt an encrypted file no directories (cryption decrypt " .. '"' .. "/some/file/path" .. '"' .. ")")
	print("clear: Clear the tmp file. be careful, if the file is messed up this is the only backup of sorts made by this program (cryption clear)")
end

function key()
	-- Check if the key file exists
	local file = io.open(keyPath, "r")
	if file then
		local key = file:read("*all")
		file:close()

		-- Check if the oldKeys file exists
		local file2 = io.open(oldKeysPath, "a")
		if file2 then
			-- Put the old key in oldKeys if there is a key
			if key then
				file2:write(key .. "\n")
			end
			file2:close()
		else
			-- If the oldKeys file doesn't exist, create it and add the key if there is one
			file2 = io.open(oldKeysPath, "w")
			if key then
				file2:write(key .. "\n")
			end
			file2:close()
		end
	end

	-- Generate a new key and write it to the file
	local newKey = data.random(16)
	local keyFile = io.open(keyPath, "w")
	keyFile:write(newKey)
	keyFile:close()
end

function processFile(mode)
    if arg[2] == nil then
        print("No specified path")
        os.exit()
    end

    local keyFile = io.open(keyPath, "r")
    if not keyFile then
        print("No key, please get the key used to encrypt and put it in a file called key.txt in root (" .. '"' .. "/key.txt" .. '"' .. ")")
        os.exit()
    end

    local key = keyFile:read("*all")
    keyFile:close()

    if key == nil then
        print("Key is empty, please get the key used to encrypt and put it in a file called key.txt in root (".. '"' .. "/key.txt" .. '"' .. ")")
        os.exit()
    end

    -- Copy the file contents to the temporary file
    local tempFile = io.open(tmpPath, "w")
    tempFile:write(io.open(arg[2], "r"):read("*all"))
    tempFile:close()

    -- Read the file contents
    local fileContent = io.open(arg[2], "r"):read("*all")

    -- Process based on the specified mode
    local processedData
    if mode == "encrypt" then
        processedData = data.encrypt(fileContent, key, key)
    elseif mode == "decrypt" then
        processedData = data.decrypt(fileContent, key, key)
    else
        print("Invalid mode specified")
        os.exit()
    end

    -- Write the processed data to the file
    local targetFile = io.open(arg[2], "w")
    targetFile:write(processedData)
    targetFile:close()

    local action = mode == "encrypt" and "encrypted" or "decrypted"
    print("File " .. action .. ". You can clear /tmp.txt manually or with the clear option.")
end

function clear()
	io.open("/tmp.txt", "w"):close()
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