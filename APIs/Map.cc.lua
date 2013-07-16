-- Map Datatype API
-- oneirosFade 2013
-- GPLv3 Licensed

-- Iterate over a mapping searching for a given
-- key.
function hasKey(tMap, tKey)
  for key, val in pairs(tMap) do
    if (key == tKey) then
      return true
    end
  end
  return false
end
