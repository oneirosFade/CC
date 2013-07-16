-- ProximitEye Sensor API Extension
-- oneirosFade 2013
-- GPLv3 Licensed

-- Enumerate CC faces and cycle through looking for
-- a peripheral that declares itself a "sensor"
function wrapSensor()
  local faceEnum = {"left", "right", "top", 
                    "bottom", "back", "front"}
  for i=1,6 do
    if (peripheral.isPresent(faceEnum[i]) and 
      peripheral.getType(faceEnum[i]) == "sensor") then
      return sensor.wrap(faceEnum[i])
    end
  end
  return nil
end

-- Return details on target entity by key, or
-- return a pcall error for parsing by the main.
function safe_getDetails(hSensor, entityKey)
  local pcallOK, pcallRVal = pcall(
      function() 
        hSensor.getTargetDetails(entityKey) 
      end)
  if (pcallOK) then
    -- Success
    return pcallRVal
  else
    -- Failure
    print("!! Error in safe_getDetails: " .. pcallData)
    return nil
  end
end

-- Poll a given sensor for player-type entities
-- and return them in a k/v mapping.
function getPlayers(hSensor)
  local allMap = hSensor.getTargets()
  local playerMap = {}
  for entityKey, basicData in pairs(allMap) do
    if (basicData.Name == "Player") then
      playerMap[entityKey] = basicData
      playerMap[entityKey].detail = 
        safe_getDetails(hSensor, entityKey)
    end
  end
  return playerMap
end

