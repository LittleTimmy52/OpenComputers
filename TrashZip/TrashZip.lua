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

--[[
	Compress function
	create a zip file with the files name but if it exists tack an incrementing number to it then add .zip. a.zip a1.zip a2.zip
	write file path
	encode deflate line then write it in a new line
	repeat for every line in the file
	write end flag of sorts in a new line
	close file and notify user
]]

local function compress(path)
	-- gets the path wether or not its full or from current dir
	path = shell.resolve(path)

	-- does it exist?
	if not fs.exists(path) then
		print("Please specify file or directory")
		os.exit()
	end

	-- create the zip file
	local zipPath = path:match("(.+)%.[^.]*$") .. ".zip"
	local counter = 0

	while fs.exists(zipPath) do
		counter = counter + 1
		zipPath = path:match("(.+)%.[^.]*$") .. counter .. ".zip"
	end
	
	local file = io.open(zipPath, "w")
	
	-- for error handleing later
	local errorCount = 0
	local notAdded = {}

	-- recursion for directories, if not it still works
	local traverseDirectory(file)
		if fs.isDirectory(file)
			file:write(file .. "\n")

			for element in fs.list(file) do
				local elementPath = fs.concat(path, element)

				-- do the function again but for sub directory or do single files
				if fs.isDirectory(elementPath) then
					traverseDirectory(elementPath)
					print(elementPath)
				else
					-- pcall comes in for error reporting
					local success, result = pcall(function()
						-- don't zip this file
						if elementPath ~= zipPath then
							file:write(elementPath .. "\n"
						
							-- read line by line and compress then write to zip
							local file2 = io.open(elementPath, "r")
							for line in file2:lines() do
								file:write(data.encode64(data.deflate(line)) .. "\n")
								os.sleep(0)
							end

							-- end flag
							file:write("cd This is the end of this file")

							file2:close()
							print(elementPath))
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
			local elementPath = fs.concat(path, element)
		end
	end

	traverseDirectory(path)

	file:close()

	-- notify user of errors and completion
	print("File(s) compressed with " .. errorCount .. " error(s). Saved as " .. zipPath)
	print(serialization.serialize(notAdded))
	if notAdded ~= nil then
		print("The following files were not added for what ever reason, likley a .zip or too large.")
		for k,v in ipairs(notAdded) do
			print(v)
		end
	end
end

--[[
	Decompress function
	create directory with the name of the zip and tack an incrementing number if it exists a a1 a2
	read the first line and tack the directory made on to the directory but get rid of extras ex line: /home/testing/ to: /home/test/testing/ not .home/test/home/testing/
	if the line was a file the same applies, make the directories then make the file
	once file open read the next line decode and decompress line write it to file
	repeat until the end flag is read
	if end flag is read then close file
	if more are present repeat process for it
]]

local function decompress(path)

end

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