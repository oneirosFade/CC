-- --------------------------------------------- --
-- ProximitEye v1.00                             --
-- --------------------------------------------- --

-- GLOBAL SPACE --

local prox = {}
prox.stateMap = {}
prox.lastMap = {}
prox.tracking = {}

-- FUNCTIONS --

function prox.getSensor()
  local d = {"left", "right", "top", "bottom", "back", "front"}
  for i=1,6 do
    if peripheral.isPresent(d[i]) then
      if peripheral.getType(d[i]) == "sensor" then
        return sensor.wrap(d[i])
      end
    end
  end

  print("No sensor found. Exiting program.")
  exit(1)
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
  local targetInfo = prox.sensor.getTargetDetails(NewEntity)
  prox.tracking[NewEntity] = targetInfo.Inventory
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
    if k ~= "oneirosFade" then
    if prox.hasKey(prox.stateMap, k) then
      -- Entity has been seen already
      -- Check Inventory
      local targetInfo = prox.sensor.getTargetDetails(k)
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
    if k ~= "oneirosFade" then
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

-- MAIN

os.loadAPI("ocs/apis/sensor")
prox.sensor = prox.getSensor()

term.clear()

prox.stateMap = prox.getPlayers(prox.sensor.getTargets())
for k,v in pairs(prox.stateMap) do
  prox.tracking[k] = prox.sensor.getTargetDetails(k).Inventory
end
term.setCursorPos(1,3)
while true do  
  local tx,ty = term.getCursorPos()
  term.setCursorPos(39,1)
  print("| ProximitEye")
  term.setCursorPos(39,2)
  print("+------------")
  term.setCursorPos(tx,ty)
    prox.lastMap = prox.getPlayers(prox.sensor.getTargets())
  local nextMap = {}

  -- Check for new entities
  nextMap = prox.getEntered(nextMap)
  nextMap = prox.getLeft(nextMap)

  prox.stateMap = nextMap
      
  os.sleep(1)

end
