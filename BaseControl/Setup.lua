local event = require("event")
local filesyetem = require("filesystem")
local component = require("component")
local internet = component.internet

local urlFile = "/home/URLFile.txt"
local baseLink = "https://raw.githubusercontent.com/LittleTimmy52/OpenComputers/refs/heads/master/BaseControl"
local timeout = 60

local urls = {}
local file = io.open(urlFile, "r")
for line in file:lines() do
	table.insert(urls, line)
end

print("Please insert a floppy disk to install to.")
print("Reinsert if already inserted.")

local address
local type
repeat
	_, address, type = event.pull("component_added", timeout)
until type == "filesystem"

filesyetem.mount(address, "/tmp/")

print("Mounted, please wait, downloading in progress.")

local function extractDirs(path)
	local fileRemoved = path:match("(.*/)")
	if not path_without_filename then return {} end

	local subdirectories = {}
	for dir in path_without_filename:gmatch("([^/]+)/") do
		table.insert(subdirectories, dir)
	end

	return subdirectories
end

for _, url in ipairs(urls) do
	local tail = url:sub(string.len(baseLink) + 1)
	for _, dir in ipairs(extractDirs(tail)) do
		if filesyetem.isDirectory("/tmp/" .. dir)
	end
end

