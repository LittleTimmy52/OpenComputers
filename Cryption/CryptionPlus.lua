local component = require("component")
local computer = component.computer
local data = component.data
local shell = require("shell")

local keyPath = "/.key.txt"
local oldKeysPath = "/.oldKeys.txt"
local tmpPath = "/.tmp.txt"

local arg = {...}

local function help()
	print("This is a simple encrypttion and decryption program. I am not liable for any data loss due to misuse or key loss, nor am I liable for data leaaks, just be responsible")
	print("Usage: CryptionT2 <option: key, encrypt, decrypt, clear, help> <option: path>")
	print("key: Generate a key used for encryption and decryption. CryptionT2 key")
	print("encrypt: Encrypt a file, no directories. CryptionT2 encrypt <path>")
	print("decrypt: Decrypt an encrypted file no directories. CryptionT2 decrypt <path>")
	print("clear: Clear the tmp file. be careful, if the file is messed up this is the only backup of sorts made by this program. CryptionT2 clear")
	print("help: Display this text")
end

local function compress(path)
	if path == nil then
		print("No specified directory or file")
		os.exit()
	elseif fs.exists(path) == false then
		print("File or directory does not exist")
		os.exit()
	end

	-- Create the zip file
	local zipPath = fs.name(path) .. ".zip"
	local counter = 0

	while fs.exists(shell.getWorkingDirectory() .. "/" .. zipPath) do
		counter = counter + 1
		zipPath = fs.name(path) .. counter .. ".zip"
	end

	local file = io.open(zipPath, "w")

	-- for error handeling in for loop
	local errorCount = 0
	local notAdded = {}
	
	local function traverseDirectory(path)
		if fs.isDirectory(path) then
			-- write the directory name to the zip file
			file:write(path .. "/\n")
			
			for element in fs.list(path) do
				local elementPath = fs.concat(path, element)
				elementPath = string.gsub(elementPath, "/$", "")
	
				if fs.isDirectory(elementPath) then
					traverseDirectory(elementPath)
					print(elementPath)
				else
					-- pcall is here because very large files error out
					local success, result = pcall(function()
						if (fs.name(elementPath) ~= zipPath) or (shell.getWorkingDirectory() .. "/" .. zipPath ~= elementPath) and not ((fs.name(elementPath) ~= zipPath) and (shell.getWorkingDirectory() .. "/" .. zipPath ~= elementPath)) then
							if elementPath:match(".+/[%w/]+%..+$") ~= nil then
								-- read and compress file content
								file:write(elementPath .. "\n")

								local file2 = io.open(elementPath, "r")
								for line in file2:lines() do
									file:write(data.encode64(data.deflate(line)) .. "\n")
									os.sleep(0)
								end

								file2:close()
								print(elementPath)
							else
								table.insert(notAdded, elementPath)
							end
						end
					end)

					-- for use later to tell user what files were not compressed to zip
					if not success then
						print("Error: " .. result)
						errorCount = errorCount + 1
						table.insert(notAdded, tostring(elementPath))
					end
				end
			end
		else
			local suscess, result = pcall(function()
				if path:match(".+/[%w/]+%..+$") ~= nil then
					-- read and compress file content
					file:write(elementPath .. "\n")

					local file2 = io.open(elementPath, "r")
					for line in file2:lines() do
						file:write(data.encode64(data.deflate(line)) .. "\n")
						os.sleep(0)
					end

					file2:close()
					print(elementPath)

					-- renameing is for dual extension bug
					fs.rename(path .. ".zip", path:match("(.+)%..+$") .. ".zip")
				else
					table.insert(notAdded, tostring(path))
				end
			end)

			if not success and result ~= nil then
				print("Error: " .. result)
				errorCount = errorCount + 1
				table.insert(notAdded, tostring(path))
			end
		end
	end
	
	traverseDirectory(path)
	
	file:close()

	print("File(s) compressed with " .. errorCount .. "error(s). Saved as " .. zipPath)
	if notAdded ~= nil then
		print("The following files were not added for what ever reason, likley a .zip or too large.")
		for k,v in ipairs(notAdded) do
			print(v)
		end
	end
end

local function decompress(path)
	if path == nil or not fs.exists(path) or fs.isDirectory(path) then
        print("No specified file")
        os.exit()
    end
    
    local outputDir = shell.getWorkingDirectory() .. "/" .. fs.name(path):match("(.+)%..+$")
	local counter = 0
	local d = outputDir
	while fs.exists(outputDir) do
		counter = counter + 1
		outputDir = d .. counter
	end
    fs.makeDirectory(outputDir)

	local errorCount = 0
	local errorFiles = {}

	local file = io.open(path, "r")
	local newFile = nil
	local newFileDir = nil
	for line in file:lines() do
		if line:match("^/.+/$") ~= nil and not line:match("[^/]+%..+") then
			if newFile then
				newFile:close()
			end

			fs.makeDirectory(outputDir .. line)
			print(outputDir .. line)
			os.sleep(0)
		elseif line:match(".+/[%w/]+%..+$") ~= nil then
			if newFile then
				newFile:close()
			end

			newFileDir = outputDir .. line
			newFile = io.open(newFileDir, "w")
			print(newFileDir)
			os.sleep(0)
		else
			local success, result = pcall(function()
				local lineDat = data.inflate(data.decode64(line))
				newFile:write(lineDat .. "\n")
			end)

			if not success and result ~= nil then
				print("Error: " .. result)
				errorCount = errorCount + 1
				table.insert(errorFiles, tostring(newFileDir))
				newFile:close()
			end
		end
		os.sleep(0)
	end

	print("File unzipped. Saved to " .. outputDir)
	if errorCount ~= 0 then
		print(errorCount .. " error(s) occoured durring file compression. The following file(s) were not zipped:")
		for k,v in ipairs(errorFiles) do
			print(v)
		end
	end
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

	local dataTier = nil
	if component.isAvailable("data") then
		local devices = computer.getDeviceInfo()
	
		for address, info in pairs(devices) do
			if info.type == "data" then
				local tier = info.tier
	
				if tier == 1 then
					dataTier = 1
				elseif tier >= 2 then
					dataTier = 2
				end
			end
		end
	end

	local keyFile = io.open(keyPath, "r")
	if not keyFile and dataTier == 2 then
		print("No key, generate one with the key function or put an existing key in " .. '"' .. keyPath .. '"')
		os.exit()
	end

	local key = keyFile:read("*all")
	keyFile:close()

	if key == nil and dataTier == 2 then
		print("Key is empty, generate one with the key function or put an existing key in ".. '"' .. keyPath .. '"')
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
		-- compress file
		TZL.compress(arg[2])

		tmpFile = io.open(tmpPath, "r")
		file = io.open(arg[2], "w")
		for line in tmpFile:lines() do
			line = tostring(line)
			if dataTier == 1 then
				file:write(data.encode64(line) .. "\n")
			else
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

		-- compress file
		TZL.compress(arg[2])
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