-- ProximitEye v1.01
-- oneirosFade 2013
-- GPLv3 Licensed

-- Namespace

local prox = {}
prox.stateMap = {}
prox.lastMap = {}
prox.tracking = {}

prox.config = {}

-- Functions

function prox.getDetails(k)
  local pcS, pcD = pcall(function() prox.sensor.getTargetDetails(k) end)
  if (not pcS) then
    print(pcD)
    return nil
  else
    return pcD
  end
end

function prox.getSensor()
  local d = {"left", "right", "top", "bottom", "back", "front"}
  for i=1,6 do
    if peripheral.isPresent(d[i]) then
      if peripheral.getType(d[i]) == "sensor" then
        return sensor.wrap(d[i])
      end
    end
  end

  return nil
end

function prox.getConfig()
  local fAbsPath = shell.resolve("./Prox.conf")
  if (not fs.exists(fAbsPath)) then
    return false
  end
  local fHandle = fs.open(fAbsPath, "r")
  local fData = fHandle.readAll()
  fHandle.close()
  prox.config = textutils.unserialize(fData)
end

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
  for pNum,pAuth in pairs(prox.config.authorized) do
    if (pName == pAuth) then
      return false -- False for authorized, do not track
    end
  end
  return true -- True for unauthorized, track this
end

function prox.getPlayers(EntityMap)
  local PlayerMap = {}
  for k,v in pairs(EntityMap) do
    if v.Name == "Player" then
      PlayerMap[k] = v
    end
  end
  return PlayerMap
end

function prox.hasKey(Map, Key)
  for k,v in pairs(Map) do
    if k == Key then
      return true
    end
  end
  return false
end

function prox.getInventory(PlayerData)
  local PlayerInventory = {}
  for k,v in pairs(PlayerData.Inventory) do
    PlayerInventory[k] = v
  end
  return PlayerInventory
end

function prox.doEnter(NewEntity)
  print("+ " .. NewEntity)
  local targetInfo = prox.getDetails(NewEntity)
  prox.tracking[NewEntity] = targetInfo
end

function prox.doLeave(OldEntity)
  print("- " .. OldEntity)
end

function prox.doInventory(Entity, Slot, New)
  print(Entity .. "/" .. Slot .. " " ..
    prox.tracking[Entity][Slot].Size .. "x" ..
    prox.tracking[Entity][Slot].Name .. " -> " ..
    New.Size .. "x" .. New.Name)
  prox.tracking[Entity][Slot] = New 
end

function prox.getEntered(nextMap)
  for k,v in pairs(prox.lastMap) do
    nextMap[k] = v
    local kPos = v.Position
    if (prox.checkName(k) and prox.checkCoords(kPos.X, kPos.Y, kPos.Z)) then
      if prox.hasKey(prox.stateMap, k) then
        -- Entity has been seen already
        -- Check Inventory
        local targetInfo = prox.getDetails(k)
        if (targetInfo) then -- Make sure it hasn't vanished!
          for i=1,42 do
            if (targetInfo.Inventory[i].Name == prox.tracking[k][i].Name) then
              if (targetInfo.Inventory[i].Size == prox.tracking[k][i].Size) then
                --- Nothing yet
              else
                prox.doInventory(k, i, targetInfo.Inventory[i])
              end
            else
              prox.doInventory(k, i, targetInfo.Inventory[i])
            end
          end
        end
      else
        -- New entity detected
        prox.doEnter(k)
      end
    end
  end
  return nextMap
end

function prox.getLeft(nextMap)
  for k,v in pairs(prox.stateMap) do
    local kPos = v.Position
    if (prox.checkName(k) and prox.checkCoords(kPos.X, kPos.Y, kPos.Z)) then
      if prox.hasKey(prox.lastMap, k) then
        -- Still present
      else
        -- Entity left
        prox.doLeave(k)
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

os.loadAPI("ocs/apis/sensor")

prox.sensor = prox.getSensor()
if (not prox.sensor) then
  print ("!! This utility requires a sensor with the Entity card.")
  return false
end

prox.getConfig()
if (not prox.config.v1x) then
  prox.config = {v1x = -9999, v1y = 1, v1z = -9999, v2x = 9999, v2y = 255, v2z = 9999,
    authorized = {}}
end

term.clear()

prox.stateMap = prox.getPlayers(prox.sensor.getTargets())
for k,v in pairs(prox.stateMap) do
  prox.tracking[k] = prox.sensor.getTargetDetails(k)
end
term.setCursorPos(1,4)
while true do  
  prox.showGUI()
  prox.lastMap = prox.getPlayers(prox.sensor.getTargets())
  local nextMap = {}

  -- Check for new entities
  nextMap = prox.getEntered(nextMap)
  nextMap = prox.getLeft(nextMap)

  prox.stateMap = nextMap
      
  os.sleep(1)
end
