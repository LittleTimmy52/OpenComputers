local data = require("component").data
local fs = require("filesystem")
local serialization = require("serialization")
local shell = require("shell")

local arg = {...}

local function help()
	print("This is a simple program to compress and decompress files. Please note that any extensionless files or fhose that end in .zip and any file larger than 90000 will be skipped for technical reasons")
	print("Usage: TrashZip <option: compress, decompress, help> <option: full path>")
	print("compress: Takes your file or directory and compresses it into a .zip file. (TrashZip compress /home/exampleDir) Use full path and no trailing slashes. (/home not /home/)")
	print("decompress: Taakes any .zip file made by this program and decompresses it back to its origonal form. (TrashZip decompress /home/exampleDir.zip) Use full path.")
	print("help: display this text")
end

local function compress(path)
	if path == nil then
		print("No specified directory or file")
		os.exit()
	elseif fs.exists(path) == false then
		if fs.exists(shell.getWorkingDirectory() .. "/" .. path) == false then
			print("File or directory does not exist")
			os.exit()
		else
			path = shell.getWorkingDirectory() .. "/" .. path
		end
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
				local elementPath = fs.concat(path, element)
				elementPath = string.gsub(elementPath, "/$", "")

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

	print("File(s) compressed with " .. errorCount .. " error(s). Saved as " .. zipPath)
	print(serialization.serialize(notAdded))
	if notAdded ~= nil then
		print("The following files were not added for what ever reason, likley a .zip or too large.")
		for k,v in ipairs(notAdded) do
			print(v)
		end
	end
end

local function decompress(path)
	if path == nil or not fs.exists(path) or fs.isDirectory(path) then
		if fs.exists(shell.getWorkingDirectory() .. "/" .. path) == false then
	        print("No specified file")
    	    os.exit()
		else
			path = shell.getWorkingDirectory() .. "/" .. path
		end
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
		print(errorCount .. " error(s) occoured durring file compression. The following file(s) were not decompressed:")
		for k,v in ipairs(errorFiles) do
			print(v)
		end
	end
end

if arg[1] == "compress" or arg[1] == "zip" then
	compress(arg[2])
elseif arg[1] == "decompress" or arg[1] == "unzip" then
	decompress(arg[2])
else
	help()
end



--[[

THIS IS BROKEN FIX DECOMPRESSION AND MAKE THE THING USE BOTH EXACT FILE AND FILE IN SAME DIR
/HOME/TEST.TXT
TEST.TXT






]]