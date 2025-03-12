local data = require("component").data

local tmpPath = "/tmp/.tmp.txt"

local arg = {...}

local function help()
	print("This is a simple encryption and decryption program for the tier 1 data card. I am not liable for any data loss due to misuse, nor am I liable for data leaaks, just be responsible")
	print("Usage: CryptionT1 <option: encrypt, decrypt, clear, help> <option: path>")
	print("encrypt: Encrypt a file, no directories. CryptionT1 encrypt <path>")
	print("decrypt: Decrypt an encrypted file no directories. CryptionT1 decrypt <path>")
	print("clear: Clear the tmp file. be careful, if the file is messed up this is the only backup of sorts made by this program. CryptionT1 clear")
	print("help: Display this text")
end

local function processFile(mode)
	if arg[2] == nil then
		print("No specified path")
		os.exit()
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
			file:write(data.encode64(line) .. "\n")
			os.sleep(0)
		end

		file:close()
		tmpFile:close()
	elseif mode == "decrypt" then
		tmpFile = io.open(tmpPath, "r")
		file = io.open(arg[2], "w")
		for line in tmpFile:lines() do
			file:write(data.decode64(line) .. "\n")
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
if arg[1] == "encrypt" then
	processFile("encrypt")
elseif arg[1] == "decrypt" then
	processFile("decrypt")
elseif arg[1] == "clear" then
	clear()
else
	help()
end