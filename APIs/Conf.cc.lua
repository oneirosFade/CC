-- Config File API
-- onerosFade 2013
-- GPLv3 Licensed

-- Open specified config file and return its
-- contents, unserialized
function loadConfig(confName)
  local absPath = shell.resolve("./"..confName)
  if (not fs.exists(absPath)) then
    return false
  end
  local hFile = fs.open(absPath, "r")
  local serData = hFile.readAll()
  hFile.close()
  return textutils.unserialize(serData)
end
