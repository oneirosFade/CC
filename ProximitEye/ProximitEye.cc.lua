-- ProximitEye v1.01
-- oneirosFade 2013
-- GPLv3 Licensed

-- APIs

os.loadAPI("/ocs/apis/sensor")
os.loadAPI(shell.resolve("../APIs/SensorX"))
os.loadAPI(shell.resolve("../APIs/Conf"))
os.loadAPI(shell.resolve("../APIs/Map"))

-- Namespace

local prox = {}
prox.stateMap = {}
prox.lastMap = {}
prox.invTracker = {}

prox.config = {}

-- Functions

function prox.checkCoords(pX, pY, pZ)
  if (((pX >= prox.config.v1x) and (pX <= prox.config.v2x)) or ((pX <= prox.config.v1x) and (pX >= prox.config.v2x))) then
    if (((pY >= prox.config.v1y) and (pY <= prox.config.v2y)) or ((pY <= prox.config.v1y) and (pY >= prox.config.v2y))) then
      if (((pZ >= prox.config.v1z) and (pZ <= prox.config.v2z)) or ((pZ <= prox.config.v1z) and (pZ >= prox.config.v2z))) then
        return true
      end
    end
  end
  return false
end

function prox.checkName(pName)
  for pIndex, pAuth in pairs(prox.config.authorized) do
    if (pName == pAuth) then
      return false -- False for authorized, do not track
    end
  end
  return true -- True for unauthorized, track this
end

function prox.doEnter(entityKey)
  print("+ " .. entityKey) -- Should always be username
  prox.invTracker[entityKey] = prox.nextMap[entityKey].detail.Inventory
end

function prox.doLeave(OldEntity)
  print("- " .. OldEntity)
end

function prox.doInventory(eName, invSlot, NewData)
  print(eName .. "/" .. invSlot .. " " ..
    prox.invTracker[eName][invSlot].Size .. "x" ..
    prox.invTracker[eName][invSlot].Name .. " -> " ..
    NewData.Size .. "x" .. NewData.Name)
  prox.invTracker[eName][invSlot] = NewData
end

function prox.getEntered(nextMap)
  for eKey, eData in pairs(prox.lastMap) do
    nextMap[eKey] = eData
    local kPos = eData.Position
    if (prox.checkName(eData.Name) and prox.checkCoords(kPos.X, kPos.Y, kPos.Z)) then
      if Map.hasKey(prox.stateMap, eKey) then
        -- Entity has been seen already
        -- Check Inventory
        local targetInfo = SensorX.getDetails(prox.sensor, eKey)
        --if (targetInfo) then -- Make sure it hasn't vanished!
          for i=1,42 do
            if (targetInfo.Inventory[i].Name == prox.invTracker[eData.Name][i].Name) then
              if (targetInfo.Inventory[i].Size == prox.invTracker[eData.Name][i].Size) then
                --- Nothing yet
              else
                prox.doInventory(eKey, i, targetInfo.Inventory[i])
              end
            else
              prox.doInventory(eKey, i, targetInfo.Inventory[i])
            end
          end
        --end
      else
        -- New entity detected
        prox.doEnter(eKey)
      end
    end
  end
  return nextMap
end

function prox.getLeft(nextMap)
  for eKey, eData in pairs(prox.stateMap) do
    local kPos = eData.Position
    if (prox.checkName(eData.Name) and prox.checkCoords(kPos.X, kPos.Y, kPos.Z)) then
      if Map.hasKey(prox.lastMap, eKey) then
        -- Still present
      else
        -- Entity left
        prox.doLeave(eKey)
      end
    end
  end
  return nextMap
end

function prox.showGUI()
  local tX, tY = term.getCursorPos()
  term.setCursorPos(1, 1)
  term.clearLine()
  print("ProximitEye")
  term.setCursorPos(1, 2)
  term.clearLine()
  print("Checking (" ..
        prox.config.v1x .. ", " ..
        prox.config.v1y .. ", " ..
        prox.config.v1z .. ")-(" ..
        prox.config.v2x .. ", " ..
        prox.config.v2y .. ", " ..
        prox.config.v2z .. ")")
  term.setCursorPos(1, 3)
  term.clearLine()
  print("---------------------------------------------------")
  term.setCursorPos(tX, tY)
end

-- Main

-- Get a handle to the sensor
prox.sensor = SensorX.wrapSensor()
if (not prox.sensor) then
  print ("!! This utility requires a sensor with the Entity card.")
  return false
end

-- Load the config, handle missing configs
prox.config = Conf.loadConfig("Prox.conf")
if (not prox.config) then
  prox.config = {v1x = -9999, v1y = 1, v1z = -9999, v2x = 9999, v2y = 255, v2z = 9999,
    authorized = {}}
end

-- Clear screen
term.clear()

-- Fill initial statemap
prox.stateMap = SensorX.getPlayers(prox.sensor)
for eKey, eData in pairs(prox.stateMap) do
  prox.invTracker[eKey] = eData.detail.Inventory
end

term.setCursorPos(1,4)
while true do  
  prox.showGUI()
  prox.lastMap = SensorX.getPlayers(prox.sensor)
  local nextMap = {}

  -- Check for new entities
  nextMap = prox.getEntered(nextMap)
  nextMap = prox.getLeft(nextMap)

  prox.stateMap = nextMap
      
  os.sleep(1)
end
