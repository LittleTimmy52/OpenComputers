local component = require("component")
local modem = component.modem
local event = require("event")
local serialization = require("serialization")
local data = component.data -- Assuming data card is available

local port2 = 1234
local controllerInterfaceAddress = "interface network card address here" -- Replace with the actual address
local password = "SecurePresharedPassword" -- Ensure this matches the main interface

local function encr(decryptedData)
  local key = data.md5(password)
  local iv = data.random(16)
  local encryptedData = data.encrypt(decryptedData, key, iv)
  return serialization.serialize({encrypted = encryptedData, iv = iv})
end

local function decr(encryptedData)
  local key = data.md5(password)
  local decoded = serialization.unserialize(encryptedData)
  return serialization.unserialize(data.decrypt(decoded.encrypted, key, decoded.iv))
end

local function remoteGetInfo(option, tableIndex)
  local message
  if option == 1 or option == 6 then
    message = "getInfo-" .. option
  else
    message = "getInfo-" .. option .. "-" .. tableIndex
  end

  modem.send(controllerInterfaceAddress, port2, encr(message)) -- Encrypt the message

  local _, _, _, _, _, response = event.pull("modem_message", 10)

  if response then
    return decr(response) -- Decrypt the response
  else
    return nil
  end
end

local function remoteManToggle(name, signal)
  local message = "manToggle-" .. name .. "-" .. signal
  modem.send(controllerInterfaceAddress, port2, encr(message)) -- Encrypt the message

  local _, _, _, _, _, response = event.pull("modem_message", 10)

  if response then
    return decr(response) -- Decrypt the response
  else
    return nil
  end
end

local function remoteManUpdate()
  modem.send(controllerInterfaceAddress, port2, encr("manUpdate")) -- Encrypt the message

  local _, _, _, _, _, response = event.pull("modem_message", 10)

  if response then
    return decr(response) -- Decrypt the response
  else
    return nil
  end
end

local function remoteManReset()
  modem.send(controllerInterfaceAddress, port2, encr("manReset")) -- Encrypt the message

  local _, _, _, _, _, response = event.pull("modem_message", 10)

  if response then
    return decr(response) -- Decrypt the response
  else
    return nil
  end
end

local function remoteInterface()
  while true do
    print("Remote Interface:")
    print("[1] Get Info")
    print("[2] Manual Toggle")
    print("[3] Manual Update")
    print("[4] Manual Reset")
    print("[5] Exit")

    local choice = tonumber(io.read())

    if choice == 1 then
      print("Select info type (1-6):")
      local infoType = tonumber(io.read())

      local tableIndex = nil
      if infoType ~= 1 and infoType ~= 6 then
        print("Enter table index:")
        tableIndex = tonumber(io.read())
      end

      local result = remoteGetInfo(infoType, tableIndex)
      if result then
        print("Result:", result)
      else
        print("Failed to get info.")
      end
    elseif choice == 2 then
      print("Enter name:")
      local name = io.read()
      print("Enter signal:")
      local signal = tonumber(io.read())
      local result = remoteManToggle(name, signal)

      if result then
        print("Result:", result)
      else
        print("Toggle failed.")
      end

    elseif choice == 3 then
        local result = remoteManUpdate()
        if result then
            print("result:", result)
        else
            print("update failed")
        end
    elseif choice == 4 then
        local result = remoteManReset()
        if result then
            print("result:", result)
        else
            print("reset failed")
        end
    elseif choice == 5 then
      break
    else
      print("Invalid choice.")
    end
  end
end

remoteInterface()