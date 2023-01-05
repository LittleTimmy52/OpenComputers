-- for GERTi
local GERTi = require("GERTiClient")
------------------------------
-- Server Filesystem Script --
------------------------------
-- Configuration --
local timeoutPeriod = 10
local useTunnelOverModem = true
local autoMountServerFS = true
local activateServerFSModule = true
local virtualizeServerFSComponent = true
local throwSoftErrors = false

-- Modules 
local computer = require("computer")
local component = require("component")
local serialization = require("serialization")
local event = require("event")
local filesystem = require("filesystem")

-- Set up the server filesystem component --
local serverFS = {
	type = "filesystem",
	address = "0000-remoteFS"
}
local functionList = {
	"spaceTotal", "spaceUsed", "spaceFree", "getLabel", "setLabel", "isReadOnly",
	"exists", "isDirectory", "size", "lastModified", "list",
	"rename", "remove", "makeDirectory",
	"open", "close", "read", "write", "seek", 
}
local functionHelp = {
	spaceUsed = "function():number -- The currently used capacity of the file system, in bytes.",
	spaceFree = "function():number -- The current amount of free space on the file system, in bytes.",
	open = "function(path:string[, mode:string='r']):number -- Opens a new file descriptor and returns its handle.",
	seek = "function(handle:number, whence:string, offset:number):number -- Seeks in an open file descriptor with the specified handle. Returns the new pointer position.",
	makeDirectory = "function(path:string):boolean -- Creates a directory at the specified absolute path in the file system. Creates parent directories, if necessary.",
	exists = "function(path:string):boolean -- Returns whether an object exists at the specified absolute path in the file system.",
	isReadOnly = "function():boolean -- Returns whether the file system is read-only.",
	write = "function(handle:number, value:string):boolean -- Writes the specified data to an open file descriptor with the specified handle.",
	spaceTotal = "function():number -- The overall capacity of the file system, in bytes.",
	isDirectory = "function(path:string):boolean -- Returns whether the object at the specified absolute path in the file system is a directory.",
	rename = "function(from:string, to:string):boolean -- Renames/moves an object from the first specified absolute path in the file system to the second.",
	list = "function(path:string):table -- Returns a list of names of objects in the directory at the specified absolute path in the file system.",
	lastModified = "function(path:string):number -- Returns the (real world) timestamp of when the object at the specified absolute path in the file system was modified.",
	getLabel = "function():string -- Get the current label of the file system.",
	remove = "function(path:string):boolean -- Removes the object at the specified absolute path in the file system.",
	close = "function(handle:number) -- Closes an open file descriptor with the specified handle.",
	size = "function(path:string):number -- Returns the size of the object at the specified absolute path in the file system.",
	read = "function(handle:number, count:number):string or nil -- Reads up to the specified amount of data from an open file descriptor with the specified handle. Returns nil when EOF is reached.",
	setLabel = "function(value:string):string -- Sets the label of the file system. Returns the new value, which may be truncated.",
}

-- Build the serverFS component module --
local lastCall = computer.uptime()
print("lastCall: " .. lastCall)
for key, value in ipairs(functionList) do
	print("key: " .. key)
	serverFS[value] = setmetatable({}, {
		__call = function(self, ...)
		print("__call" .. __call)
			if computer.uptime() - lastCall < .7 then
				os.sleep(.7 - (computer.uptime() - lastCall))
			end
			lastCall = computer.uptime()
			print("lastCall: " .. lastCall)
			
			-- Determine if we want to use the modem or tunnel.
			if (GERTi) then
				-- Use the modem
				GERTi.broadcast(serialization.serialize({value, ...}))
				print(GERTi.broadcast(serialization.serialize({value, ...})))
				while true do
					local evt = {event.pull("GERTData")}
					print("evt" .. serialization.serialize(evt))
					print("evt[4]" .. evt[4])

					if not evt[4] then
						return false, "The request timed out. The server may not be online or is handling too many requests."
					end
					if evt[4] then
						local args = serialization.unserialize(evt[4])
						if args[1] == true then
							table.remove(args, 1)
						else
							if throwSoftErrors then
								return false, args[2]
							else
								error(args[1], 2)
							end
						end
						for key, value in pairs(args) do
							if tonumber(value) then
								args[key] = tonumber(value)
							elseif value == "true" then
								args[key] = true
							elseif value == "false" then
								args[key] = false
							end
						end
						print("table.unpack(args)" .. table.unpack(args))
						return table.unpack(args)
					end
				end
			end,
		__tostring = functionHelp[value] or "function()",
	})
end

-- Mount this filesystem --
if autoMountServerFS then
	local success, errorMessage = filesystem.mount(serverFS, "srv")
	if not success then
		io.stderr:write("Failed to mount server: "..tostring(errorMessage).."\n")
	end
end

-- Add this to the loaded modules --
if activateServerFSModule then
	package.loaded["serverFS"] = serverFS
end

-- Insert the virtual serverFS component to the component API --
if virtualizeServerFSComponent then
	pcall(function()
		local component = require("component")
		local serverFS = serverFS
		if not serverFS then
			serverFS = require("serverFS")
		end

		local oldDoc = component.doc
		local oldList = component.list
		local oldProxy = component.proxy
		local oldInvoke = component.invoke
		local oldMethods = component.methods
		local oldType = component.type

		local sfsAddress = serverFS.address

		function component.doc(address, method)
			if address == sfsAddress then
				return tostring(serverFS[method])
			end
			return oldDoc
		end
		function component.list(filter, exact)
			if type(filter) == "string" then
				if (exact and filter == "filesystem") or (not exact and filter:find(("filesystem"):sub(1, #filter))) then
					local realItems = {}
					for x, y in oldList(filter, exact or false) do
						realItems[x] = y
					end
					realItems[sfsAddress] = serverFS.type
					local ilterator = function()
						for x, y in pairs(realItems) do
							coroutine.yield(x, y)
						end
					end
					return coroutine.wrap(ilterator)
				end
				return oldList(filter, exact)
			end
			return oldList(filter, exact)
		end
		function component.proxy(address)
			if address == sfsAddress then
				return serverFS
			end
			return oldProxy(address)
		end
		function component.invoke(address, funct, ...)
			if address == sfsAddress then
				return serverFS[funct](...)
			end
			return oldInvoke(address, funct, ...)
		end
		function component.methods(address)
			if address == sfsAddress then
				local functions = {}
				for key, value in pairs(serverFS) do
					if type(value) == "function" then
						functions[key] = false
					end
				end
				return functions
			end
			return oldMethods(address)
		end
		function component.type(address)
			if address == sfsAddress then
				return "filesystem"
			end
			return oldType(address)
		end
	end)
end