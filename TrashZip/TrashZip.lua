local data = require("component").data
local fs = require("filesystem")
local serialization = require("serialization")
local shell = require("shell")

local arg = {...}

local function help()
	print("This is a simple program to compress and decompress files.")
	print("Usage: TrashZip <option: compress, decompress, help> <option: path>")
	print("compress: Takes your file or directory and compresses it into a .zip file. (TrashZip compress /home/exampleDir)")
	print("decompress: Takes any .zip file made by this program and decompresses it back to its origonal form. (TrashZip decompress /home/exampleDir.zip)")
	print("help: display this help info")
end

local function compress(path)
	-- gets the path wether or not its full or from current dir
	path = shell.resolve(path)

	-- does it exist?
	if not fs.exists(path) then
		print("Please specify file or directory")
		os.exit()
	end

	-- create the zip file
	local zipPath = nil
	local counter = 0

	if fs.isDirectory(path) then
		zipPath = path .. ".zip"
	else
		zipPath = path:match("(.+)%.[^.]*$") .. ".zip"
	end

	while fs.exists(zipPath) do
		counter = counter + 1
		zipPath = path:match("(.+)%.[^.]*$") .. counter .. ".zip"
	end
	
	local file = io.open(zipPath, "w")
	
	-- for error handleing later
	local errorCount = 0
	local notAdded = {}

	-- recursion for directories, if not it still works
	local function traverseDirectory(filePath)
		if fs.isDirectory(filePath) then
			-- directory flag with the path
			file:write("dir:" .. filePath .. "\n")

			for element in fs.list(filePath) do
				local elementPath = fs.concat(filePath, element)

				-- do the function again but for sub directory or do single files
				if fs.isDirectory(elementPath) then
					traverseDirectory(elementPath)
					print(elementPath)
				else
					-- pcall comes in for error reporting
					local success, result = pcall(function()
						-- don't zip this file
						if elementPath ~= zipPath then
							-- file flag with path
							file:write("file:" .. elementPath .. "\n")
						
							-- read line, compress, write to zip, then repeat
							local file2 = io.open(elementPath, "r")
							for line in file2:lines() do
								file:write(data.encode64(data.deflate(line)) .. "\n")
								os.sleep(0)
							end

							-- end flag
							file:write("This is the end of this file \n")

							file2:close()
							print(elementPath)
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
			-- pcall comes in for error reporting
			local success, result = pcall(function()
				-- directory flag and path and file flag and path
				file:write("dir:" .. fs.path(filePath) .. "\n")
				file:write("file:" .. filePath .. "\n")

				-- read line, compress, write to zip, then repeat
				local file2 = io.open(path, "r")
				for line in file2:lines() do
					file:write(data.encode64(data.deflate(line)) .. "\n")
					os.sleep(0)
				end

				-- end flag
				file:write("This is the end of this file \n")

				file2:close()
				print(path)
			end)

			-- for use later to tell user what files were not compressed to zip
			if not success then
				print("Error: " .. result)
				errorCount = errorCount + 1
				table.insert(notAdded, tostring(elementPath))
			end
		end
	end

	traverseDirectory(path)

	file:close()

	-- notify user of errors and completion
	print("File(s) compressed with " .. errorCount .. " error(s). Saved as " .. zipPath)
	if errorCount ~= 0 then
		print("File(s) effected:")
		for k,v in ipairs(notAdded) do
			print(v)
		end
	end
end

local function decompress(path)
	-- gets the path wether or not its full or from current dir
	path = shell.resolve(path)

	-- does it exist?
	if not fs.exists(path) then
		print("Please specify file or directory")
		os.exit()
	end

	-- output and errors
	local outputDir = path:match("(.+)%..+$")
	local counter = 0
	local tmp = outputDir

	-- make the directory
	while fs.exists(outputDir) do
		counter = counter + 1
		outputDir = tmp .. counter
	end

	fs.makeDirectory(outputDir)

	-- for error handleing later
	local errorCount = 0
	local errorFiles = {}

	-- read zip
	local file = io.open(path, "r")
	local newFile
	local tmp
	
	-- the operations
	for line in file:lines() do
		if string.match(line, "dir:") then -- directory
			-- make dir and print
			line = string.gsub(line, "dir:", "")
			fs.makeDirectory(outputDir .. line)
			print(outputDir .. line)
			os.sleep(0)
		elseif string.match(line,"file:") then -- file
			-- make file, open, then print
			line = string.gsub(line, "file:", "")
			newFile = io.open(outputDir .. line, "w")
			tmp = outputDir .. line
			print(outputDir .. line)
			os.sleep(0)
		elseif line:match("This is the end of this file") then -- end flag
			newFile:close()
			os.sleep(0)
		else -- data
			-- write to opened file
			local success, result = pcall(function()
				local lineDat = data.inflate(data.decode64(line))
				newFile:write(lineDat .. "\n")
			end)

			if not success then
				print("Error: " .. result)
				errorCount = errorCount + 1
				table.insert(errorFiles, tmp)
			end
			os.sleep(0)
		end
	end

	-- notify user of errors and completion
	print("File unzipped with " .. errorCount .. " error(s). Saved to " .. outputDir)
	if errorCount ~= 0 then
		print("File(s) effected:")
		for _, v in pairs(errorFiles) do
			print(v)
		end
	end
end

-- collect arguements
if arg[1] == "compress" or arg[1] == "zip" then
	if arg[2] ~= nil then
		compress(arg[2])
	else
		help()
	end
elseif arg[1] == "decompress" or arg[1] == "unzip" then
	if arg[2] ~= nil then
		decompress(arg[2])
	else
		help()
	end
else
	help()
end